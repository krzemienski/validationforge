#!/usr/bin/env bash
# Static verification of the OpenCode plugin structure.
# Exits 0 on all-pass, 1 on any failure.
#
# This script verifies the plugin CAN load, not that it HAS loaded in a live
# OpenCode session. See README.md "Known Limitations" #6 and
# docs/opencode-plugin-parity.md for runtime verification status.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PLUGIN_DIR="$ROOT/.opencode/plugins/validationforge"

pass=0
fail=0
report=""

check() {
  local label="$1"
  local status="$2"
  local detail="$3"
  if [ "$status" = "PASS" ]; then
    pass=$((pass + 1))
    report="${report}  [PASS] ${label}: ${detail}\n"
  else
    fail=$((fail + 1))
    report="${report}  [FAIL] ${label}: ${detail}\n"
  fi
}

echo "=== OpenCode Plugin Static Verification ==="
echo "Plugin dir: $PLUGIN_DIR"
echo ""

# 1. index.ts exists
if [ -f "$PLUGIN_DIR/index.ts" ]; then
  lines=$(wc -l < "$PLUGIN_DIR/index.ts" | tr -d ' ')
  check "index.ts present" "PASS" "${lines} lines"
else
  check "index.ts present" "FAIL" "missing at $PLUGIN_DIR/index.ts"
fi

# 2. patterns.ts exists
if [ -f "$PLUGIN_DIR/patterns.ts" ]; then
  check "patterns.ts present" "PASS" "$(wc -l < "$PLUGIN_DIR/patterns.ts" | tr -d ' ') lines"
else
  check "patterns.ts present" "FAIL" "missing"
fi

# 3. package.json valid JSON
if [ -f "$PLUGIN_DIR/package.json" ]; then
  if node -e "JSON.parse(require('fs').readFileSync('$PLUGIN_DIR/package.json'))" 2>/dev/null; then
    check "package.json valid JSON" "PASS" "parsed successfully"
  else
    check "package.json valid JSON" "FAIL" "JSON.parse threw"
  fi
else
  check "package.json present" "FAIL" "missing"
fi

# 4. package.json declares @opencode-ai/plugin dependency
if grep -q '"@opencode-ai/plugin"' "$PLUGIN_DIR/package.json" 2>/dev/null; then
  check "declares @opencode-ai/plugin dep" "PASS" "found in dependencies"
else
  check "declares @opencode-ai/plugin dep" "FAIL" "dependency missing"
fi

# 5. index.ts imports Plugin type
if grep -q 'from "@opencode-ai/plugin"' "$PLUGIN_DIR/index.ts" 2>/dev/null; then
  check "imports @opencode-ai/plugin type" "PASS" "Plugin type imported"
else
  check "imports @opencode-ai/plugin type" "FAIL" "Plugin type import missing"
fi

# 6. index.ts registers vf_validate custom tool
if grep -q 'vf_validate:' "$PLUGIN_DIR/index.ts" 2>/dev/null; then
  check "vf_validate custom tool registered" "PASS" "tool key found"
else
  check "vf_validate custom tool registered" "FAIL" "tool key missing"
fi

# 7. index.ts registers vf_check_evidence custom tool
if grep -q 'vf_check_evidence:' "$PLUGIN_DIR/index.ts" 2>/dev/null; then
  check "vf_check_evidence custom tool registered" "PASS" "tool key found"
else
  check "vf_check_evidence custom tool registered" "FAIL" "tool key missing"
fi

# 8. index.ts declares permission.ask hook handler
if grep -qE '(permission\.ask|"permission"[[:space:]]*:)' "$PLUGIN_DIR/index.ts" 2>/dev/null; then
  check "permission hook handler" "PASS" "permission handler found"
else
  check "permission hook handler" "FAIL" "no permission handler"
fi

# 9. index.ts declares tool.execute.after hook handler
if grep -qE '(tool\.execute\.after|"tool\.execute\.after")' "$PLUGIN_DIR/index.ts" 2>/dev/null; then
  check "tool.execute.after hook handler" "PASS" "handler found"
else
  check "tool.execute.after hook handler" "FAIL" "no tool.execute.after handler"
fi

# 10. index.ts declares shell.env hook handler
if grep -qE '(shell\.env|"shell\.env")' "$PLUGIN_DIR/index.ts" 2>/dev/null; then
  check "shell.env hook handler" "PASS" "handler found"
else
  check "shell.env hook handler" "FAIL" "no shell.env handler"
fi

# 11. Claude Code commands count >= 5 (plugin reuses them)
if [ -d "$ROOT/commands" ]; then
  cmd_count=$(find "$ROOT/commands" -maxdepth 1 -name "*.md" | wc -l | tr -d ' ')
  if [ "$cmd_count" -ge 5 ]; then
    check "commands/ >= 5 files" "PASS" "${cmd_count} command files"
  else
    check "commands/ >= 5 files" "FAIL" "only ${cmd_count} found"
  fi
else
  check "commands/ directory" "FAIL" "missing"
fi

echo -e "$report"
echo "---"
echo "Total: $((pass + fail))  PASS: ${pass}  FAIL: ${fail}"

if [ "$fail" -eq 0 ]; then
  echo "Result: ALL CHECKS PASSED"
  exit 0
else
  echo "Result: FAILED (${fail} check(s) failed)"
  exit 1
fi
