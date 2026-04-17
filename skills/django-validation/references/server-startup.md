# Server Startup and Health Check (Steps 4–5)

*Loaded by `django-validation` when executing Steps 4-5 (Start the Server, Health and Root Endpoint Check) and you need the Django `manage.py runserver` and Flask `flask run`/gunicorn variants plus the curl health-probe commands.*

Supports **Step 4 (Start the Server)** and **Step 5 (Health and Root Endpoint
Check)**. Teaches the pattern: boot the dev server in the background, wait
briefly, then confirm it's accepting connections with a quick `curl`. Django
and Flask variants are kept separate because env vars and commands differ.

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

## Stopping the server

```bash
kill $SERVER_PID
wait $SERVER_PID 2>/dev/null
echo "Server stopped"
```
