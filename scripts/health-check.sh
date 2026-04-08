#!/usr/bin/env bash
# Poll a health endpoint until it responds or timeout
# Usage: ./health-check.sh <url> [max_attempts] [interval_seconds]

set -euo pipefail

URL="${1:?Usage: health-check.sh <url> [max_attempts] [interval]}"
MAX_ATTEMPTS="${2:-30}"
INTERVAL="${3:-1}"

# URL scheme whitelist — prevent SSRF via file://, gopher://, dict://, etc.
case "$URL" in
  http://*|https://*) ;;
  *) echo "[VF] ERROR: Only http:// and https:// URLs are allowed. Got: $URL" >&2; exit 1 ;;
esac

# Validate numeric inputs
case "$MAX_ATTEMPTS" in
  ''|*[!0-9]*) echo "[VF] ERROR: max_attempts must be a positive integer." >&2; exit 1 ;;
esac
case "$INTERVAL" in
  ''|*[!0-9]*) echo "[VF] ERROR: interval must be a positive integer." >&2; exit 1 ;;
esac

attempt=0
while [ $attempt -lt "$MAX_ATTEMPTS" ]; do
  status=$(curl -s -o /dev/null -w "%{http_code}" "$URL" 2>/dev/null || echo "000")
  if [ "$status" = "200" ]; then
    echo "HEALTHY: $URL responded 200 after $attempt seconds"
    exit 0
  fi
  sleep "$INTERVAL"
  attempt=$((attempt + 1))
done

echo "TIMEOUT: $URL did not respond 200 after $MAX_ATTEMPTS attempts"
exit 1
