#!/usr/bin/env node
// Verification script for subtask-1-1: confirm that the validationforge plugin
// is registered in ~/.claude/installed_plugins.json and that the path it
// points to exists on disk. Exit codes follow the task spec:
//   0 — registered and path exists (prints "OK: plugin registered at <path>")
//   1 — registry exists but key missing
//   2 — registry key present but path does not exist
const fs = require('fs');
const path = require('path');

const registryPath = path.join(process.env.HOME, '.claude', 'installed_plugins.json');
const registry = JSON.parse(fs.readFileSync(registryPath, 'utf8'));
const entry = registry['validationforge@validationforge'];
if (!entry) process.exit(1);
if (!fs.existsSync(entry.path)) process.exit(2);
console.log('OK: plugin registered at', entry.path);
