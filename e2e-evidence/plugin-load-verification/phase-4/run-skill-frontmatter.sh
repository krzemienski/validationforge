#!/bin/bash
# phase-4 static substitute for subtask-4-2 (live skill invocation).
# Parse each skill's SKILL.md YAML frontmatter and validate required fields.
# Also verify 3 specific skills required by spec: web-validation, api-validation, preflight.
set -u
cd "$(dirname "$0")/../../.." || exit 1

OUT="e2e-evidence/plugin-load-verification/phase-4/step-18-skill-frontmatter.txt"

echo "=== phase-4 subtask-4-2 (static substitute): skill frontmatter validation ===" > "$OUT"
echo "Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$OUT"
echo "" >> "$OUT"

node - <<'NODE' >> "$OUT"
const fs = require('fs');
const path = require('path');
const SKILLS_DIR = 'skills';

const names = fs.readdirSync(SKILLS_DIR).filter(n => fs.statSync(path.join(SKILLS_DIR, n)).isDirectory());
console.log(`Total skills directories: ${names.length}`);
console.log('');

let pass = 0, fail = 0;
const details = [];

for (const name of names.sort()) {
  const skillMd = path.join(SKILLS_DIR, name, 'SKILL.md');
  if (!fs.existsSync(skillMd)) {
    console.log(`  FAIL  ${name}/SKILL.md MISSING`);
    fail++; continue;
  }
  const raw = fs.readFileSync(skillMd, 'utf8');
  // Parse YAML frontmatter between --- lines
  const m = raw.match(/^---\s*\n([\s\S]*?)\n---/);
  if (!m) {
    console.log(`  FAIL  ${name}/SKILL.md has no YAML frontmatter`);
    fail++; continue;
  }
  const fm = m[1];
  const hasName = /^name:\s*\S/m.test(fm);
  const hasDesc = /^description:\s*\S/m.test(fm);
  if (!hasName || !hasDesc) {
    console.log(`  FAIL  ${name}/SKILL.md frontmatter missing name=${hasName} or description=${hasDesc}`);
    fail++; continue;
  }
  // Check referenced helper files in the body
  const body = raw.slice(m[0].length);
  const relRefs = body.match(/\b(scripts|templates|config|lib|helpers|references)\/[a-zA-Z0-9_./-]+/g) || [];
  const missingRefs = [];
  for (const ref of [...new Set(relRefs)]) {
    // Relative to skill dir first, then repo root
    const candidates = [
      path.join(SKILLS_DIR, name, ref),
      ref,
    ];
    if (!candidates.some(p => fs.existsSync(p))) {
      missingRefs.push(ref);
    }
  }
  // Extract name value for output
  const nameVal = (fm.match(/^name:\s*(.+)$/m) || [,''])[1].trim();
  const descVal = ((fm.match(/^description:\s*(.+)$/m) || [,''])[1] || '').trim().slice(0, 80);
  console.log(`  PASS  ${name}/SKILL.md  name="${nameVal}"  desc="${descVal}..."${missingRefs.length? '  (unresolved refs: '+missingRefs.join(',')+')':''}`);
  pass++;
  details.push({ name, nameVal, descVal, missingRefs });
}

console.log('');
console.log(`SUMMARY: ${pass} PASS, ${fail} FAIL (of ${names.length})`);
console.log('');

// Confirm the 3 spec-required skills exist
const required = ['web-validation', 'api-validation', 'preflight'];
console.log('Spec-required skills (subtask-4-2):');
for (const r of required) {
  const present = names.includes(r);
  console.log(`  ${present ? 'PASS' : 'FAIL'}  ${r} — ${present ? 'present' : 'MISSING'}`);
}
NODE

echo "" >> "$OUT"
echo "=== done ===" >> "$OUT"
tail -70 "$OUT"
