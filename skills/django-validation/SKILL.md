---
name: django-validation
description: "Use for validating Python web apps built with Django, Flask, or FastAPI. Runs an ordered protocol: check Python deps (pip freeze vs requirements.txt), system check (python manage.py check for Django), migrations up-to-date, server starts cleanly, health endpoint works, CRUD endpoints respond with correct JSON, auth flows (login/logout/protected routes), admin panel loads (Django only). Captures HTTP responses, migration state, and server logs as evidence. Reach for it on phrases like 'validate my Django app', 'check migrations', 'Flask validation', 'FastAPI endpoint check', 'django server test', or before shipping a Python web app change."
triggers:
  - "django framework testing"
  - "flask validation"
  - "django server check"
  - "migration validation"
  - "django endpoint testing"
  - "fastapi validation"
  - "python web app"
  - "python manage.py"
context_priority: standard
---

# Django / Flask Validation

## Prerequisites

| Requirement | How to verify |
|-------------|---------------|
| Python installed | `python --version` or `python3 --version` |
| pip available | `pip --version` |
| virtualenv activated (if used) | `which python` shows venv path |
| Dependencies installed | `pip install -r requirements.txt` |
| Environment variables set | Check `.env` or `export` for `SECRET_KEY`, `DATABASE_URL`, etc. |
| Database accessible | `python manage.py dbshell` (Django) or verify DB connection string |
| Migrations applied | `python manage.py showmigrations` (Django) |
| Evidence directory exists | `mkdir -p e2e-evidence` |

If using a virtual environment, activate it before starting the protocol. See
`references/setup-validation.md` for the full virtualenv bootstrap script.

## Step Overview

### Step 1: Install Dependencies

Install packages from `requirements.txt` (or via `pip-tools`) and capture the
pip log as evidence, grepping for a success marker.

> For the full `pip install`/`pip-sync` + tee + success-marker grep snippet plus the virtualenv bootstrap, see `references/setup-validation.md` — load this before Step 1 if you need the exact commands or the `Successfully installed` grep pattern; the same reference also covers Steps 2 and 3.

### Step 2: Django System Check

Run `python manage.py check` to catch configuration errors before booting the
server. For deployment readiness, add `--deploy`.

> For the `manage.py check` bash block with the "System check identified no issues" grep and the `--deploy` variant, see `references/setup-validation.md` — load it before Step 2 if you need the exact invocation; skip if `manage.py check` is already in muscle memory.

### Step 3: Migration Status

Confirm all database migrations are applied via `showmigrations`, then run
`migrate` for any outstanding items.

> For the `showmigrations` + unapplied-`[ ]` grep + `migrate` fallback sequence, see `references/setup-validation.md` — load it before Step 3 if you need the exact grep pattern for detecting pending migrations.

### Step 4: Start the Server

Boot the dev server in the background and wait briefly before probing it.
Django uses `manage.py runserver`; Flask uses `flask run` or `gunicorn` with
`FLASK_APP` / `FLASK_ENV` env vars.

> For the Django `runserver` and Flask `flask run`/gunicorn bash blocks (with `&`, `SERVER_PID`, sleep, and curl-readiness probe), see `references/server-startup.md` — load it before Step 4; skip only if you're running a framework already covered by your own startup script.

### Step 5: Health and Root Endpoint Check

`curl` the root, API root, and/or custom `/health/` endpoint; capture response
bodies and HTTP status codes.

> For the `curl -w HTTP_STATUS:%{http_code}` patterns for root, DRF API root, and custom `/health/` endpoints, see `references/server-startup.md` — load it during Step 5 if you need the exact curl flags for status + body capture.

### Step 6: Endpoint Testing with curl

Exercise GET list, POST create, GET detail, PUT update, and DELETE flows for
at least one primary resource. Chain the created resource ID through subsequent
requests, and verify DELETE is persistent by re-reading and expecting 404.

> For the per-verb curl invocations (list / create / detail / update / delete) with tee-to-JSON and the Python one-liner to extract the created resource ID, see `references/endpoint-testing-crud.md` — load this before Step 6 every time; the resource-ID chaining pattern is non-obvious and easy to break.

### Step 7: Authentication Testing

Obtain a DRF token or JWT access token from the login endpoint, store it in an
env var, and confirm unauthenticated requests to protected routes return 401
or 403.

> For the DRF token login, simplejwt access-token capture, and the unauthenticated-401/403 probe, see `references/auth-admin-testing.md` — load it during Step 7; skip if auth is outside this journey's scope.

### Step 8: Django Admin Check

Confirm `/admin/` returns 200 or a 302 login redirect. If needed, pre-seed a
superuser via `manage.py shell`.

> For the admin-200/302 curl check plus the `manage.py shell` superuser-seeding one-liner, see `references/auth-admin-testing.md` — load it during Step 8 if you're validating Django admin; skip for Flask/FastAPI.

### Step 9: Stop the Server

```bash
kill $SERVER_PID
wait $SERVER_PID 2>/dev/null
echo "Server stopped"
```

## Evidence Quality

**GOOD evidence description:**
> "django-list-RESOURCE.json contains a valid JSON array with 3 items, each having
> fields: id (integer), name (string), created_at (ISO timestamp). HTTP status 200.
> Response time 45ms."

**BAD evidence description:**
> "List endpoint returned data"

Every curl response MUST be saved to a file and the HTTP status code captured. Never
record only "it returned 200" — quote actual fields and values from the body.

## Common Failures

| Symptom | Likely Cause | Fix |
|---------|--------------|-----|
| `ImproperlyConfigured: SECRET_KEY` | Missing env var | Set `SECRET_KEY` in `.env` or environment |
| `OperationalError: no such table` | Migrations not applied | Run `python manage.py migrate` |
| `ModuleNotFoundError` | Dependency not installed or venv not activated | `pip install -r requirements.txt`; check `which python` |
| `CommandError: ... is not a valid migration module` | Corrupted migration file | Check migration files for syntax errors |
| `Address already in use` | Prior server process still running | `kill $(lsof -ti:8000)` |
| 500 on all endpoints | INSTALLED_APPS or middleware misconfiguration | Run `python manage.py check`; read full traceback in server log |
| 403 Forbidden on POST | CSRF token missing | Add `-H "X-CSRFToken: ..."` or use `@csrf_exempt` in tests |
| Django admin 404 | `django.contrib.admin` not in INSTALLED_APPS or urlconf missing | Check `settings.py` and `urls.py` |
| Flask `RuntimeError: Working outside of application context` | No `app.app_context()` | Wrap code in `with app.app_context():` |
| Empty JSON response body | View returns `HttpResponse()` without content | Return `JsonResponse(data)` or DRF `Response(data)` |

## PASS Criteria Template

- [ ] All dependencies install without errors (`pip install -r requirements.txt`)
- [ ] `python manage.py check` reports zero issues (Django only)
- [ ] All migrations applied — `showmigrations` shows no `[ ]` entries (Django only)
- [ ] Server starts and accepts connections on expected port
- [ ] Root or health endpoint returns 200 with non-empty body
- [ ] List endpoint returns 200 with valid JSON array
- [ ] Create endpoint returns 201 with new resource ID
- [ ] Detail endpoint returns 200 with correct resource data
- [ ] Update persists — re-read confirms changed fields
- [ ] Delete returns 204/200, subsequent read returns 404
- [ ] Unauthenticated requests to protected endpoints return 401 or 403
- [ ] Django admin accessible at `/admin/` (if applicable)
- [ ] No 500 errors or tracebacks in server log during validation
