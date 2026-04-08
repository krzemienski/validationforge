#!/usr/bin/env bash
# Poll a health endpoint until it responds or timeout
# Usage: ./health-check.sh <url> [max_attempts] [interval_seconds]

set -euo pipefail

URL="${1:?Usage: health-check.sh <url> [max_attempts] [interval]}"
MAX_ATTEMPTS="${2:-30}"
INTERVAL="${3:-1}"

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
