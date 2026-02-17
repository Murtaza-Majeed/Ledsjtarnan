# Supabase Setup Guide for Ledstjärnan

## Step 1: Create Supabase Project

1. Go to [supabase.com](https://supabase.com)
2. Click "Start your project"
3. Create account or sign in
4. Click "New Project"
5. Fill in:
   - **Name**: Ledstjarnan
   - **Database Password**: [Generate strong password - SAVE THIS!]
   - **Region**: Europe (Stockholm or closest to Sweden)
   - **Pricing Plan**: Free tier OK for MVP

## Step 2: Run Database Schema

1. In your Supabase dashboard, go to **SQL Editor**
2. Click "New query"
3. Copy the entire contents of `SupabaseSchema.md`
4. Paste into the editor
5. Click "Run" (bottom right)
6. Wait for success message

**Expected Result**: All 17 tables created with RLS policies enabled

## Step 3: Configure Authentication

1. Go to **Authentication** → **Providers**
2. Enable **Email** provider:
   - ✅ Enable Email provider
   - ✅ Confirm email: OFF (for MVP testing)
   - ✅ Secure email change: ON
3. Go to **Authentication** → **Email Templates**
4. Customize templates (optional for MVP):
   - Confirm signup
   - Magic Link
   - Change Email Address
   - Reset Password

**Swedish Email Template Example (Reset Password)**:
```
Subject: Återställ ditt lösenord - Ledstjärnan

Hej,

Du har begärt att återställa ditt lösenord för Ledstjärnan.

Klicka på länken nedan för att skapa ett nytt lösenord:
{{ .ConfirmationURL }}

Länken går ut om 1 timme.

Om du inte begärt detta kan du ignorera detta mejl.

Mvh,
Ledstjärnan
```

## Step 4: Seed Test Data

### Create Test Unit
```sql
INSERT INTO units (name, code, city, join_code, is_active)
VALUES ('Villa Hilleröd HVB', 'VHH-001', 'Malmö', '123456', true);
```

### Create Test Staff Account
1. Go to **Authentication** → **Users**
2. Click "Add user"
3. Fill in:
   - Email: `test@ledstjarnan.se`
   - Password: `Test1234!`
   - Auto Confirm: ✅ Yes
4. Click "Create user"
5. **Copy the User ID** (you need it for the next step)

### Link Staff to Unit + Add Test Clients (Option A)

Run the whole block in **SQL Editor**. (It uses test user ID `90a04c70-c4f2-4682-947c-ef97d4a2d0d6`; if you created a different user, replace that UUID in both places.)

```sql
-- 1) Link staff to unit (or update unit_id if already linked)
INSERT INTO staff_profiles (
    id, email, full_name, role, unit_id, onboarding_completed_at
)
SELECT 
    '90a04c70-c4f2-4682-947c-ef97d4a2d0d6',
    'test@ledstjarnan.se',
    'Test Behandlingsassistent',
    'Behandlingsassistent',
    id,
    NOW()
FROM units WHERE join_code = '123456'
ON CONFLICT (id) DO UPDATE SET unit_id = EXCLUDED.unit_id;

-- 2) Add test clients for this unit (Anna, Erik, Maria)
INSERT INTO clients (unit_id, name_or_code, created_by_staff_id)
SELECT u.id, c.name_or_code, '90a04c70-c4f2-4682-947c-ef97d4a2d0d6'
FROM units u
CROSS JOIN (VALUES 
    ('Anna Andersson'),
    ('Erik Johansson'),
    ('Maria Svensson')
) AS c(name_or_code)
WHERE u.join_code = '123456';
```

**Check:** Run this to confirm unit, staff and clients line up:
```sql
SELECT id, name, join_code FROM units WHERE join_code = '123456';
SELECT id, email, unit_id FROM staff_profiles WHERE email = 'test@ledstjarnan.se';
SELECT id, unit_id, name_or_code FROM clients 
WHERE unit_id = (SELECT unit_id FROM staff_profiles WHERE email = 'test@ledstjarnan.se');
```

### Seed Livbojen Chapters
```sql
INSERT INTO livbojen_chapters (category, title, description, order_index, is_active) VALUES
('kropp_halsa', 'Kriskunskap', 'Lär dig om 112 och 1177', 1, true),
('kropp_halsa', 'Sömnrutiner', 'Bygg hälsosamma sömnvanor', 2, true),
('kropp_halsa', 'Matvanor', 'Grundläggande näringslära', 3, true),
('utbildning_arbete', 'CV-skrivning', 'Skapa ditt CV', 1, true),
('utbildning_arbete', 'Jobbsökning', 'Hitta och ansök om jobb', 2, true),
('sjalvstandighet', 'Matlagning', 'Grundläggande matlagning', 1, true),
('sjalvstandighet', 'Tvätt och städning', 'Håll ditt hem rent', 2, true),
('sjalvstandighet', 'Privatekonomi', 'Hantera din ekonomi', 3, true),
('social_kompetens', 'Kommunikation', 'Effektiv kommunikation', 1, true),
('social_kompetens', 'Konflikthantering', 'Lösa konflikter konstruktivt', 2, true),
('relationer', 'Vänskap', 'Bygga och behålla vänner', 1, true),
('relationer', 'Familj', 'Navigera familjerelationer', 2, true),
('identitet', 'Självkänsla', 'Bygg din självkänsla', 1, true),
('identitet', 'Värderingar', 'Identifiera dina värderingar', 2, true);
```

## Step 5: Get API Credentials

1. Go to **Project Settings** → **API**
2. Copy these values:
   - **Project URL**: `https://xxxxx.supabase.co`
   - **anon public key**: `eyJhbGciOi...` (long key)

**IMPORTANT**: Keep these secret! Never commit to git.

## Step 6: Add Supabase Swift SDK

### Option A: Swift Package Manager (Recommended)
1. Open Xcode
2. Go to **File** → **Add Package Dependencies**
3. Enter: `https://github.com/supabase/supabase-swift`
4. Select version: `2.0.0` or later
5. Click "Add Package"
6. Select both:
   - ✅ Supabase
   - ✅ Realtime (for live updates)
7. Click "Add Package"

### Option B: CocoaPods
```ruby
# In your Podfile
pod 'Supabase', '~> 2.0'
```

Then run: `pod install`

## Step 7: Configure Supabase in Your App

### Create Config File
Create `Ledstjarnan/Services/SupabaseConfig.swift`:

```swift
import Foundation

enum SupabaseConfig {
    static let url = "YOUR_PROJECT_URL"
    static let anonKey = "YOUR_ANON_KEY"
}
```

**OR** use environment variables (better for security):

Create `Ledstjarnan/Config.xcconfig`:
```
SUPABASE_URL = https://xxxxx.supabase.co
SUPABASE_ANON_KEY = eyJhbGci...
```

Then access in Swift:
```swift
let url = Bundle.main.infoDictionary?["SUPABASE_URL"] as? String ?? ""
```

## Step 8: Test Connection

Run this test query in Supabase SQL Editor:
```sql
-- Should return your test unit
SELECT * FROM units WHERE join_code = '123456';

-- Should return your test staff
SELECT * FROM staff_profiles WHERE email = 'test@ledstjarnan.se';
```

## Step 9: Test Authentication

In your app, try logging in with:
- **Email**: `test@ledstjarnan.se`
- **Password**: `Test1234!`

**Expected Result**: Successful login → redirect to Unit Selection → Main tabs

## Step 10: Verify real clients show after login

1. In the app: log in → choose unit (join code `123456` if you used the seed unit) → open the **Clients** tab.
2. You should see the **database** client names (e.g. Anna Andersson, Erik Johansson, Maria Svensson), not placeholder or mock names.
3. If the list is empty or shows wrong names, use **Troubleshooting → "Real clients don't show after login"** below.

## Step 11: Enable Realtime (Optional but Recommended)

1. Go to **Database** → **Replication**
2. Enable realtime for these tables:
   - ✅ clients
   - ✅ planner_items
   - ✅ client_timeline_events
   - ✅ client_links

This allows live updates when data changes.

---

## Security Checklist

- [ ] Database password is strong and saved securely
- [ ] API keys are not committed to git
- [ ] RLS policies are enabled on all tables
- [ ] Email confirmation is configured
- [ ] Password reset works
- [ ] Test user can only see their own unit's data

---

## Troubleshooting

### "relation does not exist"
- Run the schema SQL again
- Check for SQL errors in the output

### "JWT expired" or auth errors
- Check that SUPABASE_URL and SUPABASE_ANON_KEY are correct
- Make sure you're using the **anon public** key, not the service role key

### Real clients don't show after login

If the Clients tab is empty or shows old/placeholder names instead of DB names (e.g. Anna Andersson, Erik Johansson, Maria Svensson):

1. **Confirm clients exist for your unit**  
   In SQL Editor run:
   ```sql
   SELECT id, unit_id, name_or_code FROM clients
   WHERE unit_id = (SELECT unit_id FROM staff_profiles WHERE email = 'test@ledstjarnan.se');
   ```
   You should see 3 rows. If not, run the **Link Staff to Unit + Add Test Clients** script again (use your test user’s ID: `90a04c70-c4f2-4682-947c-ef97d4a2d0d6` or replace with yours).

2. **Confirm staff and clients share the same unit**  
   `staff_profiles.unit_id` must equal `clients.unit_id` for RLS to allow SELECT. Check in Table Editor or run:
   ```sql
   SELECT sp.unit_id AS staff_unit, c.unit_id AS client_unit
   FROM staff_profiles sp
   LEFT JOIN clients c ON c.unit_id = sp.unit_id
   WHERE sp.email = 'test@ledstjarnan.se' LIMIT 1;
   ```
   Both columns should show the same UUID.

3. **Confirm RLS policy on `clients`**  
   In SQL Editor run:
   ```sql
   SELECT pg_get_expr(polqual, polrelid) AS using_expr
   FROM pg_policy WHERE polrelid = 'public.clients'::regclass AND polcmd = 'r';
   ```
   You should see a condition like `(unit_id = (SELECT unit_id FROM staff_profiles WHERE id = auth.uid()))`. If not, (re)apply the policy from `RLS_CLIENTS_EXPLAINED.md`.

4. **App config**  
   Ensure `SupabaseConfig` (or env) uses the **same project** (URL and anon key) where you created the unit, staff, and clients.

5. **After fixing data or RLS**  
   In the app: sign out, sign in again, pick the unit (join code `123456`), then open Clients. Pull-to-refresh on the list if the app supports it.

### RLS policy denies access
- Verify staff_profiles.unit_id matches clients.unit_id
- Check that auth.uid() matches the staff user ID

### Can't create test user
- Check that email provider is enabled in Auth settings
- Make sure email doesn't already exist

---

## Next Steps After Setup

1. ✅ Create `SupabaseClient.swift` service
2. ✅ Create `AuthService.swift` 
3. ✅ Update `AppState.swift` with Supabase session
4. ✅ Rebuild login flow with real auth
5. ✅ Test unit selection with join code
6. ✅ Build out remaining services

---

## Resources

- [Supabase Docs](https://supabase.com/docs)
- [Supabase Swift SDK](https://github.com/supabase/supabase-swift)
- [Row Level Security Guide](https://supabase.com/docs/guides/auth/row-level-security)
- [Auth Helpers](https://supabase.com/docs/guides/auth/auth-helpers)

---

**Need Help?**
- Supabase Discord: [discord.supabase.com](https://discord.supabase.com)
- GitHub Issues: [github.com/supabase/supabase-swift/issues](https://github.com/supabase/supabase-swift/issues)
