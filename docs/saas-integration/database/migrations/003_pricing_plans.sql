-- Resume-Matcher SaaS Pricing Plans
-- Adding specific products and prices for Resume-Matcher functionality

-- Insert Resume-Matcher Products
INSERT INTO public.stripe_products (
    stripe_product_id,
    name,
    description,
    active,
    created_at,
    updated_at
) VALUES 
(
    'prod_resume_matcher_free',
    'Resume Matcher Free',
    'Get started with basic resume analysis and job matching. Perfect for occasional job seekers.',
    true,
    now(),
    now()
),
(
    'prod_resume_matcher_pro',
    'Resume Matcher Pro',
    'Advanced resume optimization with unlimited analyses, ATS compatibility checks, and AI-powered improvement suggestions.',
    true,
    now(),
    now()
),
(
    'prod_resume_matcher_premium',
    'Resume Matcher Premium',
    'Everything in Pro plus premium templates, priority support, and advanced analytics for serious job seekers.',
    true,
    now(),
    now()
),
(
    'prod_resume_matcher_enterprise',
    'Resume Matcher Enterprise',
    'For teams and organizations. Bulk processing, API access, white-label options, and dedicated support.',
    true,
    now(),
    now()
)
ON CONFLICT (stripe_product_id) DO UPDATE SET
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    active = EXCLUDED.active,
    updated_at = now();

-- Insert Resume-Matcher Pricing Plans
INSERT INTO public.stripe_prices (
    stripe_price_id,
    stripe_product_id,
    unit_amount,
    currency,
    recurring_interval,
    active,
    created_at,
    updated_at
) VALUES 
-- Free Plan
(
    'price_resume_matcher_free',
    'prod_resume_matcher_free',
    0,
    'usd',
    null,
    true,
    now(),
    now()
),
-- Pro Plan - Monthly
(
    'price_resume_matcher_pro_monthly',
    'prod_resume_matcher_pro',
    1900, -- $19.00
    'usd',
    'month',
    true,
    now(),
    now()
),
-- Pro Plan - Yearly (2 months free)
(
    'price_resume_matcher_pro_yearly',
    'prod_resume_matcher_pro',
    19000, -- $190.00 (was $228)
    'usd',
    'year',
    true,
    now(),
    now()
),
-- Premium Plan - Monthly
(
    'price_resume_matcher_premium_monthly',
    'prod_resume_matcher_premium',
    3900, -- $39.00
    'usd',
    'month',
    true,
    now(),
    now()
),
-- Premium Plan - Yearly (2 months free)
(
    'price_resume_matcher_premium_yearly',
    'prod_resume_matcher_premium',
    39000, -- $390.00 (was $468)
    'usd',
    'year',
    true,
    now(),
    now()
),
-- Enterprise Plan - Monthly
(
    'price_resume_matcher_enterprise_monthly',
    'prod_resume_matcher_enterprise',
    9900, -- $99.00
    'usd',
    'month',
    true,
    now(),
    now()
),
-- Enterprise Plan - Yearly (2 months free)
(
    'price_resume_matcher_enterprise_yearly',
    'prod_resume_matcher_enterprise',
    99000, -- $990.00 (was $1188)
    'usd',
    'year',
    true,
    now(),
    now()
)
ON CONFLICT (stripe_price_id) DO UPDATE SET
    unit_amount = EXCLUDED.unit_amount,
    currency = EXCLUDED.currency,
    recurring_interval = EXCLUDED.recurring_interval,
    active = EXCLUDED.active,
    updated_at = now();

-- Create plan features table to define what each plan includes
CREATE TABLE IF NOT EXISTS public.plan_features (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id text REFERENCES public.stripe_products(stripe_product_id) NOT NULL,
    feature_name text NOT NULL,
    feature_value text, -- For numeric limits, JSON for complex features
    feature_type text NOT NULL CHECK (feature_type IN ('boolean', 'number', 'text', 'json')),
    display_order integer DEFAULT 0,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    
    UNIQUE(product_id, feature_name)
);

-- Enable RLS on plan_features
ALTER TABLE public.plan_features ENABLE ROW LEVEL SECURITY;

-- RLS Policy for plan_features (public read)
CREATE POLICY "Anyone can view plan features" ON public.plan_features FOR SELECT USING (true);
CREATE POLICY "Service role can manage plan features" ON public.plan_features FOR ALL USING (auth.role() = 'service_role');

-- Insert plan features
INSERT INTO public.plan_features (product_id, feature_name, feature_value, feature_type, display_order) VALUES
-- Free Plan Features
('prod_resume_matcher_free', 'monthly_analyses', '3', 'number', 1),
('prod_resume_matcher_free', 'resume_uploads', '3', 'number', 2),
('prod_resume_matcher_free', 'basic_matching', 'true', 'boolean', 3),
('prod_resume_matcher_free', 'match_score', 'true', 'boolean', 4),
('prod_resume_matcher_free', 'keyword_analysis', 'true', 'boolean', 5),
('prod_resume_matcher_free', 'basic_improvements', 'true', 'boolean', 6),
('prod_resume_matcher_free', 'export_results', 'false', 'boolean', 7),
('prod_resume_matcher_free', 'ats_compatibility', 'false', 'boolean', 8),
('prod_resume_matcher_free', 'premium_templates', 'false', 'boolean', 9),
('prod_resume_matcher_free', 'api_access', 'false', 'boolean', 10),
('prod_resume_matcher_free', 'support', 'Community', 'text', 11),

-- Pro Plan Features  
('prod_resume_matcher_pro', 'monthly_analyses', 'unlimited', 'text', 1),
('prod_resume_matcher_pro', 'resume_uploads', 'unlimited', 'text', 2),
('prod_resume_matcher_pro', 'basic_matching', 'true', 'boolean', 3),
('prod_resume_matcher_pro', 'advanced_matching', 'true', 'boolean', 4),
('prod_resume_matcher_pro', 'match_score', 'true', 'boolean', 5),
('prod_resume_matcher_pro', 'keyword_analysis', 'true', 'boolean', 6),
('prod_resume_matcher_pro', 'detailed_improvements', 'true', 'boolean', 7),
('prod_resume_matcher_pro', 'ats_compatibility', 'true', 'boolean', 8),
('prod_resume_matcher_pro', 'skills_gap_analysis', 'true', 'boolean', 9),
('prod_resume_matcher_pro', 'export_results', 'true', 'boolean', 10),
('prod_resume_matcher_pro', 'history_tracking', 'true', 'boolean', 11),
('prod_resume_matcher_pro', 'basic_templates', 'true', 'boolean', 12),
('prod_resume_matcher_pro', 'email_support', 'true', 'boolean', 13),
('prod_resume_matcher_pro', 'support', 'Email', 'text', 14),

-- Premium Plan Features
('prod_resume_matcher_premium', 'monthly_analyses', 'unlimited', 'text', 1),
('prod_resume_matcher_premium', 'resume_uploads', 'unlimited', 'text', 2),
('prod_resume_matcher_premium', 'basic_matching', 'true', 'boolean', 3),
('prod_resume_matcher_premium', 'advanced_matching', 'true', 'boolean', 4),
('prod_resume_matcher_premium', 'ai_optimization', 'true', 'boolean', 5),
('prod_resume_matcher_premium', 'match_score', 'true', 'boolean', 6),
('prod_resume_matcher_premium', 'keyword_analysis', 'true', 'boolean', 7),
('prod_resume_matcher_premium', 'detailed_improvements', 'true', 'boolean', 8),
('prod_resume_matcher_premium', 'ats_compatibility', 'true', 'boolean', 9),
('prod_resume_matcher_premium', 'skills_gap_analysis', 'true', 'boolean', 10),
('prod_resume_matcher_premium', 'export_results', 'true', 'boolean', 11),
('prod_resume_matcher_premium', 'history_tracking', 'true', 'boolean', 12),
('prod_resume_matcher_premium', 'premium_templates', 'true', 'boolean', 13),
('prod_resume_matcher_premium', 'cover_letter_generation', 'true', 'boolean', 14),
('prod_resume_matcher_premium', 'interview_preparation', 'true', 'boolean', 15),
('prod_resume_matcher_premium', 'linkedin_optimization', 'true', 'boolean', 16),
('prod_resume_matcher_premium', 'priority_support', 'true', 'boolean', 17),
('prod_resume_matcher_premium', 'support', 'Priority Email + Chat', 'text', 18),

-- Enterprise Plan Features
('prod_resume_matcher_enterprise', 'monthly_analyses', 'unlimited', 'text', 1),
('prod_resume_matcher_enterprise', 'resume_uploads', 'unlimited', 'text', 2),
('prod_resume_matcher_enterprise', 'team_accounts', 'unlimited', 'text', 3),
('prod_resume_matcher_enterprise', 'bulk_processing', 'true', 'boolean', 4),
('prod_resume_matcher_enterprise', 'api_access', 'true', 'boolean', 5),
('prod_resume_matcher_enterprise', 'white_label', 'true', 'boolean', 6),
('prod_resume_matcher_enterprise', 'custom_integrations', 'true', 'boolean', 7),
('prod_resume_matcher_enterprise', 'advanced_analytics', 'true', 'boolean', 8),
('prod_resume_matcher_enterprise', 'custom_templates', 'true', 'boolean', 9),
('prod_resume_matcher_enterprise', 'sso_integration', 'true', 'boolean', 10),
('prod_resume_matcher_enterprise', 'dedicated_support', 'true', 'boolean', 11),
('prod_resume_matcher_enterprise', 'sla_guarantee', 'true', 'boolean', 12),
('prod_resume_matcher_enterprise', 'support', 'Dedicated Account Manager', 'text', 13)
ON CONFLICT (product_id, feature_name) DO UPDATE SET
    feature_value = EXCLUDED.feature_value,
    feature_type = EXCLUDED.feature_type,
    display_order = EXCLUDED.display_order,
    updated_at = now();

-- Create usage limits table for easy plan checking
CREATE TABLE IF NOT EXISTS public.plan_limits (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id text REFERENCES public.stripe_products(stripe_product_id) NOT NULL,
    limit_type text NOT NULL, -- 'monthly_analyses', 'daily_analyses', 'resume_uploads', etc.
    limit_value integer, -- NULL means unlimited
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    
    UNIQUE(product_id, limit_type)
);

-- Enable RLS on plan_limits
ALTER TABLE public.plan_limits ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can view plan limits" ON public.plan_limits FOR SELECT USING (true);
CREATE POLICY "Service role can manage plan limits" ON public.plan_limits FOR ALL USING (auth.role() = 'service_role');

-- Insert plan limits
INSERT INTO public.plan_limits (product_id, limit_type, limit_value) VALUES
-- Free Plan Limits
('prod_resume_matcher_free', 'monthly_analyses', 3),
('prod_resume_matcher_free', 'daily_analyses', 1),
('prod_resume_matcher_free', 'resume_uploads', 3),
('prod_resume_matcher_free', 'file_size_mb', 5),

-- Pro Plan Limits (generous but reasonable)
('prod_resume_matcher_pro', 'monthly_analyses', NULL), -- unlimited
('prod_resume_matcher_pro', 'daily_analyses', 50),
('prod_resume_matcher_pro', 'resume_uploads', NULL), -- unlimited
('prod_resume_matcher_pro', 'file_size_mb', 10),

-- Premium Plan Limits (higher limits)
('prod_resume_matcher_premium', 'monthly_analyses', NULL), -- unlimited
('prod_resume_matcher_premium', 'daily_analyses', 100),
('prod_resume_matcher_premium', 'resume_uploads', NULL), -- unlimited
('prod_resume_matcher_premium', 'file_size_mb', 25),

-- Enterprise Plan Limits (essentially unlimited)
('prod_resume_matcher_enterprise', 'monthly_analyses', NULL), -- unlimited
('prod_resume_matcher_enterprise', 'daily_analyses', NULL), -- unlimited
('prod_resume_matcher_enterprise', 'resume_uploads', NULL), -- unlimited
('prod_resume_matcher_enterprise', 'file_size_mb', 100)
ON CONFLICT (product_id, limit_type) DO UPDATE SET
    limit_value = EXCLUDED.limit_value,
    updated_at = now();

-- Add updated_at triggers for new tables
CREATE TRIGGER update_plan_features_updated_at BEFORE UPDATE ON public.plan_features FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_plan_limits_updated_at BEFORE UPDATE ON public.plan_limits FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to check if user can perform an action based on their subscription
CREATE OR REPLACE FUNCTION check_user_plan_limit(
    p_user_id uuid,
    p_limit_type text,
    p_current_usage integer DEFAULT 0
)
RETURNS boolean AS $$
DECLARE
    user_product_id text;
    plan_limit integer;
BEGIN
    -- Get user's current subscription product
    SELECT sp.stripe_product_id INTO user_product_id
    FROM subscriptions s
    JOIN stripe_prices sp_price ON s.price_id = sp_price.id
    JOIN stripe_products sp ON sp_price.stripe_product_id = sp.stripe_product_id
    WHERE s.user_id = p_user_id
    AND s.status = 'active'
    ORDER BY 
        CASE WHEN sp_price.unit_amount > 0 THEN 1 ELSE 2 END, -- Paid subscriptions first
        s.created DESC
    LIMIT 1;
    
    -- If no subscription found, default to free plan
    IF user_product_id IS NULL THEN
        user_product_id := 'prod_resume_matcher_free';
    END IF;
    
    -- Get the limit for this plan
    SELECT limit_value INTO plan_limit
    FROM plan_limits
    WHERE product_id = user_product_id
    AND limit_type = p_limit_type;
    
    -- If no limit found or limit is NULL (unlimited), return true
    IF plan_limit IS NULL THEN
        RETURN true;
    END IF;
    
    -- Check if current usage is within limit
    RETURN p_current_usage < plan_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get user's plan features
CREATE OR REPLACE FUNCTION get_user_plan_features(p_user_id uuid)
RETURNS TABLE (
    product_id text,
    product_name text,
    feature_name text,
    feature_value text,
    feature_type text
) AS $$
DECLARE
    user_product_id text;
BEGIN
    -- Get user's current subscription product
    SELECT sp.stripe_product_id INTO user_product_id
    FROM subscriptions s
    JOIN stripe_prices sp_price ON s.price_id = sp_price.id
    JOIN stripe_products sp ON sp_price.stripe_product_id = sp.stripe_product_id
    WHERE s.user_id = p_user_id
    AND s.status = 'active'
    ORDER BY 
        CASE WHEN sp_price.unit_amount > 0 THEN 1 ELSE 2 END, -- Paid subscriptions first
        s.created DESC
    LIMIT 1;
    
    -- If no subscription found, default to free plan
    IF user_product_id IS NULL THEN
        user_product_id := 'prod_resume_matcher_free';
    END IF;
    
    -- Return plan features
    RETURN QUERY
    SELECT 
        pf.product_id,
        sp.name as product_name,
        pf.feature_name,
        pf.feature_value,
        pf.feature_type
    FROM plan_features pf
    JOIN stripe_products sp ON pf.product_id = sp.stripe_product_id
    WHERE pf.product_id = user_product_id
    ORDER BY pf.display_order;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Comments
COMMENT ON TABLE public.plan_features IS 'Defines what features are included in each subscription plan';
COMMENT ON TABLE public.plan_limits IS 'Defines usage limits for each subscription plan';
COMMENT ON FUNCTION check_user_plan_limit IS 'Checks if user can perform an action based on their plan limits';
COMMENT ON FUNCTION get_user_plan_features IS 'Returns all features available to a user based on their current plan';