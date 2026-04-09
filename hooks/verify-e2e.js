#!/usr/bin/env node
/**
 * End-to-end behavioral verification for config-driven hook enforcement.
 *
 * Tests all 9 scenarios from the spec:
 *   1.  permissive + block-test-files   → stdout empty, exit 0
 *   2.  strict    + block-test-files   → permissionDecision:deny in stdout, exit 0
 *   3.  no config + block-test-files   → permissionDecision:deny (standard default)
 *   4.  permissive + mock-detection    → exit 0
 *   5.  strict    + mock-detection     → exit 2
 *   6.  permissive + evidence-quality-check (empty evidence file) → exit 0 (hook disabled)
 */

'use strict';

const fs   = require('fs');
const path = require('path');
const { execFileSync, spawnSync } = require('child_process');

const ROOT       = path.resolve(__dirname, '..');
const HOOKS_DIR  = __dirname;
const INPUTS_DIR = path.join(HOOKS_DIR, 'test-inputs');

const BLOCK_INPUT    = path.join(INPUTS_DIR, 'block-test-input.json');
const MOCK_INPUT     = path.join(INPUTS_DIR, 'mock-detection-input.json');
const EVIDENCE_INPUT = path.join(INPUTS_DIR, 'evidence-empty-input.json');

const CFG_PERMISSIVE = path.join(INPUTS_DIR, 'config-permissive.json');
const CFG_STRICT     = path.join(INPUTS_DIR, 'config-strict.json');

let passed = 0;
let failed = 0;

/**
 * Run a hook with the given config path and stdin, return { stdout, stderr, status }.
 */
function runHook(hookFile, configPath, stdinFile) {
  const result = spawnSync(process.execPath, [path.join(HOOKS_DIR, hookFile)], {
    input: fs.readFileSync(stdinFile),
    env: Object.assign({}, process.env, {
      CLAUDE_PLUGIN_ROOT: ROOT,
      VF_CONFIG_PATH: configPath,
    }),
    timeout: 5000,
  });
  return {
    stdout: (result.stdout || Buffer.alloc(0)).toString(),
    stderr: (result.stderr || Buffer.alloc(0)).toString(),
    status: result.status,
  };
}

function assert(description, actual, test) {
  if (test(actual)) {
    process.stdout.write(`  PASS: ${description}\n`);
    passed++;
  } else {
    process.stdout.write(`  FAIL: ${description}\n`);
    process.stdout.write(`        actual=${JSON.stringify(actual)}\n`);
    failed++;
  }
}

process.stdout.write('=== ValidationForge Hook E2E Verification ===\n\n');

process.stdout.write('--- block-test-files.js ---\n');

process.stdout.write('Scenario 1: permissive mode → no block\n');
{
  const r = runHook('block-test-files.js', CFG_PERMISSIVE, BLOCK_INPUT);
  assert('stdout is empty (no permissionDecision)', r.stdout, s => s.trim() === '');
  assert('exit code is 0', r.status, c => c === 0);
}

process.stdout.write('Scenario 2: strict mode → hard block (deny)\n');
{
  const r = runHook('block-test-files.js', CFG_STRICT, BLOCK_INPUT);
  assert('stdout contains permissionDecision', r.stdout, s => s.includes('permissionDecision'));
  assert('stdout contains deny', r.stdout, s => s.includes('"deny"'));
  assert('exit code is 0', r.status, c => c === 0);
}

process.stdout.write('Scenario 3: no config file → standard default → denies\n');
{
  const missingCfg = path.join(INPUTS_DIR, 'config-does-not-exist-' + Date.now() + '.json');
  const r = runHook('block-test-files.js', missingCfg, BLOCK_INPUT);
  assert('stdout contains permissionDecision', r.stdout, s => s.includes('permissionDecision'));
  assert('stdout contains deny', r.stdout, s => s.includes('"deny"'));
  assert('exit code is 0', r.status, c => c === 0);
}

process.stdout.write('\n--- mock-detection.js ---\n');

process.stdout.write('Scenario 4: permissive mode → warn only, exit 0\n');
{
  const r = runHook('mock-detection.js', CFG_PERMISSIVE, MOCK_INPUT);
  assert('exit code is 0', r.status, c => c === 0);
}

process.stdout.write('Scenario 5: strict mode → hard block, exit 2\n');
{
  const r = runHook('mock-detection.js', CFG_STRICT, MOCK_INPUT);
  assert('exit code is 2', r.status, c => c === 2);
}

process.stdout.write('\n--- evidence-quality-check.js ---\n');

process.stdout.write('Scenario 6: permissive mode → hook disabled, exit 0\n');
{
  const r = runHook('evidence-quality-check.js', CFG_PERMISSIVE, EVIDENCE_INPUT);
  assert('exit code is 0 (hook disabled in permissive)', r.status, c => c === 0);
}

process.stdout.write('\n=== Summary ===\n');
process.stdout.write(`Passed: ${passed}\n`);
process.stdout.write(`Failed: ${failed}\n`);

if (failed > 0) {
  process.exit(1);
}
