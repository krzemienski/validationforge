#!/usr/bin/env node
// Confirm the plugin is cached by Claude Code with a valid manifest.
//
// Per the official plugin schema (plugins-reference.md), components in
// commands/, skills/, agents/, and hooks/hooks.json are AUTO-DISCOVERED
// from their default directories. Optional `commands`/`agents`/`hooks`/
// `mcpServers` manifest fields are for ADDITIONAL paths only; `skills`
// is not a valid manifest field at all. This verifier therefore checks
// that the cached manifest has the required metadata fields AND that
// the default component directories exist on disk — not that the
// manifest re-declares paths that CC discovers by convention.

'use strict';

const fs   = require('fs');
const path = require('path');
const os   = require('os');

// Read version from package.json so the cache path stays in sync with
// whatever version this copy advertises — no hand-maintained mirror.
let pkgVersion;
try {
  pkgVersion = require(path.resolve(__dirname, '..', 'package.json')).version;
} catch (e) {
  console.error('FAIL: cannot read package.json to determine version:', e.message);
  process.exit(1);
}

const home         = os.homedir();
const cacheRoot    = path.join(home, '.claude', 'plugins', 'cache',
                               'validationforge', 'validationforge', pkgVersion);
const manifestPath = path.join(cacheRoot, '.claude-plugin', 'plugin.json');

let manifest;
try {
  manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
} catch (e) {
  console.error('FAIL: cannot load cached plugin.json:', e.message);
  console.error('  expected: ' + manifestPath);
  console.error('  (Has Claude Code fetched this version into its cache?)');
  process.exit(1);
}

// Required metadata per the official manifest schema.
const requiredMeta = ['name', 'version', 'description'];
const missing = requiredMeta.filter(k => !manifest[k]);
if (missing.length) {
  console.error('FAIL: cached plugin.json missing metadata: ' + missing.join(', '));
  process.exit(1);
}

// Default component directories. Claude Code auto-loads each if present.
const componentDirs = {
  commands: 'commands',
  skills:   'skills',
  agents:   'agents',
};
const expectedHookFile = 'hooks/hooks.json';

const missingDirs = [];
for (const [label, rel] of Object.entries(componentDirs)) {
  const p = path.join(cacheRoot, rel);
  if (!fs.existsSync(p) || !fs.statSync(p).isDirectory()) missingDirs.push(`${label} (${rel}/)`);
}

const hookFilePath = path.join(cacheRoot, expectedHookFile);
const hooksPresent = fs.existsSync(hookFilePath);

if (missingDirs.length) {
  console.error('FAIL: cached plugin missing default component dirs: ' + missingDirs.join(', '));
  process.exit(1);
}

console.log('PASS: cached plugin at ' + cacheRoot);
console.log('  name:        ' + manifest.name);
console.log('  version:     ' + manifest.version);
console.log('  commands/:   present');
console.log('  skills/:     present');
console.log('  agents/:     present');
console.log('  hooks.json:  ' + (hooksPresent ? 'present' : 'absent (no hooks shipped)'));
