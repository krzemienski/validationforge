#!/usr/bin/env bash
# Verify a ValidationForge setup is correctly configured
# Usage: bash scripts/verify-setup.sh [project_dir]

set -euo pipefail

PROJECT_DIR="${1:-$(pwd)}"
CONFIG_FILE="${HOME}/.claude/.vf-config.json"
PASS=0
FAIL=0

ok()      { echo "  [OK] $1";      PASS=$((PASS + 1)); }
missing() { echo "  [MISSING] $1"; FAIL=$((FAIL + 1)); }

echo "=== ValidationForge Setup Verification ==="
echo ""

# --- 1. Config file ---
echo "Config (~/.claude/.vf-config.json):"

if [ ! -f "$CONFIG_FILE" ]; then
  missing "Config file not found: $CONFIG_FILE"
else
  ok "Config file exists: $CONFIG_FILE"

  for field in setupCompleted enforcement platform projectPath; do
    value=$(jq -r --arg f "$field" '.[$f] // empty' "$CONFIG_FILE" 2>/dev/null)
    if [ -n "$value" ] && [ "$value" != "null" ]; then
      ok "Field: $field = $value"
    else
      missing "Field: $field (not set or null)"
    fi
  done
fi

echo ""

# --- 2. Rules ---
echo "Rules (.claude/rules/ or ~/.claude/rules/vf-*.md):"

REQUIRED_RULES="validation-discipline evidence-management platform-detection execution-workflow team-validation"

for rule in $REQUIRED_RULES; do
  local_path="${PROJECT_DIR}/.claude/rules/${rule}.md"
  global_path="${HOME}/.claude/rules/vf-${rule}.md"

  if [ -f "$local_path" ]; then
    ok "Rule (local): $rule"
  elif [ -f "$global_path" ]; then
    ok "Rule (global): $rule"
  else
    missing "Rule: $rule (not in .claude/rules/ or ~/.claude/rules/)"
  fi
done

echo ""

# --- 3. Evidence directory ---
echo "Evidence directory:"

if [ -d "${PROJECT_DIR}/e2e-evidence" ]; then
  ok "Evidence directory: e2e-evidence/"
else
  missing "Evidence directory not found: e2e-evidence/"
fi

echo ""

# --- Summary ---
TOTAL=$((PASS + FAIL))
echo "=== Results: ${PASS}/${TOTAL} checks passed ==="

if [ "$FAIL" -gt 0 ]; then
  echo ""
  echo "  ${FAIL} check(s) failed. Run /vf-setup to complete configuration."
  exit 1
fi

echo ""
echo "  Setup is correctly configured."
exit 0
