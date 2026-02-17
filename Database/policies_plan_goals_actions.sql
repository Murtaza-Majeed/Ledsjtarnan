-- Run in Supabase SQL Editor if plan_goals or plan_actions INSERT/UPDATE fail with RLS.

CREATE POLICY "Staff can insert goals in their unit"
    ON plan_goals FOR INSERT
    WITH CHECK (
        plan_id IN (
            SELECT id FROM plans
            WHERE unit_id = (SELECT unit_id FROM staff_profiles WHERE id = auth.uid())
        )
    );

CREATE POLICY "Staff can update goals in their unit"
    ON plan_goals FOR UPDATE
    USING (
        plan_id IN (
            SELECT id FROM plans
            WHERE unit_id = (SELECT unit_id FROM staff_profiles WHERE id = auth.uid())
        )
    );

CREATE POLICY "Staff can insert actions in their unit"
    ON plan_actions FOR INSERT
    WITH CHECK (
        plan_id IN (
            SELECT id FROM plans
            WHERE unit_id = (SELECT unit_id FROM staff_profiles WHERE id = auth.uid())
        )
    );

CREATE POLICY "Staff can update actions in their unit"
    ON plan_actions FOR UPDATE
    USING (
        plan_id IN (
            SELECT id FROM plans
            WHERE unit_id = (SELECT unit_id FROM staff_profiles WHERE id = auth.uid())
        )
    );
