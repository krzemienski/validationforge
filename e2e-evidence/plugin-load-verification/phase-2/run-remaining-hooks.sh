#!/bin/bash
# subtask-2-4: remaining hooks — validation-not-compilation, completion-claim-validator,
# validation-state-tracker, mock-detection, evidence-quality-check
set -u
cd "$(dirname "$0")/../../.." || exit 1

OUT="e2e-evidence/plugin-load-verification/phase-2/step-14-standalone-hook-remaining.txt"

echo "=== subtask-2-4: remaining hooks ===" > "$OUT"
echo "Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$OUT"
echo "" >> "$OUT"

run_hook() {
  local hook="$1"
  local label="$2"
  local payload="$3"
  local expect_exit="$4"       # expected exit code
  local expect_stderr="$5"     # regex expected in stderr (or "NONE")
  echo "### Hook: $hook — Case: $label ###" >> "$OUT"
  echo "Input: $payload" >> "$OUT"
  local stdout_file=$(mktemp)
  local stderr_file=$(mktemp)
  echo "$payload" | node "hooks/$hook" > "$stdout_file" 2> "$stderr_file"
  local exit_code=$?
  echo "Exit: $exit_code (expected: $expect_exit)" >> "$OUT"
  echo "Stdout:" >> "$OUT"
  cat "$stdout_file" >> "$OUT"
  echo "" >> "$OUT"
  echo "Stderr:" >> "$OUT"
  cat "$stderr_file" >> "$OUT"
  echo "" >> "$OUT"
  local pass=1
  if [ "$exit_code" != "$expect_exit" ]; then
    pass=0
  fi
  if [ "$expect_stderr" != "NONE" ]; then
    if ! grep -qE "$expect_stderr" "$stderr_file"; then
      pass=0
    fi
  else
    if [ -s "$stderr_file" ]; then
      # stderr should be empty
      pass=0
    fi
  fi
  if [ "$pass" = "1" ]; then
    echo "ASSERTION: PASS" >> "$OUT"
  else
    echo "ASSERTION: FAIL (exit $exit_code vs expected $expect_exit; stderr regex: $expect_stderr)" >> "$OUT"
  fi
  echo "" >> "$OUT"
  rm -f "$stdout_file" "$stderr_file"
}

# --- validation-not-compilation.js ---
# Build success output -> exit 2 + stderr warning
run_hook validation-not-compilation.js "build-success" \
  '{"tool_name":"Bash","tool_input":{"command":"npm run build"},"tool_result":{"stdout":"webpack 5.x compiled successfully"}}' \
  2 "validation-not-compilation"
# Non-build output -> silent exit 0
run_hook validation-not-compilation.js "non-build-output" \
  '{"tool_name":"Bash","tool_input":{"command":"ls -la"},"tool_result":{"stdout":"drwxr-xr-x  4 user  staff"}}' \
  0 NONE

# --- completion-claim-validator.js ---
# Completion-like output with NO e2e-evidence dir -> BUT worktree HAS e2e-evidence;
# the hook checks for e2e-evidence existence relative to CWD; we run in worktree which has it,
# so it exits silently. Verify hook does not crash.
run_hook completion-claim-validator.js "completion-claim-with-evidence-dir" \
  '{"tool_name":"Bash","tool_input":{"command":"echo done"},"tool_result":{"stdout":"all tests pass"}}' \
  0 NONE
# Non-completion output -> silent exit 0
run_hook completion-claim-validator.js "non-completion-output" \
  '{"tool_name":"Bash","tool_input":{"command":"ls"},"tool_result":{"stdout":"file1 file2"}}' \
  0 NONE

# --- validation-state-tracker.js ---
# Validation command (playwright) -> exit 2 + stderr reminder
run_hook validation-state-tracker.js "playwright-command" \
  '{"tool_name":"Bash","tool_input":{"command":"npx playwright test"}}' \
  2 "validation-state-tracker"
# Non-validation command -> silent exit 0
run_hook validation-state-tracker.js "ls-command" \
  '{"tool_name":"Bash","tool_input":{"command":"ls -la"}}' \
  0 NONE

# --- mock-detection.js ---
# Content with jest.mock( -> exit 2 + stderr warning
run_hook mock-detection.js "jest-mock-content" \
  '{"tool_name":"Write","tool_input":{"file_path":"src/foo.js","content":"jest.mock(\"./bar\")"}}' \
  2 "mock-detection"
# Normal content -> silent exit 0
run_hook mock-detection.js "plain-content" \
  '{"tool_name":"Write","tool_input":{"file_path":"src/foo.js","content":"const x = 1;"}}' \
  0 NONE

# --- evidence-quality-check.js ---
# Empty content to e2e-evidence/ -> exit 2 + stderr warning
run_hook evidence-quality-check.js "empty-evidence" \
  '{"tool_name":"Write","tool_input":{"file_path":"e2e-evidence/foo/step-01.txt","content":""}}' \
  2 "evidence-quality-check"
# Non-evidence path -> silent exit 0
run_hook evidence-quality-check.js "non-evidence-path" \
  '{"tool_name":"Write","tool_input":{"file_path":"src/foo.ts","content":""}}' \
  0 NONE
# Non-empty evidence -> silent exit 0
run_hook evidence-quality-check.js "non-empty-evidence" \
  '{"tool_name":"Write","tool_input":{"file_path":"e2e-evidence/foo/step-01.txt","content":"real evidence content"}}' \
  0 NONE

echo "=== done ===" >> "$OUT"
cat "$OUT"
