#!/bin/bash
# subtask-3-1: Resolve every ${CLAUDE_PLUGIN_ROOT}-prefixed path in all plugin
# manifests against the REAL installed plugin path. Stat each file, confirm mode
# and size, and show a first-line snippet to prove the content is real.
set -u
cd "$(dirname "$0")/../../.." || exit 1

OUT="e2e-evidence/plugin-load-verification/phase-3/step-15-plugin-root-resolution.txt"

echo "=== subtask-3-1: \${CLAUDE_PLUGIN_ROOT} path resolution ===" > "$OUT"
echo "Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$OUT"
echo "" >> "$OUT"

# Resolve installed plugin root
INSTALLED_ROOT=$(node -e 'console.log(require(process.env.HOME+"/.claude/installed_plugins.json")["validationforge@validationforge"].path)')
echo "INSTALLED_ROOT = $INSTALLED_ROOT" >> "$OUT"
echo "" >> "$OUT"

echo "--- Stat of installed root ---" >> "$OUT"
stat -f 'mode=%Sp size=%z mtime=%Sm path=%N' "$INSTALLED_ROOT" >> "$OUT" 2>&1
echo "" >> "$OUT"

echo "--- All \${CLAUDE_PLUGIN_ROOT} references across plugin manifests ---" >> "$OUT"
grep -rnE '\$\{CLAUDE_PLUGIN_ROOT\}' .claude-plugin hooks commands 2>/dev/null >> "$OUT" || true
echo "" >> "$OUT"

REF_COUNT=$(grep -rE '\$\{CLAUDE_PLUGIN_ROOT\}' .claude-plugin hooks commands 2>/dev/null | wc -l | tr -d ' ')
echo "Total refs: $REF_COUNT" >> "$OUT"
echo "" >> "$OUT"

echo "--- Per-reference resolution & stat ---" >> "$OUT"

# Use node to parse hooks.json, resolve each command, stat it
node - "$INSTALLED_ROOT" <<'NODE' >> "$OUT"
const fs = require('fs');
const path = require('path');
const root = process.argv[2];
const manifestPath = 'hooks/hooks.json';
const m = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));

let total = 0;
let resolved = 0;
let failed = [];

for (const eventName of Object.keys(m.hooks)) {
  for (const group of m.hooks[eventName]) {
    for (const h of group.hooks) {
      total++;
      const template = h.command;
      // The installed hooks.json wraps commands with "node ... || true" — handle both forms
      // The *worktree* hooks.json is the simple form
      const matches = template.match(/\$\{CLAUDE_PLUGIN_ROOT\}([^\s"']+)/g) || [];
      for (const tok of matches) {
        const substituted = tok.replace('${CLAUDE_PLUGIN_ROOT}', root);
        let exists = false, size = 0, mode = '', firstLine = '';
        try {
          const st = fs.statSync(substituted);
          exists = true;
          size = st.size;
          mode = '0' + (st.mode & 0o777).toString(8);
          const content = fs.readFileSync(substituted, 'utf8');
          firstLine = (content.split('\n')[0] || '').slice(0, 100);
        } catch (e) {
          failed.push(substituted);
        }
        console.log(`  [${eventName}]`);
        console.log(`    matcher:       ${group.matcher}`);
        console.log(`    template:      ${tok}`);
        console.log(`    substituted:   ${substituted}`);
        console.log(`    exists:        ${exists}`);
        console.log(`    size:          ${size}`);
        console.log(`    mode:          ${mode}`);
        console.log(`    first-line:    ${firstLine}`);
        console.log('');
        if (exists) resolved++;
      }
    }
  }
}
console.log(`SUMMARY: total-refs=${total} resolved=${resolved} failed=${failed.length}`);
if (failed.length) {
  console.log('MISSING:');
  for (const p of failed) console.log('  ' + p);
  process.exit(1);
}
NODE
echo "" >> "$OUT"

echo "--- patterns.ts companion file in installed root (not \${CLAUDE_PLUGIN_ROOT} substituted but required by patterns.js) ---" >> "$OUT"
PATTERNS_TS="$INSTALLED_ROOT/.opencode/plugins/validationforge/patterns.ts"
if [ -f "$PATTERNS_TS" ]; then
  stat -f 'mode=%Sp size=%z path=%N' "$PATTERNS_TS" >> "$OUT"
  echo "first-line: $(head -1 "$PATTERNS_TS")" >> "$OUT"
else
  echo "MISSING: $PATTERNS_TS" >> "$OUT"
fi
echo "" >> "$OUT"

echo "=== done ===" >> "$OUT"
cat "$OUT"
