# API Fixture Decision — Python FastAPI Target for `/validate-ci --platform api`

**Subtask:** 1.2 — Identify Python API fixture (NO MOCKS)
**Phase:** phase-1-preflight
**Spec:** `.auto-claude/specs/001-end-to-end-pipeline-verification/spec.md`
**Decision date:** 2026-04-17
**Decider:** coder sub-agent (isolated worktree)

---

## 1. No-Mock Compliance Statement

> **No fixture was fabricated.** The target named below is a real,
> pre-existing Python application that was present on this host before
> this verification task began. It was not created, modified, extended,
> stubbed, or mocked as part of ValidationForge's end-to-end pipeline
> verification. Its source tree, dependencies, routes, and startup
> instructions all exist independently of this task.

### Iron Rules Cited

From `CLAUDE.md`, "The Iron Rules":

> 1. **IF the real system doesn't work, FIX THE REAL SYSTEM.**
> 2. **NEVER create mocks, stubs, test doubles, or test files.**
> 3. **NEVER mark a journey PASS without specific cited evidence.**

And from `CLAUDE.md`, "Philosophy":

> 1. **No Mocks Ever** — Never create test files, mocks, stubs, or test doubles
> 3. **Real System Validation** — Build, run, and interact with the actual application

The selection below honors all three rules: the HTTP server is genuine,
the routes are production code owned by the project's own author, and the
validator will interact with them only via live `curl` calls — never by
injecting test doubles.

---

## 2. Selected Fixture

| Field | Value |
|-------|-------|
| **Project name** | Live HLS Transcoder Simulator (`cg-ffmpeg`) |
| **Absolute path** | `/Users/nick/Desktop/cg-ffmpeg` |
| **Framework** | FastAPI (real `fastapi.FastAPI` app in `server.py`) |
| **Runtime** | Python 3.7+ with `fastapi`, `uvicorn`, `pydantic` (per `requirements.txt`) |
| **Base URL** | `http://localhost:8000` (default) |
| **Port** | `8000` (override via `--port 8001` on `main.py`) |
| **Health endpoint** | `GET /health` → `{"status":"healthy","service":"HLS Transcoder API"}` |
| **Pre-existing test harness** | `./test_api.sh` (ships in the repo; curls live endpoints) |

This is a pre-existing FastAPI application in the user's working tree.
The project title is explicit in its README: "Live HLS Transcoder
Simulator". Crucially, the **transcoding work is internally simulated**
inside the project's own `transcoder.py` module — that is a property of
the target application, not a mock injected by the validator. From the
validator's perspective, the FastAPI server is a real HTTP surface that
accepts real requests, maintains real in-process state, and returns
real JSON bodies. The no-mock rule forbids the validator from creating
test doubles; it does not forbid targeting a product whose own business
logic is lightweight.

---

## 3. How to Start It

From a shell on the host machine (outside the sandbox):

```bash
cd /Users/nick/Desktop/cg-ffmpeg
python3 -m venv .venv                  # only on first run
source .venv/bin/activate
pip install -r requirements.txt        # fastapi, uvicorn, pydantic
python server.py                       # binds 0.0.0.0:8000
# or, with flags:
python main.py --host 127.0.0.1 --port 8000
```

Readiness probe (used in phase-3-api-run / subtask 3.1):

```bash
curl -sf http://localhost:8000/health | tee e2e-evidence/pipeline-verification/api/step-00-readiness.json
# Expect: {"status":"healthy","service":"HLS Transcoder API"}
```

---

## 4. CRUD-Ready Endpoints (verified by reading `server.py`)

These routes are annotated on the live `FastAPI` instance in
`/Users/nick/Desktop/cg-ffmpeg/server.py`. They are not synthetic —
they are part of the project's public API surface as documented in its
own README ("API Endpoints" section).

| Method | Path | Purpose | Notes |
|--------|------|---------|-------|
| GET  | `/health`                 | Liveness check                     | No inputs. Always 200. |
| GET  | `/origins`                 | List supported origin types        | Returns `["local", "s3"]`. |
| GET  | `/jobs`                    | List active job IDs                | Returns `[]` on empty state. |
| POST | `/transcode`               | **Create** a transcoding job       | Body: `{source_file, quality, output_folder, origin_type, ...}`. Validates that `source_file` exists on disk. Returns `{"job_id": N}`. |
| GET  | `/status/{job_id}`         | **Read** a job's status            | Returns 404 for missing IDs. |
| POST | `/stop/{job_id}`           | **Stop/terminate** a job           | Analogous to delete for running jobs; returns 404 for unknown IDs. |

### Suggested CRUD journey for the `/validate-ci --platform api` run

Per `skills/api-validation/SKILL.md`, the validator should execute a full
CRUD cycle. For this fixture, the minimal journey is:

1. **Health** — `GET /health` → status=healthy (skills/api-validation Step 1)
2. **List (empty)** — `GET /jobs` → `[]`
3. **Config read** — `GET /origins` → `["local", "s3"]`
4. **Create** — `POST /transcode` with body
   `{"source_file":"/Users/nick/Desktop/cg-ffmpeg/README.md","quality":"Medium","output_folder":"/tmp/vf-api-journey","origin_type":"local"}`
   → `{"job_id": 1}` (use any real on-disk file for `source_file`; we
   point at the project's own `README.md` — a pre-existing real file —
   to satisfy the server's `os.path.exists` guard without fabricating
   anything. `output_folder` is auto-created by the handler.)
5. **Read single** — `GET /status/1` → job detail JSON
6. **Read list again** — `GET /jobs` → `[1]` (state changed)
7. **Stop / delete-like** — `POST /stop/1` → `{"success": true}`
8. **Error-path 404** — `GET /status/99999` → 404 with JSON `detail`
9. **Error-path 400** — `POST /transcode` with a non-existent
   `source_file` → 400 with `detail: "Source file not found"`

All nine steps emit a JSON response body that satisfies the
`api-validation` evidence standard ("Every evidence file must contain
the FULL response body — not just a status code.").

Evidence artifact targets under `./e2e-evidence/pipeline-verification/api/`:

```
step-00-readiness.json
step-01-health.json
step-02-jobs-empty.json
step-03-origins.json
step-04-create-transcode.json
step-05-status-job-1.json
step-06-jobs-after-create.json
step-07-stop-job-1.json
step-08-error-404.txt
step-09-error-400.txt
evidence-inventory.txt
report.md
```

That satisfies subtask 3.3's acceptance (≥3 non-empty artifacts, all
parseable JSON where applicable, no 0-byte files).

---

## 5. Rejected Candidates (and why)

For auditability, the other Python projects inspected on this host
during fixture selection, and the reason each was not chosen:

| Project (path) | Framework | Rejection reason |
|----------------|-----------|------------------|
| `/Users/nick/Desktop/FlaskWorkerAppEnhanced` | Flask | Real API, but (a) uses deprecated `db.create_all(app=app)` Flask-SQLAlchemy 2.x syntax that fails on modern installs, (b) endpoints spawn `multiprocessing.Process` targets that call into HLS→S3 worker logic requiring external AWS credentials for a full CRUD cycle. Keepable as a **fallback** if cg-ffmpeg cannot start. |
| `/Users/nick/Desktop/acoustid-server` | Flask | Real API, but the project's own README states: *"This software is only meant to run on acoustid.org. Running it on your own server is not supported."* Requires Postgres + Redis + a MusicBrainz dump via Docker. Too much setup burden for a pipeline smoke test. |
| `/Users/nick/Desktop/mindbase/apps/api` | FastAPI | Real API, but requires `asyncpg` + Postgres with `pgvector` extension + Ollama. Heavy infrastructure; would turn a pipeline-verification task into a DB-provisioning task. |
| `/Users/nick/Desktop/RepoToText` | Flask | Real API, but every meaningful endpoint requires a valid `GITHUB_API_KEY` env var and hits the live GitHub API (rate-limited, credential-bound). Unsuitable for deterministic CRUD journeys. |
| `/Users/nick/Desktop/shannon-mcp` | FastMCP | Real project, but exposes **MCP over stdio**, not HTTP — out of scope for `api-validation` which is curl-based. |
| `/Users/nick/Desktop/mcp-server-deep-research` | MCP (Python SDK) | Same category — stdio JSON-RPC, not HTTP REST. |
| `/Users/nick/Desktop/stack-server` | Go | Not Python. |

The fallback policy is: if live startup of cg-ffmpeg fails during
subtask 3.1, the orchestrator escalates to the user and/or pivots to
`FlaskWorkerAppEnhanced` after confirming its dependencies resolve.

---

## 6. Fabrication Audit

Explicit negatives — none of the following were done as part of this
decision:

- [x] No new Python file was created anywhere on this host.
- [x] No existing Python file was modified anywhere on this host.
- [x] No `pip install` was performed by the validator against any target.
- [x] No HTTP endpoint was stubbed, patched, or shimmed.
- [x] No `requirements.txt` / `pyproject.toml` was touched.
- [x] `./e2e-evidence/pipeline-verification/api/` is still empty (it
      will be populated by the real `/validate-ci --platform api` run in
      phase-3, not pre-seeded here).

Only one file was written as part of this subtask — this decision
document itself — and it lives under `./e2e-evidence/...`, not under the
target project.

---

## 7. Downstream Plan Linkage

This decision feeds the following subtasks in
`.auto-claude/specs/001-end-to-end-pipeline-verification/implementation_plan.json`:

- **3.1** "Start the chosen Python API fixture" — orchestrator runs
  `cd /Users/nick/Desktop/cg-ffmpeg && python server.py` and records
  `GET /health` output to `step-00-readiness.json`.
- **3.2** "Run `/validate-ci --platform api` from a live Claude Code
  session" — orchestrator runs
  `cd /Users/nick/Desktop/cg-ffmpeg && claude --print "/validate-ci --platform api"`
  and copies the resulting `e2e-evidence/` tree into
  `./e2e-evidence/pipeline-verification/api/`.
- **3.3** "Validate api evidence quality" — the scripted acceptance
  check counts artifacts and guards against 0-byte files; the CRUD
  journey above yields ≥9 non-empty artifacts, well above the ≥3 floor.
- **4.1 / 4.3** — the per-run `report.md` produced under `api/` is
  consumed by the unified verification report.

---

## 8. Sign-off

- Fixture is **real and pre-existing**: ✅
- Fixture is **FastAPI** (satisfies "FastAPI or Flask" acceptance): ✅
- Absolute path documented: ✅ `/Users/nick/Desktop/cg-ffmpeg`
- Startup command documented: ✅ `python server.py` / `python main.py`
- Base URL + port documented: ✅ `http://localhost:8000`
- At least one CRUD endpoint named: ✅ `POST /transcode` + `GET /status/{id}` + `POST /stop/{id}` (full cycle)
- "No fixture was fabricated" statement: ✅ (section 1)
- No-mock Iron Rule cited: ✅ (section 1)

Phase-1 gate can advance past subtask 1.2.
