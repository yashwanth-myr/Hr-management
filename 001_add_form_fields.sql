-- Migration to add new fields for form submission tracking

-- Add new columns to form_submissions table
ALTER TABLE form_submissions ADD COLUMN IF NOT EXISTS filled_by_id TEXT;
ALTER TABLE form_submissions ADD COLUMN IF NOT EXISTS filled_by_email TEXT;
ALTER TABLE form_submissions ADD COLUMN IF NOT EXISTS filled_by_name TEXT;
ALTER TABLE form_submissions ADD COLUMN IF NOT EXISTS filled_for_id TEXT;
ALTER TABLE form_submissions ADD COLUMN IF NOT EXISTS filled_for_email TEXT;
ALTER TABLE form_submissions ADD COLUMN IF NOT EXISTS filled_for_name TEXT;
ALTER TABLE form_submissions ADD COLUMN IF NOT EXISTS next_due_date DATE;
ALTER TABLE form_submissions ADD COLUMN IF NOT EXISTS is_due BOOLEAN DEFAULT FALSE;

-- Add new columns to score_forms table for better frequency management
ALTER TABLE score_forms ADD COLUMN IF NOT EXISTS start_date DATE;
ALTER TABLE score_forms ADD COLUMN IF NOT EXISTS end_date DATE;
ALTER TABLE score_forms ADD COLUMN IF NOT EXISTS is_recurring BOOLEAN DEFAULT FALSE;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_form_submissions_filled_by_id ON form_submissions(filled_by_id);
CREATE INDEX IF NOT EXISTS idx_form_submissions_filled_for_id ON form_submissions(filled_for_id);
CREATE INDEX IF NOT EXISTS idx_form_submissions_next_due_date ON form_submissions(next_due_date);
CREATE INDEX IF NOT EXISTS idx_score_forms_start_date ON score_forms(start_date);

-- Comments for clarity
COMMENT ON COLUMN form_submissions.filled_by_id IS 'Employee ID of who filled the form';
COMMENT ON COLUMN form_submissions.filled_by_email IS 'Email of who filled the form';
COMMENT ON COLUMN form_submissions.filled_by_name IS 'Name of who filled the form';
COMMENT ON COLUMN form_submissions.filled_for_id IS 'Employee ID of who the form is filled for';
COMMENT ON COLUMN form_submissions.filled_for_email IS 'Email of who the form is filled for';
COMMENT ON COLUMN form_submissions.filled_for_name IS 'Name of who the form is filled for';
COMMENT ON COLUMN form_submissions.next_due_date IS 'Next due date for recurring forms';
COMMENT ON COLUMN form_submissions.is_due IS 'Whether this form submission is currently due'; 