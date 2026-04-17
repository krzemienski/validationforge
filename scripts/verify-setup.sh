#!/usr/bin/env bash
# Verify a ValidationForge setup is correctly configured
# Usage: bash scripts/verify-setup.sh [project_dir]

set -euo pipefail

PROJECT_DIR="${1:-$(pwd)}"
CONFIG_FILE="${HOME}/.claude/.vf-config.json"
PLUGIN_CACHE_PATH="${HOME}/.claude/plugins/cache/validationforge/validationforge/1.0.0"
INSTALLED_PLUGINS_FILE="${HOME}/.claude/plugins/installed_plugins.json"
PASS=0
FAIL=0

ok()      { echo "  [OK] $1";      PASS=$((PASS + 1)); }
missing() { echo "  [MISSING] $1"; FAIL=$((FAIL + 1)); }

echo "=== ValidationForge Setup Verification ==="
echo ""

# --- 0. Plugin install state (required by acceptance criteria for phase-1 preflight) ---
# Three checks:
#   (a) plugin cache path present at ~/.claude/plugins/cache/validationforge/validationforge/1.0.0
#       — may be a real directory or a symlink, both are valid install layouts
#   (b) installed_plugins.json registers validationforge
#   (c) ~/.claude/.vf-config.json exists with a strictness field
echo "Plugin install state:"

# (a) Plugin cache path
if [ -L "$PLUGIN_CACHE_PATH" ]; then
  link_target=$(readlink "$PLUGIN_CACHE_PATH" 2>/dev/null || echo "?")
  ok "Plugin cache symlink present: $PLUGIN_CACHE_PATH -> $link_target"
elif [ -d "$PLUGIN_CACHE_PATH" ]; then
  ok "Plugin cache directory present: $PLUGIN_CACHE_PATH"
else
  missing "Plugin cache path not present: $PLUGIN_CACHE_PATH"
fi

# (b) installed_plugins.json registers validationforge
# The file shape varies between Claude Code versions. Known shapes:
#   - { "version": ..., "plugins": { "<name>@<marketplace>": [...] } }
#   - { "<name>@<marketplace>": [...] } (top-level map)
# Check registration keys at either location.
if [ ! -f "$INSTALLED_PLUGINS_FILE" ]; then
  missing "installed_plugins.json not found: $INSTALLED_PLUGINS_FILE"
else
  if jq -e '
    (((.plugins // {}) | keys_unsorted) + (keys_unsorted // []))
    | any(test("validationforge"; "i"))
  ' "$INSTALLED_PLUGINS_FILE" > /dev/null 2>&1; then
    ok "installed_plugins.json registers validationforge"
  else
    missing "installed_plugins.json does not register validationforge"
  fi
fi

# (c) ~/.claude/.vf-config.json exists with a strictness field
if [ ! -f "$CONFIG_FILE" ]; then
  missing "Config file not found for strictness check: $CONFIG_FILE"
else
  # Accept either top-level "strictness" or nested "enforcement.strictness"
  strictness_val=$(jq -r '(.strictness // .enforcement.strictness // .enforcement // empty)' "$CONFIG_FILE" 2>/dev/null)
  if [ -n "$strictness_val" ] && [ "$strictness_val" != "null" ]; then
    ok "Config has strictness field: $strictness_val"
  else
    missing "Config missing strictness field: $CONFIG_FILE"
  fi
fi

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
  echo "  ${FAIL} check(s) failed. Run /vf-setup in a live Claude Code session to complete configuration."
  echo "  Phase-1 gate: do NOT proceed to phase-2 / phase-3 until this is green."
  exit 1
fi

echo ""
echo "  Setup is correctly configured."
exit 0
