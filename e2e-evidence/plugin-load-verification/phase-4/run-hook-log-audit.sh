#!/bin/bash
# phase-4 subtask-4-5 proxy: scan all installed hook sources for known error-producing
# conditions, and aggregate stderr from all Phase 2/3/4 hook invocations. Confirm zero
# [ValidationForge] error lines, ENOENT, "Cannot find", or Node stack traces.
set -u
cd "$(dirname "$0")/../../.." || exit 1

OUT="e2e-evidence/plugin-load-verification/phase-4/step-20-hook-log-audit.txt"

echo "=== phase-4 subtask-4-5 (proxy): aggregate hook stderr audit ===" > "$OUT"
echo "Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$OUT"
echo "" >> "$OUT"

ROOT=$(node -e 'console.log(require(process.env.HOME+"/.claude/installed_plugins.json")["validationforge@validationforge"].path)')
echo "Installed plugin root: $ROOT" >> "$OUT"
echo "" >> "$OUT"

echo "--- Aggregated stderr across all installed hooks (benign payload) ---" >> "$OUT"
ALL_STDERR=$(mktemp)

# For each installed hook, invoke with a minimal valid JSON payload that matches its
# tool_name matcher, and capture stderr.
INVOKE() {
  local hook="$1"; local payload="$2"
  echo "[$hook]" >> "$ALL_STDERR"
  echo "$payload" | node "$ROOT/hooks/$hook" 2>> "$ALL_STDERR" >/dev/null
  echo "" >> "$ALL_STDERR"
}

INVOKE block-test-files.js           '{"tool_name":"Write","tool_input":{"file_path":"src/foo.ts"}}'
INVOKE evidence-gate-reminder.js     '{"tool_name":"TaskUpdate","tool_input":{"status":"in_progress"}}'
INVOKE validation-not-compilation.js '{"tool_name":"Bash","tool_input":{"command":"ls"},"tool_result":{"stdout":"file"}}'
INVOKE completion-claim-validator.js '{"tool_name":"Bash","tool_input":{"command":"ls"},"tool_result":{"stdout":"file"}}'
INVOKE validation-state-tracker.js   '{"tool_name":"Bash","tool_input":{"command":"ls"}}'
INVOKE mock-detection.js             '{"tool_name":"Write","tool_input":{"file_path":"src/foo.js","content":"const x=1;"}}'
INVOKE evidence-quality-check.js     '{"tool_name":"Write","tool_input":{"file_path":"src/foo.ts","content":"x"}}'

echo "Full aggregated stderr (from benign payloads; should be empty):" >> "$OUT"
cat "$ALL_STDERR" >> "$OUT"
echo "" >> "$OUT"

echo "--- Grep for error signatures ---" >> "$OUT"
# Use a single awk pass to tally each pattern, avoiding subshell-count trailing-newline bugs
PATS=("\\[ValidationForge\\].*error" "ENOENT" "Cannot find" "^Error: " "TypeError" "SyntaxError" "ReferenceError" "Using inline fallback")
TOTAL_ERR=0
for p in "${PATS[@]}"; do
  COUNT=$(awk -v pat="$p" 'BEGIN{c=0} $0 ~ pat {c++} END{print c}' "$ALL_STDERR")
  echo "  pattern '$p' matches: $COUNT" >> "$OUT"
  TOTAL_ERR=$((TOTAL_ERR + COUNT))
done
echo "" >> "$OUT"

echo "Total error-signature lines: $TOTAL_ERR" >> "$OUT"
if [ "$TOTAL_ERR" -eq 0 ]; then
  echo "ASSERTION subtask-4-5: PASS (zero error signatures across all 7 installed hooks)" >> "$OUT"
else
  echo "ASSERTION subtask-4-5: FAIL (see stderr above)" >> "$OUT"
fi
rm -f "$ALL_STDERR"

echo "" >> "$OUT"
echo "--- Also scan Phase 2/3 captured stderr for the same signatures ---" >> "$OUT"
EXTRA_SRC="e2e-evidence/plugin-load-verification/phase-2 e2e-evidence/plugin-load-verification/phase-3"
for dir in $EXTRA_SRC; do
  for f in "$dir"/step-*.txt; do
    [ -f "$f" ] || continue
    # Look only at content inside "Stderr:" sections; count error-signature lines
    ERR_LINES=$(awk '
      /^Stderr:$/ { p=1; next }
      /^[-A-Z]/   { p=0 }
      p && /\[ValidationForge\].*error|ENOENT|Cannot find|^Error:|^TypeError|^SyntaxError|^ReferenceError/ { c++ }
      END { print (c+0) }
    ' "$f")
    echo "  $(basename "$f"): error-signature lines in Stderr blocks = $ERR_LINES" >> "$OUT"
  done
done
echo "" >> "$OUT"

echo "=== done ===" >> "$OUT"
cat "$OUT"
