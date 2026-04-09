# DB Migration Validation Verdict

**Target:** users table — add `last_login_at` column and `users_email_unique` index
**Date:** 2026-04-05
**Validator:** ValidationForge api-validation protocol

## PASS Criteria (defined before validation)

| # | Criterion | Verdict | Evidence |
|---|-----------|---------|----------|
| 1 | Migration runs without errors | **PASS** | step-01-migration-output.md: exit code 0, "Batch 7 run: 1 migrations" |
| 2 | `last_login_at` column present in schema | **PASS** | step-02-schema-verify.json: column type `timestamp with time zone`, nullable=true |
| 3 | `users_email_unique` index present in schema | **PASS** | step-02-schema-verify.json: `UNIQUE, btree (email)` in psql output |
| 4 | Unique index enforced on duplicate insert | **PASS** | step-03-duplicate-check.md: ERROR 23505 `duplicate key value violates unique constraint "users_email_unique"` |
| 5 | Duplicate row not persisted | **PASS** | step-03-duplicate-check.md: `SELECT COUNT(*) = 1` confirms original row preserved |

## Journey Results

### Journey 1: DB Migration Schema Validation
**Verdict: PASS**

All 5 PASS criteria met with specific cited evidence:

1. **Migration executed** — `npx knex migrate:latest` returned exit code 0, output
   "Batch 7 run: 1 migrations / 20260405091400_add_last_login_and_email_index.js (0.847 ms)"

2. **Column confirmed** — `\d users` output shows `last_login_at | timestamp with time zone`
   with nullable=true in the live production schema

3. **Index confirmed** — `\d users` output shows
   `"users_email_unique" UNIQUE, btree (email)` in the Indexes section

4. **Constraint enforced** — Inserting `alice@example.com` (existing email) triggered
   `ERROR: duplicate key value violates unique constraint "users_email_unique"` from Postgres

5. **Rollback integrity** — `SELECT COUNT(*) WHERE email='alice@example.com'` returned 1,
   confirming the duplicate was rejected and the original row is intact

## Overall Verdict: PASS

The database migration was fully validated against the real Postgres instance. The
migration applies cleanly, the schema changes are confirmed via introspection, and the
unique constraint is enforced at the database level with a real violation attempt.

## What Was NOT Validated

- **Rollback journey** — `migrate:rollback` not tested; schema rollback unvalidated
- **Performance journey** — query performance on `last_login_at` with large datasets
- **Application layer** — no validation that app code correctly writes `last_login_at`

These gaps are intentional — only 1 of 3 planned journeys was executed, contributing
to a Coverage score of 60/100 and overall Grade B rather than Grade A.
