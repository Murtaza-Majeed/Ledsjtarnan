# ⚡ Next Steps - Getting Ledstjärnan Running

## 🎯 Current Status

✅ **Completed**:
- Database schema designed and run (17 tables)
- UI components created (LSButton, LSTextField, LSCard, LSBadge, etc.)
- Data models created (Client, Assessment, Plan, Schedule, etc.)
- Supabase config, Auth, Staff, Client services
- Supabase Swift SDK added; login works
- Test unit + staff + clients seeded (real names show in app)
- Unit selection (join code) and main tabs (Clients, Assess, Plans, Schedule, Settings)
- Clients list loads from Supabase and shows real client names

🔄 **Next**: Client detail views, onboarding, assessments, plans, schedule, settings

---

## 📦 Step 1: Add Supabase SDK (DO THIS NOW)

Follow the instructions in `ADD_SUPABASE_SDK.md`:

1. Open Xcode
2. File → Add Package Dependencies
3. Paste: `https://github.com/supabase/supabase-swift`
4. Select version 2.0.0+
5. Add all products to Ledstjarnan target

**After adding the SDK, come back here!**

---

## 🗄️ Step 2: Set Up Your Supabase Database

### Run the Database Schema

1. Go to your Supabase dashboard: https://ftlycngltgrmjzlyzjwx.supabase.co
2. Click **SQL Editor** in the left sidebar
3. Click **New query**
4. Open `Ledstjarnan/Database/SupabaseSchema.md` in a text editor
5. Copy **everything** from that file
6. Paste into the Supabase SQL Editor
7. Click **Run** (bottom right)

**Expected Result**: You should see success messages for all table creations

---

## 👤 Step 3: Create a Test User

### In Supabase Dashboard:

1. Go to **Authentication** → **Users**
2. Click **Add user**
3. Fill in:
   - Email: `test@ledstjarnan.se`
   - Password: `Test1234!`
   - Auto Confirm User: ✅ **YES**
4. Click **Create user**
5. **Copy the User ID** (it's a UUID like `123e4567-e89b-12d3-a456-426614174000`)

---

## 🏢 Step 4: Create Test Unit and Link User

Go back to **SQL Editor** and run these queries **one by one**:

### 4.1: Create a test unit
```sql
INSERT INTO units (name, code, city, join_code, is_active)
VALUES ('Villa Hilleröd HVB', 'VHH-001', 'Malmö', '123456', true)
RETURNING id;
```

**Copy the returned `id`** - this is your `unit_id`

### 4.2: Link the test user to the unit

Replace `YOUR_USER_ID` and `YOUR_UNIT_ID` with the values from above:

```sql
INSERT INTO staff_profiles (
    id, 
    email, 
    full_name, 
    role, 
    unit_id,
    onboarding_completed_at
)
VALUES (
    'YOUR_USER_ID',
    'test@ledstjarnan.se',
    'Test Behandlingsassistent',
    'Behandlingsassistent',
    'YOUR_UNIT_ID',
    NOW()
);
```

### 4.3: Seed some Livbojen chapters

```sql
INSERT INTO livbojen_chapters (category, title, description, order_index, is_active) VALUES
('kropp_halsa', 'Kriskunskap', 'Lär dig om 112 och 1177', 1, true),
('kropp_halsa', 'Sömnrutiner', 'Bygg hälsosamma sömnvanor', 2, true),
('utbildning_arbete', 'CV-skrivning', 'Skapa ditt CV', 1, true),
('sjalvstandighet', 'Matlagning', 'Grundläggande matlagning', 1, true),
('social_kompetens', 'Kommunikation', 'Effektiv kommunikation', 1, true);
```

### 4.4: Create a test client (optional)

Replace `YOUR_UNIT_ID` and `YOUR_USER_ID`:

```sql
INSERT INTO clients (unit_id, name_or_code, created_by_staff_id)
VALUES 
    ('YOUR_UNIT_ID', 'Anna Andersson', 'YOUR_USER_ID'),
    ('YOUR_UNIT_ID', 'Erik Johansson', 'YOUR_USER_ID');
```

---

## ✅ Step 5: Verify Everything Works

### Test the connection in SQL Editor:

```sql
-- Should return your test unit
SELECT * FROM units WHERE join_code = '123456';

-- Should return your test staff
SELECT * FROM staff_profiles WHERE email = 'test@ledstjarnan.se';

-- Should return test clients (if you created them)
SELECT * FROM clients;
```

If all three queries return data, you're good to go! ✅

---

## 🚀 Step 6: Build and Run the App

Once the Supabase SDK is added:

1. **Build the project**: `Cmd + B`
   - Fix any import errors if needed
   
2. **Run on simulator**: `Cmd + R`

3. **Test login**:
   - Email: `test@ledstjarnan.se`
   - Password: `Test1234!`

**Expected Flow**:
- ✅ Login succeeds
- ✅ Shows main tabs
- ✅ Can see clients (if you created test data)

---

## 🐛 Troubleshooting

### Build errors with Supabase imports

If you see errors like `Cannot find 'Supabase' in scope`:

1. Clean build folder: `Product` → `Clean Build Folder`
2. Restart Xcode
3. Try building again

### "JWT expired" or auth errors

- Check that you copied the correct **anon public key** (not service_role)
- Verify `SupabaseConfig.swift` has the right URL and key

### RLS policy denies access

Run this to verify RLS is working:

```sql
-- Should return your staff profile
SELECT * FROM staff_profiles WHERE id = 'YOUR_USER_ID';

-- Should return clients in your unit
SELECT * FROM clients WHERE unit_id = 'YOUR_UNIT_ID';
```

### Login succeeds but no data shows

- Check that `staff_profiles.unit_id` is set correctly
- Verify test clients exist with the same `unit_id`

---

## 📝 What Happens After Login

The app will:

1. ✅ Authenticate with Supabase
2. ✅ Fetch staff profile
3. ✅ Load unit information
4. ✅ Show main tabs (Clients, Assess, Plans, Schedule, Settings)
5. ✅ Display clients filtered by your unit

---

## 🎨 Next Development Tasks

Login and clients list work. Next to build:

| # | Task | Status |
|---|------|--------|
| 1 | **Unit selection** (no unit / change unit) | ✅ In place |
| 2 | **Onboarding flow** (unit code entry, profile completion) | 🔲 To do |
| 3 | **Client detail views** (profile, timeline, real Supabase data) | 🔲 To do |
| 4 | **Assessment flows** (Baseline + Follow-up) | 🔲 To do |
| 5 | **Plan builder** (goals, actions, Livbojen chapters) | 🔲 To do |
| 6 | **Schedule** (planner items, locked sessions) | 🔲 To do |
| 7 | **Settings & support** (profile, notifications, help) | 🔲 To do |

## 🛠️ Implementation Tracks (Q1 2026)

### 2️⃣ Onboarding & Unit Setup
**Status:** 🟢 Ready to implement (FirstLaunchView + UnitJoinView stubs exist)
- Wire onboarding screens to `AppState` + `StaffService` so completing the flow flips `hasSeenOnboarding`, validates join codes, and persists staff metadata (see `Documents/Flows/1.5–1.12` for screen specs).
- Add unit join error states (+ retry) that map the `unit_join_codes` SQL function errors to the UI copy from the flow deck.
- Finish “Complete Staff Profile” view so phone, role, notification preference, and consent checkboxes sync to `staff_profiles`.
- Trigger the iOS notification permission prompt after the gradient hero (Flow `1.10`), storing the toggle state in `AppState`.
- QA: Log in with the seeded staff user, walk through onboarding, and confirm RLS scopes staff to its unit before showing `MainTabView`.

### 3️⃣ Client Detail Hub
**Status:** 🟡 Partially done (List + profile shell render mock data)
- Hook `ClientProfileView` to `ClientService.getClientDetail`, `getNotes`, `getFlags`, and `TimelineService` so cards reflect real Supabase data (Flows `3.3–3.9`).
- Implement add/edit note modals plus optimistic updates for `client_notes` mutations (Flows `3.7–3.8`).
- Build the Livbojen linking sheet: generate codes, show countdown, and support unlink confirmation states (Flows `3.4–3.11`).
- Fill timeline with grouped events (plan updates, assessments, schedule actions) using `client_timeline_events`.
- Acceptance: Add a new client via “+”, open the profile, create a note, toggle a flag, and watch the timeline update without reloading the screen.

### 4️⃣ Assessment Flows
**Status:** 🟠 UI scaffolds exist, but data + RLS wiring still pending
- Connect `AssessDashboardView` to Supabase so outstanding baselines/follow-ups filter by unit (Flow `4.1`).
- Flesh out `AssessmentFormView` to pull domain templates from `assessment_domains`, capture scores + answers, and stream them into `assessment_answers` (Flows `4.2–4.3`).
- Summaries should compute domain averages, recommended treatment level, and show risk callouts before persisting (`4.4–4.5`).
- Implement follow-up entry mode with prefilled previous scores for comparison (Flows `4.6–4.7`).
- Tests: run through a baseline for a seeded client and verify policy `policies_assessment_answers.sql` allows only staff in same unit.

### 5️⃣ Plan Builder & Livbojen Chapters
**Status:** 🟡 Wizard screens in place, need Supabase + validation
- Back `PlanListView` with `PlanService` (list filters, status badges). Fetch per-client view via `ClientPlansView`.
- Implement the stepper in `PlanBuilderView` so each step (goals, actions, responsibilities, check-ins) saves draft data client-side before final insert (Flows `5.2–5.5`).
- Chapter picker must read from `livbojen_chapters` and write to `client_chapter_assignments` with ordering + optional reminders (`5.6–5.7`).
- Autosave drafts to `plans` table with `status = draft`, then flip to `active` on confirmation to keep audit history intact.
- Verify the planner + Livbojen assignments populate the client timeline as shown in Flow `3.9`.

### 6️⃣ Schedule & Locked Sessions
**Status:** 🟠 Dashboard UI done, Supabase sync + conflicts outstanding
- Wire both `ScheduleDashboardView` and `ClientScheduleView` to `PlannerService` (`planner_items` table) and hydrate client names via `ClientService`.
- Finish `PlannerItemComposer` validation (duration picker, locked toggle) and persist to Supabase with conflict detection (Flows `6.3–6.8`).
- Build edit/delete flow inside `PlannerItemDetailSheet`, respecting locked rows (staff-only override per schema).
- Surface empty states per Flow `6.1–6.2` and add bottom-sheet success toasts from `Documents/Flows/A_grayscale_wireframe_toast_states.jpg`.
- QA: Add overlapping sessions for the same client and confirm warning modal + server constraint behave as expected.

### 7️⃣ Settings, Help & Support
**Status:** 🟥 Not wired yet (views render static copy)
- Connect every settings sub-view to real data: notification prefs → `staff_notification_settings`, privacy toggles → `staff_privacy_settings`, etc. (Flows `7.2–7.9`).
- Implement Help center (`HelpView`, `FAQView`, `StatusUpdatesView`) backed by Supabase tables (`help_articles`, `status_updates`, `support_tickets`).
- Complete support flows: contact form → `support_tickets`, report issue success screen, and attachments per Flow `7.12–7.14`.
- Add About/Legal stack with markdown rendering for privacy policy + terms stored in Supabase Storage.
- Ensure Settings tab hosts “change unit” + logout modals with the confirmation copy from Flow `7.26`.

---


