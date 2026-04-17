#!/bin/bash
# subtask-2-3: evidence-gate-reminder.js
set -u
cd "$(dirname "$0")/../../.." || exit 1

HOOK="hooks/evidence-gate-reminder.js"
OUT="e2e-evidence/plugin-load-verification/phase-2/step-13-standalone-hook-evidence-gate.txt"

echo "=== subtask-2-3: evidence-gate-reminder.js ===" > "$OUT"
echo "Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$OUT"
echo "" >> "$OUT"

run_case() {
  local label="$1"
  local payload="$2"
  local expect="$3"  # "fire" or "silent"
  echo "--- Case: $label (expect: $expect) ---" >> "$OUT"
  echo "Input: $payload" >> "$OUT"
  local stdout_file=$(mktemp)
  local stderr_file=$(mktemp)
  echo "$payload" | node "$HOOK" > "$stdout_file" 2> "$stderr_file"
  local exit_code=$?
  echo "Exit: $exit_code" >> "$OUT"
  echo "Stdout-bytes: $(wc -c < "$stdout_file" | tr -d ' ')" >> "$OUT"
  echo "Stdout:" >> "$OUT"
  cat "$stdout_file" >> "$OUT"
  echo "" >> "$OUT"
  echo "Stderr:" >> "$OUT"
  cat "$stderr_file" >> "$OUT"
  echo "" >> "$OUT"
  if [ "$expect" = "fire" ]; then
    if grep -q "additionalContext" "$stdout_file" && grep -q "PERSONALLY examine" "$stdout_file"; then
      echo "ASSERTION: PASS (additionalContext with evidence checklist fired)" >> "$OUT"
    else
      echo "ASSERTION: FAIL (expected fire but checklist not found)" >> "$OUT"
    fi
  else
    if [ "$exit_code" = "0" ] && [ "$(wc -c < "$stdout_file")" -eq 0 ]; then
      echo "ASSERTION: PASS (silent as expected)" >> "$OUT"
    else
      echo "ASSERTION: FAIL (expected silent but got output)" >> "$OUT"
    fi
  fi
  echo "" >> "$OUT"
  rm -f "$stdout_file" "$stderr_file"
}

run_case "status=completed"   '{"tool_name":"TaskUpdate","tool_input":{"status":"completed"}}' fire
run_case "status=in_progress" '{"tool_name":"TaskUpdate","tool_input":{"status":"in_progress"}}' silent
run_case "status=pending"     '{"tool_name":"TaskUpdate","tool_input":{"status":"pending"}}' silent
run_case "status=missing"     '{"tool_name":"TaskUpdate","tool_input":{}}' silent

echo "=== done ===" >> "$OUT"
cat "$OUT"
