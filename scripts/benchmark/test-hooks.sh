#!/usr/bin/env bash
# Test all ValidationForge hooks with real stdin JSON piping.
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
HOOKS_DIR="$PROJECT_ROOT/hooks"

pass=0
fail=0
total=0

run_test() {
  local hook="$1" input="$2" expect_exit="$3" expect_match="$4" desc="$5"
  total=$((total + 1))

  # Run hook, capture combined output and exit code
  local tmpout="/tmp/vf-test-$$"
  echo "$input" | node "$HOOKS_DIR/$hook" >"$tmpout" 2>&1
  local exit_code=$?
  local combined
  combined=$(cat "$tmpout" 2>/dev/null)
  rm -f "$tmpout"

  local status="PASS"
  if [ "$exit_code" -ne "$expect_exit" ]; then
    status="FAIL(exit=$exit_code,expect=$expect_exit)"
  fi
  if [ -n "$expect_match" ] && [ "$status" = "PASS" ]; then
    if ! echo "$combined" | grep -qi "$expect_match" 2>/dev/null; then
      status="FAIL(no match: $expect_match)"
    fi
  fi

  if [[ "$status" == "PASS" ]]; then
    pass=$((pass + 1))
  else
    fail=$((fail + 1))
  fi

  echo "$status: $hook — $desc"
}

echo "=== ValidationForge Hook Test Suite ==="
echo ""

# --- block-test-files.js (PreToolUse) ---
echo "--- block-test-files.js ---"
run_test "block-test-files.js" '{"tool_name":"Write","tool_input":{"file_path":"src/auth.test.ts"}}' 0 "deny" "blocks .test.ts files"
run_test "block-test-files.js" '{"tool_name":"Write","tool_input":{"file_path":"src/auth.ts"}}' 0 "" "allows normal .ts files"
run_test "block-test-files.js" '{"tool_name":"Write","tool_input":{"file_path":"e2e-evidence/screenshot.png"}}' 0 "" "allowlists e2e-evidence paths"
run_test "block-test-files.js" '{"tool_name":"Write","tool_input":{"file_path":"src/__tests__/util.js"}}' 0 "deny" "blocks __tests__ directory"

# --- evidence-gate-reminder.js (PreToolUse) ---
echo ""
echo "--- evidence-gate-reminder.js ---"
run_test "evidence-gate-reminder.js" '{"tool_name":"TaskUpdate","tool_input":{"status":"completed"}}' 0 "Evidence Gate" "injects checklist on task completion"
run_test "evidence-gate-reminder.js" '{"tool_name":"TaskUpdate","tool_input":{"status":"in_progress"}}' 0 "" "silent on non-completion status"

# --- validation-not-compilation.js (PostToolUse) ---
echo ""
echo "--- validation-not-compilation.js ---"
run_test "validation-not-compilation.js" '{"tool_name":"Bash","tool_result":{"stdout":"build succeeded"}}' 2 "compilation is NOT validation" "fires on build success"
run_test "validation-not-compilation.js" '{"tool_name":"Bash","tool_result":{"stdout":"ls -la output"}}' 0 "" "silent on normal commands"

# --- completion-claim-validator.js (PostToolUse) ---
echo ""
echo "--- completion-claim-validator.js ---"
tmpdir=$(mktemp -d)
pushd "$tmpdir" >/dev/null
run_test "completion-claim-validator.js" '{"tool_name":"Bash","tool_result":{"stdout":"All tests passed"}}' 2 "completion" "fires on claim without evidence"
popd >/dev/null
rm -rf "$tmpdir"
run_test "completion-claim-validator.js" '{"tool_name":"Bash","tool_result":{"stdout":"file listing output"}}' 0 "" "silent on non-completion output"

# --- mock-detection.js (PostToolUse) ---
echo ""
echo "--- mock-detection.js ---"
run_test "mock-detection.js" '{"tool_name":"Write","tool_input":{"content":"jest.mock(\"./api\")"}}' 2 "Mock" "detects jest.mock"
run_test "mock-detection.js" '{"tool_name":"Write","tool_input":{"content":"const api = require(\"./api\")"}}' 0 "" "silent on normal imports"
run_test "mock-detection.js" '{"tool_name":"Write","tool_input":{"content":"sinon.stub(server, \"listen\")"}}' 2 "Mock" "detects sinon.stub"

# --- evidence-quality-check.js (PostToolUse) ---
echo ""
echo "--- evidence-quality-check.js ---"
run_test "evidence-quality-check.js" '{"tool_name":"Write","tool_input":{"file_path":"e2e-evidence/test.png","content":""}}' 2 "empty" "warns on empty evidence file"
run_test "evidence-quality-check.js" '{"tool_name":"Write","tool_input":{"file_path":"e2e-evidence/test.png","content":"binary data"}}' 0 "" "silent on evidence with content"
run_test "evidence-quality-check.js" '{"tool_name":"Write","tool_input":{"file_path":"src/app.js","content":""}}' 0 "" "silent on non-evidence paths"

# --- validation-state-tracker.js (PostToolUse) ---
echo ""
echo "--- validation-state-tracker.js ---"
run_test "validation-state-tracker.js" '{"tool_name":"Bash","tool_input":{"command":"npm run dev"},"tool_result":{"stdout":"ready"}}' 2 "evidence" "tracks npm run dev"
run_test "validation-state-tracker.js" '{"tool_name":"Bash","tool_input":{"command":"git status"},"tool_result":{"stdout":"clean"}}' 0 "" "silent on non-validation commands"

# --- Summary ---
echo ""
echo "=== SUMMARY ==="
echo "Total: $total  Pass: $pass  Fail: $fail"
echo '{"total":'$total',"pass":'$pass',"fail":'$fail'}'
