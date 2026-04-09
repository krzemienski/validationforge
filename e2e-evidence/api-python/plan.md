# Validation Plan — Python Flask API Platform

**Platform:** API Service (Python Flask 3.x, REST, JSON, in-memory store)
**Target:** demo/python-api
**Total Journeys:** 7
**Estimated Duration:** 10–15 minutes
**Generated:** 2026-04-08
**Inputs from:** e2e-evidence/api-python/analysis.md (Phase 0 Research)

---

## Prerequisites

- [ ] Python 3.11+ available (`python3 --version`)
- [ ] pip/venv available (`python3 -m venv --help`)
- [ ] Flask installed in virtualenv (`pip install -r demo/python-api/requirements.txt`)
- [ ] Flask server starts successfully (`python demo/python-api/app.py &`)
- [ ] Server responds to health check (`curl http://localhost:5000/health` → HTTP 200)
- [ ] `curl` available for HTTP requests
- [ ] `jq` available for JSON parsing
- [ ] Evidence directory exists (`e2e-evidence/api-python/`)
- [ ] No test fixtures — validation uses the real running Flask server

---

## Journey Validation Sequence

---

### J1: Health Check — Server Liveness [P0]

**Entry Point:** Running Flask server at `http://localhost:5000`
**Skill:** preflight + api-validation
**Endpoint:** `GET /health`

**Steps:**
1. Start Flask server: `python demo/python-api/app.py &`
2. Wait 1–2 seconds for server to bind
3. Run `curl -s -v http://localhost:5000/health` to capture full response with headers
4. Save response body to evidence file
5. Verify `Content-Type: application/json` header present

**PASS Criteria:**
- [ ] `GET /health` returns HTTP 200 (not 404, 500, or connection refused)
- [ ] Response body contains `"status": "ok"` (exact string)
- [ ] Response body contains `"items_count"` key with a non-negative integer value
- [ ] `Content-Type` response header contains `application/json`
- [ ] Response body is valid JSON (parseable by `jq`)

**Evidence:**
- Full response body: `e2e-evidence/api-python/step-01-health-response.json`
- Headers capture: `e2e-evidence/api-python/step-01-health-headers.txt`

---

### J2: List Items — Read Collection [P0]

**Entry Point:** `http://localhost:5000/api/items`
**Skill:** api-validation
**Endpoint:** `GET /api/items`

**Steps:**
1. Run `curl -s http://localhost:5000/api/items`
2. Save full JSON response to evidence file
3. Extract `items` array length and `total` value
4. Compare `items.length` to `total` for consistency
5. Verify each item has required fields

**PASS Criteria:**
- [ ] `GET /api/items` returns HTTP 200
- [ ] Response body contains `"items"` key with a JSON array value
- [ ] `"items"` array contains at least 1 entry (seeded data: 3 items on fresh start)
- [ ] `"total"` key is present and equals `items.length`
- [ ] Each item in the array has fields: `id` (integer), `name` (string), `description` (string), `in_stock` (boolean)
- [ ] `Content-Type: application/json` header is present

**Evidence:**
- Full response body: `e2e-evidence/api-python/step-02-list-items.json`

---

### J3: Create Item — Happy Path [P0]

**Entry Point:** `http://localhost:5000/api/items`
**Skill:** api-validation
**Endpoint:** `POST /api/items`

**Steps:**
1. Send POST request with valid JSON body containing `name` field
2. Save 201 response to evidence file
3. Extract new item's `id` from response
4. Confirm `id` is an integer greater than the seeded IDs (> 3)

**PASS Criteria:**
- [ ] `POST /api/items` with body `{"name": "Validation Widget", "description": "Created by pipeline", "in_stock": true}` returns HTTP 201
- [ ] Response body contains `"item"` object with all four fields: `id`, `name`, `description`, `in_stock`
- [ ] `item.name` in response matches the submitted `name`
- [ ] `item.id` is a positive integer not present in the seeded data (id > 3)
- [ ] `Content-Type: application/json` header is present

**Evidence:**
- Create response: `e2e-evidence/api-python/step-03-create-item-response.json`

---

### J4: Create Item Persistence — State Consistency [P0]

**Entry Point:** `http://localhost:5000/api/items` (following J3)
**Skill:** api-validation
**Endpoint:** `GET /api/items`
**Dependency:** J3 must PASS (new item `id` extracted)

**Steps:**
1. Re-run `GET /api/items` after the create in J3
2. Compare new `total` to the pre-create value (should be `old_total + 1`)
3. Verify the newly created item appears in the `items` array

**PASS Criteria:**
- [ ] `GET /api/items` returns HTTP 200
- [ ] `"total"` value has increased by exactly 1 compared to J2's response
- [ ] The item created in J3 (by `id`) appears in the `"items"` array
- [ ] Item's `name` and `description` in the list match what was submitted in J3

**Evidence:**
- Post-create list: `e2e-evidence/api-python/step-04-list-after-create.json`

---

### J5: Create Item — Validation Error (Missing Name) [P0]

**Entry Point:** `http://localhost:5000/api/items`
**Skill:** api-validation
**Endpoint:** `POST /api/items`

**Steps:**
1. Send POST with body `{}` (no `name` field)
2. Save response to evidence file
3. Verify status code is 400
4. Verify response body contains `"error"` key with a descriptive message

**PASS Criteria:**
- [ ] `POST /api/items` with body `{}` returns HTTP 400 (not 200, not 500)
- [ ] Response body contains `"error"` key
- [ ] Error message is human-readable (not empty string, not null)
- [ ] Error message references the missing `name` field
- [ ] `Content-Type: application/json` header is present (not HTML error page)

**Evidence:**
- 400 response: `e2e-evidence/api-python/step-05-create-bad-request.json`

---

### J6: Get Item by ID — Single Resource Fetch [P1]

**Entry Point:** `http://localhost:5000/api/items/1`
**Skill:** api-validation
**Endpoint:** `GET /api/items/<id>`

**Steps:**
1. Run `curl -s http://localhost:5000/api/items/1`
2. Save full JSON response to evidence file
3. Verify `item.id` in response equals `1`

**PASS Criteria:**
- [ ] `GET /api/items/1` returns HTTP 200
- [ ] Response body contains `"item"` object
- [ ] `item.id` equals `1` (exact match to requested ID)
- [ ] `item.name`, `item.description`, and `item.in_stock` are all present and non-null
- [ ] `Content-Type: application/json` header is present

**Evidence:**
- Single item response: `e2e-evidence/api-python/step-06-get-item-1.json`

---

### J7: Get Item by ID — 404 Not Found [P1]

**Entry Point:** `http://localhost:5000/api/items/9999`
**Skill:** api-validation
**Endpoint:** `GET /api/items/<id>`

**Steps:**
1. Run `curl -s -w "\nHTTP_STATUS:%{http_code}" http://localhost:5000/api/items/9999`
2. Save response to evidence file
3. Verify HTTP status is 404
4. Verify body contains `"error"` key (not an HTML page)

**PASS Criteria:**
- [ ] `GET /api/items/9999` returns HTTP 404 (not 200, not 500)
- [ ] Response body contains `"error"` key with a descriptive message
- [ ] Error message references the unknown ID (`9999`)
- [ ] `Content-Type: application/json` header is present (Flask JSON error handler, not default HTML)
- [ ] Response body is valid JSON (parseable by `jq`)

**Evidence:**
- 404 response: `e2e-evidence/api-python/step-07-get-item-404.json`

---

## Execution Order Summary

| Order | Journey | Priority | Dependency | Endpoint | Estimated Time |
|-------|---------|----------|------------|----------|----------------|
| 1 | J1: Health Check | P0 | None (preflight) | `GET /health` | 1 min |
| 2 | J2: List Items | P0 | J1 PASS | `GET /api/items` | 1 min |
| 3 | J3: Create Item (Happy Path) | P0 | J1 PASS | `POST /api/items` | 1 min |
| 4 | J4: Create Persistence | P0 | J3 PASS | `GET /api/items` | 1 min |
| 5 | J5: Create Item (400 Error) | P0 | J1 PASS | `POST /api/items` | 1 min |
| 6 | J6: Get Item by ID | P1 | J1 PASS | `GET /api/items/1` | 1 min |
| 7 | J7: Get Item 404 | P1 | J1 PASS | `GET /api/items/9999` | 1 min |

**Stop rule:** If J1 (Health Check / Preflight) FAIL, stop pipeline immediately. The server is not running or not reachable. Report the specific error (connection refused vs. wrong status code vs. wrong Content-Type) with actionable fix instructions before proceeding.

---

## Evidence Directory Structure

```
e2e-evidence/api-python/
  analysis.md                         ← Phase 0 Research (this directory)
  plan.md                             ← This file (Phase 1 Plan)
  preflight-report.md                 ← Phase 2 Preflight results
  step-01-health-response.json        ← J1: GET /health body
  step-01-health-headers.txt          ← J1: Response headers (Content-Type verification)
  step-02-list-items.json             ← J2: GET /api/items body
  step-03-create-item-response.json   ← J3: POST /api/items 201 body
  step-04-list-after-create.json      ← J4: GET /api/items (post-create)
  step-05-create-bad-request.json     ← J5: POST /api/items 400 body
  step-06-get-item-1.json             ← J6: GET /api/items/1 body
  step-07-get-item-404.json           ← J7: GET /api/items/9999 404 body
  evidence-inventory.txt              ← Index of all evidence files
  VERDICT.md                          ← Phase 5 Verdict + Phase 6 Ship
```

---

## Phase Gate: Plan Approval

**Plan Status:** READY FOR EXECUTION

All 7 journeys have:
- Specific, binary PASS criteria (no "partially works")
- Observable evidence types (full JSON response bodies + HTTP status codes)
- Clear dependencies and execution order
- Stop rule for P0 preflight failure
- Content-Type verification on every journey

**API Validation Notes:**
- No authentication required — all endpoints are public
- In-memory store means test isolation is guaranteed on fresh server start
- No pagination (list returns all items)
- No rate limiting (demo target)
- All error responses use `{"error": "..."}` contract — any HTML response is an automatic FAIL

**Next Phase:** Preflight (Phase 2) → `e2e-evidence/api-python/preflight-report.md`
