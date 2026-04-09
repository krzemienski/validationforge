# Phase 0: Research — Python Flask API Platform Validation

**System:** demo/python-api (Flask 3.x, Python 3.11+, in-memory store)
**Date:** 2026-04-08
**Phase:** 0 — Research
**Validator:** ValidationForge research-validation protocol

---

## Step 1: Validation Scope

**System:** demo/python-api — a minimal Flask API serving an in-memory items collection. One source file (`app.py`), one dependency (`flask>=3.0`), four endpoints, zero authentication.

**Domain:** API Service

**Platforms:** Python HTTP API (Flask 3.x, REST conventions, JSON responses)

**User types:**
- Anonymous API consumers (no authentication required)
- Internal callers (other services or the ValidationForge pipeline itself)

**Critical paths:**
- Server liveness (`GET /health`) — pipeline gate, must pass before any journey runs
- Full items list (`GET /api/items`) — primary read operation
- Item creation (`POST /api/items`) — primary write operation, validates required fields
- Single item fetch (`GET /api/items/<id>`) — ID-scoped read, must surface 404 for unknowns

**Compliance requirements:**
- RFC 9110 (HTTP Semantics) — correct status codes per method and outcome
- JSON:API informal conventions — consistent `{"error": "..."}` shape on all error responses
- Content-Type hygiene — every response must declare `application/json`
- No PII / GDPR concerns (demo data only, ephemeral in-memory store)

---

## Step 2: Applicable Standards

### 2.1 HTTP Status Code Correctness (RFC 9110)

| Scenario | Required Status | Rationale |
|----------|----------------|-----------|
| Successful GET | 200 OK | Resource exists and is returned |
| Successful POST (created) | 201 Created | New resource was created |
| Bad request body / missing fields | 400 Bad Request | Client sent malformed or incomplete data |
| Resource not found | 404 Not Found | ID does not exist in the store |
| Method not supported on route | 405 Method Not Allowed | Verb not registered for the route |

**Source:** https://httpwg.org/specs/rfc9110.html#status.codes

### 2.2 Content-Type Requirements

Every response must include `Content-Type: application/json` — whether success or error.
A bare status code without a JSON body is insufficient and fails the evidence standard.

| Requirement | Verification |
|-------------|-------------|
| Success responses include `Content-Type: application/json` | `curl -v` header capture |
| Error responses include `Content-Type: application/json` | `curl -v` on 400/404/405 |
| Response body is parseable JSON | Pipe through `jq` — non-zero exit signals failure |

**Source:** https://www.rfc-editor.org/rfc/rfc4627 (JSON media type), Flask docs

### 2.3 Error Response Contract

All error responses must follow the API's documented contract:

```json
{ "error": "<human-readable message>" }
```

A 404 that returns an HTML page (Flask default), empty body, or non-JSON is a **FAIL**.
The pipeline must verify `"error"` key presence in every non-2xx response body.

### 2.4 Input Validation Standards

| Field | Rule | Expected Behavior |
|-------|------|------------------|
| `name` (POST body) | Required, non-empty string | Missing → 400 with `"error"` message |
| Body absent or non-JSON | Invalid Content-Type or empty | 400 with `"error": "Request body must be valid JSON"` |
| `item_id` path param | Integer; non-existent value | 404 with `"error": "Item with id N not found"` |

### 2.5 Response Shape Consistency

| Endpoint | Expected Shape | Key Fields |
|----------|---------------|------------|
| `GET /health` | `{"status": "ok", "items_count": N}` | `status`, `items_count` |
| `GET /api/items` | `{"items": [...], "total": N}` | `items` (array), `total` (int) |
| `POST /api/items` | `{"item": {...}}` | `item.id`, `item.name`, `item.description`, `item.in_stock` |
| `GET /api/items/<id>` | `{"item": {...}}` | `item.id` must match requested ID |

### 2.6 REST Idempotency and State Consistency

| Behavior | Requirement |
|----------|------------|
| POST creates persist | Item created via POST must appear in subsequent `GET /api/items` |
| ID assignment is sequential | Created item `id` must be numeric and greater than existing IDs |
| In-memory store is consistent per session | Counts in `/health` and `/api/items` must agree |

---

## Step 3: Available Validation Tools

| Category | Tool | Available | Notes |
|----------|------|-----------|-------|
| HTTP client | curl | ✅ | `/usr/bin/curl` — primary validation tool |
| JSON processor | jq | ✅ | Available for parsing and validating JSON responses |
| Python runtime | python3 | ✅ | `/opt/homebrew/bin/python3` — Flask server runtime |
| Package manager | pip3 | ✅ | To install Flask in virtualenv |
| Process management | Bash | ✅ | Start/stop Flask with `python app.py &` |
| API testing | curl + bash | ✅ | Full CRUD validation without additional tooling |
| Browser automation | Not applicable | N/A | API-only; no HTML rendering |
| iOS simulator | Not applicable | N/A | Not needed for API |

**Platform indicators detected in demo/python-api:**
- `app.py` → Flask application entry point
- `requirements.txt` → `flask>=3.0,<4.0`
- No `package.json`, no `*.xcodeproj` — pure Python API
- No authentication middleware → public API, no token handling required
- No database → in-memory `_items` list, no migration or seed scripts needed

**Platform classification: API Service (Python Flask 3.x, REST, JSON)**

---

## Step 4: Standards-to-Skills Mapping

| Standard / Requirement | ValidationForge Skill | Evidence Type |
|-----------------------|----------------------|---------------|
| Server starts and responds | preflight | `curl /health` → 200 + JSON body |
| `GET /health` returns correct shape | api-validation | Full JSON response body |
| `GET /api/items` returns items array | api-validation | Full JSON response body |
| `POST /api/items` creates item (201) | api-validation | 201 response + `item.id` in body |
| Created item persists in list | api-validation | Subsequent `GET /api/items` response |
| `POST /api/items` missing name → 400 | api-validation | 400 response + `"error"` key |
| `GET /api/items/<id>` returns item | api-validation | Full JSON with `item.id` matching |
| `GET /api/items/9999` → 404 | api-validation | 404 response + `"error"` key |
| Method not allowed → 405 | api-validation | 405 response + `"error"` key |
| All responses include `Content-Type: application/json` | api-validation | `curl -v` header output |
| Items count consistent across endpoints | api-validation | Compare `/health` `items_count` to `/api/items` `total` |

---

## Step 5: Research Report

### Executive Summary

We are validating `demo/python-api`, a minimal Flask 3.x REST API with four endpoints and no authentication. The primary validation risks are: incorrect HTTP status codes on error paths (400/404/405), missing JSON body on error responses (Flask's default error handlers return HTML unless overridden), Content-Type header absence, and state consistency failures (created items not appearing in the list). The recommended approach is a linear CRUD journey sequence: health preflight → list read → create (happy path) → list re-read (persistence verification) → create (validation error) → single-item read → 404 path → 405 path. All validation uses `curl` with full response capture — no browser automation required.

### Applicable Standards (prioritized)

1. **HTTP Status Codes (RFC 9110)** — 200/201/400/404/405 must be semantically correct
2. **Content-Type: application/json** — required on every response, success and error
3. **Error body contract** — all non-2xx must return `{"error": "..."}` (not HTML, not empty)
4. **`GET /health` shape** — `{"status": "ok", "items_count": N}` with `N` ≥ 0
5. **`GET /api/items` shape** — `{"items": [...], "total": N}` where `total === items.length`
6. **POST persistence** — created item appears in subsequent `GET /api/items`
7. **400 validation** — missing `name` field triggers 400 with descriptive error message
8. **404 precision** — unknown `item_id` returns 404 with `item_id` cited in error message
9. **405 handling** — unsupported HTTP method returns 405 with JSON body (not HTML)

### Coverage Strategy

| Risk Area | Priority | Skill | Estimated Effort |
|-----------|----------|-------|-----------------|
| Server starts (preflight) | P0 | preflight | Low |
| Health check shape | P0 | api-validation | Low |
| List items response | P0 | api-validation | Low |
| Create item (happy path) | P0 | api-validation | Low |
| Create item persists | P0 | api-validation | Low |
| Create item (missing name → 400) | P0 | api-validation | Low |
| Get item by ID (200) | P1 | api-validation | Low |
| Get item by ID (unknown → 404) | P1 | api-validation | Low |
| Method not allowed (405) | P1 | api-validation | Low |
| Content-Type on all responses | P1 | api-validation | Low |
| Count consistency across endpoints | P2 | api-validation | Low |

### Recommended Validation Plan Inputs

- **Journeys to validate:** 7 (Health, List Items, Create Happy Path, Create Error, Get by ID, 404 Path, 405 Path)
- **Platforms to cover:** Python Flask API (curl-based HTTP validation)
- **Standards to verify:** RFC 9110 status codes, Content-Type hygiene, JSON error contract, POST persistence
- **Tools to use:** curl (HTTP requests), jq (JSON parsing and field extraction), python3 (server runtime)

### Sources

1. https://httpwg.org/specs/rfc9110.html#status.codes — RFC 9110 HTTP status code semantics (200, 201, 400, 404, 405 requirements)
2. https://flask.palletsprojects.com/en/3.1.x/errorhandling/ — Flask custom error handlers (JSON error response pattern)
3. https://flask.palletsprojects.com/en/3.1.x/api/#flask.Flask.route — Flask routing and method validation
4. https://www.rfc-editor.org/rfc/rfc4627 — JSON media type and `application/json` Content-Type requirement
5. demo/python-api/README.md — Documented PASS criteria for all 6 canonical journeys (authoritative spec for this target)
