#!/usr/bin/env bash
# Send an anonymized telemetry event to the VF telemetry endpoint.
# Usage: telemetry.sh <EVENT_NAME> [key=value ...]
# Exits silently (0) when telemetry is disabled or config is missing.

set -euo pipefail

CONFIG_FILE="${HOME}/.claude/.vf-config.json"
DEFAULT_ENDPOINT="https://telemetry.validationforge.dev/events"
VF_VERSION="1.0.0"

# --- Guard: require at least an event name ---
EVENT_NAME="${1:-}"
if [ -z "$EVENT_NAME" ]; then
  # Nothing to do; exit cleanly
  exit 0
fi

# --- Guard: validate event name is not an absolute path ---
case "$EVENT_NAME" in
  /*) echo "[VF] ERROR: EVENT_NAME must not be an absolute path." >&2; exit 1 ;;
esac

# --- Guard: config must exist and telemetry must be explicitly enabled ---
if [ ! -f "$CONFIG_FILE" ]; then
  exit 0
fi

TELEMETRY_ENABLED=$(jq -r '.telemetry.enabled // false' "$CONFIG_FILE" 2>/dev/null || echo "false")
if [ "$TELEMETRY_ENABLED" != "true" ]; then
  exit 0
fi

# --- Read telemetry fields from config ---
ANON_ID=$(jq -r '.telemetry.anonymousId // ""' "$CONFIG_FILE" 2>/dev/null || echo "")
ENDPOINT=$(jq -r '.telemetry.endpoint // ""' "$CONFIG_FILE" 2>/dev/null || echo "")

# Fall back to default endpoint if not set or empty
if [ -z "$ENDPOINT" ] || [ "$ENDPOINT" = "null" ]; then
  ENDPOINT="$DEFAULT_ENDPOINT"
fi

# --- Validate endpoint URL scheme: https:// only ---
case "$ENDPOINT" in
  https://*) ;;
  *) exit 0 ;;  # Silently skip if endpoint is not https
esac

# --- Build JSON payload ---
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo "")

# Start with the base payload fields
PAYLOAD="{\"event\":$(printf '%s' "$EVENT_NAME" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read()))' 2>/dev/null || echo "\"$EVENT_NAME\""),\"anonymousId\":$(printf '%s' "$ANON_ID" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read()))' 2>/dev/null || echo "\"$ANON_ID\""),\"timestamp\":\"$TIMESTAMP\",\"vf_version\":\"$VF_VERSION\""

# --- Parse key=value arguments (skip first arg which is EVENT_NAME) ---
# H2: key must match [A-Za-z_][A-Za-z0-9_-]* (no quotes, no control chars,
# no JSON-breakout vectors). Value is JSON-escaped via python3 — same
# helper pattern used for the base payload at line 53 — so quotes,
# backslashes, and control chars cannot inject new JSON fields.
shift
for arg in "$@"; do
  case "$arg" in
    *=*)
      key="${arg%%=*}"
      val="${arg#*=}"
      # Reject empty key, absolute-path keys, and anything with chars outside
      # [A-Za-z0-9_-]. Bash case globbing handles this without a subshell.
      if [ -z "$key" ]; then continue; fi
      case "$key" in
        /*)                      continue ;;  # absolute-path-looking keys
        *[!A-Za-z0-9_-]*)        continue ;;  # invalid chars
        [0-9-]*)                 continue ;;  # must start with letter/underscore
      esac
      # JSON-escape the value via python3; if python3 is unavailable or
      # rejects the input, drop the field silently (base payload uses the
      # same helper, so availability is already a requirement).
      json_val=$(printf '%s' "$val" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read()))' 2>/dev/null) || continue
      PAYLOAD="${PAYLOAD},\"${key}\":${json_val}"
      ;;
    *)
      # Non key=value argument — skip silently
      ;;
  esac
done

PAYLOAD="${PAYLOAD}}"

# --- Send telemetry silently; never block or fail the caller ---
curl \
  --silent \
  --max-time 5 \
  --request POST \
  --header "Content-Type: application/json" \
  --data "$PAYLOAD" \
  "$ENDPOINT" \
  2>/dev/null || true
