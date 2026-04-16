# ValidationForge Verdict — `demo/python-api`

- **Target:** `demo/python-api/app.py` (Flask 3.1.3, Python 3.12.13)
- **Run:** 2026-04-16 19:00 America/New_York
- **Host:** `http://localhost:5099` (PORT=5099 to avoid macOS AirPlay on :5000)
- **Evidence dir:** `e2e-evidence/python-api-260416-1900/`
- **Pipeline:** RESEARCH → PLAN → PREFLIGHT → EXECUTE → ANALYZE → VERDICT (all phases ran)
- **Overall verdict:** **PASS (6/6 journeys)**

## Phase summary

| Phase | Result | Notes |
|-------|--------|-------|
| 0. Research | PASS | Read `app.py`, `requirements.txt`, `README.md`; 6 journeys + PASS criteria discovered in README |
| 1. Plan | PASS | Evidence dir created `e2e-evidence/python-api-260416-1900/` |
| 2. Preflight | PASS | Python 3.12.13, flask 3.1.3 installed in `.venv`, server bound to :5099, `/health` → 200 |
| 3. Execute | PASS | 6 journeys invoked via `curl`; body + headers captured per step |
| 4. Analyze | PASS | Every PASS criterion verified against captured body (see per-journey citations below) |
| 5. Verdict | PASS | This document |

## Per-journey verdicts

### J1 — Health Check → PASS
- **PASS criteria (README):** HTTP 200; body contains `"status":"ok"`; `items_count` non-negative int.
- **Evidence:** `step-01-health-response.json`, `step-01-health-response.headers`
- **Citations:**
  - Status line: `HTTP/1.1 200 OK` (headers)
  - `Content-Type: application/json` (headers)
  - Body: `{"items_count":3,"status":"ok"}` — `status=ok`, `items_count=3` (non-negative int) ✓

### J2 — List Items → PASS
- **PASS criteria:** HTTP 200; `items` array ≥1; each item has `id,name,description,in_stock`; `total` = `items.length`.
- **Evidence:** `step-02-list-items.json`, `step-02-list-items.headers`
- **Citations:**
  - HTTP 200 captured via `-w HTTP_CODE=%{http_code}`
  - jq: `total=3`, `items_len=3`, `keys_per_item=["description","id","in_stock","name"]` ✓ (all 4 required keys present, total matches length)

### J3 — Create Item (happy path) → PASS
- **PASS criteria:** `POST /api/items` → 201; body has `item.id`; subsequent list contains the new item.
- **Evidence:** `step-03-create-item-request.json`, `step-04-create-item-response.json`, `step-05-list-items-after-create.json`
- **Citations:**
  - Request: `{"name":"Widget C","description":"Created by validate","in_stock":true}`
  - Response HTTP 201; body: `{"item":{"description":"Created by validate","id":4,"in_stock":true,"name":"Widget C"}}` — `id=4` assigned ✓
  - Persistence: list-after-create shows `total=4`, last item `id=4 name="Widget C"` ✓

### J4 — Create Item (validation error) → PASS
- **PASS criteria:** `POST /api/items` missing `name` → 400; body has `error` key.
- **Evidence:** `step-06-create-item-bad-request.json`
- **Citations:**
  - HTTP 400 captured via `-w`
  - Body: `{"error":"Field 'name' is required and must be non-empty"}` — `has_error_key=true` ✓

### J5 — Get Item by ID → PASS
- **PASS criteria:** `GET /api/items/1` → 200; `item.id === 1`.
- **Evidence:** `step-07-get-item-1.json`
- **Citations:**
  - HTTP 200 captured
  - Body: `{"item":{"description":"First demo item","id":1,"in_stock":true,"name":"Widget A"}}` — `id=1 name="Widget A"` ✓

### J6 — 404 on Unknown ID → PASS
- **PASS criteria:** `GET /api/items/9999` → 404; body has `error` key.
- **Evidence:** `step-08-get-item-404.json`
- **Citations:**
  - HTTP 404 captured
  - Body: `{"error":"Item with id 9999 not found"}` — `has_error_key=true` ✓

## Evidence integrity

All evidence files are non-empty (see `evidence-inventory.txt`). Smallest payload: `step-08-get-item-404.json` at 40 bytes — a legitimate minimal JSON error body.

## Iron-rules compliance

| Rule | Status |
|------|--------|
| 1. Fix the real system if it fails | N/A (no failures) |
| 2. No mocks/stubs/test doubles/test files created | ✓ Only the Flask app was run, with `curl` against real endpoints |
| 3. Every PASS cites specific evidence | ✓ See citations above |
| 4. Never skip preflight | ✓ Preflight completed before Execute |
| 5. Max 3 fix attempts per journey | N/A (no failures) |
| 6. Never partial verdict | ✓ All 6 journeys reported |
| 7. No reused evidence from prior runs | ✓ Fresh subdirectory `python-api-260416-1900` |
| 8. Compilation ≠ validation | ✓ Server was actually booted and hit with real HTTP calls |

## Open questions

The seeded-bug scenario mentioned in `README.md` ("ships with intentional validation scenarios ... a seeded bug") is not present in the current `app.py` — all 6 journeys PASS cleanly. The README may describe an intended future scenario. If a seeded bug is expected, confirm which journey should FAIL.

## Server lifecycle

- Started: PID 21640 via `nohup .venv/bin/python app.py` (PORT=5099)
- Stopped: `kill 21640`; `lsof -ti:5099` confirms port free
- Server log preserved at `server.log`
