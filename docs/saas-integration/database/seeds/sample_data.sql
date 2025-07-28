-- Sample Data for Development and Testing
-- This file contains realistic sample data for testing the Resume-Matcher SaaS platform

-- Sample Users (Profiles)
-- Note: In production, these would be created through Supabase Auth
INSERT INTO profiles (
    id,
    email,
    full_name,
    company,
    job_title,
    onboarding_completed,
    preferences,
    created_at
) VALUES 
(
    'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
    'john.doe@example.com',
    'John Doe',
    'TechCorp Inc.',
    'Software Engineer',
    true,
    '{
        "theme": "light",
        "notifications_email": true,
        "notifications_browser": true,
        "language": "en",
        "timezone": "America/New_York",
        "dashboard_layout": "grid"
    }'::jsonb,
    NOW() - INTERVAL '30 days'
),
(
    'b1ffcd99-9c0b-4ef8-bb6d-6bb9bd380a22',
    'jane.smith@example.com',
    'Jane Smith',
    'DataCorp Ltd.',
    'Data Scientist',
    true,
    '{
        "theme": "dark",
        "notifications_email": true,
        "notifications_browser": false,
        "language": "en",
        "timezone": "America/Los_Angeles",
        "dashboard_layout": "list"
    }'::jsonb,
    NOW() - INTERVAL '15 days'
),
(
    'c2ddee99-9c0b-4ef8-bb6d-6bb9bd380a33',
    'mike.johnson@example.com',
    'Mike Johnson',
    'StartupXYZ',
    'Frontend Developer',
    false,
    '{
        "theme": "light",
        "notifications_email": true,
        "notifications_browser": true,
        "language": "en",
        "timezone": "America/Chicago"
    }'::jsonb,
    NOW() - INTERVAL '7 days'
),
(
    'd3eeff99-9c0b-4ef8-bb6d-6bb9bd380a44',
    'sarah.wilson@example.com',
    'Sarah Wilson',
    'Enterprise Corp',
    'HR Manager',
    true,
    '{
        "theme": "light",
        "notifications_email": true,
        "notifications_browser": true,
        "language": "en",
        "timezone": "Europe/London",
        "dashboard_layout": "grid"
    }'::jsonb,
    NOW() - INTERVAL '45 days'
);

-- Sample Subscriptions
INSERT INTO subscriptions (
    id,
    user_id,
    plan_id,
    stripe_subscription_id,
    stripe_customer_id,
    status,
    current_period_start,
    current_period_end,
    trial_end,
    created_at
) VALUES 
(
    gen_random_uuid(),
    'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
    (SELECT id FROM subscription_plans WHERE slug = 'pro' LIMIT 1),
    'sub_1234567890',
    'cus_1234567890',
    'active',
    NOW() - INTERVAL '15 days',
    NOW() + INTERVAL '15 days',
    NULL,
    NOW() - INTERVAL '15 days'
),
(
    gen_random_uuid(),
    'b1ffcd99-9c0b-4ef8-bb6d-6bb9bd380a22',
    (SELECT id FROM subscription_plans WHERE slug = 'team' LIMIT 1),
    'sub_2345678901',
    'cus_2345678901',
    'active',
    NOW() - INTERVAL '10 days',
    NOW() + INTERVAL '20 days',
    NULL,
    NOW() - INTERVAL '10 days'
),
(
    gen_random_uuid(),
    'c2ddee99-9c0b-4ef8-bb6d-6bb9bd380a33',
    (SELECT id FROM subscription_plans WHERE slug = 'free' LIMIT 1),
    NULL,
    NULL,
    'active',
    NULL,
    NULL,
    NOW() + INTERVAL '7 days',
    NOW() - INTERVAL '7 days'
),
(
    gen_random_uuid(),
    'd3eeff99-9c0b-4ef8-bb6d-6bb9bd380a44',
    (SELECT id FROM subscription_plans WHERE slug = 'enterprise' LIMIT 1),
    'sub_3456789012',
    'cus_3456789012',
    'active',
    NOW() - INTERVAL '30 days',
    NOW() + INTERVAL '335 days',
    NULL,
    NOW() - INTERVAL '30 days'
);

-- Sample Resumes
INSERT INTO resumes (
    id,
    user_id,
    title,
    filename,
    file_path,
    file_size,
    mime_type,
    content_text,
    parsed_data,
    is_active,
    created_at
) VALUES 
(
    gen_random_uuid(),
    'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
    'John Doe - Software Engineer',
    'john_doe_resume.pdf',
    'resumes/a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11/resume_1.pdf',
    1048576,
    'application/pdf',
    'John Doe\nSoftware Engineer\nEmail: john.doe@example.com\nPhone: (555) 123-4567\n\nEXPERIENCE\nSenior Software Engineer | TechCorp Inc. | 2020-Present\n- Developed scalable web applications using React and Node.js\n- Led a team of 5 developers on microservices architecture\n- Implemented CI/CD pipelines reducing deployment time by 40%\n\nSoftware Engineer | StartupABC | 2018-2020\n- Built RESTful APIs using Python and Django\n- Optimized database queries improving performance by 30%\n- Mentored junior developers\n\nSKILLS\nProgramming: Python, JavaScript, TypeScript, Java\nFrameworks: React, Node.js, Django, Express\nDatabases: PostgreSQL, MongoDB, Redis\nTools: Docker, Kubernetes, AWS, Git',
    '{
        "personal_info": {
            "name": "John Doe",
            "email": "john.doe@example.com",
            "phone": "(555) 123-4567",
            "location": "San Francisco, CA"
        },
        "skills": {
            "programming": ["Python", "JavaScript", "TypeScript", "Java"],
            "frameworks": ["React", "Node.js", "Django", "Express"],
            "databases": ["PostgreSQL", "MongoDB", "Redis"],
            "tools": ["Docker", "Kubernetes", "AWS", "Git"]
        },
        "experience": [
            {
                "title": "Senior Software Engineer",
                "company": "TechCorp Inc.",
                "duration": "2020-Present",
                "achievements": [
                    "Developed scalable web applications using React and Node.js",
                    "Led a team of 5 developers on microservices architecture",
                    "Implemented CI/CD pipelines reducing deployment time by 40%"
                ]
            },
            {
                "title": "Software Engineer",
                "company": "StartupABC",
                "duration": "2018-2020",
                "achievements": [
                    "Built RESTful APIs using Python and Django",
                    "Optimized database queries improving performance by 30%",
                    "Mentored junior developers"
                ]
            }
        ],
        "education": [
            {
                "degree": "Bachelor of Science in Computer Science",
                "institution": "University of California, Berkeley",
                "year": "2018"
            }
        ]
    }'::jsonb,
    true,
    NOW() - INTERVAL '25 days'
),
(
    gen_random_uuid(),
    'b1ffcd99-9c0b-4ef8-bb6d-6bb9bd380a22',
    'Jane Smith - Data Scientist',
    'jane_smith_resume.pdf',
    'resumes/b1ffcd99-9c0b-4ef8-bb6d-6bb9bd380a22/resume_1.pdf',
    987654,
    'application/pdf',
    'Jane Smith\nData Scientist\nEmail: jane.smith@example.com\nPhone: (555) 987-6543\n\nEXPERIENCE\nSenior Data Scientist | DataCorp Ltd. | 2019-Present\n- Built machine learning models for customer segmentation\n- Developed predictive analytics reducing churn by 25%\n- Led data science initiatives across multiple teams\n\nData Analyst | Analytics Inc. | 2017-2019\n- Analyzed large datasets using Python and SQL\n- Created interactive dashboards with Tableau\n- Collaborated with stakeholders to drive data-driven decisions\n\nSKILLS\nProgramming: Python, R, SQL, MATLAB\nML Frameworks: TensorFlow, PyTorch, scikit-learn\nVisualization: Tableau, Power BI, matplotlib, seaborn\nBig Data: Spark, Hadoop, Kafka',
    '{
        "personal_info": {
            "name": "Jane Smith",
            "email": "jane.smith@example.com",
            "phone": "(555) 987-6543",
            "location": "New York, NY"
        },
        "skills": {
            "programming": ["Python", "R", "SQL", "MATLAB"],
            "ml_frameworks": ["TensorFlow", "PyTorch", "scikit-learn"],
            "visualization": ["Tableau", "Power BI", "matplotlib", "seaborn"],
            "big_data": ["Spark", "Hadoop", "Kafka"]
        },
        "experience": [
            {
                "title": "Senior Data Scientist",
                "company": "DataCorp Ltd.",
                "duration": "2019-Present",
                "achievements": [
                    "Built machine learning models for customer segmentation",
                    "Developed predictive analytics reducing churn by 25%",
                    "Led data science initiatives across multiple teams"
                ]
            },
            {
                "title": "Data Analyst",
                "company": "Analytics Inc.",
                "duration": "2017-2019",
                "achievements": [
                    "Analyzed large datasets using Python and SQL",
                    "Created interactive dashboards with Tableau",
                    "Collaborated with stakeholders to drive data-driven decisions"
                ]
            }
        ],
        "education": [
            {
                "degree": "Master of Science in Data Science",
                "institution": "Stanford University",
                "year": "2017"
            }
        ]
    }'::jsonb,
    true,
    NOW() - INTERVAL '12 days'
),
(
    gen_random_uuid(),
    'c2ddee99-9c0b-4ef8-bb6d-6bb9bd380a33',
    'Mike Johnson - Frontend Developer',
    'mike_johnson_resume.docx',
    'resumes/c2ddee99-9c0b-4ef8-bb6d-6bb9bd380a33/resume_1.docx',
    756432,
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'Mike Johnson\nFrontend Developer\nEmail: mike.johnson@example.com\nPhone: (555) 456-7890\n\nEXPERIENCE\nFrontend Developer | StartupXYZ | 2021-Present\n- Developed responsive web applications using React and TypeScript\n- Implemented modern CSS frameworks and design systems\n- Collaborated with UX/UI designers for pixel-perfect implementations\n\nJunior Developer | WebDev Co. | 2020-2021\n- Built landing pages and marketing websites\n- Learned modern JavaScript frameworks\n- Participated in code reviews and agile development\n\nSKILLS\nLanguages: HTML, CSS, JavaScript, TypeScript\nFrameworks: React, Vue.js, Angular\nStyling: SASS, Tailwind CSS, Bootstrap\nTools: Webpack, Vite, Git, Figma',
    '{
        "personal_info": {
            "name": "Mike Johnson",
            "email": "mike.johnson@example.com",
            "phone": "(555) 456-7890",
            "location": "Austin, TX"
        },
        "skills": {
            "languages": ["HTML", "CSS", "JavaScript", "TypeScript"],
            "frameworks": ["React", "Vue.js", "Angular"],
            "styling": ["SASS", "Tailwind CSS", "Bootstrap"],
            "tools": ["Webpack", "Vite", "Git", "Figma"]
        },
        "experience": [
            {
                "title": "Frontend Developer",
                "company": "StartupXYZ",
                "duration": "2021-Present",
                "achievements": [
                    "Developed responsive web applications using React and TypeScript",
                    "Implemented modern CSS frameworks and design systems",
                    "Collaborated with UX/UI designers for pixel-perfect implementations"
                ]
            },
            {
                "title": "Junior Developer",
                "company": "WebDev Co.",
                "duration": "2020-2021",
                "achievements": [
                    "Built landing pages and marketing websites",
                    "Learned modern JavaScript frameworks",
                    "Participated in code reviews and agile development"
                ]
            }
        ],
        "education": [
            {
                "degree": "Bachelor of Arts in Computer Science",
                "institution": "University of Texas at Austin",
                "year": "2020"
            }
        ]
    }'::jsonb,
    true,
    NOW() - INTERVAL '5 days'
);

-- Sample Job Descriptions (in addition to the ones in initial_plans.sql)
INSERT INTO job_descriptions (
    id,
    user_id,
    title,
    company,
    description,
    requirements,
    parsed_data,
    is_active,
    created_at
) VALUES 
(
    gen_random_uuid(),
    'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
    'Full Stack Engineer',
    'InnovateTech',
    'Looking for a Full Stack Engineer to build and maintain our web applications. You will work with modern technologies and contribute to both frontend and backend development.',
    'Requirements:
    - 3+ years of full-stack development experience
    - Proficiency in React and Node.js
    - Experience with TypeScript and PostgreSQL
    - Knowledge of AWS or similar cloud platforms
    - Strong problem-solving skills',
    '{
        "required_skills": ["React", "Node.js", "TypeScript", "PostgreSQL", "AWS"],
        "preferred_skills": ["Docker", "GraphQL", "Redis"],
        "experience_level": "Mid",
        "min_years_experience": 3,
        "remote_friendly": true,
        "salary_range": "$90,000 - $130,000"
    }'::jsonb,
    true,
    NOW() - INTERVAL '20 days'
),
(
    gen_random_uuid(),
    'b1ffcd99-9c0b-4ef8-bb6d-6bb9bd380a22',
    'Machine Learning Engineer',
    'AI Solutions Inc.',
    'Join our ML team to deploy and scale machine learning models in production. You will work on MLOps, model optimization, and building robust ML pipelines.',
    'Requirements:
    - 4+ years of ML engineering experience
    - Strong Python and ML frameworks knowledge
    - Experience with MLOps tools and practices
    - Cloud platform experience (AWS, GCP, Azure)
    - PhD or Masters in relevant field preferred',
    '{
        "required_skills": ["Python", "MLOps", "TensorFlow", "PyTorch", "AWS"],
        "preferred_skills": ["Kubernetes", "Airflow", "MLflow"],
        "experience_level": "Senior",
        "min_years_experience": 4,
        "education_level": "Masters",
        "remote_friendly": true,
        "salary_range": "$130,000 - $180,000"
    }'::jsonb,
    true,
    NOW() - INTERVAL '18 days'
);

-- Sample Matching Analyses
INSERT INTO matching_analyses (
    id,
    user_id,
    resume_id,
    job_id,
    overall_score,
    skills_match,
    experience_match,
    education_match,
    keyword_analysis,
    recommendations,
    created_at
) VALUES 
(
    gen_random_uuid(),
    'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
    (SELECT id FROM resumes WHERE user_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11' LIMIT 1),
    (SELECT id FROM job_descriptions WHERE user_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11' LIMIT 1),
    87.5,
    '{
        "score": 92,
        "matched_skills": ["React", "Node.js", "TypeScript", "PostgreSQL"],
        "missing_skills": ["AWS"],
        "skill_coverage": 0.8
    }'::jsonb,
    '{
        "score": 88,
        "years_required": 3,
        "years_candidate": 5,
        "experience_match": true,
        "seniority_match": "exceeds"
    }'::jsonb,
    '{
        "score": 85,
        "degree_match": true,
        "field_relevance": "high"
    }'::jsonb,
    '{
        "total_keywords": 45,
        "matched_keywords": 38,
        "keyword_density": 0.84,
        "missing_keywords": ["cloud", "microservices"]
    }'::jsonb,
    '{
        "strengths": [
            "Strong technical skill match",
            "Exceeds experience requirements",
            "Relevant educational background"
        ],
        "improvements": [
            "Add AWS cloud experience",
            "Highlight microservices architecture experience",
            "Include more specific project metrics"
        ],
        "overall_recommendation": "Excellent match - strong candidate"
    }'::jsonb,
    NOW() - INTERVAL '18 days'
),
(
    gen_random_uuid(),
    'b1ffcd99-9c0b-4ef8-bb6d-6bb9bd380a22',
    (SELECT id FROM resumes WHERE user_id = 'b1ffcd99-9c0b-4ef8-bb6d-6bb9bd380a22' LIMIT 1),
    (SELECT id FROM job_descriptions WHERE user_id = 'b1ffcd99-9c0b-4ef8-bb6d-6bb9bd380a22' LIMIT 1),
    93.2,
    '{
        "score": 95,
        "matched_skills": ["Python", "TensorFlow", "PyTorch", "AWS"],
        "missing_skills": ["MLOps"],
        "skill_coverage": 0.95
    }'::jsonb,
    '{
        "score": 92,
        "years_required": 4,
        "years_candidate": 6,
        "experience_match": true,
        "seniority_match": "exceeds"
    }'::jsonb,
    '{
        "score": 95,
        "degree_match": true,
        "field_relevance": "very_high",
        "advanced_degree": true
    }'::jsonb,
    '{
        "total_keywords": 52,
        "matched_keywords": 48,
        "keyword_density": 0.92,
        "missing_keywords": ["MLflow", "Airflow"]
    }'::jsonb,
    '{
        "strengths": [
            "Perfect skill alignment",
            "Strong educational background",
            "Extensive relevant experience"
        ],
        "improvements": [
            "Add MLOps tools experience",
            "Mention specific deployment platforms",
            "Include model performance metrics"
        ],
        "overall_recommendation": "Outstanding match - highly recommended"
    }'::jsonb,
    NOW() - INTERVAL '10 days'
);

-- Sample Usage Events
INSERT INTO usage_events (
    user_id,
    event_type,
    resource_type,
    resource_id,
    metadata,
    created_at
) VALUES 
-- John Doe usage events
('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'resume_uploaded', 'resume', (SELECT id FROM resumes WHERE user_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11' LIMIT 1), '{"file_size": 1048576}'::jsonb, NOW() - INTERVAL '25 days'),
('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'analysis_created', 'analysis', (SELECT id FROM matching_analyses WHERE user_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11' LIMIT 1), '{"analysis_type": "comprehensive"}'::jsonb, NOW() - INTERVAL '18 days'),
('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'api_call', 'endpoint', NULL, '{"endpoint": "/api/resumes", "method": "GET"}'::jsonb, NOW() - INTERVAL '15 days'),
('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'api_call', 'endpoint', NULL, '{"endpoint": "/api/analysis", "method": "POST"}'::jsonb, NOW() - INTERVAL '10 days'),

-- Jane Smith usage events
('b1ffcd99-9c0b-4ef8-bb6d-6bb9bd380a22', 'resume_uploaded', 'resume', (SELECT id FROM resumes WHERE user_id = 'b1ffcd99-9c0b-4ef8-bb6d-6bb9bd380a22' LIMIT 1), '{"file_size": 987654}'::jsonb, NOW() - INTERVAL '12 days'),
('b1ffcd99-9c0b-4ef8-bb6d-6bb9bd380a22', 'analysis_created', 'analysis', (SELECT id FROM matching_analyses WHERE user_id = 'b1ffcd99-9c0b-4ef8-bb6d-6bb9bd380a22' LIMIT 1), '{"analysis_type": "comprehensive"}'::jsonb, NOW() - INTERVAL '10 days'),
('b1ffcd99-9c0b-4ef8-bb6d-6bb9bd380a22', 'api_call', 'endpoint', NULL, '{"endpoint": "/api/analytics", "method": "GET"}'::jsonb, NOW() - INTERVAL '8 days'),

-- Mike Johnson usage events
('c2ddee99-9c0b-4ef8-bb6d-6bb9bd380a33', 'resume_uploaded', 'resume', (SELECT id FROM resumes WHERE user_id = 'c2ddee99-9c0b-4ef8-bb6d-6bb9bd380a33' LIMIT 1), '{"file_size": 756432}'::jsonb, NOW() - INTERVAL '5 days'),
('c2ddee99-9c0b-4ef8-bb6d-6bb9bd380a33', 'api_call', 'endpoint', NULL, '{"endpoint": "/api/resumes", "method": "GET"}'::jsonb, NOW() - INTERVAL '3 days');

-- Sample Usage Summaries
INSERT INTO usage_summaries (
    user_id,
    month,
    analyses_count,
    resumes_uploaded,
    jobs_analyzed,
    api_calls,
    storage_used,
    created_at
) VALUES 
(
    'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
    DATE_TRUNC('month', CURRENT_DATE)::DATE,
    5,
    2,
    3,
    15,
    2097152,
    NOW()
),
(
    'b1ffcd99-9c0b-4ef8-bb6d-6bb9bd380a22',
    DATE_TRUNC('month', CURRENT_DATE)::DATE,
    8,
    3,
    5,
    25,
    3145728,
    NOW()
),
(
    'c2ddee99-9c0b-4ef8-bb6d-6bb9bd380a33',
    DATE_TRUNC('month', CURRENT_DATE)::DATE,
    2,
    1,
    1,
    5,
    756432,
    NOW()
),
(
    'd3eeff99-9c0b-4ef8-bb6d-6bb9bd380a44',
    DATE_TRUNC('month', CURRENT_DATE)::DATE,
    25,
    15,
    20,
    150,
    52428800,
    NOW()
);

-- Sample Audit Logs
INSERT INTO audit_logs (
    user_id,
    action,
    table_name,
    record_id,
    old_values,
    new_values,
    ip_address,
    user_agent,
    created_at
) VALUES 
(
    'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
    'profile_updated',
    'profiles',
    'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
    '{"job_title": null}'::jsonb,
    '{"job_title": "Software Engineer"}'::jsonb,
    '192.168.1.100',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)',
    NOW() - INTERVAL '20 days'
),
(
    'b1ffcd99-9c0b-4ef8-bb6d-6bb9bd380a22',
    'subscription_created',
    'subscriptions',
    (SELECT id FROM subscriptions WHERE user_id = 'b1ffcd99-9c0b-4ef8-bb6d-6bb9bd380a22' LIMIT 1),
    NULL,
    '{"plan": "team", "status": "active"}'::jsonb,
    '10.0.0.1',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
    NOW() - INTERVAL '10 days'
),
(
    'c2ddee99-9c0b-4ef8-bb6d-6bb9bd380a33',
    'resume_uploaded',
    'resumes',
    (SELECT id FROM resumes WHERE user_id = 'c2ddee99-9c0b-4ef8-bb6d-6bb9bd380a33' LIMIT 1),
    NULL,
    '{"filename": "mike_johnson_resume.docx", "size": 756432}'::jsonb,
    '172.16.0.1',
    'Mozilla/5.0 (X11; Linux x86_64)',
    NOW() - INTERVAL '5 days'
);

-- Create realistic usage patterns for the last 6 months
WITH months AS (
    SELECT generate_series(
        DATE_TRUNC('month', CURRENT_DATE - INTERVAL '6 months'),
        DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 month'),
        INTERVAL '1 month'
    )::DATE AS month
),
users AS (
    SELECT id FROM profiles WHERE id != '00000000-0000-0000-0000-000000000000'
)
INSERT INTO usage_summaries (user_id, month, analyses_count, resumes_uploaded, jobs_analyzed, api_calls, storage_used)
SELECT 
    u.id,
    m.month,
    FLOOR(RANDOM() * 20 + 1)::INTEGER,
    FLOOR(RANDOM() * 5 + 1)::INTEGER,
    FLOOR(RANDOM() * 8 + 1)::INTEGER,
    FLOOR(RANDOM() * 50 + 10)::INTEGER,
    FLOOR(RANDOM() * 10485760 + 1048576)::BIGINT
FROM months m
CROSS JOIN users u
ON CONFLICT (user_id, month) DO NOTHING;

-- Add some realistic resume analyses results
INSERT INTO resume_analyses (
    resume_id,
    analysis_type,
    results,
    confidence_score,
    created_at
) VALUES 
(
    (SELECT id FROM resumes WHERE user_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11' LIMIT 1),
    'skill_extraction',
    '{
        "technical_skills": {
            "languages": ["Python", "JavaScript", "TypeScript", "Java"],
            "frameworks": ["React", "Node.js", "Django", "Express"],
            "databases": ["PostgreSQL", "MongoDB", "Redis"],
            "tools": ["Docker", "Kubernetes", "AWS", "Git"]
        },
        "soft_skills": ["Leadership", "Team Management", "Problem Solving", "Communication"],
        "certifications": [],
        "years_of_experience": 5,
        "seniority_level": "Senior"
    }'::jsonb,
    0.94,
    NOW() - INTERVAL '25 days'
),
(
    (SELECT id FROM resumes WHERE user_id = 'b1ffcd99-9c0b-4ef8-bb6d-6bb9bd380a22' LIMIT 1),
    'ats_optimization',
    '{
        "ats_score": 88,
        "keyword_density": 0.76,
        "formatting_score": 92,
        "sections_detected": ["contact", "experience", "education", "skills"],
        "improvements": [
            "Add more industry-specific keywords",
            "Include quantifiable achievements",
            "Optimize section headers"
        ]
    }'::jsonb,
    0.89,
    NOW() - INTERVAL '12 days'
);

-- Log sample data creation
INSERT INTO audit_logs (
    user_id,
    action,
    table_name,
    new_values,
    created_at
) VALUES (
    '00000000-0000-0000-0000-000000000000',
    'sample_data_created',
    'system',
    '{
        "users_created": 4,
        "subscriptions_created": 4,
        "resumes_created": 3,
        "analyses_created": 2,
        "usage_events_created": 9,
        "created_date": "'|| NOW() ||'"
    }'::jsonb,
    NOW()
);