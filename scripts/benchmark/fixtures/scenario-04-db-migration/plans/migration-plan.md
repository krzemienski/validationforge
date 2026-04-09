# DB Migration Execution Plan

**Migration:** Add `last_login_at` column and unique index to `users` table
**Date:** 2026-04-05
**Author:** DB Platform Team

## Context

The `users` table needs a `last_login_at` timestamp to support login analytics.
The `email` column currently has no uniqueness constraint — a uniqueness bug was
discovered in production where duplicate accounts can be created. Both changes are
bundled in a single migration.

## Migration File

```javascript
// migrations/20260405091400_add_last_login_and_email_index.js
exports.up = async (knex) => {
  await knex.schema.alterTable('users', (table) => {
    table.timestamp('last_login_at', { useTz: true }).nullable();
  });
  await knex.raw('CREATE UNIQUE INDEX users_email_unique ON users (email)');
};

exports.down = async (knex) => {
  await knex.raw('DROP INDEX IF EXISTS users_email_unique');
  await knex.schema.alterTable('users', (table) => {
    table.dropColumn('last_login_at');
  });
};
```

## Pre-Migration Checks

1. Confirm no duplicate emails exist before adding unique index:
   ```sql
   SELECT email, COUNT(*) FROM users GROUP BY email HAVING COUNT(*) > 1;
   ```
   Must return 0 rows or index creation will fail.

2. Confirm database is accessible and backup is current.

3. Confirm staging run completed without errors.

## Execution Steps

1. `npx knex migrate:latest --env staging` — verify on staging first
2. Capture staging schema output for comparison
3. `npx knex migrate:latest --env production` — run in production maintenance window
4. Immediately run schema introspection to verify

## Rollback Plan

If post-migration validation fails:
```bash
npx knex migrate:rollback --env production
```
The `exports.down` function drops the index and column. Confirm rollback
completes and schema returns to pre-migration state.

## Risk Assessment

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| Duplicate emails block index creation | Low | Pre-check query required |
| Column add timeout on large table | Very Low | `last_login_at` nullable — fast |
| Index build locks table | Very Low | Concurrent index build if >1M rows |
