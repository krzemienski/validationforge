# Step 03: Duplicate Email Constraint Check

**Journey:** db-validation
**Step:** 3
**Description:** Verify unique index enforcement — attempt to insert a duplicate email
**Timestamp:** 2026-04-05T09:15:01Z

## Test Query

```sql
-- Insert a known existing email to trigger the unique constraint
INSERT INTO users (email, name) VALUES ('alice@example.com', 'Alice Duplicate');
```

## Database Response

```
ERROR:  duplicate key value violates unique constraint "users_email_unique"
DETAIL:  Key (email)=(alice@example.com) already exists.
```

## What Was Observed

The database returned error `23505` (unique_violation) with constraint name
`users_email_unique` and detail `Key (email)=(alice@example.com) already exists.`

This confirms:
1. The unique index is actively enforced by Postgres (not just defined)
2. The constraint name matches the migration (`users_email_unique`)
3. The error message includes the conflicting key value (`alice@example.com`)
4. The duplicate row was NOT inserted (confirmed by SELECT count below)

## Verification Query

```sql
SELECT COUNT(*) FROM users WHERE email = 'alice@example.com';
```

Output: `count = 1` — original row preserved, duplicate rejected.

## Observation

The unique index on `users.email` is enforced at the database level. Attempting to
insert a duplicate email triggers error 23505 with the expected constraint name.
The constraint proof is the actual Postgres error message quoted above — not a
unit test assertion, not a mock response.

## Verdict

PASS — unique index `users_email_unique` enforced by real database
