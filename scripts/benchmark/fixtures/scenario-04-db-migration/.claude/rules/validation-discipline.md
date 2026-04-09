# Validation Discipline

## No-Mock Mandate

Never create test files, mocks, stubs, or test doubles. This includes:
- Files named `*.test.*`, `*.spec.*`, `*.mock.*`
- Any file importing `jest.mock`, `sinon`, or similar test frameworks
- In-memory fakes substituting for real services
- SQLite in-memory databases substituting for the real Postgres instance
- Seeded test databases with fake migration state

## Evidence Standards

Every PASS/FAIL verdict must cite specific evidence:
- **Migration output**: Quote the actual migration command output with row counts and timing
- **Schema state**: Show actual `\d tablename` or `INFORMATION_SCHEMA` query results
- **Constraint checks**: Show the actual error message when constraints are violated
- **Build output**: Quote the actual success/failure line
- **Empty files**: 0-byte or near-empty files are INVALID evidence

## Gate Protocol

Never claim completion without personally examining the evidence:
1. Run the migration against the REAL database (not an in-memory fake)
2. Introspect the schema to confirm columns and indexes were created
3. Attempt to violate constraints and capture the actual error
4. Write verdict citing specific database output
5. Only then mark the journey complete

## DB-Specific Rules

- Always validate against a **running database** -- never against migration code alone
- Capture schema state before AND after migration
- Unique indexes must be verified by attempting an actual duplicate insert
- Foreign key constraints must be tested with a real referential violation attempt
- Rollback must be tested on staging before production execution

## Iron Rules

```
1. IF the real database doesn't work, FIX THE REAL SYSTEM.
2. NEVER mark a journey PASS without specific cited evidence.
3. NEVER skip preflight -- if the DB isn't running, START IT.
4. NEVER exceed 3 fix attempts per journey.
5. Migration success is NOT functional validation.
6. A migration that runs is NOT a migration that is correct.
```
