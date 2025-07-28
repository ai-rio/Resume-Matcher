-- Initial Subscription Plans
-- Default subscription tiers for Resume-Matcher SaaS

-- Insert default subscription plans
INSERT INTO subscription_plans (
    id,
    name,
    slug,
    description,
    price_monthly,
    price_yearly,
    features,
    limits,
    is_active,
    sort_order
) VALUES 
(
    gen_random_uuid(),
    'Free',
    'free',
    'Perfect for getting started with basic resume analysis',
    0,
    0,
    '{
        "resume_uploads_per_month": 3,
        "job_analyses_per_month": 10,
        "advanced_analytics": false,
        "api_access": false,
        "priority_support": false,
        "custom_templates": false,
        "team_collaboration": false,
        "white_label": false,
        "export_formats": ["pdf"],
        "storage_included": "5MB",
        "support_level": "community"
    }'::jsonb,
    '{
        "max_resumes": 3,
        "max_file_size": 5242880,
        "analyses_per_month": 10,
        "uploads_per_month": 3,
        "storage_limit": 5242880,
        "api_calls_per_month": 0,
        "rate_limit_per_hour": 50
    }'::jsonb,
    true,
    1
),
(
    gen_random_uuid(),
    'Pro',
    'pro',
    'Advanced features for professionals and active job seekers',
    1999,
    19990,
    '{
        "resume_uploads_per_month": 25,
        "job_analyses_per_month": 100,
        "advanced_analytics": true,
        "api_access": true,
        "priority_support": true,
        "custom_templates": true,
        "team_collaboration": false,
        "white_label": false,
        "export_formats": ["pdf", "docx", "txt"],
        "storage_included": "100MB",
        "support_level": "email",
        "features_included": [
            "Detailed skill gap analysis",
            "ATS optimization tips",
            "Industry-specific keywords",
            "Salary insights",
            "Interview preparation"
        ]
    }'::jsonb,
    '{
        "max_resumes": 25,
        "max_file_size": 10485760,
        "analyses_per_month": 100,
        "uploads_per_month": 25,
        "storage_limit": 104857600,
        "api_calls_per_month": 1000,
        "rate_limit_per_hour": 500
    }'::jsonb,
    true,
    2
),
(
    gen_random_uuid(),
    'Team',
    'team',
    'Collaboration tools for teams and small businesses',
    4999,
    49990,
    '{
        "resume_uploads_per_month": 100,
        "job_analyses_per_month": 500,
        "advanced_analytics": true,
        "api_access": true,
        "priority_support": true,
        "custom_templates": true,
        "team_collaboration": true,
        "white_label": false,
        "export_formats": ["pdf", "docx", "txt", "json"],
        "storage_included": "500MB",
        "support_level": "priority",
        "team_features": [
            "Up to 10 team members",
            "Shared template library",
            "Team analytics dashboard",
            "Bulk analysis tools",
            "Role-based permissions"
        ]
    }'::jsonb,
    '{
        "max_resumes": 100,
        "max_file_size": 20971520,
        "analyses_per_month": 500,
        "uploads_per_month": 100,
        "storage_limit": 524288000,
        "api_calls_per_month": 5000,
        "rate_limit_per_hour": 2000,
        "max_team_members": 10
    }'::jsonb,
    true,
    3
),
(
    gen_random_uuid(),
    'Enterprise',
    'enterprise',
    'Custom solutions for large organizations with advanced needs',
    NULL,
    NULL,
    '{
        "resume_uploads_per_month": "unlimited",
        "job_analyses_per_month": "unlimited",
        "advanced_analytics": true,
        "api_access": true,
        "priority_support": true,
        "custom_templates": true,
        "team_collaboration": true,
        "white_label": true,
        "export_formats": ["pdf", "docx", "txt", "json", "xml"],
        "storage_included": "unlimited",
        "support_level": "dedicated",
        "enterprise_features": [
            "Unlimited team members",
            "Custom integrations",
            "White-label branding",
            "SSO authentication",
            "Advanced security",
            "Custom workflows",
            "Dedicated support manager",
            "SLA guarantees"
        ]
    }'::jsonb,
    '{
        "max_resumes": -1,
        "max_file_size": 52428800,
        "analyses_per_month": -1,
        "uploads_per_month": -1,
        "storage_limit": -1,
        "api_calls_per_month": -1,
        "rate_limit_per_hour": 10000,
        "max_team_members": -1
    }'::jsonb,
    true,
    4
);

-- Insert application settings
INSERT INTO app_settings (key, value, description) VALUES
(
    'stripe_webhook_secret',
    '{"development": "", "staging": "", "production": ""}'::jsonb,
    'Stripe webhook endpoint secrets for different environments'
),
(
    'trial_period_days',
    '14'::jsonb,
    'Default trial period in days for new subscriptions'
),
(
    'max_file_size_bytes',
    '20971520'::jsonb,
    'Maximum file size allowed for resume uploads (20MB)'
),
(
    'allowed_file_types',
    '["application/pdf", "application/msword", "application/vnd.openxmlformats-officedocument.wordprocessingml.document"]'::jsonb,
    'Allowed MIME types for resume uploads'
),
(
    'rate_limits',
    '{
        "free": {"api_calls_per_hour": 50, "uploads_per_hour": 5},
        "pro": {"api_calls_per_hour": 500, "uploads_per_hour": 25},
        "team": {"api_calls_per_hour": 2000, "uploads_per_hour": 100},
        "enterprise": {"api_calls_per_hour": 10000, "uploads_per_hour": 500}
    }'::jsonb,
    'Rate limits by subscription plan'
),
(
    'feature_flags',
    '{
        "beta_features_enabled": false,
        "maintenance_mode": false,
        "new_user_signup_enabled": true,
        "ai_analysis_v2_enabled": false
    }'::jsonb,
    'Feature flags for controlling application behavior'
),
(
    'analytics_settings',
    '{
        "track_user_events": true,
        "retention_days": 90,
        "anonymize_after_days": 365
    }'::jsonb,
    'Analytics and data retention settings'
),
(
    'email_templates',
    '{
        "welcome": {
            "subject": "Welcome to Resume-Matcher!",
            "template_id": "welcome_email"
        },
        "trial_ending": {
            "subject": "Your trial is ending soon",
            "template_id": "trial_ending"
        },
        "subscription_activated": {
            "subject": "Your subscription is now active",
            "template_id": "subscription_active"
        },
        "subscription_canceled": {
            "subject": "Subscription canceled",
            "template_id": "subscription_canceled"
        }
    }'::jsonb,
    'Email template configuration'
),
(
    'pricing_display',
    '{
        "currency": "USD",
        "currency_symbol": "$",
        "show_yearly_discount": true,
        "highlight_popular_plan": "pro",
        "free_trial_days": 14
    }'::jsonb,
    'Pricing page display settings'
),
(
    'integrations',
    '{
        "stripe": {
            "enabled": true,
            "webhook_tolerance": 300
        },
        "sendgrid": {
            "enabled": true,
            "api_version": "v3"
        },
        "sentry": {
            "enabled": true,
            "sample_rate": 0.1
        }
    }'::jsonb,
    'Third-party integration settings'
),
(
    'maintenance',
    '{
        "cleanup_old_data_enabled": true,
        "cleanup_interval_days": 7,
        "data_retention_days": 365,
        "backup_frequency": "daily"
    }'::jsonb,
    'Maintenance and cleanup settings'
);

-- Insert default admin user settings (to be updated with actual admin user ID)
-- This should be updated after the first admin user is created
INSERT INTO profiles (
    id,
    email,
    full_name,
    preferences,
    onboarding_completed,
    created_at
) VALUES (
    '00000000-0000-0000-0000-000000000000', -- Placeholder ID
    'admin@resume-matcher.com',
    'System Administrator',
    '{
        "is_admin": true,
        "email_notifications": true,
        "dashboard_layout": "admin",
        "timezone": "UTC"
    }'::jsonb,
    true,
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- Create initial usage summary for system metrics
INSERT INTO usage_summaries (
    user_id,
    month,
    analyses_count,
    resumes_uploaded,
    jobs_analyzed,
    api_calls,
    storage_used
) VALUES (
    '00000000-0000-0000-0000-000000000000',
    DATE_TRUNC('month', CURRENT_DATE)::DATE,
    0,
    0,
    0,
    0,
    0
) ON CONFLICT (user_id, month) DO NOTHING;

-- Insert sample job descriptions for testing/demo purposes
INSERT INTO job_descriptions (
    id,
    user_id,
    title,
    company,
    description,
    requirements,
    parsed_data,
    is_active
) VALUES 
(
    gen_random_uuid(),
    '00000000-0000-0000-0000-000000000000',
    'Senior Software Engineer',
    'TechCorp Inc.',
    'We are seeking a Senior Software Engineer to join our dynamic team. You will be responsible for designing, developing, and maintaining scalable web applications using modern technologies.',
    'Requirements:
    - 5+ years of software development experience
    - Strong proficiency in Python, JavaScript, and SQL
    - Experience with React, Node.js, and PostgreSQL
    - Knowledge of cloud platforms (AWS, GCP, or Azure)
    - Excellent problem-solving and communication skills
    - Bachelor''s degree in Computer Science or related field',
    '{
        "required_skills": ["Python", "JavaScript", "SQL", "React", "Node.js", "PostgreSQL"],
        "preferred_skills": ["AWS", "GCP", "Azure", "Docker", "Kubernetes"],
        "experience_level": "Senior",
        "min_years_experience": 5,
        "education_level": "Bachelor''s",
        "remote_friendly": true,
        "salary_range": "$120,000 - $180,000",
        "location": "San Francisco, CA (Remote OK)"
    }'::jsonb,
    true
),
(
    gen_random_uuid(),
    '00000000-0000-0000-0000-000000000000',
    'Data Scientist',
    'AI Innovations Ltd.',
    'Join our data science team to build machine learning models and derive insights from large datasets. You will work on cutting-edge AI projects and collaborate with cross-functional teams.',
    'Requirements:
    - 3+ years of data science experience
    - Proficiency in Python, R, and SQL
    - Experience with machine learning frameworks (TensorFlow, PyTorch, scikit-learn)
    - Strong statistical analysis and data visualization skills
    - Experience with big data tools (Spark, Hadoop)
    - Master''s degree in Data Science, Statistics, or related field',
    '{
        "required_skills": ["Python", "R", "SQL", "Machine Learning", "TensorFlow", "PyTorch", "scikit-learn"],
        "preferred_skills": ["Spark", "Hadoop", "Tableau", "Power BI", "Docker"],
        "experience_level": "Mid-Senior",
        "min_years_experience": 3,
        "education_level": "Master''s",
        "remote_friendly": true,
        "salary_range": "$100,000 - $150,000",
        "location": "New York, NY (Hybrid)"
    }'::jsonb,
    true
),
(
    gen_random_uuid(),
    '00000000-0000-0000-0000-000000000000',
    'Frontend Developer',
    'Digital Agency Co.',
    'We''re looking for a creative Frontend Developer to build beautiful and responsive user interfaces. You''ll work closely with designers and backend developers to create exceptional user experiences.',
    'Requirements:
    - 2+ years of frontend development experience
    - Proficiency in HTML, CSS, JavaScript, and TypeScript
    - Experience with React or Vue.js
    - Knowledge of responsive design and CSS frameworks
    - Familiarity with version control (Git)
    - Understanding of web performance optimization
    - Portfolio demonstrating frontend work',
    '{
        "required_skills": ["HTML", "CSS", "JavaScript", "TypeScript", "React", "Git"],
        "preferred_skills": ["Vue.js", "SASS", "Webpack", "Jest", "Figma"],
        "experience_level": "Mid",
        "min_years_experience": 2,
        "education_level": "Bachelor''s",
        "remote_friendly": false,
        "salary_range": "$70,000 - $100,000",
        "location": "Austin, TX"
    }'::jsonb,
    true
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_subscription_plans_active_slug ON subscription_plans(slug) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_app_settings_key ON app_settings(key);
CREATE INDEX IF NOT EXISTS idx_job_descriptions_sample ON job_descriptions(user_id, is_active) WHERE user_id = '00000000-0000-0000-0000-000000000000';

-- Log the initial setup
INSERT INTO audit_logs (
    user_id,
    action,
    table_name,
    new_values,
    created_at
) VALUES (
    '00000000-0000-0000-0000-000000000000',
    'initial_setup',
    'system',
    '{
        "plans_created": 4,
        "settings_configured": 10,
        "sample_jobs_created": 3,
        "setup_date": "'|| NOW() ||'"
    }'::jsonb,
    NOW()
);