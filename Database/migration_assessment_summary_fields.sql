-- Add computed summary fields to assessments table
-- Run in Supabase SQL Editor for dashboards and follow-up comparisons.

ALTER TABLE assessments
ADD COLUMN IF NOT EXISTS ptsd_total_score INTEGER DEFAULT NULL,
ADD COLUMN IF NOT EXISTS ptsd_probable BOOLEAN DEFAULT NULL,
ADD COLUMN IF NOT EXISTS safety_flags JSONB DEFAULT NULL,
ADD COLUMN IF NOT EXISTS intervention_summary JSONB DEFAULT NULL;

COMMENT ON COLUMN assessments.ptsd_total_score IS 'Sum of STRESS symptom scores (q22-q46), computed on completion';
COMMENT ON COLUMN assessments.ptsd_probable IS 'True if all PTSD criteria B+C+D+E met';
COMMENT ON COLUMN assessments.safety_flags IS 'Array of triggered safety flag messages';
COMMENT ON COLUMN assessments.intervention_summary IS 'Insatskarta recommendations (domain → interventions)';

-- Index for filtering
CREATE INDEX IF NOT EXISTS idx_assessments_safety_flags ON assessments USING GIN (safety_flags);
CREATE INDEX IF NOT EXISTS idx_assessments_ptsd_probable ON assessments (ptsd_probable) WHERE ptsd_probable = true;
