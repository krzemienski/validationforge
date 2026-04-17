#!/bin/bash
# subtask-2-2: block-test-files.js ALLOWLIST path
set -u
cd "$(dirname "$0")/../../.." || exit 1

HOOK="hooks/block-test-files.js"
OUT="e2e-evidence/plugin-load-verification/phase-2/step-12-standalone-hook-block-test-allow.txt"

echo "=== subtask-2-2: block-test-files.js ALLOWLIST path ===" > "$OUT"
echo "Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$OUT"
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
  echo "Stdout-bytes: $(wc -c < "$stdout_file" | tr -d ' ')" >> "$OUT"
  echo "Stdout-content:" >> "$OUT"
  cat "$stdout_file" >> "$OUT"
  echo "" >> "$OUT"
  echo "Stderr:" >> "$OUT"
  cat "$stderr_file" >> "$OUT"
  echo "" >> "$OUT"
  # assertion: exit 0 and empty stdout
  if [ "$exit_code" = "0" ] && [ "$(wc -c < "$stdout_file")" -eq 0 ]; then
    echo "ASSERTION: PASS (exit=0, empty stdout, allowlisted path)" >> "$OUT"
  else
    echo "ASSERTION: FAIL (expected exit=0 + empty stdout)" >> "$OUT"
  fi
  echo "" >> "$OUT"
  rm -f "$stdout_file" "$stderr_file"
}

run_case "e2e-evidence/journey/notes.test.md" '{"tool_name":"Write","tool_input":{"file_path":"e2e-evidence/journey/notes.test.md"}}'
run_case ".claude/skills/foo.spec.md"         '{"tool_name":"Write","tool_input":{"file_path":".claude/skills/foo.spec.md"}}'
run_case "validation-evidence/test.ts"        '{"tool_name":"Write","tool_input":{"file_path":"validation-evidence/test.ts"}}'
run_case "non-matching regular src/foo.ts"    '{"tool_name":"Write","tool_input":{"file_path":"src/foo.ts"}}'

echo "=== done ===" >> "$OUT"
cat "$OUT"
