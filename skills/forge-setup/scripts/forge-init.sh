#!/usr/bin/env bash
# forge-init.sh — Idempotent ValidationForge workspace initializer.
#
# Usage:
#   bash forge-init.sh [--project-dir=PATH] [--enforcement-level=LEVEL] [--force]
#
# Defaults: project-dir=. , enforcement-level=standard
# Enforcement levels: strict | standard | permissive
#
# Safe to re-run. Existing files are preserved unless --force is passed.

set -euo pipefail

PROJECT_DIR="."
LEVEL="standard"
FORCE=0

for arg in "$@"; do
  case "$arg" in
    --project-dir=*)        PROJECT_DIR="${arg#*=}" ;;
    --enforcement-level=*)  LEVEL="${arg#*=}" ;;
    --force)                FORCE=1 ;;
    -h|--help)
      sed -n '2,11p' "$0"
      exit 0
      ;;
    *)
      echo "forge-init: unknown argument: $arg" >&2
      exit 2
      ;;
  esac
done

case "$LEVEL" in
  strict|standard|permissive) ;;
  *)
    echo "forge-init: --enforcement-level must be strict, standard, or permissive (got: $LEVEL)" >&2
    exit 2
    ;;
esac

# Locate this script's source dir so we can find bundled rules.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# Rules live at repo-root/.claude/rules. This script sits at
# skills/forge-setup/scripts/ → repo-root is three levels up.
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
RULES_SOURCE="$REPO_ROOT/.claude/rules"

mkdir -p "$PROJECT_DIR"
PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"

VF_DIR="$PROJECT_DIR/.vf"
CONFIG_FILE="$VF_DIR/config.json"
STATE_DIR="$VF_DIR/state"
BENCH_DIR="$VF_DIR/benchmarks"
EVIDENCE_DIR="$PROJECT_DIR/e2e-evidence"
GITIGNORE="$PROJECT_DIR/.gitignore"
RULES_DEST="$PROJECT_DIR/.claude/rules"

mkdir -p "$VF_DIR" "$STATE_DIR" "$BENCH_DIR" "$EVIDENCE_DIR"

# 1. Config
CONFIG_WRITTEN="skipped"
if [ -f "$CONFIG_FILE" ] && [ "$FORCE" -eq 0 ]; then
  CONFIG_WRITTEN="skipped"
else
  CREATED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  cat > "$CONFIG_FILE" <<JSON
{
  "version": "1.0.0",
  "enforcement": "$LEVEL",
  "evidence_dir": "e2e-evidence",
  "evidence_retention_days": 30,
  "max_fix_attempts": 3,
  "created_at": "$CREATED_AT"
}
JSON
  CONFIG_WRITTEN="written"
fi

# 2. evidence .gitkeep
[ -f "$EVIDENCE_DIR/.gitkeep" ] || : > "$EVIDENCE_DIR/.gitkeep"

# 3. gitignore handling (warn, don't fail)
GITIGNORE_STATUS="no-gitignore"
if [ -f "$GITIGNORE" ]; then
  if grep -qE '^e2e-evidence/?($|\*|\*\*)' "$GITIGNORE"; then
    GITIGNORE_STATUS="already-listed"
  else
    printf '\n# Added by forge-init\ne2e-evidence/\n' >> "$GITIGNORE"
    GITIGNORE_STATUS="updated"
  fi
else
  echo "forge-init: warning — no .gitignore found at $GITIGNORE; evidence will not be excluded from git." >&2
fi

# 4. Copy rules (skip files that already exist in dest)
RULE_COUNT=0
if [ -d "$RULES_SOURCE" ]; then
  mkdir -p "$RULES_DEST"
  for src in "$RULES_SOURCE"/*.md; do
    [ -e "$src" ] || continue
    base="$(basename "$src")"
    dest="$RULES_DEST/$base"
    if [ ! -f "$dest" ] || [ "$FORCE" -eq 1 ]; then
      cp "$src" "$dest"
      RULE_COUNT=$((RULE_COUNT + 1))
    fi
  done
else
  echo "forge-init: warning — rules source not found at $RULES_SOURCE; skipping rules copy." >&2
fi

echo "forge-init: project=$PROJECT_DIR"
echo "Created .vf/config.json (level=$LEVEL, status=$CONFIG_WRITTEN), rules=$RULE_COUNT, gitignore updated=$GITIGNORE_STATUS, ready."
