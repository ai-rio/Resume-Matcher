-- Usage Tracking Database Functions
-- Functions to track and manage user usage limits and analytics

-- Function to increment usage counter for a user
CREATE OR REPLACE FUNCTION increment_usage(
    p_user_id UUID,
    p_event_type TEXT,
    p_resource_type TEXT DEFAULT NULL,
    p_resource_id UUID DEFAULT NULL,
    p_metadata JSONB DEFAULT '{}'::JSONB
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    current_month DATE;
    usage_record RECORD;
BEGIN
    -- Get current month start
    current_month := DATE_TRUNC('month', CURRENT_DATE)::DATE;
    
    -- Insert usage event
    INSERT INTO usage_events (
        user_id,
        event_type,
        resource_type,
        resource_id,
        metadata,
        created_at
    ) VALUES (
        p_user_id,
        p_event_type,
        p_resource_type,
        p_resource_id,
        p_metadata,
        NOW()
    );
    
    -- Update or insert monthly summary
    INSERT INTO usage_summaries (
        user_id,
        month,
        analyses_count,
        resumes_uploaded,
        jobs_analyzed,
        api_calls,
        storage_used,
        created_at
    ) VALUES (
        p_user_id,
        current_month,
        CASE WHEN p_event_type = 'analysis_created' THEN 1 ELSE 0 END,
        CASE WHEN p_event_type = 'resume_uploaded' THEN 1 ELSE 0 END,
        CASE WHEN p_event_type = 'job_analyzed' THEN 1 ELSE 0 END,
        CASE WHEN p_event_type = 'api_call' THEN 1 ELSE 0 END,
        CASE WHEN p_event_type = 'storage_used' THEN (p_metadata->>'bytes')::BIGINT ELSE 0 END,
        NOW()
    )
    ON CONFLICT (user_id, month)
    DO UPDATE SET
        analyses_count = usage_summaries.analyses_count + 
            CASE WHEN p_event_type = 'analysis_created' THEN 1 ELSE 0 END,
        resumes_uploaded = usage_summaries.resumes_uploaded + 
            CASE WHEN p_event_type = 'resume_uploaded' THEN 1 ELSE 0 END,
        jobs_analyzed = usage_summaries.jobs_analyzed + 
            CASE WHEN p_event_type = 'job_analyzed' THEN 1 ELSE 0 END,
        api_calls = usage_summaries.api_calls + 
            CASE WHEN p_event_type = 'api_call' THEN 1 ELSE 0 END,
        storage_used = usage_summaries.storage_used + 
            CASE WHEN p_event_type = 'storage_used' THEN (p_metadata->>'bytes')::BIGINT ELSE 0 END;
    
    RETURN TRUE;
END;
$$;

-- Function to check if user has exceeded usage limits
CREATE OR REPLACE FUNCTION check_usage_limit(
    p_user_id UUID,
    p_limit_type TEXT,
    p_current_month DATE DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    user_subscription RECORD;
    current_usage RECORD;
    usage_month DATE;
    result JSONB;
BEGIN
    -- Default to current month if not specified
    IF p_current_month IS NULL THEN
        usage_month := DATE_TRUNC('month', CURRENT_DATE)::DATE;
    ELSE
        usage_month := p_current_month;
    END IF;
    
    -- Get user's active subscription and plan limits
    SELECT 
        s.*,
        sp.limits
    INTO user_subscription
    FROM subscriptions s
    JOIN subscription_plans sp ON s.plan_id = sp.id
    WHERE s.user_id = p_user_id 
    AND s.status = 'active'
    AND (s.current_period_end IS NULL OR s.current_period_end > NOW())
    ORDER BY s.created_at DESC
    LIMIT 1;
    
    -- If no active subscription, use free tier limits
    IF user_subscription IS NULL THEN
        SELECT limits INTO user_subscription
        FROM subscription_plans
        WHERE slug = 'free'
        LIMIT 1;
    END IF;
    
    -- Get current month usage
    SELECT *
    INTO current_usage
    FROM usage_summaries
    WHERE user_id = p_user_id AND month = usage_month;
    
    -- If no usage record exists, create default
    IF current_usage IS NULL THEN
        current_usage := ROW(
            NULL, p_user_id, usage_month, 0, 0, 0, 0, 0, NOW()
        )::usage_summaries;
    END IF;
    
    -- Check specific limit
    CASE p_limit_type
        WHEN 'analyses' THEN
            result := jsonb_build_object(
                'limit_type', 'analyses',
                'current_usage', current_usage.analyses_count,
                'limit', COALESCE((user_subscription.limits->>'analyses_per_month')::INTEGER, 10),
                'remaining', GREATEST(0, COALESCE((user_subscription.limits->>'analyses_per_month')::INTEGER, 10) - current_usage.analyses_count),
                'exceeded', current_usage.analyses_count >= COALESCE((user_subscription.limits->>'analyses_per_month')::INTEGER, 10)
            );
        
        WHEN 'uploads' THEN
            result := jsonb_build_object(
                'limit_type', 'uploads',
                'current_usage', current_usage.resumes_uploaded,
                'limit', COALESCE((user_subscription.limits->>'uploads_per_month')::INTEGER, 3),
                'remaining', GREATEST(0, COALESCE((user_subscription.limits->>'uploads_per_month')::INTEGER, 3) - current_usage.resumes_uploaded),
                'exceeded', current_usage.resumes_uploaded >= COALESCE((user_subscription.limits->>'uploads_per_month')::INTEGER, 3)
            );
        
        WHEN 'storage' THEN
            result := jsonb_build_object(
                'limit_type', 'storage',
                'current_usage', current_usage.storage_used,
                'limit', COALESCE((user_subscription.limits->>'storage_limit')::BIGINT, 5242880), -- 5MB default
                'remaining', GREATEST(0, COALESCE((user_subscription.limits->>'storage_limit')::BIGINT, 5242880) - current_usage.storage_used),
                'exceeded', current_usage.storage_used >= COALESCE((user_subscription.limits->>'storage_limit')::BIGINT, 5242880)
            );
        
        WHEN 'api_calls' THEN
            result := jsonb_build_object(
                'limit_type', 'api_calls',
                'current_usage', current_usage.api_calls,
                'limit', COALESCE((user_subscription.limits->>'api_calls_per_month')::INTEGER, 100),
                'remaining', GREATEST(0, COALESCE((user_subscription.limits->>'api_calls_per_month')::INTEGER, 100) - current_usage.api_calls),
                'exceeded', current_usage.api_calls >= COALESCE((user_subscription.limits->>'api_calls_per_month')::INTEGER, 100)
            );
        
        ELSE
            result := jsonb_build_object(
                'error', 'Invalid limit type',
                'valid_types', ARRAY['analyses', 'uploads', 'storage', 'api_calls']
            );
    END CASE;
    
    RETURN result;
END;
$$;

-- Function to get comprehensive usage summary for a user
CREATE OR REPLACE FUNCTION get_user_usage_summary(
    p_user_id UUID,
    p_months_back INTEGER DEFAULT 3
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    user_subscription RECORD;
    usage_data JSONB;
    monthly_data JSONB[];
    month_record RECORD;
    current_month DATE;
    result JSONB;
BEGIN
    current_month := DATE_TRUNC('month', CURRENT_DATE)::DATE;
    
    -- Get user's active subscription
    SELECT 
        s.*,
        sp.name as plan_name,
        sp.limits,
        sp.features
    INTO user_subscription
    FROM subscriptions s
    JOIN subscription_plans sp ON s.plan_id = sp.id
    WHERE s.user_id = p_user_id 
    AND s.status = 'active'
    ORDER BY s.created_at DESC
    LIMIT 1;
    
    -- If no subscription, use free tier
    IF user_subscription IS NULL THEN
        SELECT 
            'free' as plan_name,
            limits,
            features
        INTO user_subscription
        FROM subscription_plans
        WHERE slug = 'free'
        LIMIT 1;
    END IF;
    
    -- Get monthly usage data
    FOR month_record IN
        SELECT *
        FROM usage_summaries
        WHERE user_id = p_user_id
        AND month >= current_month - INTERVAL '1 month' * p_months_back
        ORDER BY month DESC
    LOOP
        monthly_data := array_append(monthly_data, jsonb_build_object(
            'month', month_record.month,
            'analyses_count', month_record.analyses_count,
            'resumes_uploaded', month_record.resumes_uploaded,
            'jobs_analyzed', month_record.jobs_analyzed,
            'api_calls', month_record.api_calls,
            'storage_used', month_record.storage_used
        ));
    END LOOP;
    
    -- Build comprehensive result
    result := jsonb_build_object(
        'user_id', p_user_id,
        'current_month', current_month,
        'subscription', jsonb_build_object(
            'plan_name', user_subscription.plan_name,
            'limits', user_subscription.limits,
            'features', user_subscription.features
        ),
        'current_usage', (
            SELECT jsonb_build_object(
                'analyses_count', COALESCE(analyses_count, 0),
                'resumes_uploaded', COALESCE(resumes_uploaded, 0),
                'jobs_analyzed', COALESCE(jobs_analyzed, 0),
                'api_calls', COALESCE(api_calls, 0),
                'storage_used', COALESCE(storage_used, 0)
            )
            FROM usage_summaries
            WHERE user_id = p_user_id AND month = current_month
        ),
        'limits_status', jsonb_build_object(
            'analyses', check_usage_limit(p_user_id, 'analyses'),
            'uploads', check_usage_limit(p_user_id, 'uploads'),
            'storage', check_usage_limit(p_user_id, 'storage'),
            'api_calls', check_usage_limit(p_user_id, 'api_calls')
        ),
        'monthly_history', COALESCE(monthly_data, ARRAY[]::JSONB[])
    );
    
    RETURN result;
END;
$$;

-- Function to calculate storage usage for a user
CREATE OR REPLACE FUNCTION calculate_user_storage(p_user_id UUID)
RETURNS BIGINT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    total_storage BIGINT := 0;
BEGIN
    -- Calculate total file storage from resumes table
    SELECT COALESCE(SUM(file_size), 0)
    INTO total_storage
    FROM resumes
    WHERE user_id = p_user_id
    AND is_active = TRUE;
    
    RETURN total_storage;
END;
$$;

-- Function to cleanup old usage events (for maintenance)
CREATE OR REPLACE FUNCTION cleanup_old_usage_events(
    p_days_to_keep INTEGER DEFAULT 90
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    -- Delete old usage events
    DELETE FROM usage_events
    WHERE created_at < NOW() - INTERVAL '1 day' * p_days_to_keep;
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    RETURN deleted_count;
END;
$$;

-- Function to refresh usage summaries (for data integrity)
CREATE OR REPLACE FUNCTION refresh_usage_summaries(
    p_user_id UUID DEFAULT NULL,
    p_month DATE DEFAULT NULL
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    target_month DATE;
    updated_count INTEGER := 0;
    user_record RECORD;
BEGIN
    -- Default to current month if not specified
    IF p_month IS NULL THEN
        target_month := DATE_TRUNC('month', CURRENT_DATE)::DATE;
    ELSE
        target_month := p_month;
    END IF;
    
    -- If specific user, update only that user
    IF p_user_id IS NOT NULL THEN
        -- Delete existing summary
        DELETE FROM usage_summaries
        WHERE user_id = p_user_id AND month = target_month;
        
        -- Recalculate from events
        INSERT INTO usage_summaries (
            user_id,
            month,
            analyses_count,
            resumes_uploaded,
            jobs_analyzed,
            api_calls,
            storage_used,
            created_at
        )
        SELECT
            p_user_id,
            target_month,
            COUNT(*) FILTER (WHERE event_type = 'analysis_created'),
            COUNT(*) FILTER (WHERE event_type = 'resume_uploaded'),
            COUNT(*) FILTER (WHERE event_type = 'job_analyzed'),
            COUNT(*) FILTER (WHERE event_type = 'api_call'),
            calculate_user_storage(p_user_id),
            NOW()
        FROM usage_events
        WHERE user_id = p_user_id
        AND DATE_TRUNC('month', created_at) = target_month;
        
        updated_count := 1;
    ELSE
        -- Update all users for the specified month
        FOR user_record IN
            SELECT DISTINCT user_id
            FROM usage_events
            WHERE DATE_TRUNC('month', created_at) = target_month
        LOOP
            -- Delete existing summary
            DELETE FROM usage_summaries
            WHERE user_id = user_record.user_id AND month = target_month;
            
            -- Recalculate from events
            INSERT INTO usage_summaries (
                user_id,
                month,
                analyses_count,
                resumes_uploaded,
                jobs_analyzed,
                api_calls,
                storage_used,
                created_at
            )
            SELECT
                user_record.user_id,
                target_month,
                COUNT(*) FILTER (WHERE event_type = 'analysis_created'),
                COUNT(*) FILTER (WHERE event_type = 'resume_uploaded'),
                COUNT(*) FILTER (WHERE event_type = 'job_analyzed'),
                COUNT(*) FILTER (WHERE event_type = 'api_call'),
                calculate_user_storage(user_record.user_id),
                NOW()
            FROM usage_events
            WHERE user_id = user_record.user_id
            AND DATE_TRUNC('month', created_at) = target_month;
            
            updated_count := updated_count + 1;
        END LOOP;
    END IF;
    
    RETURN updated_count;
END;
$$;

-- Function to get usage trends and analytics
CREATE OR REPLACE FUNCTION get_usage_analytics(
    p_start_date DATE DEFAULT NULL,
    p_end_date DATE DEFAULT NULL,
    p_plan_slug TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    start_date DATE;
    end_date DATE;
    result JSONB;
    total_users INTEGER;
    active_users INTEGER;
    total_analyses INTEGER;
    total_uploads INTEGER;
    avg_analyses_per_user DECIMAL;
    plan_filter TEXT;
BEGIN
    -- Set default date range (last 30 days)
    IF p_start_date IS NULL THEN
        start_date := CURRENT_DATE - INTERVAL '30 days';
    ELSE
        start_date := p_start_date;
    END IF;
    
    IF p_end_date IS NULL THEN
        end_date := CURRENT_DATE;
    ELSE
        end_date := p_end_date;
    END IF;
    
    -- Build plan filter
    IF p_plan_slug IS NOT NULL THEN
        plan_filter := p_plan_slug;
    END IF;
    
    -- Calculate metrics
    SELECT COUNT(DISTINCT us.user_id)
    INTO total_users
    FROM usage_summaries us
    LEFT JOIN subscriptions s ON us.user_id = s.user_id
    LEFT JOIN subscription_plans sp ON s.plan_id = sp.id
    WHERE us.month >= start_date AND us.month <= end_date
    AND (plan_filter IS NULL OR sp.slug = plan_filter);
    
    SELECT COUNT(DISTINCT us.user_id)
    INTO active_users
    FROM usage_summaries us
    LEFT JOIN subscriptions s ON us.user_id = s.user_id
    LEFT JOIN subscription_plans sp ON s.plan_id = sp.id
    WHERE us.month >= start_date AND us.month <= end_date
    AND (us.analyses_count > 0 OR us.resumes_uploaded > 0)
    AND (plan_filter IS NULL OR sp.slug = plan_filter);
    
    SELECT 
        SUM(us.analyses_count),
        SUM(us.resumes_uploaded)
    INTO total_analyses, total_uploads
    FROM usage_summaries us
    LEFT JOIN subscriptions s ON us.user_id = s.user_id
    LEFT JOIN subscription_plans sp ON s.plan_id = sp.id
    WHERE us.month >= start_date AND us.month <= end_date
    AND (plan_filter IS NULL OR sp.slug = plan_filter);
    
    -- Calculate average analyses per user
    IF total_users > 0 THEN
        avg_analyses_per_user := total_analyses::DECIMAL / total_users;
    ELSE
        avg_analyses_per_user := 0;
    END IF;
    
    -- Build result
    result := jsonb_build_object(
        'period', jsonb_build_object(
            'start_date', start_date,
            'end_date', end_date
        ),
        'plan_filter', plan_filter,
        'metrics', jsonb_build_object(
            'total_users', total_users,
            'active_users', active_users,
            'total_analyses', total_analyses,
            'total_uploads', total_uploads,
            'avg_analyses_per_user', avg_analyses_per_user,
            'user_activation_rate', 
                CASE WHEN total_users > 0 
                THEN (active_users::DECIMAL / total_users * 100)
                ELSE 0 END
        )
    );
    
    RETURN result;
END;
$$;

-- Grant permissions to authenticated users
GRANT EXECUTE ON FUNCTION increment_usage TO authenticated;
GRANT EXECUTE ON FUNCTION check_usage_limit TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_usage_summary TO authenticated;
GRANT EXECUTE ON FUNCTION calculate_user_storage TO authenticated;

-- Grant admin permissions for maintenance functions
GRANT EXECUTE ON FUNCTION cleanup_old_usage_events TO service_role;
GRANT EXECUTE ON FUNCTION refresh_usage_summaries TO service_role;
GRANT EXECUTE ON FUNCTION get_usage_analytics TO service_role;