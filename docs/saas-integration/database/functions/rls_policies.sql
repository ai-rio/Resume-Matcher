-- Row Level Security (RLS) Policies
-- Comprehensive security policies to ensure data isolation and access control

-- Enable RLS on all user tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE resumes ENABLE ROW LEVEL SECURITY;
ALTER TABLE resume_analyses ENABLE ROW LEVEL SECURITY;
ALTER TABLE job_descriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE matching_analyses ENABLE ROW LEVEL SECURITY;
ALTER TABLE usage_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE usage_summaries ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- =============================================================================
-- PROFILES TABLE POLICIES
-- =============================================================================

-- Users can view their own profile
CREATE POLICY "users_can_view_own_profile" ON profiles
    FOR SELECT USING (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "users_can_update_own_profile" ON profiles
    FOR UPDATE USING (auth.uid() = id);

-- Users can insert their own profile (for signup)
CREATE POLICY "users_can_insert_own_profile" ON profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Service role can access all profiles (for admin operations)
CREATE POLICY "service_role_full_access_profiles" ON profiles
    FOR ALL USING (auth.role() = 'service_role');

-- =============================================================================
-- SUBSCRIPTIONS TABLE POLICIES
-- =============================================================================

-- Users can view their own subscriptions
CREATE POLICY "users_can_view_own_subscriptions" ON subscriptions
    FOR SELECT USING (auth.uid() = user_id);

-- Only service role can insert/update subscriptions (Stripe webhooks)
CREATE POLICY "service_role_can_manage_subscriptions" ON subscriptions
    FOR ALL USING (auth.role() = 'service_role');

-- Users can view subscription plans (public data)
CREATE POLICY "anyone_can_view_subscription_plans" ON subscription_plans
    FOR SELECT USING (is_active = true);

-- Only service role can manage subscription plans
CREATE POLICY "service_role_can_manage_plans" ON subscription_plans
    FOR ALL USING (auth.role() = 'service_role');

-- =============================================================================
-- RESUMES TABLE POLICIES
-- =============================================================================

-- Users can view their own resumes
CREATE POLICY "users_can_view_own_resumes" ON resumes
    FOR SELECT USING (auth.uid() = user_id);

-- Users can insert their own resumes
CREATE POLICY "users_can_insert_own_resumes" ON resumes
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update their own resumes
CREATE POLICY "users_can_update_own_resumes" ON resumes
    FOR UPDATE USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Users can delete their own resumes
CREATE POLICY "users_can_delete_own_resumes" ON resumes
    FOR DELETE USING (auth.uid() = user_id);

-- Service role can access all resumes (for processing)
CREATE POLICY "service_role_full_access_resumes" ON resumes
    FOR ALL USING (auth.role() = 'service_role');

-- =============================================================================
-- RESUME ANALYSES TABLE POLICIES
-- =============================================================================

-- Users can view analyses of their own resumes
CREATE POLICY "users_can_view_own_resume_analyses" ON resume_analyses
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM resumes r
            WHERE r.id = resume_analyses.resume_id
            AND r.user_id = auth.uid()
        )
    );

-- Only service role can insert/update resume analyses
CREATE POLICY "service_role_can_manage_resume_analyses" ON resume_analyses
    FOR ALL USING (auth.role() = 'service_role');

-- =============================================================================
-- JOB DESCRIPTIONS TABLE POLICIES
-- =============================================================================

-- Users can view their own job descriptions
CREATE POLICY "users_can_view_own_jobs" ON job_descriptions
    FOR SELECT USING (auth.uid() = user_id);

-- Users can insert their own job descriptions
CREATE POLICY "users_can_insert_own_jobs" ON job_descriptions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update their own job descriptions
CREATE POLICY "users_can_update_own_jobs" ON job_descriptions
    FOR UPDATE USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Users can delete their own job descriptions
CREATE POLICY "users_can_delete_own_jobs" ON job_descriptions
    FOR DELETE USING (auth.uid() = user_id);

-- Service role can access all job descriptions
CREATE POLICY "service_role_full_access_jobs" ON job_descriptions
    FOR ALL USING (auth.role() = 'service_role');

-- =============================================================================
-- MATCHING ANALYSES TABLE POLICIES
-- =============================================================================

-- Users can view their own matching analyses
CREATE POLICY "users_can_view_own_analyses" ON matching_analyses
    FOR SELECT USING (auth.uid() = user_id);

-- Users can insert their own matching analyses
CREATE POLICY "users_can_insert_own_analyses" ON matching_analyses
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update their own matching analyses
CREATE POLICY "users_can_update_own_analyses" ON matching_analyses
    FOR UPDATE USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Users can delete their own matching analyses
CREATE POLICY "users_can_delete_own_analyses" ON matching_analyses
    FOR DELETE USING (auth.uid() = user_id);

-- Service role can access all matching analyses
CREATE POLICY "service_role_full_access_analyses" ON matching_analyses
    FOR ALL USING (auth.role() = 'service_role');

-- =============================================================================
-- USAGE EVENTS TABLE POLICIES
-- =============================================================================

-- Users can view their own usage events
CREATE POLICY "users_can_view_own_usage_events" ON usage_events
    FOR SELECT USING (auth.uid() = user_id);

-- Service role can insert usage events (tracking)
CREATE POLICY "service_role_can_insert_usage_events" ON usage_events
    FOR INSERT WITH CHECK (auth.role() = 'service_role');

-- Service role can manage all usage events
CREATE POLICY "service_role_full_access_usage_events" ON usage_events
    FOR ALL USING (auth.role() = 'service_role');

-- =============================================================================
-- USAGE SUMMARIES TABLE POLICIES
-- =============================================================================

-- Users can view their own usage summaries
CREATE POLICY "users_can_view_own_usage_summaries" ON usage_summaries
    FOR SELECT USING (auth.uid() = user_id);

-- Service role can manage all usage summaries
CREATE POLICY "service_role_full_access_usage_summaries" ON usage_summaries
    FOR ALL USING (auth.role() = 'service_role');

-- =============================================================================
-- AUDIT LOGS TABLE POLICIES
-- =============================================================================

-- Users can view their own audit logs
CREATE POLICY "users_can_view_own_audit_logs" ON audit_logs
    FOR SELECT USING (auth.uid() = user_id);

-- Service role can manage all audit logs
CREATE POLICY "service_role_full_access_audit_logs" ON audit_logs
    FOR ALL USING (auth.role() = 'service_role');

-- =============================================================================
-- STORAGE POLICIES (for Supabase Storage)
-- =============================================================================

-- Policy for private resume files - users can only access their own files
CREATE POLICY "users_can_access_own_resume_files" ON storage.objects
    FOR ALL USING (
        bucket_id = 'private' AND
        (storage.foldername(name))[1] = 'resumes' AND
        (auth.uid())::text = (storage.foldername(name))[2]
    );

-- Policy for public thumbnails - anyone can view
CREATE POLICY "public_thumbnail_access" ON storage.objects
    FOR SELECT USING (
        bucket_id = 'public' AND
        (storage.foldername(name))[1] = 'thumbnails'
    );

-- Policy for user avatars - users can manage their own avatars
CREATE POLICY "users_can_manage_own_avatars" ON storage.objects
    FOR ALL USING (
        bucket_id = 'public' AND
        (storage.foldername(name))[1] = 'avatars' AND
        (auth.uid())::text = (storage.foldername(name))[2]
    );

-- Service role can access all storage objects
CREATE POLICY "service_role_full_access_storage" ON storage.objects
    FOR ALL USING (auth.role() = 'service_role');

-- =============================================================================
-- HELPER FUNCTIONS FOR COMPLEX POLICIES
-- =============================================================================

-- Function to check if user has active subscription
CREATE OR REPLACE FUNCTION user_has_active_subscription(p_user_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
    SELECT EXISTS (
        SELECT 1 FROM subscriptions
        WHERE user_id = p_user_id
        AND status = 'active'
        AND (current_period_end IS NULL OR current_period_end > NOW())
    );
$$;

-- Function to check if user can perform action based on subscription
CREATE OR REPLACE FUNCTION user_can_perform_action(
    p_user_id UUID,
    p_action TEXT,
    p_resource_count INTEGER DEFAULT 1
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
AS $$
DECLARE
    user_subscription JSONB;
    current_usage JSONB;
    limit_check JSONB;
BEGIN
    -- Get user subscription details
    user_subscription := get_active_subscription(p_user_id);
    
    -- Check specific action limits
    CASE p_action
        WHEN 'upload_resume' THEN
            limit_check := check_usage_limit(p_user_id, 'uploads');
            RETURN NOT (limit_check->>'exceeded')::BOOLEAN;
        
        WHEN 'create_analysis' THEN
            limit_check := check_usage_limit(p_user_id, 'analyses');
            RETURN NOT (limit_check->>'exceeded')::BOOLEAN;
        
        WHEN 'api_call' THEN
            limit_check := check_usage_limit(p_user_id, 'api_calls');
            RETURN NOT (limit_check->>'exceeded')::BOOLEAN;
        
        WHEN 'access_advanced_features' THEN
            RETURN can_access_feature(p_user_id, 'advanced_analytics');
        
        WHEN 'access_api' THEN
            RETURN can_access_feature(p_user_id, 'api_access');
        
        ELSE
            RETURN TRUE; -- Default allow for unknown actions
    END CASE;
END;
$$;

-- =============================================================================
-- ADDITIONAL SECURITY POLICIES WITH SUBSCRIPTION CHECKS
-- =============================================================================

-- Policy to limit resume uploads based on subscription
CREATE POLICY "limit_resume_uploads_by_subscription" ON resumes
    FOR INSERT WITH CHECK (
        auth.uid() = user_id AND
        user_can_perform_action(auth.uid(), 'upload_resume')
    );

-- Policy to limit analysis creation based on subscription
CREATE POLICY "limit_analysis_creation_by_subscription" ON matching_analyses
    FOR INSERT WITH CHECK (
        auth.uid() = user_id AND
        user_can_perform_action(auth.uid(), 'create_analysis')
    );

-- =============================================================================
-- ADMIN POLICIES FOR MANAGEMENT INTERFACE
-- =============================================================================

-- Function to check if user is admin
CREATE OR REPLACE FUNCTION is_admin(p_user_id UUID DEFAULT NULL)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
    SELECT EXISTS (
        SELECT 1 FROM profiles
        WHERE id = COALESCE(p_user_id, auth.uid())
        AND (preferences->>'is_admin')::BOOLEAN = true
    );
$$;

-- Admin can view all user data (for support)
CREATE POLICY "admin_can_view_all_profiles" ON profiles
    FOR SELECT USING (is_admin());

CREATE POLICY "admin_can_view_all_subscriptions" ON subscriptions
    FOR SELECT USING (is_admin());

CREATE POLICY "admin_can_view_all_resumes" ON resumes
    FOR SELECT USING (is_admin());

CREATE POLICY "admin_can_view_all_analyses" ON matching_analyses
    FOR SELECT USING (is_admin());

-- =============================================================================
-- SECURITY FUNCTIONS AND TRIGGERS
-- =============================================================================

-- Function to log access attempts
CREATE OR REPLACE FUNCTION log_data_access()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Log sensitive data access
    IF TG_TABLE_NAME IN ('resumes', 'matching_analyses', 'subscriptions') THEN
        INSERT INTO audit_logs (
            user_id,
            action,
            table_name,
            record_id,
            ip_address,
            user_agent,
            created_at
        ) VALUES (
            auth.uid(),
            TG_OP || '_' || TG_TABLE_NAME,
            TG_TABLE_NAME,
            COALESCE(NEW.id, OLD.id),
            inet_client_addr(),
            current_setting('request.headers', true)::json->>'user-agent',
            NOW()
        );
    END IF;
    
    RETURN COALESCE(NEW, OLD);
END;
$$;

-- Create triggers for audit logging
CREATE TRIGGER audit_resumes_access
    AFTER INSERT OR UPDATE OR DELETE ON resumes
    FOR EACH ROW EXECUTE FUNCTION log_data_access();

CREATE TRIGGER audit_analyses_access
    AFTER INSERT OR UPDATE OR DELETE ON matching_analyses
    FOR EACH ROW EXECUTE FUNCTION log_data_access();

CREATE TRIGGER audit_subscriptions_access
    AFTER INSERT OR UPDATE OR DELETE ON subscriptions
    FOR EACH ROW EXECUTE FUNCTION log_data_access();

-- =============================================================================
-- RATE LIMITING POLICIES
-- =============================================================================

-- Function to check rate limits
CREATE OR REPLACE FUNCTION check_rate_limit(
    p_user_id UUID,
    p_action TEXT,
    p_window_minutes INTEGER DEFAULT 60,
    p_max_requests INTEGER DEFAULT 100
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    request_count INTEGER;
    window_start TIMESTAMPTZ;
BEGIN
    window_start := NOW() - INTERVAL '1 minute' * p_window_minutes;
    
    -- Count requests in the time window
    SELECT COUNT(*)
    INTO request_count
    FROM usage_events
    WHERE user_id = p_user_id
    AND event_type = p_action
    AND created_at >= window_start;
    
    RETURN request_count < p_max_requests;
END;
$$;

-- Policy to enforce rate limits on API calls
CREATE POLICY "enforce_api_rate_limits" ON usage_events
    FOR INSERT WITH CHECK (
        event_type != 'api_call' OR
        check_rate_limit(user_id, 'api_call', 60, 100)
    );

-- =============================================================================
-- DATA RETENTION POLICIES
-- =============================================================================

-- Function to enforce data retention
CREATE OR REPLACE FUNCTION enforce_data_retention()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    deleted_count INTEGER := 0;
BEGIN
    -- Delete old usage events (keep 90 days)
    DELETE FROM usage_events
    WHERE created_at < NOW() - INTERVAL '90 days';
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    -- Delete old audit logs (keep 1 year)
    DELETE FROM audit_logs
    WHERE created_at < NOW() - INTERVAL '365 days';
    
    GET DIAGNOSTICS deleted_count = deleted_count + ROW_COUNT;
    
    -- Archive old resume analyses (keep 2 years)
    UPDATE resume_analyses
    SET results = '{}'::JSONB
    WHERE created_at < NOW() - INTERVAL '2 years'
    AND results != '{}'::JSONB;
    
    GET DIAGNOSTICS deleted_count = deleted_count + ROW_COUNT;
    
    RETURN deleted_count;
END;
$$;

-- =============================================================================
-- BACKUP AND RECOVERY POLICIES
-- =============================================================================

-- Function to create user data export (GDPR compliance)
CREATE OR REPLACE FUNCTION export_user_data(p_user_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    user_data JSONB;
BEGIN
    -- Only allow users to export their own data or admins
    IF auth.uid() != p_user_id AND NOT is_admin() THEN
        RAISE EXCEPTION 'Access denied';
    END IF;
    
    -- Compile all user data
    SELECT jsonb_build_object(
        'profile', (
            SELECT to_jsonb(p.*) FROM profiles p WHERE p.id = p_user_id
        ),
        'subscriptions', (
            SELECT jsonb_agg(to_jsonb(s.*))
            FROM subscriptions s WHERE s.user_id = p_user_id
        ),
        'resumes', (
            SELECT jsonb_agg(to_jsonb(r.*))
            FROM resumes r WHERE r.user_id = p_user_id
        ),
        'job_descriptions', (
            SELECT jsonb_agg(to_jsonb(j.*))
            FROM job_descriptions j WHERE j.user_id = p_user_id
        ),
        'matching_analyses', (
            SELECT jsonb_agg(to_jsonb(m.*))
            FROM matching_analyses m WHERE m.user_id = p_user_id
        ),
        'usage_summaries', (
            SELECT jsonb_agg(to_jsonb(u.*))
            FROM usage_summaries u WHERE u.user_id = p_user_id
        ),
        'export_date', NOW()
    ) INTO user_data;
    
    -- Log the export
    INSERT INTO audit_logs (
        user_id,
        action,
        table_name,
        new_values,
        created_at
    ) VALUES (
        p_user_id,
        'data_export',
        'all_tables',
        jsonb_build_object('exported_by', auth.uid()),
        NOW()
    );
    
    RETURN user_data;
END;
$$;

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION user_has_active_subscription TO authenticated;
GRANT EXECUTE ON FUNCTION user_can_perform_action TO authenticated;
GRANT EXECUTE ON FUNCTION is_admin TO authenticated;
GRANT EXECUTE ON FUNCTION check_rate_limit TO authenticated;
GRANT EXECUTE ON FUNCTION export_user_data TO authenticated;

-- Admin-only functions
GRANT EXECUTE ON FUNCTION enforce_data_retention TO service_role;
GRANT EXECUTE ON FUNCTION log_data_access TO service_role;

-- Create indexes for better performance on RLS queries
CREATE INDEX IF NOT EXISTS idx_resumes_user_id_active ON resumes(user_id) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_subscriptions_user_status ON subscriptions(user_id, status);
CREATE INDEX IF NOT EXISTS idx_usage_events_user_type_created ON usage_events(user_id, event_type, created_at);
CREATE INDEX IF NOT EXISTS idx_audit_logs_user_created ON audit_logs(user_id, created_at);

-- Enable real-time subscriptions for user-specific data
ALTER PUBLICATION supabase_realtime ADD TABLE profiles;
ALTER PUBLICATION supabase_realtime ADD TABLE subscriptions;
ALTER PUBLICATION supabase_realtime ADD TABLE resumes;
ALTER PUBLICATION supabase_realtime ADD TABLE matching_analyses;
ALTER PUBLICATION supabase_realtime ADD TABLE usage_summaries;