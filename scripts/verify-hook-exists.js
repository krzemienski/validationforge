#!/usr/bin/env node
const fs = require('fs');
const path = process.env.HOME + '/.claude/hooks/block-test-files.js';
if (!fs.existsSync(path)) {
  console.error('FAIL: Hook file missing: ' + path);
  process.exit(1);
}
console.log('PASS: block-test-files.js exists at:', path);
