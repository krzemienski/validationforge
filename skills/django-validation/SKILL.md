---
name: django-validation
description: >
  Django and Flask web application validation through server startup, database
  migration verification, curl endpoint testing, and Django admin checks.
  Captures HTTP responses, migration status, and server logs as evidence.
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

If using a virtual environment, activate it first:
```bash
# Create virtualenv
python -m venv venv

# Activate (Linux/macOS)
source venv/bin/activate

# Activate (Windows)
venv\Scripts\activate

# Verify activation
which python
```

## Step 1: Install Dependencies

```bash
# Install from requirements file
pip install -r requirements.txt 2>&1 | tee e2e-evidence/django-pip-install.txt

# Or with pip-tools
pip install pip-tools && pip-sync requirements.txt 2>&1 | tee e2e-evidence/django-pip-install.txt
```

Check result:
```bash
if grep -qE "Successfully installed|already satisfied" e2e-evidence/django-pip-install.txt; then
  echo "PASS: Dependencies installed"
else
  echo "FAIL: pip install failed — check requirements.txt and Python version"
  cat e2e-evidence/django-pip-install.txt
  exit 1
fi
```

## Step 2: Django System Check

Run Django's built-in system check to catch configuration errors before starting:

```bash
python manage.py check 2>&1 | tee e2e-evidence/django-check.txt
```

Check result:
```bash
if grep -q "System check identified no issues" e2e-evidence/django-check.txt; then
  echo "PASS: Django system check clean"
else
  echo "FAIL: Django system check found issues"
  cat e2e-evidence/django-check.txt
  exit 1
fi
```

For deployment-readiness check:
```bash
python manage.py check --deploy 2>&1 | tee e2e-evidence/django-check-deploy.txt
```

## Step 3: Migration Status

Verify all database migrations are applied:

```bash
python manage.py showmigrations 2>&1 | tee e2e-evidence/django-migrations.txt
```

Check for unapplied migrations:
```bash
if grep -q "[ ]" e2e-evidence/django-migrations.txt; then
  echo "FAIL: Unapplied migrations found — run 'python manage.py migrate'"
  grep "[ ]" e2e-evidence/django-migrations.txt
else
  echo "PASS: All migrations applied"
fi
```

Apply any outstanding migrations:
```bash
python manage.py migrate 2>&1 | tee e2e-evidence/django-migrate.txt
```

## Step 4: Start the Server

### Django

```bash
# Start development server (background)
python manage.py runserver 0.0.0.0:8000 2>&1 | tee e2e-evidence/django-server.txt &
SERVER_PID=$!
sleep 3

# Verify server is accepting connections
curl -sf http://localhost:8000/ > /dev/null 2>&1 && \
  echo "PASS: Django server is running" || \
  echo "FAIL: Django server did not start — check e2e-evidence/django-server.txt"
```

### Flask

```bash
# Set required environment variables
export FLASK_APP=app.py  # or your app module
export FLASK_ENV=development

# Start Flask development server (background)
flask run --host=0.0.0.0 --port=5000 2>&1 | tee e2e-evidence/flask-server.txt &
SERVER_PID=$!
sleep 3

# Or with Gunicorn (production-like)
gunicorn app:app --bind 0.0.0.0:5000 --workers 2 \
  2>&1 | tee e2e-evidence/flask-server.txt &
SERVER_PID=$!
sleep 3

# Verify server is accepting connections
curl -sf http://localhost:5000/ > /dev/null 2>&1 && \
  echo "PASS: Flask server is running" || \
  echo "FAIL: Flask server did not start — check e2e-evidence/flask-server.txt"
```

## Step 5: Health and Root Endpoint Check

```bash
# Root or health endpoint
curl -s -w "\nHTTP_STATUS:%{http_code}" http://localhost:8000/ \
  | tee e2e-evidence/django-health.txt
echo ""

# Django REST Framework API root (if applicable)
curl -s http://localhost:8000/api/ \
  -H "Accept: application/json" \
  | tee e2e-evidence/django-api-root.json | python -m json.tool

# Custom health endpoint
curl -s http://localhost:8000/health/ \
  | tee e2e-evidence/django-health.json | python -m json.tool
```

## Step 6: Endpoint Testing with curl

### GET list endpoint

```bash
curl -s http://localhost:8000/api/RESOURCE/ \
  -H "Accept: application/json" \
  | tee e2e-evidence/django-list-RESOURCE.json | python -m json.tool

echo "HTTP Status: $(curl -s -o /dev/null -w '%{http_code}' http://localhost:8000/api/RESOURCE/)" \
  >> e2e-evidence/django-list-RESOURCE.json
```

### POST create endpoint

```bash
curl -s -X POST http://localhost:8000/api/RESOURCE/ \
  -H "Content-Type: application/json" \
  -H "Authorization: Token $AUTH_TOKEN" \
  -d '{"name": "Test Item", "description": "Created during validation"}' \
  | tee e2e-evidence/django-create-RESOURCE.json | python -m json.tool

RESOURCE_ID=$(python -c "import sys, json; d=json.load(open('e2e-evidence/django-create-RESOURCE.json')); print(d.get('id', d.get('pk', '')))")
echo "Created ID: $RESOURCE_ID"
```

### GET detail endpoint

```bash
curl -s http://localhost:8000/api/RESOURCE/$RESOURCE_ID/ \
  -H "Accept: application/json" \
  -H "Authorization: Token $AUTH_TOKEN" \
  | tee e2e-evidence/django-detail-RESOURCE.json | python -m json.tool
```

### PUT update endpoint

```bash
curl -s -X PUT http://localhost:8000/api/RESOURCE/$RESOURCE_ID/ \
  -H "Content-Type: application/json" \
  -H "Authorization: Token $AUTH_TOKEN" \
  -d '{"name": "Updated Item", "description": "Modified during validation"}' \
  | tee e2e-evidence/django-update-RESOURCE.json | python -m json.tool
```

### DELETE endpoint

```bash
curl -s -X DELETE http://localhost:8000/api/RESOURCE/$RESOURCE_ID/ \
  -H "Authorization: Token $AUTH_TOKEN" \
  -w "\nHTTP_STATUS:%{http_code}" \
  | tee e2e-evidence/django-delete-RESOURCE.txt

# Verify 404 on subsequent read
curl -s -w "\nHTTP_STATUS:%{http_code}" \
  http://localhost:8000/api/RESOURCE/$RESOURCE_ID/ \
  -H "Authorization: Token $AUTH_TOKEN" \
  | tee e2e-evidence/django-deleted-RESOURCE.txt
```

## Step 7: Authentication Testing

### Obtain token (Django REST Framework token auth)

```bash
AUTH_TOKEN=$(curl -s -X POST http://localhost:8000/api/auth/token/ \
  -H "Content-Type: application/json" \
  -d '{"username": "testuser", "password": "testpassword"}' \
  | tee e2e-evidence/django-auth-login.json \
  | python -c "import sys, json; print(json.load(sys.stdin).get('token',''))")
echo "Token: $AUTH_TOKEN"
```

### JWT auth (if using simplejwt)

```bash
ACCESS_TOKEN=$(curl -s -X POST http://localhost:8000/api/token/ \
  -H "Content-Type: application/json" \
  -d '{"username": "testuser", "password": "testpassword"}' \
  | tee e2e-evidence/django-auth-jwt.json \
  | python -c "import sys, json; print(json.load(sys.stdin).get('access',''))")
echo "Access token: $ACCESS_TOKEN"
```

### Unauthenticated request (expect 401/403)

```bash
curl -s -w "\nHTTP_STATUS:%{http_code}" http://localhost:8000/api/protected/ \
  | tee e2e-evidence/django-auth-unauthed.txt
```

## Step 8: Django Admin Check

Verify Django admin is accessible (if used):

```bash
curl -s -w "\nHTTP_STATUS:%{http_code}" http://localhost:8000/admin/ \
  | tee e2e-evidence/django-admin-check.txt

if grep -q "HTTP_STATUS:200" e2e-evidence/django-admin-check.txt || \
   grep -q "HTTP_STATUS:302" e2e-evidence/django-admin-check.txt; then
  echo "PASS: Django admin accessible"
else
  echo "FAIL: Django admin not reachable"
fi
```

Create superuser for admin access (if needed):
```bash
echo "from django.contrib.auth import get_user_model; \
User = get_user_model(); \
User.objects.filter(username='admin').exists() or \
User.objects.create_superuser('admin', 'admin@example.com', 'adminpassword')" \
| python manage.py shell 2>&1 | tee e2e-evidence/django-create-superuser.txt
```

## Step 9: Stop the Server

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
