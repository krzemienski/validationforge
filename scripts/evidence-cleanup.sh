#!/usr/bin/env bash
# Enforce evidence retention policy — remove evidence older than retention period.
# Respects in-progress validation guard and logs all removals for audit.
#
# Usage: ./scripts/evidence-cleanup.sh [evidence_dir] [retention_days]
#   evidence_dir    — relative path to evidence root (default: e2e-evidence)
#   retention_days  — days to keep evidence (default: read from config, else 30)
#
# Environment:
#   EVIDENCE_CLEANUP_DRY_RUN=1   — log what would be removed without deleting

set -euo pipefail

EVIDENCE_DIR="${1:-e2e-evidence}"
DRY_RUN="${EVIDENCE_CLEANUP_DRY_RUN:-0}"

# ── Path validation ────────────────────────────────────────────────────────────
# Must be a relative path and must not contain traversal sequences.
case "$EVIDENCE_DIR" in
  /*)
    echo "[VF] ERROR: evidence_dir must be a relative path. Got: $EVIDENCE_DIR" >&2
    exit 1
    ;;
  *../* | */..)
    echo "[VF] ERROR: evidence_dir must not contain traversal (../). Got: $EVIDENCE_DIR" >&2
    exit 1
    ;;
esac

# ── Retention days ─────────────────────────────────────────────────────────────
# Priority: CLI arg → ~/.claude/.vf-config.json → .vf/active-config.json → default 30
resolve_retention_days() {
  local days=""

  # 1. ~/.claude/.vf-config.json
  local user_config="$HOME/.claude/.vf-config.json"
  if [ -f "$user_config" ]; then
    days=$(python3 -c "
import json, sys
try:
    d = json.load(open('$user_config'))
    v = d.get('evidence_retention_days')
    if isinstance(v, int) and v > 0:
        print(v)
except Exception:
    pass
" 2>/dev/null || true)
    [ -n "$days" ] && echo "$days" && return
  fi

  # 2. .vf/active-config.json
  if [ -f ".vf/active-config.json" ]; then
    days=$(python3 -c "
import json, sys
try:
    d = json.load(open('.vf/active-config.json'))
    v = d.get('evidence_retention_days')
    if isinstance(v, int) and v > 0:
        print(v)
except Exception:
    pass
" 2>/dev/null || true)
    [ -n "$days" ] && echo "$days" && return
  fi

  # 3. Default
  echo "30"
}

if [ $# -ge 2 ]; then
  RETENTION_DAYS="${2}"
  # Validate numeric
  case "$RETENTION_DAYS" in
    ''|*[!0-9]*)
      echo "[VF] ERROR: retention_days must be a non-negative integer. Got: $RETENTION_DAYS" >&2
      exit 1
      ;;
  esac
else
  RETENTION_DAYS="$(resolve_retention_days)"
fi

# ── In-progress validation guard ───────────────────────────────────────────────
LOCK_FILE=".vf/state/validation-in-progress.lock"

if [ -f "$LOCK_FILE" ]; then
  # Check lock age: stale if older than 1 hour (3600 seconds)
  lock_mtime=$(python3 -c "
import os, time
try:
    age = time.time() - os.path.getmtime('$LOCK_FILE')
    print(int(age))
except Exception:
    print(99999)
" 2>/dev/null || echo "99999")

  if [ "$lock_mtime" -lt 3600 ]; then
    echo "[VF] ABORT: Validation is currently in progress ($LOCK_FILE exists and is < 1 hour old)." >&2
    echo "[VF] Wait for validation to complete or remove a stale lock: rm $LOCK_FILE" >&2
    exit 1
  else
    echo "[VF] WARNING: Stale lock detected (age: ${lock_mtime}s). Proceeding with cleanup."
  fi
fi

# ── Guard: evidence directory must exist ───────────────────────────────────────
if [ ! -d "$EVIDENCE_DIR" ]; then
  echo "[VF] INFO: Evidence directory does not exist: $EVIDENCE_DIR — nothing to clean."
  exit 0
fi

# ── Audit log setup ────────────────────────────────────────────────────────────
AUDIT_LOG="$EVIDENCE_DIR/cleanup.log"

log_audit() {
  local entry="$1"
  local ts
  ts=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
  echo "[$ts] $entry" >> "$AUDIT_LOG"
}

# ── Discovery ──────────────────────────────────────────────────────────────────
# Find immediate subdirectories of EVIDENCE_DIR older than RETENTION_DAYS.
# We only clean journey-level subdirectories, not top-level files.
mapfile -t OLD_DIRS < <(
  find "$EVIDENCE_DIR" -mindepth 1 -maxdepth 1 -type d -mtime +"$RETENTION_DAYS" \
    | sort
) 2>/dev/null || OLD_DIRS=()

# ── Cleanup loop ───────────────────────────────────────────────────────────────
removed_count=0
freed_bytes=0

for dir in "${OLD_DIRS[@]:-}"; do
  # Skip empty entry (mapfile can produce one if find yields nothing)
  [ -z "$dir" ] && continue

  # Safety: ensure the path is within EVIDENCE_DIR (no traversal escape)
  case "$dir" in
    "$EVIDENCE_DIR"/*) ;;
    *)
      echo "[VF] WARNING: Skipping suspicious path outside evidence dir: $dir" >&2
      continue
      ;;
  esac

  # Compute directory size before removal
  dir_bytes=$(du -sb "$dir" 2>/dev/null | awk '{print $1}' || echo "0")

  if [ "$DRY_RUN" = "1" ]; then
    echo "[VF] DRY_RUN: would remove $dir (${dir_bytes} bytes)"
    log_audit "DRY_RUN: would remove $dir (${dir_bytes} bytes)"
  else
    echo "[VF] Removing $dir (${dir_bytes} bytes)"
    log_audit "REMOVED: $dir (${dir_bytes} bytes)"
    rm -rf "$dir"
    removed_count=$((removed_count + 1))
    freed_bytes=$((freed_bytes + dir_bytes))
  fi
done

# ── Summary ────────────────────────────────────────────────────────────────────
if [ "$DRY_RUN" = "1" ]; then
  echo "[VF] Dry-run complete. ${#OLD_DIRS[@]} director(ies) would be removed."
  log_audit "DRY_RUN summary: ${#OLD_DIRS[@]} director(ies) eligible (retention=${RETENTION_DAYS} days)"
else
  echo "[VF] Cleanup complete: ${removed_count} director(ies) removed, ${freed_bytes} bytes freed."
  log_audit "SUMMARY: ${removed_count} director(ies) removed, ${freed_bytes} bytes freed (retention=${RETENTION_DAYS} days)"
fi
