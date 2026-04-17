# API Validation Reference

Platform-specific commands, tools, and patterns for validating REST/GraphQL APIs.

## Build and Start

```bash
# Node.js
npm install && npm start &

# Python
pip install -r requirements.txt && python app.py &

# Go
go build -o server && ./server &

# Rust
cargo build --release && ./target/release/server &

# Wait for ready
for i in $(seq 1 30); do
  curl -sf http://localhost:PORT/health > /dev/null 2>&1 && break
  sleep 1
done
```

## Health Check (Always First)

```bash
# Basic health
curl -sf http://localhost:PORT/health | jq .
# Expected: {"status": "ok"} or {"status": "healthy"}

# With timing
curl -sf -w '\nTime: %{time_total}s\nStatus: %{http_code}\n' \
  http://localhost:PORT/health | tee e2e-evidence/j0-health.txt
```

If health check fails, STOP. Fix the server before validating endpoints.

## CRUD Operations

### Create (POST)

```bash
curl -s -X POST http://localhost:PORT/api/resource \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer TOKEN' \
  -d '{"name": "Test Item", "value": 42}' \
  | tee e2e-evidence/j1-create.json | jq .

# Verify:
# - Status code: 201
# - Response body contains created resource with ID
# - Resource has all submitted fields
```

### Read (GET)

```bash
# List
curl -s http://localhost:PORT/api/resource \
  -H 'Authorization: Bearer TOKEN' \
  | tee e2e-evidence/j2-list.json | jq .

# Single item
curl -s http://localhost:PORT/api/resource/ID \
  -H 'Authorization: Bearer TOKEN' \
  | tee e2e-evidence/j2-detail.json | jq .

# Verify:
# - Status code: 200
# - List returns array with expected count
# - Detail returns object with all fields
```

### Update (PUT/PATCH)

```bash
curl -s -X PATCH http://localhost:PORT/api/resource/ID \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer TOKEN' \
  -d '{"name": "Updated Item"}' \
  | tee e2e-evidence/j3-update.json | jq .

# Verify:
# - Status code: 200
# - Response shows updated field
# - GET same resource confirms persistence
```

### Delete (DELETE)

```bash
curl -s -X DELETE http://localhost:PORT/api/resource/ID \
  -H 'Authorization: Bearer TOKEN' \
  -w '\nStatus: %{http_code}\n' \
  | tee e2e-evidence/j4-delete.txt

# Verify:
# - Status code: 200 or 204
# - GET same resource returns 404
```

## Authentication Testing

```bash
# Login — get token
curl -s -X POST http://localhost:PORT/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"email": "user@example.com", "password": "password123"}' \
  | tee e2e-evidence/j5-login.json | jq .

# Extract token
TOKEN=$(jq -r '.access_token // .token // .jwt' e2e-evidence/j5-login.json)

# Use token
curl -s http://localhost:PORT/api/protected \
  -H "Authorization: Bearer $TOKEN" \
  | tee e2e-evidence/j5-protected.json | jq .

# Expired/invalid token
curl -s http://localhost:PORT/api/protected \
  -H "Authorization: Bearer invalid-token" \
  -w '\nStatus: %{http_code}\n' \
  | tee e2e-evidence/j5-unauthorized.txt

# No token
curl -s http://localhost:PORT/api/protected \
  -w '\nStatus: %{http_code}\n' \
  | tee e2e-evidence/j5-no-auth.txt

# Verify:
# - Valid token: 200 with data
# - Invalid token: 401 with error message
# - No token: 401 with error message
```

## Error Case Testing

```bash
# Missing required field
curl -s -X POST http://localhost:PORT/api/resource \
  -H 'Content-Type: application/json' \
  -d '{}' \
  -w '\nStatus: %{http_code}\n' \
  | tee e2e-evidence/j6-missing-field.txt
# Expected: 400 with {"error": "name is required"}

# Invalid data type
curl -s -X POST http://localhost:PORT/api/resource \
  -H 'Content-Type: application/json' \
  -d '{"name": 123}' \
  -w '\nStatus: %{http_code}\n' \
  | tee e2e-evidence/j6-invalid-type.txt
# Expected: 400 with validation error

# Non-existent resource
curl -s http://localhost:PORT/api/resource/nonexistent-id \
  -w '\nStatus: %{http_code}\n' \
  | tee e2e-evidence/j6-not-found.txt
# Expected: 404 with {"error": "resource not found"}

# Wrong HTTP method
curl -s -X PATCH http://localhost:PORT/api/resource \
  -w '\nStatus: %{http_code}\n' \
  | tee e2e-evidence/j6-wrong-method.txt
# Expected: 405 Method Not Allowed
```

## Response Validation Checklist

For EVERY API response, verify:

| Check | How | Example |
|-------|-----|---------|
| Status code | `-w '%{http_code}'` | `201` for create, `200` for read |
| Content-Type | `-w '%{content_type}'` | `application/json` |
| Response body | `jq .` | Has expected fields and values |
| Data types | `jq 'type'` | Numbers are numbers, not strings |
| Pagination | `jq '.total, .page, .limit'` | Correct counts and offsets |
| Error format | `jq '.error'` | Consistent error message structure |
| Timing | `-w '%{time_total}'` | Under acceptable threshold |

## Rate Limiting (if applicable)

```bash
# Rapid-fire requests
for i in $(seq 1 20); do
  curl -s -o /dev/null -w "%{http_code} " http://localhost:PORT/api/resource
done | tee e2e-evidence/j7-rate-limit.txt

# Expected: Series of 200s then 429s
# Verify the 429 response includes retry-after header
```

## Evidence Quality Examples

**GOOD response review:**
> "POST /api/users returned 201. Body: `{"id": "usr_abc123", "name": "Test User",
> "email": "test@example.com", "created_at": "2026-03-07T14:30:00Z"}`.
> All submitted fields present, ID auto-generated, timestamp set."

**BAD response review:**
> "User created successfully"

**GOOD error review:**
> "POST /api/users with empty body returned 400. Body:
> `{"error": "Validation failed", "details": [{"field": "name", "message": "is required"},
> {"field": "email", "message": "is required"}]}`.
> Error message is specific and lists all missing fields."

**BAD error review:**
> "Error handling works"

## Common API Validation Journeys

| Journey | Method | Key Evidence |
|---------|--------|-------------|
| Health Check | GET /health | 200 with status body |
| Create Resource | POST /api/resource | 201 with created object |
| List Resources | GET /api/resource | 200 with array, correct count |
| Get Single | GET /api/resource/:id | 200 with full object |
| Update Resource | PATCH /api/resource/:id | 200 with updated fields |
| Delete Resource | DELETE /api/resource/:id | 204, then GET returns 404 |
| Authentication | POST /auth/login | Token in response, usable on protected routes |
| Authorization | GET /api/protected | 200 with token, 401 without |
| Validation | POST with bad data | 400 with specific error messages |
| Not Found | GET /api/resource/fake | 404 with error message |
