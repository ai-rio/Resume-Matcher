-- Subscription Helper Functions
-- Functions to manage subscription lifecycle, upgrades, downgrades, and billing

-- Function to get user's active subscription with plan details
CREATE OR REPLACE FUNCTION get_active_subscription(p_user_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    subscription_data RECORD;
    result JSONB;
BEGIN
    -- Get active subscription with plan details
    SELECT 
        s.*,
        sp.name as plan_name,
        sp.slug as plan_slug,
        sp.price_monthly,
        sp.price_yearly,
        sp.features,
        sp.limits,
        sp.description
    INTO subscription_data
    FROM subscriptions s
    JOIN subscription_plans sp ON s.plan_id = sp.id
    WHERE s.user_id = p_user_id 
    AND s.status = 'active'
    AND (s.current_period_end IS NULL OR s.current_period_end > NOW())
    ORDER BY s.created_at DESC
    LIMIT 1;
    
    -- If no active subscription found, return free plan info
    IF subscription_data IS NULL THEN
        SELECT 
            NULL as id,
            p_user_id as user_id,
            NULL as stripe_subscription_id,
            NULL as stripe_customer_id,
            'free' as status,
            NULL as current_period_start,
            NULL as current_period_end,
            NULL as trial_end,
            NOW() as created_at,
            NOW() as updated_at,
            sp.name as plan_name,
            sp.slug as plan_slug,
            sp.price_monthly,
            sp.price_yearly,
            sp.features,
            sp.limits,
            sp.description
        INTO subscription_data
        FROM subscription_plans sp
        WHERE sp.slug = 'free'
        LIMIT 1;
    END IF;
    
    -- Build result JSON
    result := jsonb_build_object(
        'subscription', jsonb_build_object(
            'id', subscription_data.id,
            'user_id', subscription_data.user_id,
            'status', subscription_data.status,
            'stripe_subscription_id', subscription_data.stripe_subscription_id,
            'stripe_customer_id', subscription_data.stripe_customer_id,
            'current_period_start', subscription_data.current_period_start,
            'current_period_end', subscription_data.current_period_end,
            'trial_end', subscription_data.trial_end,
            'created_at', subscription_data.created_at,
            'updated_at', subscription_data.updated_at
        ),
        'plan', jsonb_build_object(
            'name', subscription_data.plan_name,
            'slug', subscription_data.plan_slug,
            'price_monthly', subscription_data.price_monthly,
            'price_yearly', subscription_data.price_yearly,
            'features', subscription_data.features,
            'limits', subscription_data.limits,
            'description', subscription_data.description
        )
    );
    
    RETURN result;
END;
$$;

-- Function to create or update subscription from Stripe webhook
CREATE OR REPLACE FUNCTION upsert_subscription(
    p_user_id UUID,
    p_stripe_subscription_id TEXT,
    p_stripe_customer_id TEXT,
    p_plan_slug TEXT,
    p_status TEXT,
    p_current_period_start TIMESTAMPTZ DEFAULT NULL,
    p_current_period_end TIMESTAMPTZ DEFAULT NULL,
    p_trial_end TIMESTAMPTZ DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    plan_record RECORD;
    subscription_id UUID;
    existing_subscription UUID;
BEGIN
    -- Get plan ID from slug
    SELECT id, name INTO plan_record
    FROM subscription_plans
    WHERE slug = p_plan_slug AND is_active = TRUE
    LIMIT 1;
    
    IF plan_record IS NULL THEN
        RAISE EXCEPTION 'Invalid plan slug: %', p_plan_slug;
    END IF;
    
    -- Check for existing subscription with same Stripe ID
    SELECT id INTO existing_subscription
    FROM subscriptions
    WHERE stripe_subscription_id = p_stripe_subscription_id
    LIMIT 1;
    
    IF existing_subscription IS NOT NULL THEN
        -- Update existing subscription
        UPDATE subscriptions SET
            status = p_status,
            current_period_start = p_current_period_start,
            current_period_end = p_current_period_end,
            trial_end = p_trial_end,
            updated_at = NOW()
        WHERE id = existing_subscription;
        
        subscription_id := existing_subscription;
    ELSE
        -- Deactivate any existing active subscriptions for this user
        UPDATE subscriptions 
        SET status = 'canceled', updated_at = NOW()
        WHERE user_id = p_user_id AND status = 'active';
        
        -- Create new subscription
        INSERT INTO subscriptions (
            user_id,
            plan_id,
            stripe_subscription_id,
            stripe_customer_id,
            status,
            current_period_start,
            current_period_end,
            trial_end
        ) VALUES (
            p_user_id,
            plan_record.id,
            p_stripe_subscription_id,
            p_stripe_customer_id,
            p_status,
            p_current_period_start,
            p_current_period_end,
            p_trial_end
        ) RETURNING id INTO subscription_id;
    END IF;
    
    -- Log subscription change
    INSERT INTO audit_logs (
        user_id,
        action,
        table_name,
        record_id,
        new_values,
        created_at
    ) VALUES (
        p_user_id,
        'subscription_updated',
        'subscriptions',
        subscription_id,
        jsonb_build_object(
            'plan', plan_record.name,
            'status', p_status,
            'stripe_subscription_id', p_stripe_subscription_id
        ),
        NOW()
    );
    
    RETURN subscription_id;
END;
$$;

-- Function to cancel subscription
CREATE OR REPLACE FUNCTION cancel_subscription(
    p_user_id UUID,
    p_reason TEXT DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    subscription_record RECORD;
BEGIN
    -- Get active subscription
    SELECT * INTO subscription_record
    FROM subscriptions
    WHERE user_id = p_user_id 
    AND status = 'active'
    ORDER BY created_at DESC
    LIMIT 1;
    
    IF subscription_record IS NULL THEN
        RAISE EXCEPTION 'No active subscription found for user';
    END IF;
    
    -- Update subscription status
    UPDATE subscriptions 
    SET 
        status = 'canceled',
        updated_at = NOW()
    WHERE id = subscription_record.id;
    
    -- Log cancellation
    INSERT INTO audit_logs (
        user_id,
        action,
        table_name,
        record_id,
        old_values,
        new_values,
        created_at
    ) VALUES (
        p_user_id,
        'subscription_canceled',
        'subscriptions',
        subscription_record.id,
        jsonb_build_object(
            'status', subscription_record.status
        ),
        jsonb_build_object(
            'status', 'canceled',
            'reason', p_reason
        ),
        NOW()
    );
    
    RETURN TRUE;
END;
$$;

-- Function to check if user can access feature
CREATE OR REPLACE FUNCTION can_access_feature(
    p_user_id UUID,
    p_feature_key TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    subscription_data JSONB;
    features JSONB;
BEGIN
    -- Get user's active subscription
    subscription_data := get_active_subscription(p_user_id);
    features := subscription_data->'plan'->'features';
    
    -- Check if feature exists and is enabled
    IF features ? p_feature_key THEN
        RETURN (features->>p_feature_key)::BOOLEAN;
    END IF;
    
    -- Default to false if feature not found
    RETURN FALSE;
END;
$$;

-- Function to check if user has reached usage limit
CREATE OR REPLACE FUNCTION has_reached_limit(
    p_user_id UUID,
    p_limit_type TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    limit_check JSONB;
BEGIN
    -- Use the usage tracking function
    limit_check := check_usage_limit(p_user_id, p_limit_type);
    
    -- Return if limit exceeded
    RETURN (limit_check->>'exceeded')::BOOLEAN;
END;
$$;

-- Function to get subscription billing info
CREATE OR REPLACE FUNCTION get_subscription_billing_info(p_user_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    subscription_data JSONB;
    billing_info JSONB;
    next_billing_date TIMESTAMPTZ;
    days_until_billing INTEGER;
    subscription_record RECORD;
BEGIN
    -- Get active subscription
    subscription_data := get_active_subscription(p_user_id);
    
    -- Extract subscription record
    SELECT 
        (subscription_data->'subscription'->>'current_period_end')::TIMESTAMPTZ as current_period_end,
        (subscription_data->'subscription'->>'status')::TEXT as status,
        (subscription_data->'plan'->>'price_monthly')::INTEGER as price_monthly,
        (subscription_data->'plan'->>'price_yearly')::INTEGER as price_yearly
    INTO subscription_record;
    
    -- Calculate next billing date
    IF subscription_record.current_period_end IS NOT NULL THEN
        next_billing_date := subscription_record.current_period_end;
        days_until_billing := EXTRACT(days FROM (next_billing_date - NOW()));
    END IF;
    
    -- Build billing info
    billing_info := jsonb_build_object(
        'status', subscription_record.status,
        'next_billing_date', next_billing_date,
        'days_until_billing', days_until_billing,
        'monthly_price', subscription_record.price_monthly,
        'yearly_price', subscription_record.price_yearly,
        'currency', 'usd',
        'billing_cycle', CASE 
            WHEN subscription_record.current_period_end IS NOT NULL 
            THEN 'monthly'
            ELSE 'free'
        END
    );
    
    RETURN billing_info;
END;
$$;

-- Function to get plan comparison data
CREATE OR REPLACE FUNCTION get_plan_comparison()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    plans JSONB[];
    plan_record RECORD;
    result JSONB;
BEGIN
    -- Get all active plans
    FOR plan_record IN
        SELECT *
        FROM subscription_plans
        WHERE is_active = TRUE
        ORDER BY sort_order, price_monthly NULLS FIRST
    LOOP
        plans := array_append(plans, jsonb_build_object(
            'id', plan_record.id,
            'name', plan_record.name,
            'slug', plan_record.slug,
            'description', plan_record.description,
            'price_monthly', plan_record.price_monthly,
            'price_yearly', plan_record.price_yearly,
            'features', plan_record.features,
            'limits', plan_record.limits,
            'sort_order', plan_record.sort_order,
            'is_popular', plan_record.slug = 'pro', -- Mark pro as popular
            'yearly_discount', CASE 
                WHEN plan_record.price_yearly IS NOT NULL AND plan_record.price_monthly IS NOT NULL
                THEN ROUND((1 - (plan_record.price_yearly::DECIMAL / (plan_record.price_monthly * 12))) * 100)
                ELSE 0
            END
        ));
    END LOOP;
    
    result := jsonb_build_object(
        'plans', COALESCE(plans, ARRAY[]::JSONB[]),
        'comparison_features', ARRAY[
            'resume_uploads_per_month',
            'job_analyses_per_month',
            'advanced_analytics',
            'api_access',
            'priority_support',
            'custom_templates',
            'team_collaboration',
            'white_label'
        ]
    );
    
    RETURN result;
END;
$$;

-- Function to calculate plan upgrade/downgrade price difference
CREATE OR REPLACE FUNCTION calculate_plan_change_cost(
    p_user_id UUID,
    p_new_plan_slug TEXT,
    p_billing_cycle TEXT DEFAULT 'monthly'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    current_subscription JSONB;
    current_plan JSONB;
    new_plan RECORD;
    current_price INTEGER;
    new_price INTEGER;
    price_difference INTEGER;
    prorated_amount INTEGER;
    days_remaining INTEGER;
    days_in_cycle INTEGER;
    result JSONB;
BEGIN
    -- Get current subscription
    current_subscription := get_active_subscription(p_user_id);
    current_plan := current_subscription->'plan';
    
    -- Get new plan details
    SELECT *
    INTO new_plan
    FROM subscription_plans
    WHERE slug = p_new_plan_slug AND is_active = TRUE
    LIMIT 1;
    
    IF new_plan IS NULL THEN
        RETURN jsonb_build_object('error', 'Plan not found');
    END IF;
    
    -- Get current and new prices
    IF p_billing_cycle = 'yearly' THEN
        current_price := COALESCE((current_plan->>'price_yearly')::INTEGER, 0);
        new_price := COALESCE(new_plan.price_yearly, 0);
        days_in_cycle := 365;
    ELSE
        current_price := COALESCE((current_plan->>'price_monthly')::INTEGER, 0);
        new_price := COALESCE(new_plan.price_monthly, 0);
        days_in_cycle := 30;
    END IF;
    
    -- Calculate price difference
    price_difference := new_price - current_price;
    
    -- Calculate prorated amount if upgrading mid-cycle
    IF (current_subscription->'subscription'->>'current_period_end') IS NOT NULL THEN
        days_remaining := EXTRACT(days FROM (
            (current_subscription->'subscription'->>'current_period_end')::TIMESTAMPTZ - NOW()
        ));
        
        IF days_remaining > 0 AND price_difference > 0 THEN
            prorated_amount := ROUND((price_difference::DECIMAL / days_in_cycle) * days_remaining);
        ELSE
            prorated_amount := 0;
        END IF;
    ELSE
        prorated_amount := new_price; -- First paid plan
        days_remaining := days_in_cycle;
    END IF;
    
    result := jsonb_build_object(
        'current_plan', current_plan->>'slug',
        'new_plan', p_new_plan_slug,
        'billing_cycle', p_billing_cycle,
        'current_price', current_price,
        'new_price', new_price,
        'price_difference', price_difference,
        'prorated_amount', prorated_amount,
        'days_remaining', days_remaining,
        'is_upgrade', price_difference > 0,
        'is_downgrade', price_difference < 0,
        'immediate_charge', GREATEST(0, prorated_amount)
    );
    
    RETURN result;
END;
$$;

-- Function to handle trial expiration
CREATE OR REPLACE FUNCTION handle_trial_expiration()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    expired_trial RECORD;
    processed_count INTEGER := 0;
BEGIN
    -- Find expired trials
    FOR expired_trial IN
        SELECT *
        FROM subscriptions
        WHERE trial_end IS NOT NULL
        AND trial_end < NOW()
        AND status = 'active'
    LOOP
        -- Update subscription status
        UPDATE subscriptions
        SET status = 'past_due', updated_at = NOW()
        WHERE id = expired_trial.id;
        
        -- Log trial expiration
        INSERT INTO audit_logs (
            user_id,
            action,
            table_name,
            record_id,
            new_values,
            created_at
        ) VALUES (
            expired_trial.user_id,
            'trial_expired',
            'subscriptions',
            expired_trial.id,
            jsonb_build_object(
                'trial_end', expired_trial.trial_end,
                'new_status', 'past_due'
            ),
            NOW()
        );
        
        processed_count := processed_count + 1;
    END LOOP;
    
    RETURN processed_count;
END;
$$;

-- Function to get subscription analytics
CREATE OR REPLACE FUNCTION get_subscription_analytics(
    p_start_date DATE DEFAULT NULL,
    p_end_date DATE DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    start_date DATE;
    end_date DATE;
    result JSONB;
    plan_stats JSONB[];
    plan_record RECORD;
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
    
    -- Get stats by plan
    FOR plan_record IN
        SELECT 
            sp.name,
            sp.slug,
            COUNT(s.id) as subscriber_count,
            COUNT(s.id) FILTER (WHERE s.status = 'active') as active_subscribers,
            COUNT(s.id) FILTER (WHERE s.created_at >= start_date AND s.created_at <= end_date) as new_subscribers,
            COUNT(s.id) FILTER (WHERE s.status = 'canceled' AND s.updated_at >= start_date AND s.updated_at <= end_date) as churned_subscribers,
            COALESCE(SUM(CASE 
                WHEN s.status = 'active' AND sp.price_monthly IS NOT NULL 
                THEN sp.price_monthly 
                ELSE 0 
            END), 0) as monthly_revenue
        FROM subscription_plans sp
        LEFT JOIN subscriptions s ON sp.id = s.plan_id
        WHERE sp.is_active = TRUE
        GROUP BY sp.id, sp.name, sp.slug, sp.price_monthly
        ORDER BY sp.sort_order
    LOOP
        plan_stats := array_append(plan_stats, jsonb_build_object(
            'plan_name', plan_record.name,
            'plan_slug', plan_record.slug,
            'total_subscribers', plan_record.subscriber_count,
            'active_subscribers', plan_record.active_subscribers,
            'new_subscribers', plan_record.new_subscribers,
            'churned_subscribers', plan_record.churned_subscribers,
            'monthly_revenue', plan_record.monthly_revenue,
            'churn_rate', CASE 
                WHEN plan_record.subscriber_count > 0 
                THEN ROUND((plan_record.churned_subscribers::DECIMAL / plan_record.subscriber_count) * 100, 2)
                ELSE 0 
            END
        ));
    END LOOP;
    
    -- Build comprehensive result
    result := jsonb_build_object(
        'period', jsonb_build_object(
            'start_date', start_date,
            'end_date', end_date
        ),
        'summary', jsonb_build_object(
            'total_revenue', (
                SELECT COALESCE(SUM(
                    CASE WHEN s.status = 'active' THEN sp.price_monthly ELSE 0 END
                ), 0)
                FROM subscriptions s
                JOIN subscription_plans sp ON s.plan_id = sp.id
            ),
            'total_active_subscribers', (
                SELECT COUNT(*)
                FROM subscriptions
                WHERE status = 'active'
            ),
            'total_free_users', (
                SELECT COUNT(*)
                FROM profiles p
                LEFT JOIN subscriptions s ON p.id = s.user_id AND s.status = 'active'
                WHERE s.id IS NULL
            )
        ),
        'plans', COALESCE(plan_stats, ARRAY[]::JSONB[])
    );
    
    RETURN result;
END;
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION get_active_subscription TO authenticated;
GRANT EXECUTE ON FUNCTION can_access_feature TO authenticated;
GRANT EXECUTE ON FUNCTION has_reached_limit TO authenticated;
GRANT EXECUTE ON FUNCTION get_subscription_billing_info TO authenticated;
GRANT EXECUTE ON FUNCTION get_plan_comparison TO authenticated;
GRANT EXECUTE ON FUNCTION calculate_plan_change_cost TO authenticated;

-- Admin functions
GRANT EXECUTE ON FUNCTION upsert_subscription TO service_role;
GRANT EXECUTE ON FUNCTION cancel_subscription TO service_role;
GRANT EXECUTE ON FUNCTION handle_trial_expiration TO service_role;
GRANT EXECUTE ON FUNCTION get_subscription_analytics TO service_role;