#!/usr/bin/env node
'use strict';

const fs = require('fs');
const path = require('path');

let failed = false;

// Check package.json files array
const pkg = require('../package.json');

if (!pkg.files || !pkg.files.includes('bin/')) {
  console.error('FAIL: bin/ not in files array');
  failed = true;
} else {
  console.log('OK: files array includes bin/');
}

const requiredFiles = ['bin/', '.claude-plugin/', 'CLAUDE.md', 'README.md', 'skills/', 'hooks/', 'agents/', 'commands/', 'rules/', 'config/', 'templates/', 'scripts/'];
for (const entry of requiredFiles) {
  if (!pkg.files.includes(entry)) {
    console.error(`FAIL: ${entry} not in files array`);
    failed = true;
  }
}

// Check .npmignore
const npmignore = fs.readFileSync(path.join(__dirname, '..', '.npmignore'), 'utf8');

if (!npmignore.includes('.auto-claude')) {
  console.error('FAIL: .auto-claude not in .npmignore');
  failed = true;
} else {
  console.log('OK: .npmignore excludes .auto-claude/');
}

const devOnlyDirs = ['.git/', 'node_modules/', '.auto-claude/'];
for (const dir of devOnlyDirs) {
  if (!npmignore.includes(dir)) {
    console.error(`FAIL: ${dir} not excluded in .npmignore`);
    failed = true;
  } else {
    console.log(`OK: .npmignore excludes ${dir}`);
  }
}

if (failed) {
  process.exit(1);
} else {
  console.log('OK: Package includes bin/, excludes .auto-claude/');
}
