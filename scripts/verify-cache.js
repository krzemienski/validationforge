#!/usr/bin/env node
'use strict';

const path = require('path');
const home = process.env.HOME;
const cachePath = path.join(home, '.claude', 'plugins', 'cache', 'validationforge', 'validationforge', '1.0.0');
const pluginJsonPath = path.join(cachePath, '.claude-plugin', 'plugin.json');

let p;
try {
  p = require(pluginJsonPath);
} catch (e) {
  console.error('FAIL: Cannot load cached plugin.json:', e.message);
  console.error('Expected path:', pluginJsonPath);
  process.exit(1);
}

const required = ['commands', 'skills'];
for (const k of required) {
  if (!p[k]) {
    console.error('FAIL: Cache missing:', k);
    process.exit(1);
  }
}

console.log('PASS: cached plugin.json has directory declarations');
console.log('  commands:', p.commands);
console.log('  skills:', p.skills);
