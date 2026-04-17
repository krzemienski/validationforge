# Authentication and Admin Testing (Steps 8–9)

Supports **Step 7/8 (Authentication Testing)** and **Step 8/9 (Django Admin
Check)**. Teaches the pattern: obtain a token via login, confirm unauthenticated
requests are rejected, and verify the admin panel is reachable (Django only).

## Authentication Testing

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

## Django Admin Check

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
