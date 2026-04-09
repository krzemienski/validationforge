#!/usr/bin/env node
'use strict';

const fs = require('fs');
const path = require('path');
const home = process.env.HOME;
const installedPath = path.join(home, '.claude', 'installed_plugins.json');

let r;
try {
  r = JSON.parse(fs.readFileSync(installedPath, 'utf8'));
} catch (e) {
  console.error('FAIL: Cannot read installed_plugins.json:', e.message);
  process.exit(1);
}

const entry = r['validationforge@validationforge'];
if (!entry) {
  console.error('FAIL: Not registered — no validationforge@validationforge entry in', installedPath);
  process.exit(1);
}

if (!fs.existsSync(entry.path)) {
  console.error('FAIL: Path does not exist:', entry.path);
  process.exit(1);
}

console.log('PASS: plugin registered at existing path:', entry.path);
