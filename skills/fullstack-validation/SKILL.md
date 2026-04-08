---
name: fullstack-validation
description: >
  Fullstack validation using strict bottom-up approach: Database -> API -> Frontend.
  Validates each layer independently, then tests integration across the entire stack.
  References api-validation and web-validation skills for layer-specific procedures.
---

# Fullstack Validation

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

## Prerequisites

| Requirement | How to verify |
|-------------|---------------|
| Database running and accessible | `psql $DATABASE_URL -c "SELECT 1"` or equivalent |
| API server running | `curl -s http://localhost:API_PORT/health` |
| Frontend dev server running | `curl -s http://localhost:FE_PORT -o /dev/null -w "%{http_code}"` |
| Evidence directory exists | `mkdir -p e2e-evidence` |

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

After the database is verified, validate the API layer. Follow the full `api-validation` skill procedure.

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

After the API is verified, validate the frontend. Follow the full `web-validation` skill procedure.

### Verify frontend renders API data
```
browser_navigate  url="http://localhost:FE_PORT"
browser_snapshot
browser_take_screenshot  filename="e2e-evidence/web-homepage-with-data.png"
```

Key check: The data visible in the frontend MUST match what the API returned. If the API returned 5 users, the frontend should display 5 users.

### Interactive flows
Navigate through all user-facing journeys using Playwright MCP or Chrome DevTools MCP. Capture screenshots at each step.

**PASS gate:** Do not proceed to integration testing until the frontend correctly renders API data.

## Layer 4: Integration Testing

After all three layers pass independently, validate data flows across the entire stack.

### Frontend-to-database write path
```
# 1. Create via frontend
browser_navigate  url="http://localhost:FE_PORT/items/new"
browser_fill_form  fields=[{"name":"Item Name","type":"textbox","ref":"NAME_REF","value":"Integration Test Item"}]
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

## Common Failures

| Symptom | Layer | Likely Cause | Fix |
|---------|-------|--------------|-----|
| Frontend shows empty list | DB or API | No seed data, or API query wrong | Check DB seed data first, then API response |
| API returns stale data | DB or API | Caching, connection pooling, or migration pending | Clear cache, restart server, run migrations |
| Frontend shows data but API returns different data | Frontend | Frontend using mock/cached data | Remove mocks, verify fetch URL points to real API |
| Create works in frontend but data missing in DB | API | Transaction not committed, or write to wrong table | Check API create handler and DB connection |
| Data appears in DB but not in API | API | Query filter excluding new records, or wrong table | Check API query and table name |
| 500 error only on frontend actions | API | Missing CORS headers or request format mismatch | Check API CORS config and request Content-Type |

## PASS Criteria Template

- [ ] **Database:** Schema matches expected structure (tables, columns, types)
- [ ] **Database:** Seed data present and correct
- [ ] **API:** Health endpoint returns 200
- [ ] **API:** CRUD operations work and persist to database
- [ ] **API:** Auth flow works (if applicable)
- [ ] **Frontend:** Pages render without console errors
- [ ] **Frontend:** Data from API displayed correctly
- [ ] **Integration:** Data created in frontend appears in database
- [ ] **Integration:** Data inserted in database appears in frontend
- [ ] **Integration:** Updates propagate across all layers
- [ ] **Integration:** Deletes cascade correctly across all layers
