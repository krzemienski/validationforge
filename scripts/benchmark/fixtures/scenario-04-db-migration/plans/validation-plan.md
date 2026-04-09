# Validation Plan: DB Migration

**Scenario:** DB migration — `last_login_at` column + `users_email_unique` index
**Date:** 2026-04-05
**Planner:** ValidationForge api-validation protocol

## Context

A database migration modifies the `users` table. Validation must confirm the schema
changes are applied correctly and the new unique constraint is actively enforced by
the real database — not just present in migration code.

## Journeys to Validate

### Journey 1: Schema Migration Validation
**PASS Criteria:**
- `npx knex migrate:latest` exits with code 0
- `last_login_at` column appears in `\d users` output with correct type
- `users_email_unique` UNIQUE index appears in `\d users` output
- Attempting to insert a duplicate email triggers `ERROR 23505` with constraint name
- Original row count unchanged after rejected duplicate

**Evidence Required:**
- `step-01-migration-output.md` — full migration command output including batch number
- `step-02-schema-verify.json` — `\d users` psql output with all columns and indexes
- `step-03-duplicate-check.md` — duplicate insert error message and SELECT count result

### Journey 2: Migration Rollback
**PASS Criteria:**
- `npx knex migrate:rollback` exits with code 0
- `last_login_at` column no longer present in schema
- `users_email_unique` index no longer present in schema
- Duplicate email insert succeeds after rollback (constraint removed)

**Evidence Required:**
- `step-04-rollback-output.md` — rollback command output
- `step-05-post-rollback-schema.json` — schema introspection confirming column/index removed

### Journey 3: Performance Validation
**PASS Criteria:**
- `SELECT * FROM users WHERE last_login_at > NOW() - INTERVAL '7 days'` completes in < 100ms
- `SELECT * FROM users WHERE email = 'test@example.com'` uses index scan (EXPLAIN ANALYZE)

**Evidence Required:**
- `step-06-query-performance.json` — EXPLAIN ANALYZE output with actual timing

## Pre-flight Checks

1. Database running and accessible
2. `SELECT COUNT(*) FROM users` returns known row count (no surprises)
3. No duplicate emails: `SELECT email, COUNT(*) FROM users GROUP BY email HAVING COUNT(*) > 1` returns 0 rows
4. Migration file present: `ls migrations/20260405091400_add_last_login_and_email_index.js`

## Execution Order

1. Run pre-flight (database health, duplicate check)
2. Execute Journey 1 (schema migration validation)
3. Execute Journey 2 (rollback validation) — on staging only
4. Execute Journey 3 (performance validation) — optional
5. Write verdict to `e2e-evidence/report.md`

## Note on This Fixture

In this benchmark fixture, only Journey 1 was executed. Journeys 2 and 3 were
planned but not executed, intentionally demonstrating partial coverage (Grade B
rather than Grade A).
