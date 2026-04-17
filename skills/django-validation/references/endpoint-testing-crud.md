# Endpoint and CRUD Testing (Steps 6–7)

*Loaded by `django-validation` when executing Step 6 (Endpoint Testing with curl) and you need the per-verb curl invocations (GET list/detail, POST create, PUT update, DELETE) with resource-ID chaining and tee-to-evidence patterns.*

Supports **Step 6 (Endpoint Testing with curl)** covering GET list/detail, POST
create, PUT update, and DELETE flows. Teaches the pattern: hit each REST verb
with `curl`, pipe the response to a named evidence file, and capture the HTTP
status code or created-resource ID so later steps can chain off it.

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
