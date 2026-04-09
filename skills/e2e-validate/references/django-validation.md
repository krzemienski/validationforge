# Django / Flask Validation Reference

Platform-specific commands, tools, and patterns for validating Django and Flask web applications including server startup, migration verification, Django management commands, and curl-based endpoint testing.

## Build and Start

### Django

```bash
# Create and activate virtual environment
python -m venv venv
source venv/bin/activate  # Linux/macOS
# venv\Scripts\activate   # Windows

# Install dependencies
pip install -r requirements.txt 2>&1 | tee e2e-evidence/pip-install.txt

# Set required environment variables
export DJANGO_SETTINGS_MODULE=myproject.settings
export SECRET_KEY="your-secret-key"
export DATABASE_URL="sqlite:///db.sqlite3"  # or postgres/mysql URL

# Apply database migrations
python manage.py migrate 2>&1 | tee e2e-evidence/django-migrate.txt

# (Optional) Load fixtures / seed data
python manage.py loaddata fixtures/initial_data.json 2>&1 | tee e2e-evidence/django-loaddata.txt

# Start development server (background)
python manage.py runserver 0.0.0.0:8000 2>&1 | tee e2e-evidence/django-server.txt &
SERVER_PID=$!

# Wait for server to be ready
for i in $(seq 1 20); do
  curl -sf http://localhost:8000/ > /dev/null 2>&1 && break
  sleep 1
done
echo "Django server ready"
```

### Flask

```bash
# Install dependencies
pip install -r requirements.txt 2>&1 | tee e2e-evidence/pip-install.txt

# Set required environment variables
export FLASK_APP=app.py  # or your app module name
export FLASK_ENV=development
export DATABASE_URL="sqlite:///app.db"

# Apply database migrations (Flask-Migrate)
flask db upgrade 2>&1 | tee e2e-evidence/flask-migrate.txt
# or SQLAlchemy init:
# flask init-db 2>&1 | tee e2e-evidence/flask-migrate.txt

# Start Flask development server (background)
flask run --host=0.0.0.0 --port=5000 2>&1 | tee e2e-evidence/flask-server.txt &
SERVER_PID=$!

# Or with Gunicorn for production-like testing
gunicorn app:app --bind 0.0.0.0:5000 --workers 2 \
  2>&1 | tee e2e-evidence/flask-server.txt &
SERVER_PID=$!

# Wait for server to be ready
for i in $(seq 1 20); do
  curl -sf http://localhost:5000/ > /dev/null 2>&1 && break
  sleep 1
done
echo "Flask server ready"
```

## Django Management Commands

```bash
# Run built-in system check (validates settings, models, urlconf)
python manage.py check 2>&1 | tee e2e-evidence/django-check.txt
# Expected: "System check identified no issues (0 silenced)."

# Deployment readiness check
python manage.py check --deploy 2>&1 | tee e2e-evidence/django-check-deploy.txt

# Show migration status ([ ] = unapplied, [X] = applied)
python manage.py showmigrations 2>&1 | tee e2e-evidence/django-showmigrations.txt

# Check for unapplied migrations
if grep -q "\[ \]" e2e-evidence/django-showmigrations.txt; then
  echo "FAIL: Unapplied migrations detected"
  grep "\[ \]" e2e-evidence/django-showmigrations.txt
else
  echo "PASS: All migrations applied"
fi

# List all URL routes
python manage.py show_urls 2>&1 | tee e2e-evidence/django-urls.txt
# (requires django-extensions; otherwise inspect urls.py manually)

# Open interactive shell
python manage.py shell

# Create superuser (for admin access)
echo "from django.contrib.auth import get_user_model; \
User = get_user_model(); \
User.objects.filter(username='admin').exists() or \
User.objects.create_superuser('admin', 'admin@example.com', 'adminpassword')" \
| python manage.py shell 2>&1 | tee e2e-evidence/django-superuser.txt

# Inspect a model's fields
echo "from myapp.models import MyModel; print([f.name for f in MyModel._meta.get_fields()])" \
| python manage.py shell 2>&1

# Collect static files (production setup)
python manage.py collectstatic --noinput 2>&1 | tee e2e-evidence/django-collectstatic.txt
```

## Health Check

```bash
# Django root URL or health endpoint
curl -s -w "\nHTTP_STATUS:%{http_code}\nTime:%{time_total}s\n" \
  http://localhost:8000/ | tee e2e-evidence/django-health.txt

# Custom health endpoint
curl -s http://localhost:8000/health/ \
  | tee e2e-evidence/django-health.json | python -m json.tool

# Django REST Framework API root
curl -s http://localhost:8000/api/ \
  -H "Accept: application/json" \
  | tee e2e-evidence/django-api-root.json | python -m json.tool

# Flask health endpoint
curl -s -w "\nHTTP_STATUS:%{http_code}\n" http://localhost:5000/health \
  | tee e2e-evidence/flask-health.txt
```

If the health check fails, STOP. Fix the server before validating endpoints.

## curl CRUD Patterns

### Authentication — obtain token

```bash
# Django REST Framework token authentication
AUTH_TOKEN=$(curl -s -X POST http://localhost:8000/api/auth/token/ \
  -H "Content-Type: application/json" \
  -d '{"username": "admin", "password": "adminpassword"}' \
  | tee e2e-evidence/django-auth.json \
  | python -c "import sys, json; print(json.load(sys.stdin).get('token',''))")
echo "Token: $AUTH_TOKEN"

# JWT (django-rest-framework-simplejwt)
ACCESS_TOKEN=$(curl -s -X POST http://localhost:8000/api/token/ \
  -H "Content-Type: application/json" \
  -d '{"username": "admin", "password": "adminpassword"}' \
  | tee e2e-evidence/django-jwt.json \
  | python -c "import sys, json; print(json.load(sys.stdin).get('access',''))")
echo "Access token: $ACCESS_TOKEN"

# Flask-Login or Flask-JWT
ACCESS_TOKEN=$(curl -s -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "admin@example.com", "password": "adminpassword"}' \
  | tee e2e-evidence/flask-auth.json \
  | python -c "import sys, json; print(json.load(sys.stdin).get('access_token',''))")
```

### GET list

```bash
curl -s http://localhost:8000/api/RESOURCE/ \
  -H "Accept: application/json" \
  -H "Authorization: Token $AUTH_TOKEN" \
  -w "\nHTTP_STATUS:%{http_code}" \
  | tee e2e-evidence/django-list.json
python -m json.tool e2e-evidence/django-list.json
```

### POST create

```bash
curl -s -X POST http://localhost:8000/api/RESOURCE/ \
  -H "Content-Type: application/json" \
  -H "Authorization: Token $AUTH_TOKEN" \
  -d '{"name": "Test Item", "description": "Validation item"}' \
  -w "\nHTTP_STATUS:%{http_code}" \
  | tee e2e-evidence/django-create.json
python -m json.tool e2e-evidence/django-create.json

RESOURCE_ID=$(python -c "import json; d=json.load(open('e2e-evidence/django-create.json')); print(d.get('id', d.get('pk','')))" 2>/dev/null)
echo "Created ID: $RESOURCE_ID"
```

### GET detail

```bash
curl -s http://localhost:8000/api/RESOURCE/$RESOURCE_ID/ \
  -H "Authorization: Token $AUTH_TOKEN" \
  -w "\nHTTP_STATUS:%{http_code}" \
  | tee e2e-evidence/django-detail.json
```

### PATCH partial update

```bash
curl -s -X PATCH http://localhost:8000/api/RESOURCE/$RESOURCE_ID/ \
  -H "Content-Type: application/json" \
  -H "Authorization: Token $AUTH_TOKEN" \
  -d '{"name": "Updated Name"}' \
  -w "\nHTTP_STATUS:%{http_code}" \
  | tee e2e-evidence/django-update.json
```

### DELETE

```bash
curl -s -X DELETE http://localhost:8000/api/RESOURCE/$RESOURCE_ID/ \
  -H "Authorization: Token $AUTH_TOKEN" \
  -w "\nHTTP_STATUS:%{http_code}" \
  | tee e2e-evidence/django-delete.txt

# Verify 404 on subsequent read
curl -s http://localhost:8000/api/RESOURCE/$RESOURCE_ID/ \
  -H "Authorization: Token $AUTH_TOKEN" \
  -w "\nHTTP_STATUS:%{http_code}" \
  | tee e2e-evidence/django-deleted-check.txt
```

### Error case — unauthenticated

```bash
curl -s http://localhost:8000/api/RESOURCE/ \
  -w "\nHTTP_STATUS:%{http_code}" \
  | tee e2e-evidence/django-unauthed.txt
# Expected: HTTP_STATUS:401 or 403
```

### Error case — invalid payload

```bash
curl -s -X POST http://localhost:8000/api/RESOURCE/ \
  -H "Content-Type: application/json" \
  -H "Authorization: Token $AUTH_TOKEN" \
  -d '{}' \
  -w "\nHTTP_STATUS:%{http_code}" \
  | tee e2e-evidence/django-error-empty-body.json
# Expected: HTTP_STATUS:400 with validation error fields
```

### CSRF handling (session auth / non-DRF views)

```bash
# Get CSRF token from login page
CSRF_TOKEN=$(curl -s -c cookies.txt http://localhost:8000/login/ \
  | grep -o 'csrfmiddlewaretoken" value="[^"]*"' | cut -d'"' -f3)
echo "CSRF: $CSRF_TOKEN"

# POST with CSRF token
curl -s -X POST http://localhost:8000/login/ \
  -b cookies.txt -c cookies.txt \
  -H "X-CSRFToken: $CSRF_TOKEN" \
  -d "username=admin&password=adminpassword&csrfmiddlewaretoken=$CSRF_TOKEN" \
  -w "\nHTTP_STATUS:%{http_code}" \
  | tee e2e-evidence/django-session-login.txt
```

## Django Admin

```bash
# Check admin is accessible
curl -s -w "\nHTTP_STATUS:%{http_code}" http://localhost:8000/admin/ \
  | tee e2e-evidence/django-admin.txt
# Expected: HTTP_STATUS:200 (login page) or 302 (redirect to login)

# Verify admin login page content
if grep -q "Django administration" e2e-evidence/django-admin.txt || \
   grep -qE "HTTP_STATUS:(200|302)" e2e-evidence/django-admin.txt; then
  echo "PASS: Django admin accessible"
else
  echo "FAIL: Django admin not reachable"
fi
```

## Evidence Quality Examples

**GOOD response review:**
> "POST /api/items/ returned HTTP_STATUS:201. Body contains:
> `{"id": 42, "name": "Test Item", "description": "Validation item",
> "created_at": "2026-04-08T14:30:00Z", "updated_at": "2026-04-08T14:30:00Z"}`.
> All submitted fields present, auto-generated id=42, timestamps populated."

**BAD response review:**
> "Item created successfully"

**GOOD migration status review:**
> "django-showmigrations.txt shows 12 apps, all migrations marked [X].
> No `[ ]` unapplied entries. Last applied: `myapp 0005_add_user_profile`."

**BAD migration status review:**
> "Migrations are up to date"

**GOOD system check review:**
> "django-check.txt output: `System check identified no issues (0 silenced).`
> No WARNINGS or ERRORS lines present."

**BAD system check review:**
> "System check passed"

**GOOD error response review:**
> "POST /api/items/ with empty body returned HTTP_STATUS:400. Body:
> `{"name": ["This field is required."], "description": ["This field is required."]}`.
> DRF serializer validation errors identify each missing field by name."

**BAD error response review:**
> "Error handling works correctly"

## Common Django / Flask Validation Journeys

| Journey | Entry | Key Evidence |
|---------|-------|-------------|
| Server Startup (Django) | `python manage.py runserver` | Server log shows `Starting development server`, health check 200 |
| Server Startup (Flask) | `flask run` | Server log shows `Running on http://`, health check 200 |
| Migration Check | `python manage.py showmigrations` | All `[X]` entries, zero `[ ]` unapplied |
| System Check | `python manage.py check` | "System check identified no issues (0 silenced)" |
| Authentication | POST `/api/auth/token/` | Token returned in response body, usable on protected routes |
| List Resources | GET `/api/RESOURCE/` | 200 with JSON array, correct item count |
| Create Resource | POST `/api/RESOURCE/` | 201 with new object including ID |
| Update Resource | PATCH `/api/RESOURCE/:id/` | 200 with updated fields, GET confirms persistence |
| Delete Resource | DELETE `/api/RESOURCE/:id/` | 204 or 200, subsequent GET returns 404 |
| Unauthenticated Access | GET `/api/RESOURCE/` (no token) | 401 or 403 with error message |
| Validation Error | POST with empty body | 400 with field-specific error messages |
| Django Admin | GET `/admin/` | 200 (login page) or 302 (redirect), no 404 or 500 |
