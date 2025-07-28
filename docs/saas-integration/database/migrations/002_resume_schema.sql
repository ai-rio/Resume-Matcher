-- Resume-Matcher SaaS Integration Schema
-- Integrating Resume-Matcher functionality into QuoteKit's SaaS platform

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Resume storage and analysis tables
CREATE TABLE IF NOT EXISTS public.resumes (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    resume_id text UNIQUE NOT NULL, -- Compatible with Resume-Matcher format
    title text,
    filename text,
    content text NOT NULL, -- Markdown/HTML content from PDF/DOCX
    content_type text NOT NULL DEFAULT 'markdown',
    file_url text, -- Supabase Storage URL for original file
    file_size integer,
    uploaded_at timestamp with time zone DEFAULT now() NOT NULL,
    processed_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

-- Processed resume data (AI-extracted structured data)
CREATE TABLE IF NOT EXISTS public.processed_resumes (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    resume_id text REFERENCES public.resumes(resume_id) ON DELETE CASCADE NOT NULL,
    user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    personal_data jsonb,
    experiences jsonb,
    projects jsonb,
    skills jsonb,
    research_work jsonb,
    achievements jsonb,
    education jsonb,
    extracted_keywords jsonb,
    processing_status text DEFAULT 'pending' CHECK (processing_status IN ('pending', 'processing', 'completed', 'failed')),
    processing_error text,
    processed_at timestamp with time zone DEFAULT now() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

-- Job descriptions for matching
CREATE TABLE IF NOT EXISTS public.jobs (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    job_id text UNIQUE NOT NULL, -- Compatible with Resume-Matcher format
    title text NOT NULL,
    company text,
    location text,
    content text NOT NULL, -- Raw job description
    url text, -- Source URL if scraped
    employment_type text,
    date_posted text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

-- Processed job data (AI-extracted structured data)
CREATE TABLE IF NOT EXISTS public.processed_jobs (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    job_id text REFERENCES public.jobs(job_id) ON DELETE CASCADE NOT NULL,
    user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    job_title text NOT NULL,
    company_profile text,
    location text,
    date_posted text,
    employment_type text,
    job_summary text NOT NULL,
    key_responsibilities jsonb,
    qualifications jsonb,
    compensation_and_benefits jsonb,
    application_info jsonb,
    extracted_keywords jsonb,
    processing_status text DEFAULT 'pending' CHECK (processing_status IN ('pending', 'processing', 'completed', 'failed')),
    processing_error text,
    processed_at timestamp with time zone DEFAULT now() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

-- Resume-Job analysis results (many-to-many relationship)
CREATE TABLE IF NOT EXISTS public.resume_job_analyses (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    resume_id text REFERENCES public.resumes(resume_id) ON DELETE CASCADE NOT NULL,
    job_id text REFERENCES public.jobs(job_id) ON DELETE CASCADE NOT NULL,
    
    -- Matching scores and analysis
    overall_score decimal(5,2), -- 0.00 to 100.00
    keyword_match_score decimal(5,2),
    skills_match_score decimal(5,2),
    experience_match_score decimal(5,2),
    education_match_score decimal(5,2),
    
    -- AI-generated improvements and suggestions
    improvements jsonb, -- Structured improvement suggestions
    missing_keywords jsonb,
    suggested_skills jsonb,
    ats_compatibility_score decimal(5,2),
    readability_score decimal(5,2),
    
    -- Analysis metadata
    analysis_version text DEFAULT '1.0',
    ai_provider text, -- 'openai', 'ollama', etc.
    model_used text,
    tokens_used integer,
    processing_time_ms integer,
    
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    
    -- Ensure one analysis per resume-job pair per user
    UNIQUE(user_id, resume_id, job_id)
);

-- Usage tracking for subscription limits
CREATE TABLE IF NOT EXISTS public.user_usage (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    
    -- Monthly usage counters (reset monthly)
    month_year text NOT NULL, -- Format: 'YYYY-MM'
    resumes_uploaded integer DEFAULT 0,
    jobs_analyzed integer DEFAULT 0,
    analyses_performed integer DEFAULT 0,
    ai_tokens_used integer DEFAULT 0,
    
    -- Daily limits tracking
    daily_analyses_performed integer DEFAULT 0,
    last_analysis_date date DEFAULT current_date,
    
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    
    -- One record per user per month
    UNIQUE(user_id, month_year)
);

-- Resume templates (for premium users)
CREATE TABLE IF NOT EXISTS public.resume_templates (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    name text NOT NULL,
    description text,
    category text, -- 'tech', 'marketing', 'finance', etc.
    template_data jsonb NOT NULL, -- Structure and styling info
    preview_url text, -- Preview image URL
    is_premium boolean DEFAULT false,
    is_active boolean DEFAULT true,
    created_by uuid REFERENCES auth.users(id),
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

-- User saved resume templates and customizations
CREATE TABLE IF NOT EXISTS public.user_resume_templates (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    template_id uuid REFERENCES public.resume_templates(id) ON DELETE CASCADE NOT NULL,
    customizations jsonb, -- User's modifications to the template
    name text, -- User's custom name for this template
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    
    UNIQUE(user_id, template_id)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_resumes_user_id ON public.resumes(user_id);
CREATE INDEX IF NOT EXISTS idx_resumes_created_at ON public.resumes(created_at);
CREATE INDEX IF NOT EXISTS idx_processed_resumes_user_id ON public.processed_resumes(user_id);
CREATE INDEX IF NOT EXISTS idx_processed_resumes_status ON public.processed_resumes(processing_status);
CREATE INDEX IF NOT EXISTS idx_jobs_user_id ON public.jobs(user_id);
CREATE INDEX IF NOT EXISTS idx_processed_jobs_user_id ON public.processed_jobs(user_id);
CREATE INDEX IF NOT EXISTS idx_resume_job_analyses_user_id ON public.resume_job_analyses(user_id);
CREATE INDEX IF NOT EXISTS idx_resume_job_analyses_created_at ON public.resume_job_analyses(created_at);
CREATE INDEX IF NOT EXISTS idx_user_usage_user_month ON public.user_usage(user_id, month_year);

-- Row Level Security (RLS) Policies

-- Enable RLS on all tables
ALTER TABLE public.resumes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.processed_resumes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.processed_jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.resume_job_analyses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_usage ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.resume_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_resume_templates ENABLE ROW LEVEL SECURITY;

-- RLS Policies for resumes
CREATE POLICY "Users can view own resumes" ON public.resumes FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own resumes" ON public.resumes FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own resumes" ON public.resumes FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own resumes" ON public.resumes FOR DELETE USING (auth.uid() = user_id);

-- RLS Policies for processed_resumes
CREATE POLICY "Users can view own processed resumes" ON public.processed_resumes FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own processed resumes" ON public.processed_resumes FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own processed resumes" ON public.processed_resumes FOR UPDATE USING (auth.uid() = user_id);

-- RLS Policies for jobs
CREATE POLICY "Users can view own jobs" ON public.jobs FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own jobs" ON public.jobs FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own jobs" ON public.jobs FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own jobs" ON public.jobs FOR DELETE USING (auth.uid() = user_id);

-- RLS Policies for processed_jobs
CREATE POLICY "Users can view own processed jobs" ON public.processed_jobs FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own processed jobs" ON public.processed_jobs FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own processed jobs" ON public.processed_jobs FOR UPDATE USING (auth.uid() = user_id);

-- RLS Policies for resume_job_analyses
CREATE POLICY "Users can view own analyses" ON public.resume_job_analyses FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own analyses" ON public.resume_job_analyses FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own analyses" ON public.resume_job_analyses FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own analyses" ON public.resume_job_analyses FOR DELETE USING (auth.uid() = user_id);

-- RLS Policies for user_usage
CREATE POLICY "Users can view own usage" ON public.user_usage FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own usage" ON public.user_usage FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own usage" ON public.user_usage FOR UPDATE USING (auth.uid() = user_id);

-- RLS Policies for resume_templates (public read, restricted write)
CREATE POLICY "Anyone can view active templates" ON public.resume_templates FOR SELECT USING (is_active = true);
CREATE POLICY "Admins can manage templates" ON public.resume_templates FOR ALL USING (
    EXISTS (
        SELECT 1 FROM public.admin_roles ar 
        WHERE ar.user_id = auth.uid() 
        AND ar.role = 'admin'
    )
);

-- RLS Policies for user_resume_templates
CREATE POLICY "Users can view own template customizations" ON public.user_resume_templates FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can manage own template customizations" ON public.user_resume_templates FOR ALL USING (auth.uid() = user_id);

-- Service role policies for backend operations
CREATE POLICY "Service role can manage all resume data" ON public.resumes FOR ALL USING (auth.role() = 'service_role');
CREATE POLICY "Service role can manage all processed resume data" ON public.processed_resumes FOR ALL USING (auth.role() = 'service_role');
CREATE POLICY "Service role can manage all job data" ON public.jobs FOR ALL USING (auth.role() = 'service_role');
CREATE POLICY "Service role can manage all processed job data" ON public.processed_jobs FOR ALL USING (auth.role() = 'service_role');
CREATE POLICY "Service role can manage all analysis data" ON public.resume_job_analyses FOR ALL USING (auth.role() = 'service_role');
CREATE POLICY "Service role can manage all usage data" ON public.user_usage FOR ALL USING (auth.role() = 'service_role');

-- Functions for automatic updates

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Add updated_at triggers
CREATE TRIGGER update_resumes_updated_at BEFORE UPDATE ON public.resumes FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_processed_resumes_updated_at BEFORE UPDATE ON public.processed_resumes FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_jobs_updated_at BEFORE UPDATE ON public.jobs FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_processed_jobs_updated_at BEFORE UPDATE ON public.processed_jobs FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_resume_job_analyses_updated_at BEFORE UPDATE ON public.resume_job_analyses FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_user_usage_updated_at BEFORE UPDATE ON public.user_usage FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_resume_templates_updated_at BEFORE UPDATE ON public.resume_templates FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_user_resume_templates_updated_at BEFORE UPDATE ON public.user_resume_templates FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to update daily analysis counter
CREATE OR REPLACE FUNCTION update_daily_analysis_counter()
RETURNS TRIGGER AS $$
BEGIN
    -- Reset daily counter if it's a new day
    IF NEW.last_analysis_date < CURRENT_DATE THEN
        NEW.daily_analyses_performed = 1;
        NEW.last_analysis_date = CURRENT_DATE;
    ELSE
        NEW.daily_analyses_performed = NEW.daily_analyses_performed + 1;
    END IF;
    
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger for daily analysis tracking
CREATE TRIGGER update_daily_analysis_counter_trigger 
    BEFORE UPDATE OF analyses_performed ON public.user_usage 
    FOR EACH ROW 
    WHEN (NEW.analyses_performed > OLD.analyses_performed)
    EXECUTE FUNCTION update_daily_analysis_counter();

-- Comments for documentation
COMMENT ON TABLE public.resumes IS 'User-uploaded resumes with file storage and basic metadata';
COMMENT ON TABLE public.processed_resumes IS 'AI-processed structured data extracted from resumes';
COMMENT ON TABLE public.jobs IS 'Job descriptions for resume matching';
COMMENT ON TABLE public.processed_jobs IS 'AI-processed structured data extracted from job descriptions';
COMMENT ON TABLE public.resume_job_analyses IS 'Resume-job matching analysis results with scores and suggestions';
COMMENT ON TABLE public.user_usage IS 'Usage tracking for subscription limits and billing';
COMMENT ON TABLE public.resume_templates IS 'Available resume templates for users';
COMMENT ON TABLE public.user_resume_templates IS 'User customizations of resume templates';