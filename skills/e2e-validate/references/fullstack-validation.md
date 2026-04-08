# Fullstack Validation Reference

Platform-specific commands, tools, and patterns for validating fullstack applications (frontend + backend + database).

## The Bottom-Up Principle

Fullstack validation MUST proceed bottom-up. A bug at any layer corrupts all layers above it.

```
Layer 3: Frontend  ← Validate LAST
Layer 2: Backend   ← Validate SECOND
Layer 1: Database  ← Validate FIRST
```

Never start at the frontend. If the frontend shows wrong data, the bug could be in the database, the API, the frontend state management, or the rendering. Starting at the bottom eliminates possibilities systematically.

## Layer 1: Database Validation

### Verify Database is Running

```bash
# PostgreSQL
pg_isready -h localhost -p 5432
psql -h localhost -U postgres -c "SELECT 1;" 2>&1 | tee e2e-evidence/j0-db-health.txt

# MySQL
mysqladmin -u root ping
mysql -u root -e "SELECT 1;" 2>&1 | tee e2e-evidence/j0-db-health.txt

# SQLite
sqlite3 ./data.db "SELECT 1;" 2>&1 | tee e2e-evidence/j0-db-health.txt

# MongoDB
mongosh --eval "db.runCommand({ping: 1})" 2>&1 | tee e2e-evidence/j0-db-health.txt
```

### Verify Schema

```bash
# PostgreSQL — list tables
psql -h localhost -U postgres -d mydb -c "\dt" 2>&1 | tee e2e-evidence/j0-db-schema.txt

# Check specific table structure
psql -h localhost -U postgres -d mydb -c "\d users" >> e2e-evidence/j0-db-schema.txt

# Verify migrations ran
psql -h localhost -U postgres -d mydb -c "SELECT * FROM schema_migrations ORDER BY version DESC LIMIT 5;" \
  >> e2e-evidence/j0-db-schema.txt
```

### Verify Seed Data

```bash
# Check row counts
psql -h localhost -U postgres -d mydb -c "
  SELECT 'users' as table_name, COUNT(*) as rows FROM users
  UNION ALL
  SELECT 'sessions', COUNT(*) FROM sessions
  UNION ALL
  SELECT 'projects', COUNT(*) FROM projects;
" 2>&1 | tee e2e-evidence/j0-db-data.txt

# Sample data
psql -h localhost -U postgres -d mydb -c "SELECT id, name, email FROM users LIMIT 5;" \
  >> e2e-evidence/j0-db-data.txt
```

## Layer 2: Backend API Validation

Only proceed here if Layer 1 passes.

### Health Check

```bash
curl -sf http://localhost:PORT/health | jq . | tee e2e-evidence/j1-api-health.json
# Must return 200 with status body
```

### CRUD Endpoints

Follow the patterns in `references/api-validation.md`. Key difference for fullstack: verify that API responses match database state.

```bash
# Create via API
curl -s -X POST http://localhost:PORT/api/users \
  -H 'Content-Type: application/json' \
  -d '{"name": "Validation User", "email": "val@test.com"}' \
  | tee e2e-evidence/j1-api-create.json | jq .

# Verify in database
CREATED_ID=$(jq -r '.id' e2e-evidence/j1-api-create.json)
psql -h localhost -U postgres -d mydb -c \
  "SELECT id, name, email FROM users WHERE id = '$CREATED_ID';" \
  | tee e2e-evidence/j1-db-verify-create.txt

# Both should show the same data
```

### Authentication

```bash
# Login via API
curl -s -X POST http://localhost:PORT/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"email": "val@test.com", "password": "password123"}' \
  | tee e2e-evidence/j1-api-login.json | jq .

TOKEN=$(jq -r '.token // .access_token' e2e-evidence/j1-api-login.json)

# Use token on protected endpoint
curl -s http://localhost:PORT/api/me \
  -H "Authorization: Bearer $TOKEN" \
  | tee e2e-evidence/j1-api-me.json | jq .
```

## Layer 3: Frontend Validation

Only proceed here if Layer 2 passes.

### Start Frontend

```bash
# Start frontend (separate from backend if applicable)
cd frontend && npm run dev &
FRONTEND_PID=$!

# Wait for ready
for i in $(seq 1 30); do
  curl -sf http://localhost:3000 > /dev/null 2>&1 && break
  sleep 1
done
```

### Verify Data Displays from Real API

This is the critical integration check. The frontend must show data from the REAL backend, not mock data.

```
# Navigate to data page
browser_navigate url="http://localhost:3000/dashboard"
browser_snapshot

# Verify: snapshot shows data that matches API response
# Compare with e2e-evidence/j1-api-list.json
# If API returned 41 items, frontend should show 41 items
```

### Cross-Layer Integration Test

The strongest fullstack validation: make a change in one layer and verify ALL layers reflect it.

```bash
# Step 1: Create record via API
curl -s -X POST http://localhost:PORT/api/items \
  -H 'Content-Type: application/json' \
  -d '{"title": "Integration Test Item"}' \
  | tee e2e-evidence/j2-integration-create.json | jq .

# Step 2: Verify in database
ITEM_ID=$(jq -r '.id' e2e-evidence/j2-integration-create.json)
psql -h localhost -U postgres -d mydb -c \
  "SELECT * FROM items WHERE id = '$ITEM_ID';" \
  | tee e2e-evidence/j2-integration-db.txt

# Step 3: Verify in frontend
# Navigate to items list and take screenshot
# browser_navigate url="http://localhost:3000/items"
# browser_take_screenshot filename="e2e-evidence/j2-integration-frontend.png"
# Verify: "Integration Test Item" appears in the list
```

### Frontend Error States

```
# Check console for errors
browser_console_messages level="error"
# Expected: zero errors

# Check network for failed requests
browser_network_requests includeStatic=false
# Expected: all API calls return 2xx
```

## Environment Configuration

Fullstack apps often have configuration connecting layers. Verify:

```bash
# Check frontend points to correct API
grep -r "API_URL\|NEXT_PUBLIC_API\|VITE_API\|REACT_APP_API" \
  frontend/.env frontend/.env.local frontend/src/config* 2>/dev/null \
  | tee e2e-evidence/j0-config-frontend.txt

# Check backend points to correct database
grep -r "DATABASE_URL\|DB_HOST\|MONGO_URI" \
  backend/.env backend/.env.local backend/src/config* 2>/dev/null \
  | tee e2e-evidence/j0-config-backend.txt

# Verify they align (same ports, same hosts)
```

## Evidence Quality Examples

**GOOD cross-layer review:**
> "Created user 'Validation User' via POST /api/users (201, id: usr_abc123).
> Database query confirms row exists: `usr_abc123 | Validation User | val@test.com`.
> Frontend dashboard screenshot shows user in the list at row 3 with matching name and email.
> All three layers consistent."

**BAD cross-layer review:**
> "Created user and it shows up in the frontend"

**GOOD integration evidence:**
> "Added item via API. Database has 42 rows (was 41). Frontend list shows 42 items
> with 'Integration Test Item' at the top (sorted by created_at DESC).
> Console: zero errors. Network: GET /api/items returned 200 with 42 items in body."

**BAD integration evidence:**
> "Integration works end to end"

## Common Fullstack Validation Journeys

| Journey | Layers | Key Evidence |
|---------|--------|-------------|
| Database Health | DB | Connection succeeds, tables exist, data present |
| API Health | API + DB | Health endpoint 200, can query data |
| Frontend Loads | All | Page renders, no console errors, data from API visible |
| Create Flow | All | POST creates in DB, shows in API list, appears in UI |
| Update Flow | All | PATCH updates DB, API reflects change, UI shows new value |
| Delete Flow | All | DELETE removes from DB, gone from API list, removed from UI |
| Auth Flow | All | Login via UI, token issued, protected data accessible |
| Error Propagation | All | DB constraint violation → API error response → UI error message |
