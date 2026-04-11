#!/usr/bin/env bash
# ValidationForge non-interactive setup script.
# Creates or updates ~/.claude/.vf-config.json with profile + detected platform.
#
# Usage:
#   vf-setup.sh [--strict|--standard|--permissive|--auto]
#              [--config-path PATH]
#              [--evidence-dir DIR]
#              [--quiet]
#
# Flags:
#   --strict        Use strict enforcement profile
#   --standard      Use standard enforcement profile (default when --auto)
#   --permissive    Use permissive enforcement profile
#   --auto          Select standard profile automatically (default if no flag)
#   --config-path   Write config to custom path (default: ~/.claude/.vf-config.json)
#   --evidence-dir  Evidence directory name (default: e2e-evidence)
#   --quiet         Suppress non-error output
#
# Exits 0 on success, 1 on any unrecoverable failure. Idempotent.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

PROFILE=""
CONFIG_PATH="${HOME}/.claude/.vf-config.json"
EVIDENCE_DIR="e2e-evidence"
QUIET=0

while [ $# -gt 0 ]; do
  case "$1" in
    --strict)      PROFILE="strict"; shift ;;
    --standard)    PROFILE="standard"; shift ;;
    --permissive)  PROFILE="permissive"; shift ;;
    --auto)        PROFILE="standard"; shift ;;
    --config-path) CONFIG_PATH="$2"; shift 2 ;;
    --evidence-dir) EVIDENCE_DIR="$2"; shift 2 ;;
    --quiet)       QUIET=1; shift ;;
    -h|--help)
      sed -n '1,22p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "Unknown flag: $1" >&2
      exit 1
      ;;
  esac
done

if [ -z "$PROFILE" ]; then
  PROFILE="standard"
fi

log() {
  [ "$QUIET" -eq 0 ] && echo "$@"
}

log "=== ValidationForge Setup ==="
log "Profile:       $PROFILE"
log "Config path:   $CONFIG_PATH"
log "Evidence dir:  $EVIDENCE_DIR"
log ""

PLATFORM="generic"
if [ -x "$SCRIPT_DIR/detect-platform.sh" ]; then
  PLATFORM="$("$SCRIPT_DIR/detect-platform.sh" "." 2>/dev/null || echo generic)"
fi
log "Detected platform: $PLATFORM"

CONFIG_DIR="$(dirname "$CONFIG_PATH")"
if [ ! -d "$CONFIG_DIR" ]; then
  mkdir -p "$CONFIG_DIR" || { echo "ERROR: cannot create $CONFIG_DIR" >&2; exit 1; }
fi

if [ -f "$CONFIG_PATH" ]; then
  cp "$CONFIG_PATH" "${CONFIG_PATH}.bak" 2>/dev/null || true
  log "Existing config backed up to ${CONFIG_PATH}.bak"
fi

TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

cat > "$CONFIG_PATH" <<JSON
{
  "profile": "$PROFILE",
  "platform": "$PLATFORM",
  "evidence_dir": "$EVIDENCE_DIR",
  "created_at": "$TIMESTAMP",
  "updated_at": "$TIMESTAMP",
  "vf_version": "1.0.0"
}
JSON

if ! node -e "JSON.parse(require('fs').readFileSync('$CONFIG_PATH'))" 2>/dev/null; then
  echo "ERROR: written config is not valid JSON" >&2
  exit 1
fi

log "Wrote $CONFIG_PATH"

if [ ! -d "$EVIDENCE_DIR" ]; then
  mkdir -p "$EVIDENCE_DIR"
  log "Created $EVIDENCE_DIR/"
fi

log ""
log "=== Setup complete ==="
log "Next step: Run /validate in Claude Code to execute your first validation pipeline."
log "Expected total time from install to first verdict: under 5 minutes on a standard web project."

exit 0
