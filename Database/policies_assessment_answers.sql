-- Run in Supabase SQL Editor if assessment_answers INSERT/UPDATE fail with RLS.
-- Allows staff to insert and update answers for assessments in their unit.

CREATE POLICY "Staff can insert answers in their unit"
    ON assessment_answers FOR INSERT
    WITH CHECK (
        assessment_id IN (
            SELECT id FROM assessments
            WHERE unit_id = (SELECT unit_id FROM staff_profiles WHERE id = auth.uid())
        )
    );

CREATE POLICY "Staff can update answers in their unit"
    ON assessment_answers FOR UPDATE
    USING (
        assessment_id IN (
            SELECT id FROM assessments
            WHERE unit_id = (SELECT unit_id FROM staff_profiles WHERE id = auth.uid())
        )
    );
