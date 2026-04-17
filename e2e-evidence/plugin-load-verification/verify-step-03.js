#!/usr/bin/env node
// Verification script for subtask-1-3: validate hooks/hooks.json.
//
// Rules enforced (per task spec):
//   1. hooks/hooks.json is valid JSON.
//   2. The manifest references exactly 7 hook scripts.
//   3. Every ${CLAUDE_PLUGIN_ROOT}/hooks/<name>.js pathname resolves to an
//      existing file inside the INSTALLED plugin path (from
//      ~/.claude/installed_plugins.json), not just the worktree.
//
// Exit codes:
//   0 — all checks pass (prints "OK: <n> hook refs resolved")
//   1 — hooks.json missing or unparseable
//   2 — ~/.claude/installed_plugins.json missing / missing plugin entry
//   3 — ref count != 7
//   4 — one or more referenced files missing in the installed path
const fs = require('fs');
const path = require('path');

const manifestPath = 'hooks/hooks.json';
const installedRegistryPath = path.join(process.env.HOME, '.claude', 'installed_plugins.json');
const pluginKey = 'validationforge@validationforge';

let manifest;
try {
  manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
} catch (e) {
  console.error('FAIL: could not parse', manifestPath, '-', e.message);
  process.exit(1);
}

let installedRoot;
try {
  const reg = JSON.parse(fs.readFileSync(installedRegistryPath, 'utf8'));
  if (!reg[pluginKey] || !reg[pluginKey].path) {
    console.error('FAIL: installed_plugins.json has no entry for', pluginKey);
    process.exit(2);
  }
  installedRoot = reg[pluginKey].path;
} catch (e) {
  console.error('FAIL: could not read', installedRegistryPath, '-', e.message);
  process.exit(2);
}

const refs = [];
for (const ev of Object.keys(manifest.hooks || {})) {
  for (const group of manifest.hooks[ev]) {
    for (const h of group.hooks || []) {
      refs.push(h.command);
    }
  }
}

const missing = refs.filter((r) => {
  const resolved = r.replace('${CLAUDE_PLUGIN_ROOT}', installedRoot);
  return !fs.existsSync(resolved);
});

if (refs.length !== 7) {
  console.error('FAIL: expected 7 hook refs, found', refs.length);
  process.exit(3);
}
if (missing.length) {
  console.error('FAIL: missing files for refs:', missing);
  process.exit(4);
}
console.log('OK:', refs.length, 'hook refs resolved');
