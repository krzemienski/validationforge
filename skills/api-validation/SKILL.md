---
name: api-validation
description: >
  API platform validation through direct HTTP requests (curl). Captures full
  response bodies, headers, and status codes as evidence. Tests CRUD operations,
  authentication flows, error responses, pagination, and rate limiting.
---

# API Validation

## Prerequisites

| Requirement | How to verify |
|-------------|---------------|
| API server running | `curl -s http://localhost:PORT/health` |
| Database seeded (if applicable) | Check server startup logs for seed confirmation |
| Auth tokens available (if applicable) | Login endpoint returns token |
| `jq` installed | `jq --version` |
| Evidence directory exists | `mkdir -p e2e-evidence` |

## Step 1: Health Check

```bash
curl -s http://localhost:PORT/health \
  | tee e2e-evidence/api-health.json | jq .
```

Verify the response includes expected fields (status, version, uptime, etc.). A bare `200 OK` without body content is suspicious — document it.

## Step 2: CRUD Validation Pattern

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
curl -s -w "\nHTTP_STATUS:%{http_code}" http://localhost:PORT/api/RESOURCE/$RESOURCE_ID \
  -H "Authorization: Bearer $TOKEN" \
  | tee e2e-evidence/api-read-after-delete-RESOURCE.txt
```

Expected: 404 response.

## Step 3: Authentication Testing

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

Test that error responses include proper status codes AND meaningful bodies:

```bash
# 400 — Bad request (missing required field)
curl -s -w "\nHTTP_STATUS:%{http_code}" -X POST http://localhost:PORT/api/RESOURCE \
  -H 'Content-Type: application/json' \
  -d '{}' \
  | tee e2e-evidence/api-error-400.txt

# 404 — Not found
curl -s -w "\nHTTP_STATUS:%{http_code}" http://localhost:PORT/api/RESOURCE/nonexistent-id \
  | tee e2e-evidence/api-error-404.txt

# 422 — Validation error (invalid data)
curl -s -w "\nHTTP_STATUS:%{http_code}" -X POST http://localhost:PORT/api/RESOURCE \
  -H 'Content-Type: application/json' \
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

```bash
for i in $(seq 1 20); do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:PORT/api/RESOURCE)
  echo "Request $i: $STATUS" | tee -a e2e-evidence/api-rate-limit-test.txt
done
```

If rate limiting exists, expect 429 status after threshold with a `Retry-After` header.

## Evidence Standards

**GOOD:** Full JSON response body saved to file, status code captured, response describes what data was returned.

**BAD:** "API returned 200" or "Request succeeded" without saving the response body.

Every evidence file must contain the FULL response body — not just a status code.

## Common Failures

| Symptom | Likely Cause | Fix |
|---------|--------------|-----|
| Connection refused | Server not running or wrong port | Start server, check PORT env var |
| 500 Internal Server Error | Unhandled exception in route handler | Check server logs for stack trace |
| Empty response body | Handler returns status without body | Add response body to handler |
| CRUD read-after-delete returns 200 | Soft delete not filtering correctly | Check delete implementation and query filters |
| Auth token not returned | Login handler missing token generation | Check auth service and token signing |
| Pagination returns duplicates | Missing ORDER BY in query | Add deterministic ordering to list queries |

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
