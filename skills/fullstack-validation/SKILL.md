---
name: fullstack-validation
description: "Use whenever validating a multi-layer app where frontend depends on backend depends on database — Rails+React, Django+Vue, Next.js+Postgres, any monorepo or separate repos that share data. Runs a strict bottom-up protocol: verify DB schema and seed data first, then API CRUD, then frontend rendering, then cross-layer integration flows (create in frontend → appears in DB, insert in DB → appears in frontend, update via API → propagates everywhere, delete cascades). Reach for this when a bug could be in any layer and you need to prove which one, or before shipping a change that touches more than one layer."
context_priority: standard
---

# Fullstack Validation

**Composed runner**: `bash scripts/fullstack-validate.sh --db-check-cmd='psql -c SELECT 1' --api-base-url=http://localhost:3000 --web-base-url=http://localhost:3000 --evidence-dir=e2e-evidence/fullstack` runs the DB → API → Web gates in order, invoking `api-validation/scripts/crud-validator.sh` for the API layer. It exits non-zero on the first gate that fails.

## The Bottom-Up Rule

```
+------------------+
|    Frontend      |   <-- Validate LAST
+------------------+
        |
+------------------+
|    Backend API   |   <-- Validate SECOND
+------------------+
        |
+------------------+
|    Database      |   <-- Validate FIRST
+------------------+
```

**Why bottom-up?** A frontend bug might actually be a backend bug. A backend bug might actually be a database bug. If you start at the frontend, you waste time debugging symptoms instead of root causes. Always start at the deepest dependency.

**Gates matter.** Each layer has a PASS gate. If Layer 1 (DB) fails, do **not** proceed to Layer 2 — fix the DB first, or your API layer findings will be noise. Same from 2→3 and 3→4. Skipping a gate turns 20 minutes of rework into hours of chasing ghosts.

## Scope vs. platform-specific skills

This skill orchestrates the cross-layer flow. It does **not** replace the platform-specific skills — it composes them:

- For full API endpoint coverage (error shapes, auth, pagination, rate limiting) → load `api-validation` during Layer 2.
- For full frontend coverage (console errors, network tab, responsive, route coverage) → load `web-validation` during Layer 3.

This skill covers the integration work that those skills don't: proving the same record travels through all three layers unchanged.

## Prerequisites

Each row is a gate — if it fails, fix the failure first. The fix hints are framework-agnostic suggestions; adapt to your stack.

| Requirement | How to verify | If it fails |
|-------------|---------------|-------------|
| Database running and accessible | `psql $DATABASE_URL -c "SELECT 1"` or equivalent | Start DB service (`brew services start postgresql`, `docker compose up db`, etc.) |
| API server running | `curl -s http://localhost:API_PORT/health` | Start API (`npm run dev`, `python manage.py runserver`, `bundle exec rails server`) |
| Frontend dev server running | `curl -s http://localhost:FE_PORT -o /dev/null -w "%{http_code}"` | Start frontend (`npm run dev`, `pnpm dev`) |
| Evidence directory exists | `test -d e2e-evidence && echo ok` | `mkdir -p e2e-evidence` |
| Browser automation MCP available | Playwright MCP or Chrome DevTools MCP connected | Configure in `.claude/mcp.json`; see the `web-validation` skill |

## Layer 1: Database Validation

Verify the database is in the expected state before testing anything above it.

### Schema verification
```bash
# PostgreSQL
psql $DATABASE_URL -c "\dt" | tee e2e-evidence/db-tables.txt
psql $DATABASE_URL -c "\d users" | tee e2e-evidence/db-schema-users.txt

# MySQL
mysql -u USER -p DB -e "SHOW TABLES" | tee e2e-evidence/db-tables.txt
mysql -u USER -p DB -e "DESCRIBE users" | tee e2e-evidence/db-schema-users.txt

# SQLite
sqlite3 DB_PATH ".tables" | tee e2e-evidence/db-tables.txt
sqlite3 DB_PATH ".schema users" | tee e2e-evidence/db-schema-users.txt
```

### Seed data verification
```bash
psql $DATABASE_URL -c "SELECT count(*) FROM users" | tee e2e-evidence/db-seed-count.txt
psql $DATABASE_URL -c "SELECT id, email FROM users LIMIT 5" | tee e2e-evidence/db-seed-sample.txt
```

### Migration status
```bash
# Check pending migrations (framework-specific)
# Rails:   rails db:migrate:status
# Django:  python manage.py showmigrations
# Prisma:  npx prisma migrate status
# Knex:    npx knex migrate:status
```

**PASS gate:** Do not proceed to Layer 2 until database schema and seed data are confirmed correct.

## Layer 2: API Validation

After the database is verified, validate the API layer. For full coverage — error shapes, auth, pagination, rate limiting — load the `api-validation` skill and run its protocol. The steps below are the minimum cross-layer checks that prove the API is actually talking to the database you just verified.

### Quick API health
```bash
curl -s http://localhost:API_PORT/health \
  | tee e2e-evidence/api-health.json | jq .
```

### Verify API returns database data
```bash
# This proves the API is actually reading from the database, not returning hardcoded data
curl -s http://localhost:API_PORT/api/users \
  | tee e2e-evidence/api-users-list.json | jq .

# Cross-reference: count from API should match count from DB
API_COUNT=$(jq 'if type == "array" then length else .data | length end' e2e-evidence/api-users-list.json)
echo "API returned $API_COUNT users" | tee e2e-evidence/api-db-crossref.txt
```

### CRUD cycle
Run the full CRUD pattern from `api-validation` skill against at least one resource. Save all evidence.

**PASS gate:** Do not proceed to Layer 3 until API correctly reads from and writes to the database.

## Layer 3: Frontend Validation

After the API is verified, validate the frontend. For full coverage — console errors, network tab, responsive, route coverage, form testing — load the `web-validation` skill. The steps below are the minimum cross-layer checks that prove the frontend is actually rendering data from the API you just verified (not hardcoded fixtures, not cached).

### Verify frontend renders API data

The commands below use Playwright MCP syntax. If you have Chrome DevTools MCP instead, the equivalents are `navigate_page` / `take_snapshot` / `take_screenshot` (see the `web-validation` skill for the mapping).

```
browser_navigate  url="http://localhost:FE_PORT"
browser_snapshot
browser_take_screenshot  filename="e2e-evidence/web-homepage-with-data.png"
```

Key check: The data visible in the frontend MUST match what the API returned. If the API returned 5 users, the frontend should display 5 users.

### Interactive flows
Navigate through all user-facing journeys using Playwright MCP or Chrome DevTools MCP. Capture screenshots at each step.

**PASS gate:** Do not proceed to Layer 4 until the frontend correctly renders API data and all displayed values match the API responses captured in evidence.

## Layer 4: Integration Testing

After all three layers pass independently, validate data flows across the entire stack.

### Frontend-to-database write path
```
# 1. Create via frontend
browser_navigate  url="http://localhost:FE_PORT/items/new"
browser_snapshot                                        # Get refs for form fields
browser_fill_form  fields=[{ref: "NAME_REF", value: "Integration Test Item"}]
browser_click  ref="SAVE_REF"
browser_take_screenshot  filename="e2e-evidence/integration-create-frontend.png"

# 2. Verify in API
curl -s http://localhost:API_PORT/api/items?q=Integration+Test+Item \
  | tee e2e-evidence/integration-create-api-verify.json | jq .

# 3. Verify in database
psql $DATABASE_URL -c "SELECT * FROM items WHERE name = 'Integration Test Item'" \
  | tee e2e-evidence/integration-create-db-verify.txt
```

### Database-to-frontend read path
```bash
# 1. Insert directly into database
psql $DATABASE_URL -c "INSERT INTO items (name) VALUES ('DB Direct Insert') RETURNING id" \
  | tee e2e-evidence/integration-db-insert.txt
```

```
# 2. Verify API returns it
curl -s http://localhost:API_PORT/api/items?q=DB+Direct+Insert \
  | tee e2e-evidence/integration-api-shows-db-insert.json | jq .

# 3. Verify frontend displays it
browser_navigate  url="http://localhost:FE_PORT/items"
browser_take_screenshot  filename="e2e-evidence/integration-frontend-shows-db-insert.png"
```

### API-to-frontend update propagation
```bash
# 1. Update via API
curl -s -X PUT http://localhost:API_PORT/api/items/ID \
  -H 'Content-Type: application/json' \
  -d '{"name": "API Updated Name"}' \
  | tee e2e-evidence/integration-api-update.json | jq .
```

```
# 2. Verify frontend shows updated data (may need refresh)
browser_navigate  url="http://localhost:FE_PORT/items"
browser_take_screenshot  filename="e2e-evidence/integration-frontend-after-api-update.png"
```

### Delete cascade
```bash
# 1. Delete via frontend
# (capture the delete action via browser automation)

# 2. Verify API returns 404
curl -s -w "\nHTTP_STATUS:%{http_code}" http://localhost:API_PORT/api/items/DELETED_ID \
  | tee e2e-evidence/integration-api-after-delete.txt

# 3. Verify database row removed
psql $DATABASE_URL -c "SELECT count(*) FROM items WHERE id = 'DELETED_ID'" \
  | tee e2e-evidence/integration-db-after-delete.txt
```

**PASS gate:** Do not proceed to the final verdict until all cross-layer data flows (frontend→API→DB and DB→API→frontend) have been verified with evidence captured at each layer.

## Evidence Standards

**GOOD:** Screenshot shows specific data values from the API response rendered in the UI; curl output saved to file with full JSON body; database query output shows exact rows with IDs; cross-layer comparisons cite actual counts or values.

**BAD:** "Frontend loaded successfully" without a screenshot showing the actual data; "API returned 200" without saving the response body; "Database has data" without a query output file; claiming layers are integrated without verifying the same record appears at each layer.

Every evidence file must contain the FULL content — not just a status code or a note that something "worked". Cross-layer evidence must trace the same data item (by ID or unique value) across all three layers.

## Common Failures

| Symptom | Layer | How to diagnose | Fix |
|---------|-------|-----------------|-----|
| Frontend shows empty list | DB or API | Run `psql $DATABASE_URL -c "SELECT count(*) FROM $TABLE"` — 0 rows means seed missing. Then curl the API endpoint; empty response means query filter wrong. | Run migrations/seeds; fix the API query |
| API returns stale data | DB or API | Check migration status (`showmigrations`, `migrate:status`); check your server for in-memory cache; `DESCRIBE $TABLE` vs expected schema | Run pending migrations, clear cache, restart server |
| Frontend shows data but API returns different data | Frontend | Curl the API directly and compare JSON byte-for-byte with what the browser shows; open Network tab in DevTools | Remove mocks, verify fetch URL points to real API, clear browser cache |
| Create works in frontend but data missing in DB | API | Check API logs during the create attempt; query DB immediately after: `SELECT * FROM $TABLE ORDER BY created_at DESC LIMIT 1` | Check transaction commit; confirm the handler writes to the right table |
| Data appears in DB but not in API | API | `SELECT id FROM $TABLE WHERE ...` returns the row, but `/api/...` doesn't include it. Read the API query. | Check API query WHERE clauses; confirm table name matches |
| 500 error only on frontend actions | API | Browser DevTools Network tab → click the failing request → Preview/Response tab. Cross-reference with API server logs. | Check CORS config, Content-Type header, request body shape |

## PASS Criteria Template

"Correctly" below means: **values match exactly** (no truncation, no formatting that changes meaning), **count matches** (if API returns 5 items, frontend shows 5 rows or paginated total of 5), and **order matches** when order is specified (sorting). For any checkbox that's a soft maybe, write the exact values you compared into the evidence file.

- [ ] **Database:** Schema matches expected structure (tables, columns, types)
- [ ] **Database:** Seed data present and correct (count and sample values cited in evidence)
- [ ] **API:** Health endpoint returns 200
- [ ] **API:** CRUD operations work and persist to database
- [ ] **API:** Auth flow works (if applicable)
- [ ] **Frontend:** Pages render without console errors
- [ ] **Frontend:** Data from API displayed correctly (exact values quoted, count matches API response)
- [ ] **Integration:** Data created in frontend appears in database (same ID or unique value cited at each layer)
- [ ] **Integration:** Data inserted in database appears in frontend (same ID or unique value cited at each layer)
- [ ] **Integration:** Updates propagate across all layers (old value vs new value cited at each layer)
- [ ] **Integration:** Deletes cascade correctly across all layers (absence verified by count decrease and 404 responses)
