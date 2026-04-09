# ValidationForge Demo: Python Flask API

A minimal Flask API used as the **Python platform validation target** for the ValidationForge end-to-end pipeline.

## Purpose

This API exists to prove that ValidationForge's `/validate` pipeline works against real Python HTTP services — not just Next.js. It ships with intentional validation scenarios (happy-path PASS journeys and a seeded bug) so the pipeline can demonstrate evidence capture, root-cause analysis, and the fix loop.

## Endpoints

| Method | Path | Status | Description |
|--------|------|--------|-------------|
| `GET` | `/health` | 200 | Liveness check — confirms the server is up |
| `GET` | `/api/items` | 200 | List all items |
| `POST` | `/api/items` | 201 / 400 | Create a new item |
| `GET` | `/api/items/<id>` | 200 / 404 | Fetch a single item by integer ID |

### GET /health

Always returns `200 OK` while the process is running. Used by the preflight check.

```bash
curl -s http://localhost:5000/health | jq .
```

```json
{
  "status": "ok",
  "items_count": 3
}
```

### GET /api/items

Returns the complete in-memory item list plus a `total` count.

```bash
curl -s http://localhost:5000/api/items | jq .
```

```json
{
  "items": [
    { "id": 1, "name": "Widget A", "description": "First demo item",  "in_stock": true  },
    { "id": 2, "name": "Widget B", "description": "Second demo item", "in_stock": false },
    { "id": 3, "name": "Gadget X", "description": "Third demo item",  "in_stock": true  }
  ],
  "total": 3
}
```

### POST /api/items

Creates a new item. `name` is required; `description` and `in_stock` are optional.

```bash
curl -s -X POST http://localhost:5000/api/items \
  -H "Content-Type: application/json" \
  -d '{"name": "Widget C", "description": "New item", "in_stock": true}' | jq .
```

**201 Created:**
```json
{
  "item": {
    "id": 4,
    "name": "Widget C",
    "description": "New item",
    "in_stock": true
  }
}
```

**400 Bad Request (missing name):**
```json
{ "error": "Field 'name' is required and must be non-empty" }
```

### GET /api/items/\<id\>

```bash
curl -s http://localhost:5000/api/items/1 | jq .
```

**200 OK:**
```json
{
  "item": { "id": 1, "name": "Widget A", "description": "First demo item", "in_stock": true }
}
```

**404 Not Found:**
```json
{ "error": "Item with id 99 not found" }
```

## How to Run

### Prerequisites

- Python 3.11+
- `pip` (or a virtual environment manager)

### Quick Start

```bash
cd demo/python-api

# Create and activate a virtual environment (recommended)
python3 -m venv .venv
source .venv/bin/activate   # Windows: .venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Start the server
python app.py
```

The server listens on `http://localhost:5000`.

### Verify It's Running

```bash
curl -s http://localhost:5000/health
# → {"status": "ok", "items_count": 3}
```

## What the Validation Pipeline Should Verify

ValidationForge's `/validate` command runs these journeys against the live server:

### Journey 1 — Health Check (Preflight Gate)

**PASS criteria:**
- `GET /health` returns HTTP 200
- Response body contains `"status": "ok"`
- `items_count` is a non-negative integer

**Evidence captured:**
- `e2e-evidence/api/step-01-health-response.json` — full response body
- Headers confirming `Content-Type: application/json`

### Journey 2 — List Items

**PASS criteria:**
- `GET /api/items` returns HTTP 200
- Response body contains `"items"` array with at least one entry
- Each item has `id`, `name`, `description`, `in_stock` fields
- `total` matches `items.length`

**Evidence captured:**
- `e2e-evidence/api/step-02-list-items.json` — full items payload

### Journey 3 — Create Item (Happy Path)

**PASS criteria:**
- `POST /api/items` with valid JSON body returns HTTP 201
- Response body contains `"item"` object with a new `id`
- Subsequent `GET /api/items` shows the new item in the list

**Evidence captured:**
- `e2e-evidence/api/step-03-create-item-request.json` — request body
- `e2e-evidence/api/step-04-create-item-response.json` — 201 response
- `e2e-evidence/api/step-05-list-items-after-create.json` — list confirming persistence

### Journey 4 — Create Item (Validation Error)

**PASS criteria:**
- `POST /api/items` with missing `name` field returns HTTP 400
- Response body contains `"error"` key with a descriptive message

**Evidence captured:**
- `e2e-evidence/api/step-06-create-item-bad-request.json` — 400 response body

### Journey 5 — Get Item by ID

**PASS criteria:**
- `GET /api/items/1` returns HTTP 200
- Response body `item.id === 1`

**Evidence captured:**
- `e2e-evidence/api/step-07-get-item-1.json` — single item response

### Journey 6 — 404 on Unknown ID

**PASS criteria:**
- `GET /api/items/9999` returns HTTP 404
- Response body contains `"error"` key

**Evidence captured:**
- `e2e-evidence/api/step-08-get-item-404.json` — 404 response body

## Error Handling Contract

All error responses use consistent JSON:

```json
{ "error": "<human-readable message>" }
```

The pipeline treats any non-JSON error response as a **FAIL** — it signals a configuration or server crash, not a handled error.

## Relation to the Demo Scenario

This API mirrors the server-side role in the [DEMO-SCENARIO.md](../DEMO-SCENARIO.md) Next.js example but is a standalone Python service. The key validation insight is the same: unit tests with mocked HTTP clients cannot catch a contract mismatch between an API and its callers. Only calling the **real** running server reveals whether the contract holds.

The `flask` framework was chosen because it's the minimal-ceremony option for a demo target — one file, one dependency, easy to read and reason about.
