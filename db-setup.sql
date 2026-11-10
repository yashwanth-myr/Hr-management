
-- Create tables for HR Management Application
-- Author: TericSoft HR Admin
-- Created: 2023-12-15

-- create extensions
create extension if not exists "uuid-ossp";

-- create departments table
create table if not exists departments (
  id text primary key,
  name text not null,
  "teamLeadId" text,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- create employees table
create table if not exists employees (
  id text primary key,
  name text not null,
  email text not null,
  "phoneNumber" text not null,
  designation text not null,
  "departmentId" text references departments(id) on delete set null,
  "jobRole" text not null default 'employee',
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- add foreign key from departments to employees
do $$
begin
  if not exists (
    select 1 
    from information_schema.table_constraints 
    where constraint_name = 'fk_team_lead' 
    and table_name = 'departments'
  ) then
    alter table departments add constraint fk_team_lead
      foreign key ("teamLeadId") references employees(id) on delete set null;
  end if;
end $$;

-- create projects table
create table if not exists projects (
  id text primary key,
  name text not null,
  "startMonth" text not null,
  "startYear" text not null,
  status text not null default 'active',
  "projectManagerId" text references employees(id) on delete set null,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- create project_members junction table
create table if not exists project_members (
  id uuid primary key default uuid_generate_v4(),
  project_id text not null references projects(id) on delete cascade,
  employee_id text not null references employees(id) on delete cascade,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now(),
  unique(project_id, employee_id)
);

-- create project_allocations table
create table if not exists project_allocations (
  id text primary key,
  "projectId" text not null references projects(id) on delete cascade,
  month text not null,
  year text not null,
  "projectManagerId" text references employees(id) on delete set null,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now(),
  unique("projectId", month, year)
);

-- create allocation_members junction table
create table if not exists allocation_members (
  id uuid primary key default uuid_generate_v4(),
  allocation_id text not null references project_allocations(id) on delete cascade,
  employee_id text not null references employees(id) on delete cascade,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now(),
  unique(allocation_id, employee_id)
);

-- create form frequency enum
create type form_frequency as enum ('once', 'daily', 'weekly', 'biweekly', 'monthly', 'quarterly', 'yearly');

-- create form status enum
create type form_status as enum ('draft', 'published', 'archived');

-- create audience type enum
create type audience_type as enum ('employee', 'team_lead', 'project_manager', 'all');

-- create question type enum
create type question_type as enum (
  'short_text', 
  'long_text', 
  'multiple_choice', 
  'checkbox', 
  'dropdown', 
  'linear_scale', 
  'date', 
  'time'
);

-- create score_forms table
create table if not exists score_forms (
  id uuid primary key default uuid_generate_v4(),
  title text not null,
  description text,
  frequency form_frequency not null default 'once',
  audience audience_type not null default 'all',
  status form_status not null default 'draft',
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now(),
  published_at timestamp with time zone
);

-- create form_questions table
create table if not exists form_questions (
  id uuid primary key default uuid_generate_v4(),
  form_id uuid not null references score_forms(id) on delete cascade,
  question_text text not null,
  question_type question_type not null default 'short_text',
  is_required boolean not null default false,
  order_number integer not null default 0,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- create question_options table
create table if not exists question_options (
  id uuid primary key default uuid_generate_v4(),
  question_id uuid not null references form_questions(id) on delete cascade,
  option_text text not null,
  order_number integer not null default 0,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- create form_responses table
create table if not exists form_responses (
  id uuid primary key default uuid_generate_v4(),
  form_id uuid not null references score_forms(id) on delete cascade,
  respondent_id uuid references auth.users(id) on delete set null,
  started_at timestamp with time zone default now(),
  submitted_at timestamp with time zone,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- create question_answers table
create table if not exists question_answers (
  id uuid primary key default uuid_generate_v4(),
  response_id uuid not null references form_responses(id) on delete cascade,
  question_id uuid not null references form_questions(id) on delete cascade,
  answer_text text,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- create updated_at trigger function
create or replace function update_modified_column()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

-- create triggers for all tables with updated_at column
create trigger update_departments_modified
before update on departments
for each row execute function update_modified_column();

create trigger update_employees_modified
before update on employees
for each row execute function update_modified_column();

create trigger update_projects_modified
before update on projects
for each row execute function update_modified_column();

create trigger update_project_members_modified
before update on project_members
for each row execute function update_modified_column();

create trigger update_project_allocations_modified
before update on project_allocations
for each row execute function update_modified_column();

create trigger update_allocation_members_modified
before update on allocation_members
for each row execute function update_modified_column();

create trigger update_score_forms_updated_at
before update on score_forms
for each row execute function update_modified_column();

create trigger update_form_questions_updated_at
before update on form_questions
for each row execute function update_modified_column();

create trigger update_question_options_updated_at
before update on question_options
for each row execute function update_modified_column();

create trigger update_form_responses_updated_at
before update on form_responses
for each row execute function update_modified_column();

create trigger update_question_answers_updated_at
before update on question_answers
for each row execute function update_modified_column();

-- disable row level security for all tables
alter table departments disable row level security;
alter table employees disable row level security;
alter table projects disable row level security;
alter table project_members disable row level security;
alter table project_allocations disable row level security;
alter table allocation_members disable row level security;
alter table score_forms disable row level security;
alter table form_questions disable row level security;
alter table question_options disable row level security;
alter table form_responses disable row level security;
alter table question_answers disable row level security;
