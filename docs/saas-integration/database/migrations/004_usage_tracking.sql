-- Usage Tracking and Analytics Schema
-- This migration adds comprehensive usage tracking, analytics, and monitoring capabilities

-- =============================================
-- USAGE TRACKING & ANALYTICS
-- =============================================

-- User activity log for detailed tracking
CREATE TABLE IF NOT EXISTS public.user_activities (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    
    -- Activity details
    activity_type text NOT NULL CHECK (activity_type IN (
        'login', 'logout', 'signup', 'profile_update',
        'resume_upload', 'resume_delete', 'resume_view',
        'job_create', 'job_delete', 'job_view',
        'analysis_start', 'analysis_complete', 'analysis_fail',
        'subscription_start', 'subscription_cancel', 'subscription_renew',
        'template_use', 'export_resume', 'api_call'
    )),
    activity_description text,
    
    -- Context and metadata
    ip_address inet,
    user_agent text,
    referer text,
    page_url text,
    session_id text,
    
    -- Activity-specific data
    metadata jsonb DEFAULT '{}',
    
    -- Performance tracking
    duration_ms integer, -- For activities that take time (like analysis)
    success boolean DEFAULT true,
    error_message text,
    
    created_at timestamp with time zone DEFAULT now() NOT NULL
);

-- Daily user usage summary (for efficient quota checking)
CREATE TABLE IF NOT EXISTS public.daily_usage_summary (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    date date NOT NULL,
    
    -- Usage counters
    resumes_uploaded integer DEFAULT 0,
    jobs_created integer DEFAULT 0,
    analyses_performed integer DEFAULT 0,
    api_calls_made integer DEFAULT 0,
    templates_used integer DEFAULT 0,
    exports_generated integer DEFAULT 0,
    
    -- Resource usage
    storage_used_bytes bigint DEFAULT 0,
    ai_tokens_consumed integer DEFAULT 0,
    analysis_time_seconds integer DEFAULT 0,
    
    -- System metrics
    login_count integer DEFAULT 0,
    session_duration_minutes integer DEFAULT 0,
    
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    
    UNIQUE(user_id, date)
);

-- Monthly usage rollup (for billing and reporting)
CREATE TABLE IF NOT EXISTS public.monthly_usage_summary (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    year integer NOT NULL,
    month integer NOT NULL CHECK (month >= 1 AND month <= 12),
    
    -- Aggregated usage
    total_resumes_uploaded integer DEFAULT 0,
    total_jobs_created integer DEFAULT 0,
    total_analyses_performed integer DEFAULT 0,
    total_api_calls_made integer DEFAULT 0,
    total_templates_used integer DEFAULT 0,
    total_exports_generated integer DEFAULT 0,
    
    -- Resource usage
    total_storage_used_bytes bigint DEFAULT 0,
    total_ai_tokens_consumed integer DEFAULT 0,
    total_analysis_time_seconds integer DEFAULT 0,
    
    -- Engagement metrics
    active_days integer DEFAULT 0,
    total_session_duration_minutes integer DEFAULT 0,
    
    -- Billing information
    subscription_status text,
    plan_name text,
    billing_amount_cents integer DEFAULT 0,
    
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    
    UNIQUE(user_id, year, month)
);

-- Feature usage tracking (which features are used most)
CREATE TABLE IF NOT EXISTS public.feature_usage (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Feature identification
    feature_name text NOT NULL,
    feature_category text, -- 'core', 'premium', 'enterprise'
    
    -- Usage details
    usage_count integer DEFAULT 1,
    first_used_at timestamp with time zone DEFAULT now() NOT NULL,
    last_used_at timestamp with time zone DEFAULT now() NOT NULL,
    
    -- Context
    plan_when_used text, -- Which plan user had when using this feature
    success_rate decimal(5,2) DEFAULT 100.00, -- Success rate for this feature
    
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    
    UNIQUE(user_id, feature_name)
);

-- System-wide analytics (aggregated metrics)
CREATE TABLE IF NOT EXISTS public.system_analytics (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    date date NOT NULL UNIQUE,
    
    -- User metrics
    total_users integer DEFAULT 0,
    new_users integer DEFAULT 0,
    active_users integer DEFAULT 0,
    premium_users integer DEFAULT 0,
    
    -- Usage metrics
    total_analyses integer DEFAULT 0,
    total_resumes_uploaded integer DEFAULT 0,
    total_jobs_created integer DEFAULT 0,
    
    -- Performance metrics
    avg_analysis_time_seconds decimal(10,2) DEFAULT 0,
    success_rate decimal(5,2) DEFAULT 100.00,
    error_rate decimal(5,2) DEFAULT 0.00,
    
    -- Revenue metrics
    total_revenue_cents integer DEFAULT 0,
    new_subscriptions integer DEFAULT 0,
    canceled_subscriptions integer DEFAULT 0,
    
    -- System health
    uptime_percentage decimal(5,2) DEFAULT 100.00,
    avg_response_time_ms decimal(10,2) DEFAULT 0,
    
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

-- Error and issue tracking
CREATE TABLE IF NOT EXISTS public.error_logs (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
    
    -- Error details
    error_type text NOT NULL,
    error_code text,
    error_message text NOT NULL,
    stack_trace text,
    
    -- Context
    endpoint text,
    method text,
    request_id text,
    session_id text,
    
    -- Request details
    user_agent text,
    ip_address inet,
    request_body jsonb,
    response_status integer,
    
    -- Environment
    environment text DEFAULT 'production',
    version text,
    
    -- Resolution
    resolved boolean DEFAULT false,
    resolved_at timestamp with time zone,
    resolution_notes text,
    
    created_at timestamp with time zone DEFAULT now() NOT NULL
);

-- =============================================
-- PERFORMANCE & MONITORING
-- =============================================

-- API endpoint performance tracking
CREATE TABLE IF NOT EXISTS public.api_metrics (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Endpoint identification
    endpoint text NOT NULL,
    method text NOT NULL,
    
    -- Performance metrics
    response_time_ms integer NOT NULL,
    status_code integer NOT NULL,
    
    -- Request details
    user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
    request_size_bytes integer,
    response_size_bytes integer,
    
    -- Context
    user_agent text,
    ip_address inet,
    referer text,
    
    -- Timestamp (partitioned by date for performance)
    created_at timestamp with time zone DEFAULT now() NOT NULL
);

-- Partition api_metrics by month for better performance
-- Note: This is just documentation - actual partitioning would be set up during deployment
-- CREATE TABLE api_metrics_202501 PARTITION OF api_metrics FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');

-- Background job tracking
CREATE TABLE IF NOT EXISTS public.background_jobs (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Job identification
    job_type text NOT NULL,
    job_id text UNIQUE NOT NULL,
    
    -- Job details
    status text NOT NULL CHECK (status IN ('pending', 'running', 'completed', 'failed', 'canceled')),
    priority integer DEFAULT 0,
    
    -- Payload and results
    input_data jsonb,
    output_data jsonb,
    error_data jsonb,
    
    -- Progress tracking
    progress_percentage integer DEFAULT 0 CHECK (progress_percentage >= 0 AND progress_percentage <= 100),
    current_step text,
    total_steps integer,
    
    -- Timing
    scheduled_at timestamp with time zone DEFAULT now() NOT NULL,
    started_at timestamp with time zone,
    completed_at timestamp with time zone,
    
    -- Resource usage
    cpu_time_ms integer,
    memory_used_mb integer,
    
    -- Retry logic
    retry_count integer DEFAULT 0,
    max_retries integer DEFAULT 3,
    next_retry_at timestamp with time zone,
    
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

-- =============================================
-- INDEXES FOR PERFORMANCE
-- =============================================

-- User activities indexes
CREATE INDEX IF NOT EXISTS idx_user_activities_user_id ON public.user_activities(user_id);
CREATE INDEX IF NOT EXISTS idx_user_activities_type ON public.user_activities(activity_type);
CREATE INDEX IF NOT EXISTS idx_user_activities_created_at ON public.user_activities(created_at);
CREATE INDEX IF NOT EXISTS idx_user_activities_user_date ON public.user_activities(user_id, created_at);

-- Daily usage summary indexes
CREATE INDEX IF NOT EXISTS idx_daily_usage_user_id ON public.daily_usage_summary(user_id);
CREATE INDEX IF NOT EXISTS idx_daily_usage_date ON public.daily_usage_summary(date);
CREATE INDEX IF NOT EXISTS idx_daily_usage_user_date ON public.daily_usage_summary(user_id, date);

-- Monthly usage summary indexes
CREATE INDEX IF NOT EXISTS idx_monthly_usage_user_id ON public.monthly_usage_summary(user_id);
CREATE INDEX IF NOT EXISTS idx_monthly_usage_year_month ON public.monthly_usage_summary(year, month);

-- Feature usage indexes
CREATE INDEX IF NOT EXISTS idx_feature_usage_user_id ON public.feature_usage(user_id);
CREATE INDEX IF NOT EXISTS idx_feature_usage_feature_name ON public.feature_usage(feature_name);
CREATE INDEX IF NOT EXISTS idx_feature_usage_category ON public.feature_usage(feature_category);

-- API metrics indexes
CREATE INDEX IF NOT EXISTS idx_api_metrics_endpoint ON public.api_metrics(endpoint);
CREATE INDEX IF NOT EXISTS idx_api_metrics_created_at ON public.api_metrics(created_at);
CREATE INDEX IF NOT EXISTS idx_api_metrics_user_id ON public.api_metrics(user_id);
CREATE INDEX IF NOT EXISTS idx_api_metrics_response_time ON public.api_metrics(response_time_ms);

-- Background jobs indexes
CREATE INDEX IF NOT EXISTS idx_background_jobs_status ON public.background_jobs(status);
CREATE INDEX IF NOT EXISTS idx_background_jobs_type ON public.background_jobs(job_type);
CREATE INDEX IF NOT EXISTS idx_background_jobs_scheduled_at ON public.background_jobs(scheduled_at);
CREATE INDEX IF NOT EXISTS idx_background_jobs_next_retry ON public.background_jobs(next_retry_at) WHERE status = 'failed';

-- Error logs indexes
CREATE INDEX IF NOT EXISTS idx_error_logs_user_id ON public.error_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_error_logs_error_type ON public.error_logs(error_type);
CREATE INDEX IF NOT EXISTS idx_error_logs_created_at ON public.error_logs(created_at);
CREATE INDEX IF NOT EXISTS idx_error_logs_resolved ON public.error_logs(resolved);

-- =============================================
-- ROW LEVEL SECURITY
-- =============================================

-- Enable RLS on all new tables
ALTER TABLE public.user_activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_usage_summary ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.monthly_usage_summary ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.feature_usage ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.system_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.error_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.api_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.background_jobs ENABLE ROW LEVEL SECURITY;

-- User activities policies
CREATE POLICY "Users can view own activities" ON public.user_activities FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Service role can manage all activities" ON public.user_activities FOR ALL USING (auth.role() = 'service_role');

-- Usage summary policies
CREATE POLICY "Users can view own daily usage" ON public.daily_usage_summary FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can view own monthly usage" ON public.monthly_usage_summary FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Service role can manage usage data" ON public.daily_usage_summary FOR ALL USING (auth.role() = 'service_role');
CREATE POLICY "Service role can manage monthly data" ON public.monthly_usage_summary FOR ALL USING (auth.role() = 'service_role');

-- Feature usage policies
CREATE POLICY "Users can view own feature usage" ON public.feature_usage FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Service role can manage feature usage" ON public.feature_usage FOR ALL USING (auth.role() = 'service_role');

-- System analytics (admin only)
CREATE POLICY "Admins can view system analytics" ON public.system_analytics FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM public.admin_roles ar 
        WHERE ar.user_id = auth.uid() 
        AND ar.role = 'admin'
    )
);
CREATE POLICY "Service role can manage system analytics" ON public.system_analytics FOR ALL USING (auth.role() = 'service_role');

-- Error logs (admin only for viewing, service role for management)
CREATE POLICY "Admins can view error logs" ON public.error_logs FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM public.admin_roles ar 
        WHERE ar.user_id = auth.uid() 
        AND ar.role = 'admin'
    )
);
CREATE POLICY "Service role can manage error logs" ON public.error_logs FOR ALL USING (auth.role() = 'service_role');

-- API metrics and background jobs (service role only)
CREATE POLICY "Service role can manage api metrics" ON public.api_metrics FOR ALL USING (auth.role() = 'service_role');
CREATE POLICY "Service role can manage background jobs" ON public.background_jobs FOR ALL USING (auth.role() = 'service_role');

-- =============================================
-- FUNCTIONS & TRIGGERS
-- =============================================

-- Add updated_at triggers for new tables
CREATE TRIGGER update_daily_usage_summary_updated_at BEFORE UPDATE ON public.daily_usage_summary FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_monthly_usage_summary_updated_at BEFORE UPDATE ON public.monthly_usage_summary FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_feature_usage_updated_at BEFORE UPDATE ON public.feature_usage FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_system_analytics_updated_at BEFORE UPDATE ON public.system_analytics FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_background_jobs_updated_at BEFORE UPDATE ON public.background_jobs FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to track user activity
CREATE OR REPLACE FUNCTION track_user_activity(
    p_user_id uuid,
    p_activity_type text,
    p_description text DEFAULT NULL,
    p_metadata jsonb DEFAULT '{}'::jsonb,
    p_duration_ms integer DEFAULT NULL,
    p_success boolean DEFAULT true,
    p_error_message text DEFAULT NULL
)
RETURNS uuid AS $$
DECLARE
    activity_id uuid;
BEGIN
    INSERT INTO public.user_activities (
        user_id,
        activity_type,
        activity_description,
        metadata,
        duration_ms,
        success,
        error_message
    ) VALUES (
        p_user_id,
        p_activity_type,
        p_description,
        p_metadata,
        p_duration_ms,
        p_success,
        p_error_message
    ) RETURNING id INTO activity_id;
    
    RETURN activity_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update daily usage summary
CREATE OR REPLACE FUNCTION update_daily_usage(
    p_user_id uuid,
    p_date date,
    p_resumes_uploaded integer DEFAULT 0,
    p_jobs_created integer DEFAULT 0,
    p_analyses_performed integer DEFAULT 0,
    p_api_calls_made integer DEFAULT 0,
    p_storage_used_bytes bigint DEFAULT 0,
    p_ai_tokens_consumed integer DEFAULT 0
)
RETURNS void AS $$
BEGIN
    INSERT INTO public.daily_usage_summary (
        user_id,
        date,
        resumes_uploaded,
        jobs_created,
        analyses_performed,
        api_calls_made,
        storage_used_bytes,
        ai_tokens_consumed
    ) VALUES (
        p_user_id,
        p_date,
        p_resumes_uploaded,
        p_jobs_created,
        p_analyses_performed,
        p_api_calls_made,
        p_storage_used_bytes,
        p_ai_tokens_consumed
    )
    ON CONFLICT (user_id, date) 
    DO UPDATE SET
        resumes_uploaded = daily_usage_summary.resumes_uploaded + EXCLUDED.resumes_uploaded,
        jobs_created = daily_usage_summary.jobs_created + EXCLUDED.jobs_created,
        analyses_performed = daily_usage_summary.analyses_performed + EXCLUDED.analyses_performed,
        api_calls_made = daily_usage_summary.api_calls_made + EXCLUDED.api_calls_made,
        storage_used_bytes = EXCLUDED.storage_used_bytes, -- This should be the current total, not additive
        ai_tokens_consumed = daily_usage_summary.ai_tokens_consumed + EXCLUDED.ai_tokens_consumed,
        updated_at = now();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check user quota
CREATE OR REPLACE FUNCTION check_user_quota(
    p_user_id uuid,
    p_quota_type text,
    p_time_period text DEFAULT 'daily' -- 'daily' or 'monthly'
)
RETURNS TABLE (
    current_usage integer,
    quota_limit integer,
    can_proceed boolean,
    usage_percentage decimal
) AS $$
DECLARE
    user_product_id text;
    current_count integer := 0;
    limit_value integer;
    check_date date;
BEGIN
    -- Determine the date to check
    IF p_time_period = 'daily' THEN
        check_date := CURRENT_DATE;
    ELSE
        check_date := date_trunc('month', CURRENT_DATE)::date;
    END IF;
    
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
    
    -- Default to free plan if no subscription
    IF user_product_id IS NULL THEN
        user_product_id := 'prod_resume_matcher_free';
    END IF;
    
    -- Get quota limit for this plan
    SELECT limit_value INTO limit_value
    FROM plan_limits
    WHERE product_id = user_product_id
    AND limit_type = CASE 
        WHEN p_time_period = 'daily' THEN 'daily_' || p_quota_type
        ELSE 'monthly_' || p_quota_type
    END;
    
    -- Get current usage
    IF p_time_period = 'daily' THEN
        SELECT COALESCE(
            CASE p_quota_type
                WHEN 'analyses' THEN analyses_performed
                WHEN 'resumes' THEN resumes_uploaded
                WHEN 'jobs' THEN jobs_created
                WHEN 'api_calls' THEN api_calls_made
                ELSE 0
            END, 0
        ) INTO current_count
        FROM daily_usage_summary
        WHERE user_id = p_user_id AND date = check_date;
    ELSE
        SELECT COALESCE(
            CASE p_quota_type
                WHEN 'analyses' THEN total_analyses_performed
                WHEN 'resumes' THEN total_resumes_uploaded
                WHEN 'jobs' THEN total_jobs_created
                WHEN 'api_calls' THEN total_api_calls_made
                ELSE 0
            END, 0
        ) INTO current_count
        FROM monthly_usage_summary
        WHERE user_id = p_user_id 
        AND year = EXTRACT(YEAR FROM CURRENT_DATE)
        AND month = EXTRACT(MONTH FROM CURRENT_DATE);
    END IF;
    
    -- Return results
    RETURN QUERY SELECT
        current_count,
        limit_value,
        CASE 
            WHEN limit_value IS NULL THEN true -- Unlimited
            WHEN current_count < limit_value THEN true
            ELSE false
        END,
        CASE 
            WHEN limit_value IS NULL THEN 0.0::decimal
            WHEN limit_value = 0 THEN 100.0::decimal
            ELSE LEAST(100.0, (current_count::decimal / limit_value::decimal) * 100.0)
        END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================
-- COMMENTS FOR DOCUMENTATION
-- =============================================

COMMENT ON TABLE public.user_activities IS 'Detailed log of all user actions for analytics and auditing';
COMMENT ON TABLE public.daily_usage_summary IS 'Daily aggregated usage metrics for efficient quota checking';
COMMENT ON TABLE public.monthly_usage_summary IS 'Monthly usage rollups for billing and reporting';
COMMENT ON TABLE public.feature_usage IS 'Tracks which features are used by users for product optimization';
COMMENT ON TABLE public.system_analytics IS 'System-wide metrics and KPIs aggregated daily';
COMMENT ON TABLE public.error_logs IS 'Application error tracking and monitoring';
COMMENT ON TABLE public.api_metrics IS 'API endpoint performance metrics';
COMMENT ON TABLE public.background_jobs IS 'Asynchronous job processing tracking';

COMMENT ON FUNCTION track_user_activity IS 'Records user activity for analytics and monitoring';
COMMENT ON FUNCTION update_daily_usage IS 'Updates daily usage counters for a user';
COMMENT ON FUNCTION check_user_quota IS 'Checks if user can perform action based on their plan quotas';