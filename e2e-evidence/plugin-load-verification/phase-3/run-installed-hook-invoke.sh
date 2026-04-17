#!/bin/bash
# subtask-3-2: Invoke hooks/block-test-files.js FROM the INSTALLED plugin path
# (simulating Claude Code's runtime invocation from that working dir). Confirms
# patterns.js loads the sibling .opencode patterns.ts successfully and DENY fires.
set -u
cd "$(dirname "$0")/../../.." || exit 1

OUT="e2e-evidence/plugin-load-verification/phase-3/step-16-installed-hook-invoke.txt"

echo "=== subtask-3-2: invoke hook from installed plugin root ===" > "$OUT"
echo "Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$OUT"
echo "" >> "$OUT"

ROOT=$(node -e 'console.log(require(process.env.HOME+"/.claude/installed_plugins.json")["validationforge@validationforge"].path)')
echo "Installed root: $ROOT" >> "$OUT"
echo "" >> "$OUT"

HOOK="$ROOT/hooks/block-test-files.js"
echo "--- Stat of installed hook ---" >> "$OUT"
stat -f 'mode=%Sp size=%z path=%N' "$HOOK" >> "$OUT" 2>&1
echo "" >> "$OUT"

echo "--- Invoke .test.ts DENY from installed path ---" >> "$OUT"
STDOUT=$(mktemp); STDERR=$(mktemp)
echo '{"tool_name":"Write","tool_input":{"file_path":"scratch/foo.test.ts"}}' | node "$HOOK" > "$STDOUT" 2> "$STDERR"
EXIT=$?
echo "Exit: $EXIT" >> "$OUT"
echo "Stdout:" >> "$OUT"; cat "$STDOUT" >> "$OUT"; echo "" >> "$OUT"
echo "Stderr:" >> "$OUT"; cat "$STDERR" >> "$OUT"; echo "" >> "$OUT"
if grep -q permissionDecision "$STDOUT" && grep -q '"deny"' "$STDOUT"; then
  echo "ASSERTION 3-2a: PASS (permissionDecision=deny emitted from installed path)" >> "$OUT"
else
  echo "ASSERTION 3-2a: FAIL" >> "$OUT"
fi
echo "" >> "$OUT"

# Check that patterns.js did NOT fall back to inline (absence of stderr)
echo "--- Confirm patterns.js loaded from .opencode (no fallback stderr) ---" >> "$OUT"
if grep -q "Using inline fallback" "$STDERR"; then
  echo "ASSERTION 3-2b: FAIL (patterns.js fell back to inline definitions)" >> "$OUT"
else
  echo "ASSERTION 3-2b: PASS (patterns.js loaded external patterns.ts without fallback)" >> "$OUT"
fi
echo "" >> "$OUT"
rm -f "$STDOUT" "$STDERR"

echo "--- Allowlist case from installed path: e2e-evidence/foo.test.md ---" >> "$OUT"
STDOUT=$(mktemp); STDERR=$(mktemp)
echo '{"tool_name":"Write","tool_input":{"file_path":"e2e-evidence/foo.test.md"}}' | node "$HOOK" > "$STDOUT" 2> "$STDERR"
EXIT=$?
echo "Exit: $EXIT" >> "$OUT"
echo "Stdout-bytes: $(wc -c < "$STDOUT" | tr -d ' ')" >> "$OUT"
echo "Stderr:" >> "$OUT"; cat "$STDERR" >> "$OUT"; echo "" >> "$OUT"
if [ "$EXIT" = "0" ] && [ ! -s "$STDOUT" ]; then
  echo "ASSERTION 3-2c: PASS (allowlisted path, silent exit 0)" >> "$OUT"
else
  echo "ASSERTION 3-2c: FAIL" >> "$OUT"
fi
rm -f "$STDOUT" "$STDERR"
echo "" >> "$OUT"

echo "=== done ===" >> "$OUT"
cat "$OUT"
