#!/usr/bin/env node
'use strict';

var p = require('../package.json');
var required = ['name', 'version', 'description', 'license', 'bin', 'engines', 'scripts'];
var missing = required.filter(function(f) { return !p[f]; });

if (missing.length) {
  console.error('MISSING fields:', missing.join(', '));
  process.exit(1);
}

if (!p.scripts.postinstall) {
  console.error('FAIL: scripts.postinstall is missing');
  process.exit(1);
}

if (!p.repository) {
  console.error('FAIL: repository field is missing');
  process.exit(1);
}

if (!p.keywords || p.keywords.length === 0) {
  console.error('FAIL: keywords field is missing or empty');
  process.exit(1);
}

if (!p.files || !p.files.includes('bin/')) {
  console.error('FAIL: bin/ missing from files array');
  process.exit(1);
}

console.log('OK: package.json valid, version=' + p.version);
console.log('  name:           ' + p.name);
console.log('  version:        ' + p.version);
console.log('  description:    ' + p.description);
console.log('  license:        ' + p.license);
console.log('  repository:     ' + p.repository.url);
console.log('  bin:            ' + JSON.stringify(p.bin));
console.log('  postinstall:    ' + p.scripts.postinstall);
console.log('  engines.node:   ' + p.engines.node);
console.log('  keywords:       ' + p.keywords.join(', '));
console.log('  files includes bin/: YES');
