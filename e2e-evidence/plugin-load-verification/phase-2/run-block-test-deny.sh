#!/bin/bash
# subtask-2-1: block-test-files.js DENY path
# Pipes test/mock/stub paths to the hook and captures response.
set -u
cd "$(dirname "$0")/../../.." || exit 1

HOOK="hooks/block-test-files.js"
OUT="e2e-evidence/plugin-load-verification/phase-2/step-11-standalone-hook-block-test-deny.txt"

echo "=== subtask-2-1: block-test-files.js DENY path ===" > "$OUT"
echo "Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$OUT"
echo "Hook: $HOOK" >> "$OUT"
echo "" >> "$OUT"

run_case() {
  local label="$1"
  local payload="$2"
  echo "--- Case: $label ---" >> "$OUT"
  echo "Input: $payload" >> "$OUT"
  local stdout_file=$(mktemp)
  local stderr_file=$(mktemp)
  echo "$payload" | node "$HOOK" > "$stdout_file" 2> "$stderr_file"
  local exit_code=$?
  echo "Exit: $exit_code" >> "$OUT"
  echo "Stdout:" >> "$OUT"
  cat "$stdout_file" >> "$OUT"
  echo "" >> "$OUT"
  echo "Stderr:" >> "$OUT"
  cat "$stderr_file" >> "$OUT"
  echo "" >> "$OUT"
  # assertion
  if grep -q "permissionDecision" "$stdout_file" && grep -q "deny" "$stdout_file"; then
    echo "ASSERTION: PASS (permissionDecision=deny present)" >> "$OUT"
  else
    echo "ASSERTION: FAIL (permissionDecision=deny NOT present)" >> "$OUT"
  fi
  echo "" >> "$OUT"
  rm -f "$stdout_file" "$stderr_file"
}

run_case ".test.ts"    '{"tool_name":"Write","tool_input":{"file_path":"src/foo.test.ts"}}'
run_case ".spec.ts"    '{"tool_name":"Write","tool_input":{"file_path":"src/foo.spec.ts"}}'
run_case "__tests__"   '{"tool_name":"Write","tool_input":{"file_path":"src/__tests__/foo.ts"}}'
run_case ".mock.js"    '{"tool_name":"Write","tool_input":{"file_path":"src/user.mock.js"}}'
run_case "Tests.swift" '{"tool_name":"Write","tool_input":{"file_path":"Tests/UserTests.swift"}}'
run_case "test_file.py" '{"tool_name":"Write","tool_input":{"file_path":"src/test_login.py"}}'

echo "=== done ===" >> "$OUT"
cat "$OUT"
