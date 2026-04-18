#!/usr/bin/env node
// Post-install health check: confirm the block-test-files hook is reachable
// at the install path recorded in ~/.claude/installed_plugins.json, or at
// the canonical install path if the manifest is absent.
//
// Why this file exists: install.sh writes a symlink at
// ~/.claude/plugins/validationforge, and postinstall.js writes a symlink
// or directory at the same place. This check catches the common failure
// mode where the plugin "installed" (npm exit 0) but the plugin dir never
// materialized (permission error, conflicting pre-existing file, etc.).

'use strict';

const fs   = require('fs');
const path = require('path');
const os   = require('os');

const HOME            = os.homedir();
const CANONICAL_ROOT  = path.join(HOME, '.claude', 'plugins', 'validationforge');
const MANIFEST_PATH   = path.join(HOME, '.claude', 'installed_plugins.json');
const HOOK_REL        = path.join('hooks', 'block-test-files.js');

function checkAt(root) {
  const hookPath = path.join(root, HOOK_REL);
  return fs.existsSync(hookPath) ? hookPath : null;
}

// 1. Canonical install path
let foundAt = checkAt(CANONICAL_ROOT);

// 2. Fallback: resolve via installed_plugins.json manifest
if (!foundAt && fs.existsSync(MANIFEST_PATH)) {
  try {
    const manifest = JSON.parse(fs.readFileSync(MANIFEST_PATH, 'utf8'));
    const entries = manifest.plugins || manifest || [];
    const list = Array.isArray(entries) ? entries : Object.values(entries);
    for (const entry of list) {
      const root = entry && (entry.path || entry.installDir || entry.root);
      if (root) {
        const hit = checkAt(root);
        if (hit) { foundAt = hit; break; }
      }
    }
  } catch (_) { /* fall through */ }
}

if (foundAt) {
  console.log('PASS: block-test-files.js exists at:', foundAt);
  process.exit(0);
}

console.error('FAIL: block-test-files.js not found.');
console.error('  Checked canonical path: ' + path.join(CANONICAL_ROOT, HOOK_REL));
console.error('  Checked manifest:       ' + MANIFEST_PATH);
console.error('  Ensure ValidationForge is installed via `bash install.sh` or `npm install -g validationforge`.');
process.exit(1);
