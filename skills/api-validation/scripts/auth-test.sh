#!/usr/bin/env bash
# Authentication validation: valid-login, authenticated-request, invalid-token, no-token.
# Saves each response body + status as evidence.
# Usage:
#   bash scripts/auth-test.sh \
#     --base-url=http://localhost:PORT \
#     --login-endpoint=/auth/login \
#     --protected-endpoint=/api/protected \
#     --email=user@example.com \
#     --password=validpassword \
#     --evidence-dir=e2e-evidence/api
set -euo pipefail

BASE_URL=""
LOGIN_ENDPOINT=""
PROTECTED_ENDPOINT=""
EMAIL=""
PASSWORD=""
EVIDENCE_DIR=""

for arg in "$@"; do
  case "$arg" in
    --base-url=*)            BASE_URL="${arg#*=}" ;;
    --login-endpoint=*)      LOGIN_ENDPOINT="${arg#*=}" ;;
    --protected-endpoint=*)  PROTECTED_ENDPOINT="${arg#*=}" ;;
    --email=*)               EMAIL="${arg#*=}" ;;
    --password=*)            PASSWORD="${arg#*=}" ;;
    --evidence-dir=*)        EVIDENCE_DIR="${arg#*=}" ;;
    *) echo "Unknown arg: $arg" >&2; exit 2 ;;
  esac
done

if [ -z "$BASE_URL" ] || [ -z "$LOGIN_ENDPOINT" ] || [ -z "$PROTECTED_ENDPOINT" ] \
   || [ -z "$EMAIL" ] || [ -z "$PASSWORD" ] || [ -z "$EVIDENCE_DIR" ]; then
  echo "Usage: $0 --base-url=URL --login-endpoint=PATH --protected-endpoint=PATH --email=E --password=P --evidence-dir=DIR" >&2
  exit 2
fi

command -v jq >/dev/null || { echo "ERROR: jq not installed" >&2; exit 2; }
mkdir -p "$EVIDENCE_DIR"

check_status() {
  local actual="$1" expected_pattern="$2" step="$3"
  if [[ "$actual" =~ $expected_pattern ]]; then
    echo "[auth] $step: $actual OK"
  else
    echo "[auth] $step: $actual — expected $expected_pattern" >&2
    exit 1
  fi
}

# 1. Valid credentials — obtain token
echo "[auth] logging in as $EMAIL..."
LOGIN_FILE="$EVIDENCE_DIR/api-auth-valid-login.json"
STATUS=$(curl -s -o "$LOGIN_FILE" -w "%{http_code}" \
  -X POST "$BASE_URL$LOGIN_ENDPOINT" \
  -H 'Content-Type: application/json' \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}")
echo "$STATUS" > "$EVIDENCE_DIR/api-auth-valid-login.status"
check_status "$STATUS" '^(200|201)$' "valid-login"

TOKEN=$(jq -r '.token // .access_token // empty' "$LOGIN_FILE")
if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
  echo "[auth] ERROR: no token in $LOGIN_FILE" >&2
  exit 1
fi
echo "[auth] got token (len=${#TOKEN})"

# 2. Authenticated request
PROT_FILE="$EVIDENCE_DIR/api-auth-protected-access.json"
STATUS=$(curl -s -o "$PROT_FILE" -w "%{http_code}" \
  -H "Authorization: Bearer $TOKEN" \
  "$BASE_URL$PROTECTED_ENDPOINT")
echo "$STATUS" > "$EVIDENCE_DIR/api-auth-protected-access.status"
check_status "$STATUS" '^200$' "authenticated-request"

# 3. Invalid token — expect 401
INV_FILE="$EVIDENCE_DIR/api-auth-invalid-token.json"
STATUS=$(curl -s -o "$INV_FILE" -w "%{http_code}" \
  -H "Authorization: Bearer invalid.token.here" \
  "$BASE_URL$PROTECTED_ENDPOINT")
echo "$STATUS" > "$EVIDENCE_DIR/api-auth-invalid-token.status"
check_status "$STATUS" '^401$' "invalid-token"

# 4. No token — expect 401
NONE_FILE="$EVIDENCE_DIR/api-auth-no-token.json"
STATUS=$(curl -s -o "$NONE_FILE" -w "%{http_code}" "$BASE_URL$PROTECTED_ENDPOINT")
echo "$STATUS" > "$EVIDENCE_DIR/api-auth-no-token.status"
check_status "$STATUS" '^401$' "no-token"

echo "[auth] all 4 auth checks PASS — evidence in $EVIDENCE_DIR"
