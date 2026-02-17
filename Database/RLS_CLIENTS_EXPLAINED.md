# RLS on `clients` – What it does and how to fix it

## What RLS is doing

**Row Level Security (RLS)** means: each row is only visible or changeable if the policy condition is true.

For **SELECT** on `clients`:

- The policy checks: *“Is this row’s `unit_id` the same as the current user’s unit?”*
- Current user = **`auth.uid()`** (the Supabase Auth user id of the logged-in person).
- That user’s unit = **`unit_id`** in **`staff_profiles`** where **`staff_profiles.id = auth.uid()`**.

So:

- Staff can only see clients where **`clients.unit_id`** = **their** **`staff_profiles.unit_id`**.
- If a staff has no `unit_id` in `staff_profiles`, the subquery returns `NULL` and no rows match → they see no clients.
- If the JWT/session isn’t sent with the request, `auth.uid()` is `NULL` → again no rows.

Your policies are:

| Policy name                         | Command | Meaning |
|-------------------------------------|--------|---------|
| Staff can view clients in their unit | SELECT | Show only clients whose `unit_id` = staff’s `unit_id` |
| Staff can create clients in their unit | INSERT | Allow insert only when `unit_id` = staff’s `unit_id` |
| Staff can update clients in their unit | UPDATE | Allow update only on clients in staff’s unit |

So the **first point** you need for names to show is: the **SELECT** policy must be exactly this logic.

---

## Exact SQL for the SELECT policy

If the policy was created differently or is missing, run this in the **Supabase SQL Editor** (Dashboard → SQL Editor).

**1. Enable RLS on `clients` (if not already):**

```sql
ALTER TABLE clients ENABLE ROW LEVEL SECURITY;
```

**2. Drop the existing SELECT policy (if it exists) so we can recreate it cleanly:**

```sql
DROP POLICY IF EXISTS "Staff can view clients in their unit" ON clients;
```

**3. Create the SELECT policy:**

```sql
CREATE POLICY "Staff can view clients in their unit"
    ON clients FOR SELECT
    USING (
        unit_id = (SELECT unit_id FROM staff_profiles WHERE id = auth.uid())
    );
```

Meaning in words:

- **`auth.uid()`** = current logged-in user’s id (same as `staff_profiles.id`).
- **`(SELECT unit_id FROM staff_profiles WHERE id = auth.uid())`** = that staff’s unit.
- **`unit_id = (...)`** = “this client row belongs to that unit”.

So: staff only see rows from `clients` where `clients.unit_id` matches their `staff_profiles.unit_id`.

---

## If clients still don’t show

Then either:

1. **No matching staff row**  
   Check:

   ```sql
   SELECT id, unit_id FROM staff_profiles WHERE id = auth.uid();
   ```  
   Run in SQL Editor while logged in as that user (or with “Run as user” if your project has it). You should get one row with a non-null `unit_id`.

2. **Session not sent from the app**  
   Supabase client must send the JWT so `auth.uid()` is set. In your app you’re using `SupabaseManager.shared.client` and signing in with `AuthService`; that should attach the session. Ensure you’re not using the anon key without a signed-in user for these requests.

3. **Clients in another unit**  
   Check:

   ```sql
   SELECT id, unit_id, name_or_code FROM clients;
   ```  
   (Temporarily without RLS or as a superuser.) Confirm that the `unit_id` values match the `unit_id` from the `staff_profiles` query above.

---

## Summary

- **RLS** = “only rows that pass the policy condition”.
- **SELECT on `clients`** = “only rows where `clients.unit_id` = current staff’s `staff_profiles.unit_id`”.
- Recreate the SELECT policy with the exact SQL above, ensure the staff has `unit_id` set and clients have the same `unit_id`, and that the app sends the auth session so `auth.uid()` is set. Then the real client names from the database will show.
