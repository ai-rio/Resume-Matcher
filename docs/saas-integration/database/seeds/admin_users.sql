-- Admin Users Setup
-- Initial admin accounts and permissions for Resume-Matcher SaaS platform

-- Note: This file should be run after the initial admin users are created through Supabase Auth
-- Replace the UUIDs below with actual user IDs from your auth.users table

-- Create admin user profiles
-- These IDs should match actual user IDs created through Supabase Auth
INSERT INTO profiles (
    id,
    email,
    full_name,
    company,
    job_title,
    preferences,
    onboarding_completed,
    created_at
) VALUES 
(
    'admin-uuid-1111-1111-1111-111111111111', -- Replace with actual admin user ID
    'admin@resume-matcher.com',
    'System Administrator',
    'Resume-Matcher',
    'System Administrator',
    '{
        "is_admin": true,
        "is_super_admin": true,
        "theme": "dark",
        "notifications_email": true,
        "notifications_browser": true,
        "language": "en",
        "timezone": "UTC",
        "dashboard_layout": "admin",
        "admin_permissions": {
            "user_management": true,
            "subscription_management": true,
            "analytics_access": true,
            "system_settings": true,
            "billing_management": true,
            "support_access": true
        },
        "security_settings": {
            "mfa_enabled": true,
            "session_timeout": 3600,
            "ip_whitelist": []
        }
    }'::jsonb,
    true,
    NOW()
) ON CONFLICT (id) DO UPDATE SET
    preferences = EXCLUDED.preferences,
    updated_at = NOW();

INSERT INTO profiles (
    id,
    email,
    full_name,
    company,
    job_title,
    preferences,
    onboarding_completed,
    created_at
) VALUES 
(
    'admin-uuid-2222-2222-2222-222222222222', -- Replace with actual support admin user ID
    'support@resume-matcher.com',
    'Support Manager',
    'Resume-Matcher',
    'Customer Support Manager',
    '{
        "is_admin": true,
        "is_super_admin": false,
        "theme": "light",
        "notifications_email": true,
        "notifications_browser": true,
        "language": "en",
        "timezone": "America/New_York",
        "dashboard_layout": "support",
        "admin_permissions": {
            "user_management": true,
            "subscription_management": false,
            "analytics_access": true,
            "system_settings": false,
            "billing_management": false,
            "support_access": true
        },
        "security_settings": {
            "mfa_enabled": true,
            "session_timeout": 7200,
            "ip_whitelist": []
        }
    }'::jsonb,
    true,
    NOW()
) ON CONFLICT (id) DO UPDATE SET
    preferences = EXCLUDED.preferences,
    updated_at = NOW();

INSERT INTO profiles (
    id,
    email,
    full_name,
    company,
    job_title,
    preferences,
    onboarding_completed,
    created_at
) VALUES 
(
    'admin-uuid-3333-3333-3333-333333333333', -- Replace with actual billing admin user ID
    'billing@resume-matcher.com',
    'Billing Administrator',
    'Resume-Matcher',
    'Billing Administrator',
    '{
        "is_admin": true,
        "is_super_admin": false,
        "theme": "light",
        "notifications_email": true,
        "notifications_browser": true,
        "language": "en",
        "timezone": "America/Los_Angeles",
        "dashboard_layout": "admin",
        "admin_permissions": {
            "user_management": false,
            "subscription_management": true,
            "analytics_access": true,
            "system_settings": false,
            "billing_management": true,
            "support_access": false
        },
        "security_settings": {
            "mfa_enabled": true,
            "session_timeout": 3600,
            "ip_whitelist": []
        }
    }'::jsonb,
    true,
    NOW()
) ON CONFLICT (id) DO UPDATE SET
    preferences = EXCLUDED.preferences,
    updated_at = NOW();

-- Create admin subscriptions (free enterprise access)
INSERT INTO subscriptions (
    id,
    user_id,
    plan_id,
    status,
    created_at
) VALUES 
(
    gen_random_uuid(),
    'admin-uuid-1111-1111-1111-111111111111',
    (SELECT id FROM subscription_plans WHERE slug = 'enterprise' LIMIT 1),
    'active',
    NOW()
),
(
    gen_random_uuid(),
    'admin-uuid-2222-2222-2222-222222222222',
    (SELECT id FROM subscription_plans WHERE slug = 'enterprise' LIMIT 1),
    'active',
    NOW()
),
(
    gen_random_uuid(),
    'admin-uuid-3333-3333-3333-333333333333',
    (SELECT id FROM subscription_plans WHERE slug = 'enterprise' LIMIT 1),
    'active',
    NOW()
) ON CONFLICT DO NOTHING;

-- Create admin roles table for fine-grained permissions
CREATE TABLE IF NOT EXISTS admin_roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    description TEXT,
    permissions JSONB NOT NULL DEFAULT '{}',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert admin roles
INSERT INTO admin_roles (name, description, permissions) VALUES 
(
    'super_admin',
    'Full system access with all permissions',
    '{
        "user_management": {
            "view_users": true,
            "edit_users": true,
            "delete_users": true,
            "suspend_users": true,
            "reset_passwords": true,
            "manage_profiles": true
        },
        "subscription_management": {
            "view_subscriptions": true,
            "modify_subscriptions": true,
            "cancel_subscriptions": true,
            "refund_payments": true,
            "manage_plans": true
        },
        "system_management": {
            "view_settings": true,
            "modify_settings": true,
            "manage_features": true,
            "system_maintenance": true,
            "database_access": true
        },
        "analytics": {
            "view_analytics": true,
            "export_data": true,
            "user_insights": true,
            "revenue_reports": true
        },
        "support": {
            "view_tickets": true,
            "respond_to_tickets": true,
            "escalate_issues": true,
            "access_user_data": true
        }
    }'::jsonb
),
(
    'support_admin',
    'Customer support and user management permissions',
    '{
        "user_management": {
            "view_users": true,
            "edit_users": true,
            "delete_users": false,
            "suspend_users": true,
            "reset_passwords": true,
            "manage_profiles": true
        },
        "subscription_management": {
            "view_subscriptions": true,
            "modify_subscriptions": false,
            "cancel_subscriptions": false,
            "refund_payments": false,
            "manage_plans": false
        },
        "analytics": {
            "view_analytics": true,
            "export_data": false,
            "user_insights": true,
            "revenue_reports": false
        },
        "support": {
            "view_tickets": true,
            "respond_to_tickets": true,
            "escalate_issues": true,
            "access_user_data": true
        }
    }'::jsonb
),
(
    'billing_admin',
    'Billing and subscription management permissions',
    '{
        "user_management": {
            "view_users": true,
            "edit_users": false,
            "delete_users": false,
            "suspend_users": false,
            "reset_passwords": false,
            "manage_profiles": false
        },
        "subscription_management": {
            "view_subscriptions": true,
            "modify_subscriptions": true,
            "cancel_subscriptions": true,
            "refund_payments": true,
            "manage_plans": true
        },
        "analytics": {
            "view_analytics": true,
            "export_data": true,
            "user_insights": false,
            "revenue_reports": true
        },
        "support": {
            "view_tickets": false,
            "respond_to_tickets": false,
            "escalate_issues": false,
            "access_user_data": false
        }
    }'::jsonb
);

-- Create user-role assignments table
CREATE TABLE IF NOT EXISTS admin_user_roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    role_id UUID REFERENCES admin_roles(id) ON DELETE CASCADE,
    assigned_by UUID REFERENCES profiles(id),
    assigned_at TIMESTAMPTZ DEFAULT NOW(),
    is_active BOOLEAN DEFAULT TRUE,
    UNIQUE(user_id, role_id)
);

-- Assign roles to admin users
INSERT INTO admin_user_roles (user_id, role_id, assigned_by) VALUES 
(
    'admin-uuid-1111-1111-1111-111111111111',
    (SELECT id FROM admin_roles WHERE name = 'super_admin'),
    'admin-uuid-1111-1111-1111-111111111111'
),
(
    'admin-uuid-2222-2222-2222-222222222222',
    (SELECT id FROM admin_roles WHERE name = 'support_admin'),
    'admin-uuid-1111-1111-1111-111111111111'
),
(
    'admin-uuid-3333-3333-3333-333333333333',
    (SELECT id FROM admin_roles WHERE name = 'billing_admin'),
    'admin-uuid-1111-1111-1111-111111111111'
) ON CONFLICT (user_id, role_id) DO NOTHING;

-- Create admin activity log
CREATE TABLE IF NOT EXISTS admin_activity_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_user_id UUID REFERENCES profiles(id),
    action TEXT NOT NULL,
    target_type TEXT, -- user, subscription, plan, setting, etc.
    target_id UUID,
    details JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS on admin tables
ALTER TABLE admin_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_activity_log ENABLE ROW LEVEL SECURITY;

-- Admin table policies
CREATE POLICY "super_admin_full_access_roles" ON admin_roles
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM admin_user_roles aur
            JOIN admin_roles ar ON aur.role_id = ar.id
            WHERE aur.user_id = auth.uid()
            AND ar.name = 'super_admin'
            AND aur.is_active = true
        )
    );

CREATE POLICY "admins_can_view_roles" ON admin_roles
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM profiles p
            WHERE p.id = auth.uid()
            AND (p.preferences->>'is_admin')::boolean = true
        )
    );

CREATE POLICY "admins_can_view_user_roles" ON admin_user_roles
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM profiles p
            WHERE p.id = auth.uid()
            AND (p.preferences->>'is_admin')::boolean = true
        )
    );

CREATE POLICY "super_admin_manage_user_roles" ON admin_user_roles
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM admin_user_roles aur
            JOIN admin_roles ar ON aur.role_id = ar.id
            WHERE aur.user_id = auth.uid()
            AND ar.name = 'super_admin'
            AND aur.is_active = true
        )
    );

CREATE POLICY "admins_can_view_activity_log" ON admin_activity_log
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM profiles p
            WHERE p.id = auth.uid()
            AND (p.preferences->>'is_admin')::boolean = true
        )
    );

CREATE POLICY "service_role_activity_log" ON admin_activity_log
    FOR INSERT USING (auth.role() = 'service_role');

-- Function to check admin permissions
CREATE OR REPLACE FUNCTION check_admin_permission(
    p_user_id UUID,
    p_permission_path TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    user_permissions JSONB;
    permission_parts TEXT[];
    current_path JSONB;
    i INTEGER;
BEGIN
    -- Check if user is admin
    IF NOT EXISTS (
        SELECT 1 FROM profiles 
        WHERE id = p_user_id 
        AND (preferences->>'is_admin')::boolean = true
    ) THEN
        RETURN FALSE;
    END IF;
    
    -- Get user's combined permissions from all active roles
    SELECT jsonb_agg(ar.permissions)
    INTO user_permissions
    FROM admin_user_roles aur
    JOIN admin_roles ar ON aur.role_id = ar.id
    WHERE aur.user_id = p_user_id
    AND aur.is_active = true
    AND ar.is_active = true;
    
    -- If no roles assigned, check legacy admin flag
    IF user_permissions IS NULL THEN
        SELECT preferences->>'is_super_admin'
        FROM profiles
        WHERE id = p_user_id
        INTO current_path;
        
        RETURN COALESCE((current_path)::boolean, false);
    END IF;
    
    -- Parse permission path (e.g., "user_management.edit_users")
    permission_parts := string_to_array(p_permission_path, '.');
    
    -- Check if any role has the required permission
    FOR i IN 1..jsonb_array_length(user_permissions) LOOP
        current_path := user_permissions->i-1;
        
        -- Navigate through the permission path
        FOR j IN 1..array_length(permission_parts, 1) LOOP
            current_path := current_path->permission_parts[j];
            IF current_path IS NULL THEN
                EXIT;
            END IF;
        END LOOP;
        
        -- If permission found and is true, return true
        IF current_path IS NOT NULL AND (current_path)::boolean = true THEN
            RETURN TRUE;
        END IF;
    END LOOP;
    
    RETURN FALSE;
END;
$$;

-- Function to log admin activity
CREATE OR REPLACE FUNCTION log_admin_activity(
    p_admin_user_id UUID,
    p_action TEXT,
    p_target_type TEXT DEFAULT NULL,
    p_target_id UUID DEFAULT NULL,
    p_details JSONB DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    activity_id UUID;
BEGIN
    INSERT INTO admin_activity_log (
        admin_user_id,
        action,
        target_type,
        target_id,
        details,
        ip_address,
        user_agent
    ) VALUES (
        p_admin_user_id,
        p_action,
        p_target_type,
        p_target_id,
        p_details,
        inet_client_addr(),
        current_setting('request.headers', true)::json->>'user-agent'
    ) RETURNING id INTO activity_id;
    
    RETURN activity_id;
END;
$$;

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_admin_user_roles_user_active ON admin_user_roles(user_id, is_active);
CREATE INDEX IF NOT EXISTS idx_admin_activity_log_user_created ON admin_activity_log(admin_user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_admin_activity_log_action ON admin_activity_log(action, created_at DESC);

-- Insert initial admin settings
INSERT INTO app_settings (key, value, description) VALUES 
(
    'admin_settings',
    '{
        "max_admin_sessions": 5,
        "admin_session_timeout": 3600,
        "require_mfa_for_admins": true,
        "admin_ip_whitelist_enabled": false,
        "admin_activity_retention_days": 365,
        "super_admin_notifications": true
    }'::jsonb,
    'Administrative security and access settings'
),
(
    'admin_dashboard_config',
    '{
        "default_dashboard": "overview",
        "widgets_enabled": {
            "user_stats": true,
            "revenue_chart": true,
            "subscription_breakdown": true,
            "support_queue": true,
            "system_health": true
        },
        "refresh_intervals": {
            "user_stats": 300,
            "revenue_chart": 600,
            "system_health": 60
        }
    }'::jsonb,
    'Admin dashboard configuration'
) ON CONFLICT (key) DO UPDATE SET
    value = EXCLUDED.value,
    updated_at = NOW();

-- Grant permissions
GRANT EXECUTE ON FUNCTION check_admin_permission TO authenticated;
GRANT EXECUTE ON FUNCTION log_admin_activity TO service_role;

-- Log admin setup
INSERT INTO audit_logs (
    user_id,
    action,
    table_name,
    new_values,
    created_at
) VALUES (
    '00000000-0000-0000-0000-000000000000',
    'admin_setup_completed',
    'system',
    '{
        "admin_users_created": 3,
        "roles_created": 3,
        "permissions_configured": true,
        "security_policies_enabled": true,
        "setup_date": "'|| NOW() ||'"
    }'::jsonb,
    NOW()
);

-- Instructions for completing admin setup
DO $$
BEGIN
    RAISE NOTICE 'Admin setup completed successfully!';
    RAISE NOTICE '';
    RAISE NOTICE 'IMPORTANT: Please update the following UUIDs with actual user IDs:';
    RAISE NOTICE '1. admin-uuid-1111-1111-1111-111111111111 (System Administrator)';
    RAISE NOTICE '2. admin-uuid-2222-2222-2222-222222222222 (Support Manager)';
    RAISE NOTICE '3. admin-uuid-3333-3333-3333-333333333333 (Billing Administrator)';
    RAISE NOTICE '';
    RAISE NOTICE 'These should match the actual user IDs created through Supabase Auth.';
    RAISE NOTICE 'You can find the user IDs in the auth.users table after creating the accounts.';
    RAISE NOTICE '';
    RAISE NOTICE 'After updating the UUIDs, re-run this script to properly assign admin roles.';
END $$;