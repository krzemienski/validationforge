#!/bin/bash
# phase-4 simulated substitute for subtasks 4-3 and 4-4 (live-session hook firing).
# Invoke block-test-files and evidence-gate-reminder with a payload that exactly matches
# what Claude Code would construct when a user issues the corresponding tool call.
# We cannot launch a live `claude` CLI from within this subagent, so this is the
# closest reproducible proxy — it exercises the same code path the live session would.
set -u
cd "$(dirname "$0")/../../.." || exit 1

OUT="e2e-evidence/plugin-load-verification/phase-4/step-19-realistic-hook-invocations.txt"

echo "=== phase-4 subtasks 4-3 + 4-4 (live proxy): realistic hook invocations ===" > "$OUT"
echo "Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$OUT"
echo "" >> "$OUT"

ROOT=$(node -e 'console.log(require(process.env.HOME+"/.claude/installed_plugins.json")["validationforge@validationforge"].path)')
echo "Installed plugin root: $ROOT" >> "$OUT"
echo "(Using installed plugin hooks — these are the paths Claude Code actually invokes.)" >> "$OUT"
echo "" >> "$OUT"

# ========= subtask 4-3 proxy: Write scratch/foo.test.ts =========
echo "--- subtask-4-3 proxy: Write tool call for scratch/foo.test.ts ---" >> "$OUT"
echo "Payload (matches Claude Code PreToolUse event shape):" >> "$OUT"
PAYLOAD='{"tool_name":"Write","tool_input":{"file_path":"scratch/foo.test.ts","content":"export const x = 1;"}}'
echo "  $PAYLOAD" >> "$OUT"
STDOUT=$(mktemp); STDERR=$(mktemp)
echo "$PAYLOAD" | node "$ROOT/hooks/block-test-files.js" > "$STDOUT" 2> "$STDERR"
EXIT=$?
echo "Exit: $EXIT" >> "$OUT"
echo "Stdout:" >> "$OUT"; cat "$STDOUT" >> "$OUT"; echo "" >> "$OUT"
echo "Stderr:" >> "$OUT"; cat "$STDERR" >> "$OUT"; echo "" >> "$OUT"

# Parse stdout as JSON and assert the PreToolUse protocol fields
node - "$STDOUT" >> "$OUT" 2>&1 <<'NODE'
const fs = require('fs');
const raw = fs.readFileSync(process.argv[2], 'utf8');
try {
  const p = JSON.parse(raw);
  const h = p.hookSpecificOutput || {};
  const conditions = {
    hookEventName: h.hookEventName === 'PreToolUse',
    permissionDecision: h.permissionDecision === 'deny',
    reasonMentionsIronRule: /Iron Rule/.test(h.permissionDecisionReason || ''),
    reasonQuotesFilePath: /foo\.test\.ts/.test(h.permissionDecisionReason || ''),
  };
  console.log('Parsed hookSpecificOutput:');
  console.log('  hookEventName =', h.hookEventName, conditions.hookEventName ? 'PASS' : 'FAIL');
  console.log('  permissionDecision =', h.permissionDecision, conditions.permissionDecision ? 'PASS' : 'FAIL');
  console.log('  reason mentions "Iron Rule":', conditions.reasonMentionsIronRule ? 'PASS' : 'FAIL');
  console.log('  reason quotes file path:', conditions.reasonQuotesFilePath ? 'PASS' : 'FAIL');
  const allPass = Object.values(conditions).every(Boolean);
  console.log('ASSERTION subtask-4-3: ' + (allPass ? 'PASS' : 'FAIL'));
} catch (e) {
  console.log('ASSERTION subtask-4-3: FAIL (stdout not valid JSON: ' + e.message + ')');
}
NODE
rm -f "$STDOUT" "$STDERR"
echo "" >> "$OUT"

# ========= subtask 4-4 proxy: TaskUpdate status=completed =========
echo "--- subtask-4-4 proxy: TaskUpdate status=completed ---" >> "$OUT"
PAYLOAD='{"tool_name":"TaskUpdate","tool_input":{"status":"completed","task_id":"abc123","task_description":"finish the foo"}}'
echo "Payload: $PAYLOAD" >> "$OUT"
STDOUT=$(mktemp); STDERR=$(mktemp)
echo "$PAYLOAD" | node "$ROOT/hooks/evidence-gate-reminder.js" > "$STDOUT" 2> "$STDERR"
EXIT=$?
echo "Exit: $EXIT" >> "$OUT"
echo "Stdout:" >> "$OUT"; cat "$STDOUT" >> "$OUT"; echo "" >> "$OUT"
echo "Stderr:" >> "$OUT"; cat "$STDERR" >> "$OUT"; echo "" >> "$OUT"

node - "$STDOUT" >> "$OUT" 2>&1 <<'NODE'
const fs = require('fs');
const raw = fs.readFileSync(process.argv[2], 'utf8');
try {
  const p = JSON.parse(raw);
  const h = p.hookSpecificOutput || {};
  const ctx = h.additionalContext || '';
  const c = {
    hookEventName: h.hookEventName === 'PreToolUse',
    hasAdditionalContext: ctx.length > 0,
    hasPersonallyExamine: /PERSONALLY examine/.test(ctx),
    hasFiveItems: (ctx.match(/^\[ \]/gm) || []).length >= 5,
  };
  console.log('Parsed hookSpecificOutput:');
  console.log('  hookEventName =', h.hookEventName, c.hookEventName ? 'PASS' : 'FAIL');
  console.log('  additionalContext present:', c.hasAdditionalContext ? 'PASS' : 'FAIL');
  console.log('  mentions "PERSONALLY examine":', c.hasPersonallyExamine ? 'PASS' : 'FAIL');
  console.log('  5-item checklist:', c.hasFiveItems ? 'PASS' : 'FAIL');
  const allPass = Object.values(c).every(Boolean);
  console.log('ASSERTION subtask-4-4: ' + (allPass ? 'PASS' : 'FAIL'));
} catch (e) {
  console.log('ASSERTION subtask-4-4: FAIL (stdout not valid JSON: ' + e.message + ')');
}
NODE
rm -f "$STDOUT" "$STDERR"
echo "" >> "$OUT"

echo "=== done ===" >> "$OUT"
cat "$OUT"
