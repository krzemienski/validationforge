#!/usr/bin/env node
// Verification script for subtask-1-2: validate that .claude-plugin/plugin.json
// and .claude-plugin/marketplace.json parse as JSON and contain the required
// fields. Exit codes follow the task spec:
//   0 — both manifests valid (prints "OK: <name> <version>")
//   1 — plugin.json missing required name or version
//   2 — marketplace.json missing a non-empty plugins array
const fs = require('fs');

const p = JSON.parse(fs.readFileSync('.claude-plugin/plugin.json', 'utf8'));
const m = JSON.parse(fs.readFileSync('.claude-plugin/marketplace.json', 'utf8'));
if (!p.name || !p.version) process.exit(1);
if (!Array.isArray(m.plugins) || m.plugins.length === 0) process.exit(2);
console.log('OK:', p.name, p.version);
