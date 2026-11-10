-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Helper function to update 'updated_at' columns
CREATE OR REPLACE FUNCTION update_modified_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- ENUM Types
CREATE TYPE user_role AS ENUM ('admin', 'employee', 'team_lead', 'project_manager');
CREATE TYPE form_frequency AS ENUM ('once', 'daily', 'weekly', 'biweekly', 'monthly', 'quarterly', 'yearly');
CREATE TYPE form_status AS ENUM ('draft', 'published', 'archived');
CREATE TYPE audience_type AS ENUM ('employee', 'team_lead', 'project_manager', 'all');
CREATE TYPE question_type AS ENUM ('short_text', 'long_text', 'multiple_choice', 'checkbox', 'dropdown', 'linear_scale', 'date', 'time');
CREATE TYPE reporting_period AS ENUM ('daily', 'weekly', 'monthly', 'quarterly', 'yearly');

-- Core Tables
CREATE TABLE IF NOT EXISTS departments (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    team_lead_id TEXT, -- Kept for backward compatibility as per lib/data.js
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TRIGGER update_departments_modtime
BEFORE UPDATE ON departments
FOR EACH ROW EXECUTE PROCEDURE update_modified_column();

CREATE TABLE IF NOT EXISTS employees (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    phone_number TEXT NOT NULL,
    designation TEXT NOT NULL,
    department_id TEXT REFERENCES departments(id) ON DELETE SET NULL,
    job_role TEXT NOT NULL DEFAULT 'employee', -- Consider using user_role enum if values align
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TRIGGER update_employees_modtime
BEFORE UPDATE ON employees
FOR EACH ROW EXECUTE PROCEDURE update_modified_column();

-- Add foreign key from departments.team_lead_id to employees.id (if not exists)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.table_constraints
    WHERE constraint_name = 'fk_departments_team_lead'
    AND table_name = 'departments'
  ) THEN
    ALTER TABLE departments ADD CONSTRAINT fk_departments_team_lead
      FOREIGN KEY (team_lead_id) REFERENCES employees(id) ON DELETE SET NULL;
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS department_team_leads (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    department_id TEXT NOT NULL REFERENCES departments(id) ON DELETE CASCADE,
    employee_id TEXT NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(department_id, employee_id)
);

CREATE INDEX IF NOT EXISTS idx_department_team_leads_department_id ON department_team_leads(department_id);
CREATE INDEX IF NOT EXISTS idx_department_team_leads_employee_id ON department_team_leads(employee_id);

CREATE TRIGGER update_department_team_leads_modtime
BEFORE UPDATE ON department_team_leads
FOR EACH ROW EXECUTE PROCEDURE update_modified_column();

-- Employee-Department Many-to-Many Relationship
CREATE TABLE IF NOT EXISTS employee_departments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id TEXT NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
    department_id TEXT NOT NULL REFERENCES departments(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(employee_id, department_id)
);

CREATE INDEX IF NOT EXISTS idx_employee_departments_employee_id ON employee_departments(employee_id);
CREATE INDEX IF NOT EXISTS idx_employee_departments_department_id ON employee_departments(department_id);

CREATE TRIGGER update_employee_departments_modtime
BEFORE UPDATE ON employee_departments
FOR EACH ROW EXECUTE PROCEDURE update_modified_column();

CREATE TABLE IF NOT EXISTS projects (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    start_month TEXT NOT NULL,
    start_year TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'active',
    project_manager_id TEXT REFERENCES employees(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TRIGGER update_projects_modtime
BEFORE UPDATE ON projects
FOR EACH ROW EXECUTE PROCEDURE update_modified_column();

CREATE TABLE IF NOT EXISTS project_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id TEXT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    employee_id TEXT NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(project_id, employee_id)
);

CREATE TRIGGER update_project_members_modtime
BEFORE UPDATE ON project_members
FOR EACH ROW EXECUTE PROCEDURE update_modified_column();

CREATE TABLE IF NOT EXISTS project_allocations (
    id TEXT PRIMARY KEY,
    project_id TEXT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    month TEXT NOT NULL,
    year TEXT NOT NULL,
    project_manager_id TEXT REFERENCES employees(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(project_id, month, year)
);

CREATE TRIGGER update_project_allocations_modtime
BEFORE UPDATE ON project_allocations
FOR EACH ROW EXECUTE PROCEDURE update_modified_column();

CREATE TABLE IF NOT EXISTS allocation_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    allocation_id TEXT NOT NULL REFERENCES project_allocations(id) ON DELETE CASCADE,
    employee_id TEXT NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(allocation_id, employee_id)
);

CREATE TRIGGER update_allocation_members_modtime
BEFORE UPDATE ON allocation_members
FOR EACH ROW EXECUTE PROCEDURE update_modified_column();

-- Score Forms & Related Tables
CREATE TABLE IF NOT EXISTS score_forms (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    description TEXT,
    frequency form_frequency NOT NULL DEFAULT 'once',
    audience audience_type NOT NULL DEFAULT 'all',
    status form_status NOT NULL DEFAULT 'draft',
    created_by TEXT, -- Changed from UUID to TEXT for compatibility
    published_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TRIGGER update_score_forms_modtime
BEFORE UPDATE ON score_forms
FOR EACH ROW EXECUTE PROCEDURE update_modified_column();

CREATE TABLE IF NOT EXISTS score_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    form_id UUID NOT NULL REFERENCES score_forms(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    weight INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TRIGGER update_score_categories_modtime
BEFORE UPDATE ON score_categories
FOR EACH ROW EXECUTE PROCEDURE update_modified_column();

CREATE TABLE IF NOT EXISTS form_questions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    form_id UUID NOT NULL REFERENCES score_forms(id) ON DELETE CASCADE,
    question_text TEXT NOT NULL,
    question_type question_type NOT NULL DEFAULT 'short_text',
    is_required BOOLEAN NOT NULL DEFAULT FALSE,
    order_number INTEGER NOT NULL DEFAULT 0,
    category_id UUID REFERENCES score_categories(id) ON DELETE SET NULL,
    max_score INTEGER DEFAULT 5,
    score_weight INTEGER DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TRIGGER update_form_questions_modtime
BEFORE UPDATE ON form_questions
FOR EACH ROW EXECUTE PROCEDURE update_modified_column();

CREATE TABLE IF NOT EXISTS question_options (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    question_id UUID NOT NULL REFERENCES form_questions(id) ON DELETE CASCADE,
    option_text TEXT NOT NULL,
    order_number INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TRIGGER update_question_options_modtime
BEFORE UPDATE ON question_options
FOR EACH ROW EXECUTE PROCEDURE update_modified_column();

-- Form Submissions / Reports
CREATE TABLE IF NOT EXISTS form_submissions ( -- Merged 'form_responses' and 'employee_score_reports' concepts
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(), -- Changed from submission_id for consistency
    form_id UUID NOT NULL REFERENCES score_forms(id) ON DELETE CASCADE,
    user_id TEXT, -- Changed from UUID to TEXT for compatibility
    user_email TEXT, -- Denormalized for convenience
    employee_id TEXT REFERENCES employees(id) ON DELETE SET NULL, -- Employee being assessed
    employee_name TEXT, -- Denormalized for convenience
    department_id TEXT REFERENCES departments(id) ON DELETE SET NULL, -- Denormalized
    department_name TEXT, -- Denormalized
    status TEXT NOT NULL DEFAULT 'pending', -- e.g., pending, completed, reviewed
    submitted_at TIMESTAMPTZ DEFAULT now(),
    reviewed_at TIMESTAMPTZ,
    reviewed_by TEXT, -- Changed from UUID to TEXT for compatibility
    total_score INTEGER,
    max_possible_score INTEGER,
    submission_month TEXT, -- e.g., '01', '12'
    submission_year TEXT,  -- e.g., '2023'
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TRIGGER update_form_submissions_modtime
BEFORE UPDATE ON form_submissions
FOR EACH ROW EXECUTE PROCEDURE update_modified_column();

CREATE TABLE IF NOT EXISTS submission_answers ( -- Replaces 'question_answers'
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    submission_id UUID NOT NULL REFERENCES form_submissions(id) ON DELETE CASCADE,
    question_id UUID NOT NULL REFERENCES form_questions(id) ON DELETE CASCADE,
    answer_text TEXT,
    score INTEGER, -- Score given by reviewer for this answer
    max_score INTEGER, -- Max possible score for this question (denormalized for this answer context)
    comments TEXT, -- Reviewer comments for this specific answer
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TRIGGER update_submission_answers_modtime
BEFORE UPDATE ON submission_answers
FOR EACH ROW EXECUTE PROCEDURE update_modified_column();

-- Disable RLS on all tables (since we're not using Supabase auth)
ALTER TABLE departments DISABLE ROW LEVEL SECURITY;
ALTER TABLE employees DISABLE ROW LEVEL SECURITY;
ALTER TABLE department_team_leads DISABLE ROW LEVEL SECURITY;
ALTER TABLE employee_departments DISABLE ROW LEVEL SECURITY;
ALTER TABLE projects DISABLE ROW LEVEL SECURITY;
ALTER TABLE project_members DISABLE ROW LEVEL SECURITY;
ALTER TABLE project_allocations DISABLE ROW LEVEL SECURITY;
ALTER TABLE allocation_members DISABLE ROW LEVEL SECURITY;
ALTER TABLE score_forms DISABLE ROW LEVEL SECURITY;
ALTER TABLE score_categories DISABLE ROW LEVEL SECURITY;
ALTER TABLE form_questions DISABLE ROW LEVEL SECURITY;
ALTER TABLE question_options DISABLE ROW LEVEL SECURITY;
ALTER TABLE form_submissions DISABLE ROW LEVEL SECURITY;
ALTER TABLE submission_answers DISABLE ROW LEVEL SECURITY;

-- Comments on tables for clarity
COMMENT ON TABLE departments IS 'Stores information about company departments.';
COMMENT ON TABLE employees IS 'Stores information about employees.';
COMMENT ON TABLE projects IS 'Stores information about projects.';
COMMENT ON TABLE project_allocations IS 'Stores monthly project allocations.';
COMMENT ON TABLE score_forms IS 'Stores performance evaluation forms.';
COMMENT ON TABLE form_submissions IS 'Stores form submission data and scores.'; 