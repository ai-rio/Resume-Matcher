-- Base SaaS Schema for Resume-Matcher
-- This migration sets up the core SaaS infrastructure including authentication, subscriptions, and user management
-- Based on Supabase Auth + Stripe integration pattern

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";

-- =============================================
-- AUTHENTICATION & USER MANAGEMENT
-- =============================================

-- Note: auth.users table is managed by Supabase Auth automatically
-- We extend it with a profiles table for additional user data

-- User profiles (extends Supabase auth.users)
CREATE TABLE IF NOT EXISTS public.profiles (
    id uuid REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    email text UNIQUE NOT NULL,
    full_name text,
    avatar_url text,
    company text,
    job_title text,
    industry text,
    
    -- User preferences
    timezone text DEFAULT 'UTC',
    notifications_enabled boolean DEFAULT true,
    marketing_emails boolean DEFAULT false,
    
    -- Profile completion tracking
    profile_completed boolean DEFAULT false,
    onboarding_completed boolean DEFAULT false,
    
    -- Timestamps
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

-- Admin roles for user management
CREATE TABLE IF NOT EXISTS public.admin_roles (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    role text NOT NULL CHECK (role IN ('admin', 'moderator', 'support')),
    granted_by uuid REFERENCES auth.users(id),
    granted_at timestamp with time zone DEFAULT now() NOT NULL,
    
    UNIQUE(user_id, role)
);

-- =============================================
-- STRIPE INTEGRATION
-- =============================================

-- Stripe customers mapping
CREATE TABLE IF NOT EXISTS public.customers (
    id uuid REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    stripe_customer_id text UNIQUE NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

-- Stripe products
CREATE TABLE IF NOT EXISTS public.stripe_products (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    stripe_product_id text UNIQUE NOT NULL,
    name text NOT NULL,
    description text,
    active boolean DEFAULT true,
    metadata jsonb DEFAULT '{}',
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

-- Stripe prices  
CREATE TABLE IF NOT EXISTS public.stripe_prices (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    stripe_price_id text UNIQUE NOT NULL,
    stripe_product_id text REFERENCES public.stripe_products(stripe_product_id) NOT NULL,
    unit_amount integer, -- in cents, null for free
    currency text DEFAULT 'usd',
    recurring_interval text CHECK (recurring_interval IN ('day', 'week', 'month', 'year')),
    active boolean DEFAULT true,
    metadata jsonb DEFAULT '{}',
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

-- User subscriptions
CREATE TABLE IF NOT EXISTS public.subscriptions (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    stripe_subscription_id text UNIQUE,
    stripe_customer_id text,
    price_id uuid REFERENCES public.stripe_prices(id) NOT NULL,
    status text NOT NULL CHECK (status IN ('active', 'canceled', 'incomplete', 'incomplete_expired', 'past_due', 'trialing', 'unpaid')),
    
    -- Subscription periods
    current_period_start timestamp with time zone,
    current_period_end timestamp with time zone,
    trial_start timestamp with time zone,
    trial_end timestamp with time zone,
    
    -- Cancellation
    cancel_at timestamp with time zone,
    cancel_at_period_end boolean DEFAULT false,
    canceled_at timestamp with time zone,
    ended_at timestamp with time zone,
    
    -- Metadata
    created timestamp with time zone DEFAULT now() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    
    -- Index for efficient queries
    CONSTRAINT unique_active_subscription_per_user UNIQUE (user_id, status) DEFERRABLE INITIALLY DEFERRED
);

-- Remove the unique constraint that was causing issues and add a better index
ALTER TABLE public.subscriptions DROP CONSTRAINT IF EXISTS unique_active_subscription_per_user;
CREATE UNIQUE INDEX IF NOT EXISTS idx_one_active_subscription_per_user 
ON public.subscriptions (user_id) 
WHERE status = 'active';

-- Stripe webhook events (for idempotency and debugging)
CREATE TABLE IF NOT EXISTS public.stripe_webhook_events (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    stripe_event_id text UNIQUE NOT NULL,
    event_type text NOT NULL,
    processed boolean DEFAULT false,
    processed_at timestamp with time zone,
    error_message text,
    data jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);

-- =============================================
-- SYSTEM CONFIGURATION
-- =============================================

-- Admin settings for system configuration
CREATE TABLE IF NOT EXISTS public.admin_settings (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    key text UNIQUE NOT NULL,
    value jsonb NOT NULL,
    description text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

-- =============================================
-- INDEXES FOR PERFORMANCE
-- =============================================

-- Profiles indexes
CREATE INDEX IF NOT EXISTS idx_profiles_email ON public.profiles(email);
CREATE INDEX IF NOT EXISTS idx_profiles_created_at ON public.profiles(created_at);

-- Subscriptions indexes
CREATE INDEX IF NOT EXISTS idx_subscriptions_user_id ON public.subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_status ON public.subscriptions(status);
CREATE INDEX IF NOT EXISTS idx_subscriptions_stripe_id ON public.subscriptions(stripe_subscription_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_created ON public.subscriptions(created);

-- Stripe webhook events indexes
CREATE INDEX IF NOT EXISTS idx_webhook_events_type ON public.stripe_webhook_events(event_type);
CREATE INDEX IF NOT EXISTS idx_webhook_events_processed ON public.stripe_webhook_events(processed);
CREATE INDEX IF NOT EXISTS idx_webhook_events_created_at ON public.stripe_webhook_events(created_at);

-- =============================================
-- ROW LEVEL SECURITY (RLS)
-- =============================================

-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stripe_products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stripe_prices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stripe_webhook_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_settings ENABLE ROW LEVEL SECURITY;

-- Profiles RLS policies
CREATE POLICY "Users can view own profile" ON public.profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);

-- Admin roles RLS policies  
CREATE POLICY "Admins can view admin roles" ON public.admin_roles FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM public.admin_roles ar 
        WHERE ar.user_id = auth.uid() 
        AND ar.role = 'admin'
    )
);

-- Customers RLS policies
CREATE POLICY "Users can view own customer data" ON public.customers FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can insert own customer data" ON public.customers FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Users can update own customer data" ON public.customers FOR UPDATE USING (auth.uid() = id);

-- Products and prices (public read access)
CREATE POLICY "Anyone can view active products" ON public.stripe_products FOR SELECT USING (active = true);
CREATE POLICY "Anyone can view active prices" ON public.stripe_prices FOR SELECT USING (active = true);

-- Subscriptions RLS policies
CREATE POLICY "Users can view own subscriptions" ON public.subscriptions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own subscriptions" ON public.subscriptions FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own subscriptions" ON public.subscriptions FOR UPDATE USING (auth.uid() = user_id);

-- Admin settings (admin only)
CREATE POLICY "Admins can view settings" ON public.admin_settings FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM public.admin_roles ar 
        WHERE ar.user_id = auth.uid() 
        AND ar.role = 'admin'
    )
);

-- Service role policies (for backend operations)
CREATE POLICY "Service role can manage profiles" ON public.profiles FOR ALL USING (auth.role() = 'service_role');
CREATE POLICY "Service role can manage customers" ON public.customers FOR ALL USING (auth.role() = 'service_role');
CREATE POLICY "Service role can manage products" ON public.stripe_products FOR ALL USING (auth.role() = 'service_role');
CREATE POLICY "Service role can manage prices" ON public.stripe_prices FOR ALL USING (auth.role() = 'service_role');
CREATE POLICY "Service role can manage subscriptions" ON public.subscriptions FOR ALL USING (auth.role() = 'service_role');
CREATE POLICY "Service role can manage webhook events" ON public.stripe_webhook_events FOR ALL USING (auth.role() = 'service_role');
CREATE POLICY "Service role can manage settings" ON public.admin_settings FOR ALL USING (auth.role() = 'service_role');

-- =============================================
-- FUNCTIONS & TRIGGERS
-- =============================================

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Add updated_at triggers
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_customers_updated_at BEFORE UPDATE ON public.customers FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_stripe_products_updated_at BEFORE UPDATE ON public.stripe_products FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_stripe_prices_updated_at BEFORE UPDATE ON public.stripe_prices FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_subscriptions_updated_at BEFORE UPDATE ON public.subscriptions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_admin_settings_updated_at BEFORE UPDATE ON public.admin_settings FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to handle new user registration (creates profile automatically)
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, full_name)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1))
    );
    RETURN NEW;
END;
$$ language 'plpgsql' SECURITY DEFINER;

-- Trigger to create profile on user registration
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- =============================================
-- INITIAL CONFIGURATION
-- =============================================

-- Insert default admin settings
INSERT INTO public.admin_settings (key, value, description) VALUES
('app_name', '"Resume Matcher"', 'Application name'),
('app_version', '"1.0.0"', 'Application version'),
('maintenance_mode', 'false', 'Whether the app is in maintenance mode'),
('max_file_size_mb', '10', 'Maximum file upload size in MB'),
('supported_file_types', '["application/pdf", "application/vnd.openxmlformats-officedocument.wordprocessingml.document"]', 'Supported file types for upload'),
('ai_provider', '"openai"', 'Default AI provider for analysis'),
('analysis_timeout_seconds', '300', 'Timeout for analysis operations'),
('stripe_config', '{"mode": "test", "webhook_secret": "", "publishable_key": "", "secret_key": ""}', 'Stripe configuration (to be updated with real values)')
ON CONFLICT (key) DO NOTHING;

-- =============================================
-- COMMENTS FOR DOCUMENTATION
-- =============================================

COMMENT ON TABLE public.profiles IS 'Extended user profile information beyond Supabase auth.users';
COMMENT ON TABLE public.admin_roles IS 'Admin role assignments for user management';
COMMENT ON TABLE public.customers IS 'Mapping between users and Stripe customers';
COMMENT ON TABLE public.stripe_products IS 'Stripe products for subscription plans';
COMMENT ON TABLE public.stripe_prices IS 'Stripe pricing information for products';
COMMENT ON TABLE public.subscriptions IS 'User subscription status and billing information';
COMMENT ON TABLE public.stripe_webhook_events IS 'Stripe webhook event processing log';
COMMENT ON TABLE public.admin_settings IS 'System-wide configuration settings';

COMMENT ON FUNCTION handle_new_user() IS 'Automatically creates user profile when new user registers via Supabase Auth';
COMMENT ON FUNCTION update_updated_at_column() IS 'Updates the updated_at timestamp on record modification';