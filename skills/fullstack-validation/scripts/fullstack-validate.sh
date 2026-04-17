#!/usr/bin/env bash
# Thin orchestrator for the fullstack bottom-up validation sequence:
#   DB gate -> API gate -> Web gate.
# Each gate is optional-skippable; the first failure exits non-zero.
# Composes api-validation/scripts/crud-validator.sh for the API layer.
#
# Usage:
#   bash scripts/fullstack-validate.sh \
#     --db-check-cmd='psql -c "SELECT 1"' \
#     --api-base-url=http://localhost:3000 \
#     --web-base-url=http://localhost:3000 \
#     --evidence-dir=e2e-evidence/fullstack \
#     --resource=posts \
#     --token=$TOKEN
set -euo pipefail

DB_CHECK_CMD="true"            # default: no-op (skip DB gate)
API_BASE_URL=""
WEB_BASE_URL=""
EVIDENCE_DIR="e2e-evidence/fullstack"
RESOURCE="posts"
TOKEN=""

for arg in "$@"; do
  case "$arg" in
    --db-check-cmd=*) DB_CHECK_CMD="${arg#*=}" ;;
    --api-base-url=*) API_BASE_URL="${arg#*=}" ;;
    --web-base-url=*) WEB_BASE_URL="${arg#*=}" ;;
    --evidence-dir=*) EVIDENCE_DIR="${arg#*=}" ;;
    --resource=*)     RESOURCE="${arg#*=}" ;;
    --token=*)        TOKEN="${arg#*=}" ;;
    -h|--help)
      sed -n '2,14p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *) echo "Unknown arg: $arg" >&2; exit 2 ;;
  esac
done

mkdir -p "$EVIDENCE_DIR"

# Resolve the bundled crud-validator relative to THIS script, not cwd.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CRUD_VALIDATOR="$SCRIPT_DIR/../../api-validation/scripts/crud-validator.sh"

db_status="skip"
api_status="skip"
web_status="skip"

# ---------- Layer 1: DB gate ----------
if [ "$DB_CHECK_CMD" != "true" ]; then
  echo "[fullstack] DB gate: running: $DB_CHECK_CMD"
  db_log="$EVIDENCE_DIR/fullstack-db-check.txt"
  if bash -c "$DB_CHECK_CMD" > "$db_log" 2>&1; then
    db_status="pass"
    echo "[fullstack] DB gate PASS — evidence: $db_log"
  else
    db_status="fail"
    echo "[fullstack] DB gate FAIL — command '$DB_CHECK_CMD' exited non-zero" >&2
    echo "[fullstack] see $db_log for details" >&2
    echo "fullstack: db=$db_status api=$api_status web=$web_status"
    exit 1
  fi
else
  echo "[fullstack] DB gate: skipped (no --db-check-cmd supplied)"
fi

# ---------- Layer 2: API gate ----------
if [ -n "$API_BASE_URL" ]; then
  if [ ! -f "$CRUD_VALIDATOR" ]; then
    echo "[fullstack] API gate FAIL — crud-validator not found at $CRUD_VALIDATOR" >&2
    api_status="fail"
    echo "fullstack: db=$db_status api=$api_status web=$web_status"
    exit 1
  fi
  echo "[fullstack] API gate: invoking crud-validator against $API_BASE_URL (resource=$RESOURCE)"
  crud_args=(
    --base-url="$API_BASE_URL"
    --resource="$RESOURCE"
    --evidence-dir="$EVIDENCE_DIR"
  )
  [ -n "$TOKEN" ] && crud_args+=(--token="$TOKEN")
  if bash "$CRUD_VALIDATOR" "${crud_args[@]}"; then
    api_status="pass"
    echo "[fullstack] API gate PASS"
  else
    api_status="fail"
    echo "[fullstack] API gate FAIL — crud-validator exited non-zero" >&2
    echo "fullstack: db=$db_status api=$api_status web=$web_status"
    exit 1
  fi
else
  echo "[fullstack] API gate: skipped (no --api-base-url supplied)"
fi

# ---------- Layer 3: Web gate ----------
if [ -n "$WEB_BASE_URL" ]; then
  web_out="$EVIDENCE_DIR/fullstack-web-index.html"
  web_status_file="$EVIDENCE_DIR/fullstack-web-index.status"
  echo "[fullstack] Web gate: GET $WEB_BASE_URL -> $web_out"
  if http_code=$(curl --fail -s --max-time 10 -o "$web_out" -w "%{http_code}" "$WEB_BASE_URL"); then
    echo "$http_code" > "$web_status_file"
    if [ "$http_code" = "200" ]; then
      web_status="pass"
      echo "[fullstack] Web gate PASS (HTTP 200) — evidence: $web_out"
    else
      web_status="fail"
      echo "[fullstack] Web gate FAIL — expected 200, got $http_code" >&2
      echo "fullstack: db=$db_status api=$api_status web=$web_status"
      exit 1
    fi
  else
    web_status="fail"
    echo "[fullstack] Web gate FAIL — curl could not fetch $WEB_BASE_URL" >&2
    echo "fullstack: db=$db_status api=$api_status web=$web_status"
    exit 1
  fi
else
  echo "[fullstack] Web gate: skipped (no --web-base-url supplied)"
fi

echo "fullstack: db=$db_status api=$api_status web=$web_status"
