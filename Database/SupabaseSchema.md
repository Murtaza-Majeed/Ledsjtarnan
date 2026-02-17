# Ledstjärnan Supabase Database Schema

## Overview
This schema supports the Ledstjärnan (staff) and Livbojen (client) apps with a single-unit access model, staff-only notes/flags, and selective data sharing.

---

## Core Tables

### 1. units
**Purpose**: HVB homes and support housing units

```sql
CREATE TABLE units (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    code TEXT NOT NULL, -- e.g., "Villa Hilleröd HVB"
    city TEXT,
    join_code TEXT UNIQUE NOT NULL, -- 6-digit code for staff to join
    join_code_expires_at TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Index for fast join code lookup
CREATE INDEX idx_units_join_code ON units(join_code) WHERE is_active = true;

ALTER TABLE units ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Staff can view their unit"
    ON units FOR SELECT
    USING (
        id = (SELECT unit_id FROM staff_profiles WHERE id = auth.uid())
    );

CREATE POLICY "Staff can update their unit"
    ON units FOR UPDATE
    USING (
        id = (SELECT unit_id FROM staff_profiles WHERE id = auth.uid())
    )
    WITH CHECK (
        id = (SELECT unit_id FROM staff_profiles WHERE id = auth.uid())
    );

-- Use an RPC so staff can enter a join code before they belong to a unit
CREATE OR REPLACE FUNCTION public.lookup_unit_by_join_code(p_join_code text)
RETURNS units
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    result units%ROWTYPE;
BEGIN
    SELECT * INTO result
    FROM units
    WHERE join_code = p_join_code
      AND is_active = true
    LIMIT 1;
    RETURN result;
END;
$$;

REVOKE ALL ON FUNCTION public.lookup_unit_by_join_code(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.lookup_unit_by_join_code(text) TO authenticated;
```

---

### 2. staff_profiles
**Purpose**: Staff (Behandlingsassistent) profiles - single unit access

```sql
CREATE TABLE staff_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    full_name TEXT NOT NULL,
    role TEXT DEFAULT 'Behandlingsassistent',
    unit_id UUID REFERENCES units(id) ON DELETE SET NULL,
    unit_joined_at TIMESTAMPTZ,
    notifications_enabled BOOLEAN DEFAULT true,
    notification_prefs JSONB DEFAULT '{
        "followups_due": true,
        "sessions": true,
        "schedule_changes": true,
        "quiet_start": "22:00",
        "quiet_end": "07:00"
    }'::jsonb,
    privacy_ack_at TIMESTAMPTZ,
    onboarding_completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- RLS: Staff can only read their own profile
ALTER TABLE staff_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Staff can view own profile"
    ON staff_profiles FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Staff can update own profile"
    ON staff_profiles FOR UPDATE
    USING (auth.uid() = id);
```

---

### 3. clients
**Purpose**: Youth/young adults (16-21) in care

```sql
CREATE TABLE clients (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    unit_id UUID NOT NULL REFERENCES units(id) ON DELETE CASCADE,
    name_or_code TEXT NOT NULL, -- Can be name or anonymous code
    linked_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL, -- Links to Livbojen user
    created_by_staff_id UUID REFERENCES staff_profiles(id),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- RLS: Staff can only see clients in their unit
ALTER TABLE clients ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Staff can view clients in their unit"
    ON clients FOR SELECT
    USING (
        unit_id = (SELECT unit_id FROM staff_profiles WHERE id = auth.uid())
    );

CREATE POLICY "Staff can create clients in their unit"
    ON clients FOR INSERT
    WITH CHECK (
        unit_id = (SELECT unit_id FROM staff_profiles WHERE id = auth.uid())
    );

CREATE POLICY "Staff can update clients in their unit"
    ON clients FOR UPDATE
    USING (
        unit_id = (SELECT unit_id FROM staff_profiles WHERE id = auth.uid())
    );
```

---

### 4. client_links
**Purpose**: Link codes for connecting Ledstjärnan clients to Livbojen users

```sql
CREATE TABLE client_links (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    unit_id UUID NOT NULL REFERENCES units(id) ON DELETE CASCADE,
    code TEXT NOT NULL, -- 6-digit code, unique only while active
    created_by_staff_id UUID REFERENCES staff_profiles(id),
    expires_at TIMESTAMPTZ NOT NULL,
    is_used BOOLEAN DEFAULT false,
    used_at TIMESTAMPTZ,
    linked_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'used', 'expired', 'unlinked')),
    unlinked_at TIMESTAMPTZ,
    unlinked_by_staff_id UUID REFERENCES staff_profiles(id),
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Only one active code per client
CREATE UNIQUE INDEX idx_client_active_link 
    ON client_links(client_id) 
    WHERE status = 'active';

CREATE UNIQUE INDEX idx_client_link_active_code
    ON client_links(code)
    WHERE status = 'active';

-- RLS
ALTER TABLE client_links ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Staff can view links in their unit"
    ON client_links FOR SELECT
    USING (
        unit_id = (SELECT unit_id FROM staff_profiles WHERE id = auth.uid())
    );

CREATE POLICY "Staff can create links in their unit"
    ON client_links FOR INSERT
    WITH CHECK (
        unit_id = (SELECT unit_id FROM staff_profiles WHERE id = auth.uid())
    );

CREATE POLICY "Staff can update links in their unit"
    ON client_links FOR UPDATE
    USING (
        unit_id = (SELECT unit_id FROM staff_profiles WHERE id = auth.uid())
    )
    WITH CHECK (
        unit_id = (SELECT unit_id FROM staff_profiles WHERE id = auth.uid())
    );
```

---

### 5. staff_client_access
**Purpose**: Track which staff are responsible for which clients

```sql
CREATE TABLE staff_client_access (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    staff_id UUID NOT NULL REFERENCES staff_profiles(id) ON DELETE CASCADE,
    client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    is_primary BOOLEAN DEFAULT false,
    assigned_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(staff_id, client_id)
);

-- RLS
ALTER TABLE staff_client_access ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Staff can view access in their unit"
    ON staff_client_access FOR SELECT
    USING (
        client_id IN (
            SELECT id FROM clients 
            WHERE unit_id = (SELECT unit_id FROM staff_profiles WHERE id = auth.uid())
        )
    );
```

---

## Assessment Tables

### 6. assessments
**Purpose**: Baseline and follow-up assessments

```sql
CREATE TABLE assessments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    unit_id UUID NOT NULL REFERENCES units(id) ON DELETE CASCADE,
    assessment_type TEXT NOT NULL CHECK (assessment_type IN ('baseline', 'followup')),
    created_by_staff_id UUID REFERENCES staff_profiles(id),
    status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'in_progress', 'completed')),
    completed_at TIMESTAMPTZ,
    assessment_date DATE,
    domain_scores JSONB, -- Stores scores per domain
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- RLS
ALTER TABLE assessments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Staff can view assessments in their unit"
    ON assessments FOR SELECT
    USING (
        unit_id = (SELECT unit_id FROM staff_profiles WHERE id = auth.uid())
    );

CREATE POLICY "Staff can create assessments in their unit"
    ON assessments FOR INSERT
    WITH CHECK (
        unit_id = (SELECT unit_id FROM staff_profiles WHERE id = auth.uid())
    );

CREATE POLICY "Staff can update assessments in their unit"
    ON assessments FOR UPDATE
    USING (
        unit_id = (SELECT unit_id FROM staff_profiles WHERE id = auth.uid())
    );
```

---

### 7. assessment_answers
**Purpose**: Individual answers per domain/question

```sql
CREATE TABLE assessment_answers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    assessment_id UUID NOT NULL REFERENCES assessments(id) ON DELETE CASCADE,
    domain_key TEXT NOT NULL, -- e.g., 'housing', 'health'
    question_key TEXT NOT NULL,
    value JSONB, -- Flexible: number, text, array
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(assessment_id, domain_key, question_key)
);

-- RLS inherits from assessments via assessment_id
ALTER TABLE assessment_answers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Staff can view answers in their unit"
    ON assessment_answers FOR SELECT
    USING (
        assessment_id IN (
            SELECT id FROM assessments 
            WHERE unit_id = (SELECT unit_id FROM staff_profiles WHERE id = auth.uid())
        )
    );

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
    )
    WITH CHECK (
        assessment_id IN (
            SELECT id FROM assessments
            WHERE unit_id = (SELECT unit_id FROM staff_profiles WHERE id = auth.uid())
        )
    );
```

---

## Plans Tables

### 8. plans
**Purpose**: Care plans with focus areas and follow-up dates

```sql
CREATE TABLE plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    unit_id UUID NOT NULL REFERENCES units(id) ON DELETE CASCADE,
    created_by_staff_id UUID REFERENCES staff_profiles(id),
    title TEXT,
    focus_domains TEXT[] DEFAULT '{}', -- Array of domain keys
    status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'active', 'archived')),
    next_follow_up_at TIMESTAMPTZ,
    activated_at TIMESTAMPTZ,
    archived_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- RLS
ALTER TABLE plans ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Staff can view plans in their unit"
    ON plans FOR SELECT
    USING (
        unit_id = (SELECT unit_id FROM staff_profiles WHERE id = auth.uid())
    );

CREATE POLICY "Staff can create plans in their unit"
    ON plans FOR INSERT
    WITH CHECK (
        unit_id = (SELECT unit_id FROM staff_profiles WHERE id = auth.uid())
    );

CREATE POLICY "Staff can update plans in their unit"
    ON plans FOR UPDATE
    USING (
        unit_id = (SELECT unit_id FROM staff_profiles WHERE id = auth.uid())
    );
```

---

### 9. plan_goals
**Purpose**: Goals within each plan (by focus area)

```sql
CREATE TABLE plan_goals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    plan_id UUID NOT NULL REFERENCES plans(id) ON DELETE CASCADE,
    area_key TEXT NOT NULL,
    goal_text TEXT NOT NULL,
    created_by_staff_id UUID REFERENCES staff_profiles(id),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- RLS inherits from plans
ALTER TABLE plan_goals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Staff can view goals in their unit"
    ON plan_goals FOR SELECT
    USING (
        plan_id IN (
            SELECT id FROM plans 
            WHERE unit_id = (SELECT unit_id FROM staff_profiles WHERE id = auth.uid())
        )
    );

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
    )
    WITH CHECK (
        plan_id IN (
            SELECT id FROM plans
            WHERE unit_id = (SELECT unit_id FROM staff_profiles WHERE id = auth.uid())
        )
    );
```

---

### 10. plan_actions
**Purpose**: Actions within plans (staff/client/shared)

```sql
CREATE TABLE plan_actions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    plan_id UUID NOT NULL REFERENCES plans(id) ON DELETE CASCADE,
    area_key TEXT NOT NULL,
    title TEXT NOT NULL,
    who TEXT NOT NULL CHECK (who IN ('staff', 'client', 'shared')),
    frequency TEXT, -- e.g., 'daily', 'weekly', 'custom'
    locked_session BOOLEAN DEFAULT false,
    default_duration INTEGER, -- minutes
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- RLS inherits from plans
ALTER TABLE plan_actions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Staff can view actions in their unit"
    ON plan_actions FOR SELECT
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
    )
    WITH CHECK (
        plan_id IN (
            SELECT id FROM plans
            WHERE unit_id = (SELECT unit_id FROM staff_profiles WHERE id = auth.uid())
        )
    );
```

---

## Livbojen Chapters (Shared with Livbojen)

### 11. livbojen_chapters
**Purpose**: Master list of Livbojen learning modules

```sql
CREATE TABLE livbojen_chapters (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category TEXT NOT NULL, -- Maps to domain areas
    title TEXT NOT NULL,
    description TEXT,
    order_index INTEGER,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now()
);
```

---

### 12. client_chapter_assignments
**Purpose**: Which chapters are assigned/unlocked for each client

```sql
CREATE TABLE client_chapter_assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    chapter_id UUID NOT NULL REFERENCES livbojen_chapters(id) ON DELETE CASCADE,
    assigned_by_staff_id UUID REFERENCES staff_profiles(id),
    assigned_at TIMESTAMPTZ DEFAULT now(),
    status TEXT DEFAULT 'assigned' CHECK (status IN ('assigned', 'unlocked', 'in_progress', 'completed')),
    UNIQUE(client_id, chapter_id)
);

-- RLS
ALTER TABLE client_chapter_assignments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Staff can view assignments in their unit"
    ON client_chapter_assignments FOR SELECT
    USING (
        client_id IN (
            SELECT id FROM clients 
            WHERE unit_id = (SELECT unit_id FROM staff_profiles WHERE id = auth.uid())
        )
    );

CREATE POLICY "Staff can create assignments in their unit"
    ON client_chapter_assignments FOR INSERT
    WITH CHECK (
        client_id IN (
            SELECT id FROM clients 
            WHERE unit_id = (SELECT unit_id FROM staff_profiles WHERE id = auth.uid())
        )
    );
```

---

## Schedule Tables

### 13. planner_items
**Purpose**: Unified schedule (staff sessions + client tasks)

```sql
CREATE TABLE planner_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id UUID REFERENCES clients(id) ON DELETE CASCADE,
    unit_id UUID NOT NULL REFERENCES units(id) ON DELETE CASCADE,
    created_by_role TEXT NOT NULL CHECK (created_by_role IN ('staff', 'client')),
    created_by_user_id UUID REFERENCES auth.users(id),
    type TEXT NOT NULL CHECK (type IN ('session', 'task', 'activity')),
    title TEXT NOT NULL,
    start_at TIMESTAMPTZ NOT NULL,
    end_at TIMESTAMPTZ,
    locked BOOLEAN DEFAULT false, -- true = staff-controlled, client can view only
    visibility TEXT DEFAULT 'shared' CHECK (visibility IN ('shared', 'staff_only', 'client_only')),
    status TEXT DEFAULT 'planned' CHECK (status IN ('planned', 'done', 'cancelled')),
    notes TEXT,
    conflict_override BOOLEAN DEFAULT false,
    cancelled_at TIMESTAMPTZ,
    cancelled_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- RLS
ALTER TABLE planner_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Staff can view items in their unit"
    ON planner_items FOR SELECT
    USING (
        unit_id = (SELECT unit_id FROM staff_profiles WHERE id = auth.uid())
    );

CREATE POLICY "Staff can create items in their unit"
    ON planner_items FOR INSERT
    WITH CHECK (
        unit_id = (SELECT unit_id FROM staff_profiles WHERE id = auth.uid())
    );

CREATE POLICY "Staff can update items in their unit"
    ON planner_items FOR UPDATE
    USING (
        unit_id = (SELECT unit_id FROM staff_profiles WHERE id = auth.uid())
    );
```

---

## Staff-Only Tables (Never synced to Livbojen)

### 14. client_notes
**Purpose**: Staff-only internal notes about clients

```sql
CREATE TABLE client_notes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    staff_id UUID NOT NULL REFERENCES staff_profiles(id) ON DELETE CASCADE,
    note_text TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- RLS: Strict unit-based access
ALTER TABLE client_notes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Staff can view notes in their unit"
    ON client_notes FOR SELECT
    USING (
        client_id IN (
            SELECT id FROM clients 
            WHERE unit_id = (SELECT unit_id FROM staff_profiles WHERE id = auth.uid())
        )
    );

CREATE POLICY "Staff can create notes in their unit"
    ON client_notes FOR INSERT
    WITH CHECK (
        client_id IN (
            SELECT id FROM clients 
            WHERE unit_id = (SELECT unit_id FROM staff_profiles WHERE id = auth.uid())
        )
        AND staff_id = auth.uid()
    );

CREATE POLICY "Staff can update their own notes"
    ON client_notes FOR UPDATE
    USING (staff_id = auth.uid());

CREATE POLICY "Staff can delete their own notes"
    ON client_notes FOR DELETE
    USING (staff_id = auth.uid());
```

---

### 15. client_flags
**Purpose**: Quick indicators (trauma, low readiness, risk, etc.) - staff only

```sql
CREATE TABLE client_flags (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    flag_key TEXT NOT NULL, -- e.g., 'trauma', 'low_readiness', 'risk'
    is_on BOOLEAN DEFAULT true,
    updated_by_staff_id UUID REFERENCES staff_profiles(id),
    updated_at TIMESTAMPTZ DEFAULT now(),
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(client_id, flag_key)
);

-- RLS
ALTER TABLE client_flags ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Staff can view flags in their unit"
    ON client_flags FOR SELECT
    USING (
        client_id IN (
            SELECT id FROM clients 
            WHERE unit_id = (SELECT unit_id FROM staff_profiles WHERE id = auth.uid())
        )
    );

CREATE POLICY "Staff can insert flags in their unit"
    ON client_flags FOR INSERT
    WITH CHECK (
        client_id IN (
            SELECT id FROM clients 
            WHERE unit_id = (SELECT unit_id FROM staff_profiles WHERE id = auth.uid())
        )
    );

CREATE POLICY "Staff can update flags in their unit"
    ON client_flags FOR UPDATE
    USING (
        client_id IN (
            SELECT id FROM clients 
            WHERE unit_id = (SELECT unit_id FROM staff_profiles WHERE id = auth.uid())
        )
    )
    WITH CHECK (
        client_id IN (
            SELECT id FROM clients 
            WHERE unit_id = (SELECT unit_id FROM staff_profiles WHERE id = auth.uid())
        )
    );

CREATE POLICY "Staff can delete flags in their unit"
    ON client_flags FOR DELETE
    USING (
        client_id IN (
            SELECT id FROM clients 
            WHERE unit_id = (SELECT unit_id FROM staff_profiles WHERE id = auth.uid())
        )
    );
```

---

## Timeline & Audit Tables

### 16. client_timeline_events
**Purpose**: Audit log of key client events

```sql
CREATE TABLE client_timeline_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    unit_id UUID NOT NULL REFERENCES units(id) ON DELETE CASCADE,
    event_type TEXT NOT NULL, -- e.g., 'baseline_completed', 'plan_activated', 'link_created'
    title TEXT NOT NULL,
    description TEXT,
    metadata JSONB,
    created_by_staff_id UUID REFERENCES staff_profiles(id),
    created_at TIMESTAMPTZ DEFAULT now()
);

-- RLS
ALTER TABLE client_timeline_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Staff can view timeline in their unit"
    ON client_timeline_events FOR SELECT
    USING (
        unit_id = (SELECT unit_id FROM staff_profiles WHERE id = auth.uid())
    );
```

---

## Support Tables

### 17. support_tickets
**Purpose**: Issue reports from staff

```sql
CREATE TABLE support_tickets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_by_staff_id UUID REFERENCES staff_profiles(id),
    unit_id UUID REFERENCES units(id),
    issue_type TEXT NOT NULL CHECK (issue_type IN ('bug', 'data', 'sync', 'other')),
    location_path TEXT,
    description TEXT NOT NULL,
    attachment_url TEXT,
    app_version TEXT,
    device_model TEXT,
    status TEXT DEFAULT 'new' CHECK (status IN ('new', 'in_progress', 'resolved')),
    created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE support_tickets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Staff can view their tickets"
    ON support_tickets FOR SELECT
    USING (
        created_by_staff_id = auth.uid()
        OR unit_id = (
            SELECT unit_id FROM staff_profiles WHERE id = auth.uid()
        )
    );

CREATE POLICY "Staff can create tickets"
    ON support_tickets FOR INSERT
    WITH CHECK (
        created_by_staff_id = auth.uid()
    );

CREATE POLICY "Staff can update their tickets"
    ON support_tickets FOR UPDATE
    USING (created_by_staff_id = auth.uid())
    WITH CHECK (created_by_staff_id = auth.uid());
```

---

## Functions & Triggers

### Auto-update timestamps

```sql
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to relevant tables
CREATE TRIGGER update_staff_profiles_updated_at BEFORE UPDATE ON staff_profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_clients_updated_at BEFORE UPDATE ON clients
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_assessments_updated_at BEFORE UPDATE ON assessments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_plans_updated_at BEFORE UPDATE ON plans
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_planner_items_updated_at BEFORE UPDATE ON planner_items
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

---

## Initial Data Seeds

### Insert default unit for testing

```sql
INSERT INTO units (name, code, city, join_code)
VALUES ('Villa Hilleröd HVB', 'VHH-001', 'Malmö', '123456');
```

### Insert Livbojen chapters (example)

```sql
INSERT INTO livbojen_chapters (category, title, description, order_index) VALUES
('kropp_halsa', 'Kriskunskap', 'Learn about 112 and 1177', 1),
('kropp_halsa', 'Sömnrutiner', 'Build healthy sleep habits', 2),
('utbildning_arbete', 'CV-skrivning', 'Create your CV', 1),
('sjalvstandighet', 'Matlagning', 'Basic cooking skills', 1);
```

---

## Summary

This schema supports:
- ✅ Single-unit staff access (enforced via RLS)
- ✅ Client linking via 6-digit codes
- ✅ Staff-only notes & flags (never synced to Livbojen)
- ✅ Shared schedule with locked sessions
- ✅ Baseline & follow-up assessments
- ✅ Care plans with goals & actions
- ✅ Livbojen chapter assignments
- ✅ Timeline/audit logging
- ✅ Support ticket system

**Next Steps**:
1. Run this schema in your Supabase project
2. Configure Supabase Auth for email/password login
3. Set up storage buckets if needed for attachments
4. Create Supabase Edge Functions for complex operations (optional)
