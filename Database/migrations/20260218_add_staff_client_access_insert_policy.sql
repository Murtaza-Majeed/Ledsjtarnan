-- Supabase Postgres doesn't support IF NOT EXISTS on CREATE POLICY,
-- so run this only once or wrap in DO block when applying manually.
CREATE POLICY "Staff can assign access in their unit"
    ON staff_client_access FOR INSERT
    WITH CHECK (
        client_id IN (
            SELECT id FROM clients
            WHERE unit_id = (SELECT unit_id FROM staff_profiles WHERE id = auth.uid())
        )
        AND staff_id IN (
            SELECT id FROM staff_profiles
            WHERE unit_id = (SELECT unit_id FROM staff_profiles WHERE id = auth.uid())
        )
    );
