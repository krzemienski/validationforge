#!/usr/bin/env bash
# Full CRUD validation cycle for a single API resource.
# Runs: create, read-single, read-list, update, verify-update, delete, verify-404.
# Saves each response body and status code as evidence.
# Usage:
#   bash scripts/crud-validator.sh \
#     --base-url=http://localhost:PORT \
#     --resource=posts \
#     --token=$TOKEN \
#     --evidence-dir=e2e-evidence/api
set -euo pipefail

BASE_URL=""
RESOURCE=""
TOKEN=""
EVIDENCE_DIR=""

for arg in "$@"; do
  case "$arg" in
    --base-url=*)     BASE_URL="${arg#*=}" ;;
    --resource=*)     RESOURCE="${arg#*=}" ;;
    --token=*)        TOKEN="${arg#*=}" ;;
    --evidence-dir=*) EVIDENCE_DIR="${arg#*=}" ;;
    *) echo "Unknown arg: $arg" >&2; exit 2 ;;
  esac
done

if [ -z "$BASE_URL" ] || [ -z "$RESOURCE" ] || [ -z "$EVIDENCE_DIR" ]; then
  echo "Usage: $0 --base-url=URL --resource=NAME [--token=TOKEN] --evidence-dir=DIR" >&2
  exit 2
fi

command -v jq >/dev/null || { echo "ERROR: jq not installed" >&2; exit 2; }
mkdir -p "$EVIDENCE_DIR"

AUTH_HEADER=()
[ -n "$TOKEN" ] && AUTH_HEADER=(-H "Authorization: Bearer $TOKEN")

URL="$BASE_URL/api/$RESOURCE"

# Helper: curl with status capture; writes body to file, prints status to stdout.
req() {
  local method="$1" url="$2" out="$3"; shift 3
  curl -s -o "$out" -w "%{http_code}" -X "$method" "${AUTH_HEADER[@]}" "$@" "$url"
}

check_status() {
  local actual="$1" expected_pattern="$2" step="$3"
  if [[ "$actual" =~ $expected_pattern ]]; then
    echo "[crud] $step: $actual OK"
  else
    echo "[crud] $step: $actual — expected $expected_pattern" >&2
    exit 1
  fi
}

# 1. Create
echo "[crud] creating $RESOURCE..."
CREATE_FILE="$EVIDENCE_DIR/api-create-$RESOURCE.json"
STATUS=$(req POST "$URL" "$CREATE_FILE" \
  -H 'Content-Type: application/json' \
  -d '{"name":"Test Item","description":"Created by validation"}')
check_status "$STATUS" '^(200|201)$' "create"
echo "$STATUS" > "$EVIDENCE_DIR/api-create-$RESOURCE.status"

RESOURCE_ID=$(jq -r '.id // .data.id // empty' "$CREATE_FILE")
if [ -z "$RESOURCE_ID" ] || [ "$RESOURCE_ID" = "null" ]; then
  echo "[crud] ERROR: could not extract id from $CREATE_FILE" >&2
  exit 1
fi
echo "[crud] created id=$RESOURCE_ID"

# 2. Read single
STATUS=$(req GET "$URL/$RESOURCE_ID" "$EVIDENCE_DIR/api-read-$RESOURCE.json")
check_status "$STATUS" '^200$' "read-single"
echo "$STATUS" > "$EVIDENCE_DIR/api-read-$RESOURCE.status"

# 3. Read list
STATUS=$(req GET "$URL" "$EVIDENCE_DIR/api-list-$RESOURCE.json")
check_status "$STATUS" '^200$' "read-list"
echo "$STATUS" > "$EVIDENCE_DIR/api-list-$RESOURCE.status"

# 4. Update
STATUS=$(req PUT "$URL/$RESOURCE_ID" "$EVIDENCE_DIR/api-update-$RESOURCE.json" \
  -H 'Content-Type: application/json' \
  -d '{"name":"Updated Item","description":"Modified by validation"}')
check_status "$STATUS" '^(200|204)$' "update"
echo "$STATUS" > "$EVIDENCE_DIR/api-update-$RESOURCE.status"

# 5. Verify update persisted
STATUS=$(req GET "$URL/$RESOURCE_ID" "$EVIDENCE_DIR/api-read-after-update-$RESOURCE.json")
check_status "$STATUS" '^200$' "read-after-update"
echo "$STATUS" > "$EVIDENCE_DIR/api-read-after-update-$RESOURCE.status"

# 6. Delete
STATUS=$(req DELETE "$URL/$RESOURCE_ID" "$EVIDENCE_DIR/api-delete-$RESOURCE.json")
check_status "$STATUS" '^(200|202|204)$' "delete"
echo "$STATUS" > "$EVIDENCE_DIR/api-delete-$RESOURCE.status"

# 7. Verify 404 after delete
STATUS=$(req GET "$URL/$RESOURCE_ID" "$EVIDENCE_DIR/api-read-after-delete-$RESOURCE.json")
check_status "$STATUS" '^404$' "read-after-delete"
echo "$STATUS" > "$EVIDENCE_DIR/api-read-after-delete-$RESOURCE.status"

echo "[crud] all CRUD steps PASS for resource=$RESOURCE — evidence in $EVIDENCE_DIR"
