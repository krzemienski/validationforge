#!/usr/bin/env bash
# web-validation-harness.sh — auto port-detection + health check for the web-validation skill.
# Replaces the 3-step "detect port / wait for ready / curl health" sequence with one command.
set -euo pipefail

# ------------------------------ defaults ------------------------------
PROJECT_DIR="."
DEV_LOG="dev-server.log"
HEALTH_PATH="/"
EVIDENCE_DIR="e2e-evidence/web"
TOOL="auto"

# ------------------------------ arg parse -----------------------------
for arg in "$@"; do
  case "$arg" in
    --project-dir=*)  PROJECT_DIR="${arg#*=}" ;;
    --dev-log=*)      DEV_LOG="${arg#*=}" ;;
    --health-path=*)  HEALTH_PATH="${arg#*=}" ;;
    --evidence-dir=*) EVIDENCE_DIR="${arg#*=}" ;;
    --tool=*)         TOOL="${arg#*=}" ;;
    -h|--help)
      cat <<EOF
Usage: $0 [--project-dir=.] [--dev-log=dev-server.log] [--health-path=/]
          [--evidence-dir=e2e-evidence/web] [--tool=auto|playwright|chrome-devtools]

Reads a dev-server log, extracts the listening port, curls the health path,
and writes evidence + a next-step recommendation.
EOF
      exit 0 ;;
    *) echo "unknown arg: $arg" >&2; exit 2 ;;
  esac
done

case "$TOOL" in
  auto|playwright|chrome-devtools) ;;
  *) echo "--tool must be one of: auto, playwright, chrome-devtools" >&2; exit 2 ;;
esac

# ------------------------------ paths ---------------------------------
# Absolute dev log: if user passed an absolute path, respect it; else join under project-dir.
case "$DEV_LOG" in
  /*) LOG_PATH="$DEV_LOG" ;;
  *)  LOG_PATH="$PROJECT_DIR/$DEV_LOG" ;;
esac
case "$EVIDENCE_DIR" in
  /*) EV_PATH="$EVIDENCE_DIR" ;;
  *)  EV_PATH="$PROJECT_DIR/$EVIDENCE_DIR" ;;
esac

mkdir -p "$EV_PATH"

# ------------------------------ port scan -----------------------------
# Poll the log for up to 10 seconds. First matching port wins.
PORT=""
for i in 1 2 3 4 5 6 7 8 9 10; do
  if [ -r "$LOG_PATH" ]; then
    # Try a cascade of common framework patterns. First match wins.
    PORT=$(grep -Eo 'http://localhost:[0-9]+' "$LOG_PATH" 2>/dev/null | head -1 | grep -Eo '[0-9]+$' || true)
    if [ -z "${PORT:-}" ]; then
      PORT=$(grep -Eo 'localhost:[0-9]+' "$LOG_PATH" 2>/dev/null | head -1 | grep -Eo '[0-9]+$' || true)
    fi
    if [ -z "${PORT:-}" ]; then
      PORT=$(grep -Eio 'running on port [0-9]+' "$LOG_PATH" 2>/dev/null | head -1 | grep -Eo '[0-9]+$' || true)
    fi
    if [ -z "${PORT:-}" ]; then
      PORT=$(grep -Eio 'ready on[^0-9]*([0-9]+)' "$LOG_PATH" 2>/dev/null | head -1 | grep -Eo '[0-9]+$' || true)
    fi
    if [ -z "${PORT:-}" ]; then
      PORT=$(grep -Eo '127\.0\.0\.1:[0-9]+' "$LOG_PATH" 2>/dev/null | head -1 | grep -Eo '[0-9]+$' || true)
    fi
    if [ -n "${PORT:-}" ]; then
      break
    fi
  fi
  sleep 1
done

if [ -z "${PORT:-}" ]; then
  echo "FAIL: dev server log has no detectable listening port — is the server running? (log=$LOG_PATH)" >&2
  echo "web-validation: port=none health=fail tool=$TOOL"
  exit 1
fi

echo "Detected PORT=$PORT (from $LOG_PATH)"

# ------------------------------ health check --------------------------
HEALTH_BODY="$EV_PATH/web-health.html"
HEALTH_META="$EV_PATH/web-health-meta.txt"
URL="http://localhost:${PORT}${HEALTH_PATH}"

# --fail keeps exit non-zero on 4xx/5xx; we tolerate that so we still write the summary.
set +e
curl --fail -s -o "$HEALTH_BODY" \
  -w "http_code=%{http_code} size=%{size_download}\n" \
  "$URL" | tee "$HEALTH_META"
CURL_RC=$?
set -e

if [ "$CURL_RC" -eq 0 ]; then
  HEALTH="pass"
else
  HEALTH="fail"
fi

# ------------------------------ next-tool hint ------------------------
if [ "$TOOL" = "auto" ]; then
  case "$PWD" in
    /tmp/*|/var/folders/*) NEXT="playwright" ;;
    *)                     NEXT="chrome-devtools" ;;
  esac
  echo "next: use $NEXT (auto-chosen; set --tool to override)"
else
  NEXT="$TOOL"
  echo "next: $NEXT"
fi

# ------------------------------ summary -------------------------------
echo "web-validation: port=$PORT health=$HEALTH tool=$NEXT"
