-- reset_dev_data.sql
-- ------------------------------------------------------------------
-- Danger: Run only in development/staging environments.
-- This script wipes staff, client, plan, assessment, schedule,
-- and related records so you can reseed Ledstjärnan from scratch.
-- ------------------------------------------------------------------

BEGIN;

-- 1) Remove app data that references staff/clients.
TRUNCATE TABLE
    client_timeline_events,
    client_notes,
    client_flags,
    client_chapter_assignments,
    planner_items,
    plan_actions,
    plan_goals,
    plans,
    assessment_answers,
    assessments,
    staff_client_access,
    client_links,
    clients
RESTART IDENTITY CASCADE;

-- 2) Remove staff + units (CASCADE handles dependent rows that may remain).
TRUNCATE TABLE
    staff_profiles,
    units
RESTART IDENTITY CASCADE;

-- 3) Clean up Supabase Auth users except for any admin/sandbox accounts you
-- want to preserve. Replace the email list below before running.
DELETE FROM auth.users
WHERE email NOT IN (
    'keep-this-admin@ledstjarnan.se'
);

COMMIT;

-- After running:
--  • Recreate at least one unit (see Database/NEXT_STEPS.md step 4.1).
--  • Add new staff accounts in Supabase Auth or invite them via the app.
--  • Seed baseline reference data (e.g., Livbojen chapters) if needed.
