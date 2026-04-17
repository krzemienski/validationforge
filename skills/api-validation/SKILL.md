---
name: api-validation
description: "Use whenever validating an HTTP API (REST, GraphQL-over-HTTP, webhook receiver) — before deployment, after endpoint or auth changes, when onboarding a new API consumer, or when answering 'does this API actually work end-to-end'. Covers health checks, full CRUD cycles, auth (valid/invalid/missing tokens, 401/403), error response shape, pagination, and rate limiting, all via curl with JSON bodies and status codes saved as evidence. Reach for it on phrases like 'test the API', 'validate the endpoints', 'check auth', 'curl the server', 'does /api/... work'."
triggers:
  - "api testing"
  - "curl validation"
  - "api contract"
  - "endpoint verification"
  - "HTTP status codes"
  - "test the api"
  - "validate endpoints"
  - "check auth flow"
context_priority: standard
---

# API Validation

## Quick start

Work this list in order. If Health + CRUD + Auth all PASS, most APIs are validated — you only need steps 4-6 when they apply.

| # | Step | Time | Skip when |
|---|------|------|-----------|
| 1 | Health check | 5 min | never |
| 2 | CRUD cycle (per resource) | ~20 min | API is read-only |
| 3 | Auth (valid / invalid / missing token) | ~10 min | API has no auth |
| 4 | Error response shape | 10 min | never (even if auth/CRUD pass, error bodies often lie) |
| 5 | Pagination | 10 min | no list endpoints |
| 6 | Rate limiting | 5 min | API docs don't mention rate limits |

## Prerequisites

Verify every row before starting — each is a gate, not a hint. If any fails, fix that first or the rest of the run is noise.

| Requirement | How to verify |
|-------------|---------------|
| API server running | `curl -s http://localhost:PORT/health` |
| Database seeded (if applicable) | Check server startup logs for seed confirmation |
| Auth tokens available (if applicable) | Login endpoint returns token |
| `jq` installed | `jq --version` |
| Evidence directory exists | `mkdir -p e2e-evidence` |

## Common failures (read this before debugging)

Most "API validation is broken" reports trace back to one of these. Check here before diving into the protocol steps.

| Symptom | Likely Cause | Fix |
|---------|--------------|-----|
| Connection refused | Server not running or wrong port | Start server, check PORT env var |
| 500 Internal Server Error | Unhandled exception in route handler | Check server logs for stack trace |
| Empty response body | Handler returns status without body | Add response body to handler |
| CRUD read-after-delete returns 200 | Soft delete not filtering correctly | Check delete implementation and query filters |
| Auth token not returned | Login handler missing token generation | Check auth service and token signing |
| Pagination returns duplicates | Missing ORDER BY in query | Add deterministic ordering to list queries |

## Step 1: Health Check

```bash
curl -s http://localhost:PORT/health \
  | tee e2e-evidence/api-health.json | jq .
```

Verify the response includes expected fields (status, version, uptime, etc.). A bare `200 OK` without body content is suspicious — document it.

## Step 2: CRUD Validation Pattern

**Prerequisite: `$TOKEN` must be set before Step 2.** The Create/Read/Update/Delete
requests below all send `Authorization: Bearer $TOKEN`. The token is obtained in
Step 3 ("Valid credentials"). If you are running steps individually — or the API
requires auth on every CRUD endpoint — run Step 3's login request first, export
`TOKEN=...`, then return here. If the API is unauthenticated, drop the
`-H "Authorization: Bearer $TOKEN"` header from the snippets below.

**Fast path**: If you just want to run the whole CRUD cycle, `bash scripts/crud-validator.sh --base-url=http://localhost:PORT --resource=posts --token=$TOKEN --evidence-dir=e2e-evidence/api` does steps 2.1–2.7 in one shot. The inline steps below exist for the cases where you need to inspect or modify a single step.

For each resource in the API, execute the full CRUD cycle. Save every response.

### Create
```bash
curl -s -X POST http://localhost:PORT/api/RESOURCE \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"name": "Test Item", "description": "Created by validation"}' \
  | tee e2e-evidence/api-create-RESOURCE.json | jq .

# Extract the created ID for subsequent operations
RESOURCE_ID=$(jq -r '.id // .data.id' e2e-evidence/api-create-RESOURCE.json)
echo "Created ID: $RESOURCE_ID"
[ -z "$RESOURCE_ID" ] || [ "$RESOURCE_ID" = "null" ] && { echo "ERROR: Create failed, cannot continue CRUD cycle" >&2; exit 1; }
```

### Read (single)
```bash
curl -s http://localhost:PORT/api/RESOURCE/$RESOURCE_ID \
  -H "Authorization: Bearer $TOKEN" \
  | tee e2e-evidence/api-read-RESOURCE.json | jq .
```

### Read (list)
```bash
curl -s http://localhost:PORT/api/RESOURCE \
  -H "Authorization: Bearer $TOKEN" \
  | tee e2e-evidence/api-list-RESOURCE.json | jq .
```

### Update
```bash
curl -s -X PUT http://localhost:PORT/api/RESOURCE/$RESOURCE_ID \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"name": "Updated Item", "description": "Modified by validation"}' \
  | tee e2e-evidence/api-update-RESOURCE.json | jq .
```

### Verify update persisted
```bash
curl -s http://localhost:PORT/api/RESOURCE/$RESOURCE_ID \
  -H "Authorization: Bearer $TOKEN" \
  | tee e2e-evidence/api-read-after-update-RESOURCE.json | jq .
```

### Delete
```bash
curl -s -X DELETE http://localhost:PORT/api/RESOURCE/$RESOURCE_ID \
  -H "Authorization: Bearer $TOKEN" \
  | tee e2e-evidence/api-delete-RESOURCE.json | jq .
```

### Verify delete
```bash
curl -s -w "\nHTTP_STATUS:%{http_code}" \
  -H "Authorization: Bearer $TOKEN" \
  http://localhost:PORT/api/RESOURCE/$RESOURCE_ID \
  | tee e2e-evidence/api-read-after-delete-RESOURCE.txt
```

Expected: 404 response.

## Step 3: Authentication Testing

**Fast path**: `bash scripts/auth-test.sh --base-url=http://localhost:PORT --login-endpoint=/auth/login --protected-endpoint=/api/protected --email=user@example.com --password=validpassword --evidence-dir=e2e-evidence/api` runs the four core auth checks (valid login, authenticated request, invalid token → 401, no token → 401) and writes all evidence in one shot. The inline steps below remain the pedagogical source of truth.

### Valid credentials
```bash
TOKEN=$(curl -s -X POST http://localhost:PORT/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"email": "user@example.com", "password": "validpassword"}' \
  | tee e2e-evidence/api-auth-valid-login.json | jq -r '.token // .access_token')
echo "Token: $TOKEN"
```

### Authenticated request
```bash
curl -s -H "Authorization: Bearer $TOKEN" http://localhost:PORT/api/protected \
  | tee e2e-evidence/api-auth-protected-access.json | jq .
```

### Expired/invalid token
```bash
curl -s -w "\nHTTP_STATUS:%{http_code}" \
  -H "Authorization: Bearer invalid.token.here" \
  http://localhost:PORT/api/protected \
  | tee e2e-evidence/api-auth-invalid-token.txt
```

Expected: 401 with error message body.

### No token
```bash
curl -s -w "\nHTTP_STATUS:%{http_code}" http://localhost:PORT/api/protected \
  | tee e2e-evidence/api-auth-no-token.txt
```

Expected: 401.

### Wrong role (if RBAC exists)
```bash
curl -s -w "\nHTTP_STATUS:%{http_code}" \
  -H "Authorization: Bearer $USER_TOKEN" \
  http://localhost:PORT/api/admin-only \
  | tee e2e-evidence/api-auth-wrong-role.txt
```

Expected: 403.

## Step 4: Error Response Validation

Test that error responses include proper status codes AND meaningful bodies. This is the step that most often catches real bugs — a 422 response that APIs claim "works" because the status code is right, but has a useless body, silently breaks every frontend that reads it.

**Good error response** (actionable, machine-readable AND human-readable):
```json
{
  "error": "Validation failed",
  "errors": [
    {"field": "email", "message": "Invalid email format"},
    {"field": "password", "message": "Must be at least 8 characters"}
  ]
}
```

**Bad error responses** (all of these fail validation):
```json
{"error": 1008}                           // numeric code only, no message
{}                                         // empty object
{"errors": []}                             // empty errors array — validation said what?
{"message": "Something went wrong"}       // not actionable, no field info
```

The rule: a human reading the response should know what to fix. A frontend parsing the response should know which field is wrong.

```bash
# 400 — Bad request (missing required field)
curl -s -w "\nHTTP_STATUS:%{http_code}" -X POST http://localhost:PORT/api/RESOURCE \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $TOKEN" \
  -d '{}' \
  | tee e2e-evidence/api-error-400.txt

# 404 — Not found
curl -s -w "\nHTTP_STATUS:%{http_code}" \
  -H "Authorization: Bearer $TOKEN" \
  http://localhost:PORT/api/RESOURCE/nonexistent-id \
  | tee e2e-evidence/api-error-404.txt

# 422 — Validation error (invalid data)
curl -s -w "\nHTTP_STATUS:%{http_code}" -X POST http://localhost:PORT/api/RESOURCE \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"email": "not-an-email"}' \
  | tee e2e-evidence/api-error-422.txt
```

Every error response MUST include a human-readable message, not just a status code.

## Step 5: Pagination

```bash
# First page
curl -s "http://localhost:PORT/api/RESOURCE?limit=2&offset=0" \
  -H "Authorization: Bearer $TOKEN" \
  | tee e2e-evidence/api-pagination-page1.json | jq .

# Second page
curl -s "http://localhost:PORT/api/RESOURCE?limit=2&offset=2" \
  -H "Authorization: Bearer $TOKEN" \
  | tee e2e-evidence/api-pagination-page2.json | jq .
```

Verify:
- Page 1 and Page 2 return different items
- Total count (if included) is consistent
- Empty page returns empty array, not error

## Step 6: Rate Limiting (if applicable)

Skip this step unless the API docs mention rate limits, or you can see rate-limit middleware in the code (Express `express-rate-limit`, `@fastify/rate-limit`, Django's `ratelimit`, etc.). If rate limiting isn't configured, hammering the endpoint just produces noise.

```bash
for i in $(seq 1 20); do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:PORT/api/RESOURCE)
  echo "Request $i: $STATUS" | tee -a e2e-evidence/api-rate-limit-test.txt
done
```

If rate limiting exists, expect 429 status after the threshold with a `Retry-After` header. Without the header, clients don't know when to retry — that's a FAIL even if 429 is returned.

## Evidence Standards

**GOOD:** Full JSON response body saved to file, status code captured, response describes what data was returned.

**BAD:** "API returned 200" or "Request succeeded" without saving the response body.

Every evidence file must contain the FULL response body — not just a status code.

## PASS Criteria Template

- [ ] Health endpoint returns 200 with expected body structure
- [ ] Create returns 201 with created resource (including ID)
- [ ] Read returns 200 with correct resource data
- [ ] Update returns 200 with modified data, changes persist on re-read
- [ ] Delete returns 200/204, subsequent read returns 404
- [ ] Auth: valid credentials return token, invalid return 401
- [ ] Auth: protected endpoints reject unauthenticated requests
- [ ] Error responses include status code AND human-readable message body
- [ ] Pagination returns correct subsets with consistent totals
- [ ] Response times under 500ms for single-resource operations
