#!/usr/bin/env node
// ValidationForge hook verification script.
// Tests all 7 VF hooks with representative input and validates correct output.
// Usage: node ./scripts/verify-hooks.js
// Expected: 7/7 hooks PASS

'use strict';

const path = require('path');
const fs = require('fs');
const os = require('os');
const { spawnSync } = require('child_process');

const HOOKS_DIR = path.join(__dirname, '..', 'hooks');

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/**
 * Run a hook script with the given JSON input and return { exitCode, stdout, stderr }.
 * @param {string} hookName  - filename in hooks/ (e.g. 'block-test-files.js')
 * @param {object} inputObj  - will be JSON-stringified and piped to stdin
 * @param {object} [opts]    - spawnSync options override (e.g. { cwd })
 */
function runHook(hookName, inputObj, opts) {
  const hookPath = path.join(HOOKS_DIR, hookName);
  const input = JSON.stringify(inputObj);
  const result = spawnSync('node', [hookPath], {
    input,
    encoding: 'utf8',
    timeout: 5000,
    ...(opts || {}),
  });
  return {
    exitCode: result.status !== null ? result.status : -1,
    stdout: result.stdout || '',
    stderr: result.stderr || '',
  };
}

/** Make a temp directory, run fn(tmpDir), then clean up. */
function withTempDir(fn) {
  const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'vf-verify-'));
  try {
    return fn(tmpDir);
  } finally {
    fs.rmSync(tmpDir, { recursive: true, force: true });
  }
}

// ---------------------------------------------------------------------------
// Test definitions
// ---------------------------------------------------------------------------
// Each test: { name, run() → { passed, reason } }

const tests = [
  // 1. block-test-files — must return hookSpecificOutput.permissionDecision = "deny"
  {
    name: 'block-test-files',
    run() {
      const r = runHook('block-test-files.js', {
        tool: 'Write',
        tool_input: { file_path: 'src/auth.test.tsx' },
      });
      if (r.exitCode !== 0) {
        return { passed: false, reason: `unexpected exit code ${r.exitCode}` };
      }
      let out;
      try {
        out = JSON.parse(r.stdout);
      } catch (e) {
        return { passed: false, reason: `stdout is not valid JSON: ${r.stdout.slice(0, 80)}` };
      }
      const decision = out?.hookSpecificOutput?.permissionDecision;
      if (decision === 'deny') {
        return { passed: true, reason: 'permissionDecision=deny for .test.tsx' };
      }
      return { passed: false, reason: `permissionDecision="${decision}", expected "deny"` };
    },
  },

  // 2. evidence-gate-reminder — must output additionalContext checklist for status=completed
  {
    name: 'evidence-gate-reminder',
    run() {
      const r = runHook('evidence-gate-reminder.js', {
        tool: 'TaskUpdate',
        tool_input: { status: 'completed' },
      });
      if (r.exitCode !== 0) {
        return { passed: false, reason: `unexpected exit code ${r.exitCode}` };
      }
      let out;
      try {
        out = JSON.parse(r.stdout);
      } catch (e) {
        return { passed: false, reason: `stdout is not valid JSON: ${r.stdout.slice(0, 80)}` };
      }
      const ctx = out?.hookSpecificOutput?.additionalContext || '';
      if (ctx.includes('Evidence Gate') || ctx.includes('ValidationForge')) {
        return { passed: true, reason: 'additionalContext contains evidence checklist' };
      }
      return { passed: false, reason: `additionalContext missing checklist: "${ctx.slice(0, 80)}"` };
    },
  },

  // 3. validation-not-compilation — must exit 2 + stderr reminder when build succeeds
  {
    name: 'validation-not-compilation',
    run() {
      const r = runHook('validation-not-compilation.js', {
        tool: 'Bash',
        tool_result: { stdout: 'Build succeeded' },
      });
      if (r.exitCode !== 2) {
        return { passed: false, reason: `exit code ${r.exitCode}, expected 2` };
      }
      if (r.stderr.includes('compilation is NOT validation') || r.stderr.includes('ValidationForge')) {
        return { passed: true, reason: 'exit 2 + reminder message on build success' };
      }
      return { passed: false, reason: `stderr missing expected reminder: "${r.stderr.slice(0, 80)}"` };
    },
  },

  // 4. completion-claim-validator — must exit 2 when output claims tests pass + no e2e-evidence dir
  {
    name: 'completion-claim-validator',
    run() {
      return withTempDir(tmpDir => {
        const r = runHook(
          'completion-claim-validator.js',
          {
            tool: 'Bash',
            tool_result: { stdout: 'All tests pass' },
          },
          { cwd: tmpDir }
        );
        if (r.exitCode !== 2) {
          return { passed: false, reason: `exit code ${r.exitCode}, expected 2 (no e2e-evidence in tmpdir)` };
        }
        if (r.stderr.includes('completion') || r.stderr.includes('ValidationForge') || r.stderr.includes('evidence')) {
          return { passed: true, reason: 'exit 2 + warning when completion claimed without evidence' };
        }
        return { passed: false, reason: `stderr missing expected warning: "${r.stderr.slice(0, 80)}"` };
      });
    },
  },

  // 5. mock-detection — must exit 2 + stderr warning when jest.mock( found
  {
    name: 'mock-detection',
    run() {
      const r = runHook('mock-detection.js', {
        tool: 'Write',
        tool_input: { content: 'jest.mock("./api")' },
      });
      if (r.exitCode !== 2) {
        return { passed: false, reason: `exit code ${r.exitCode}, expected 2` };
      }
      if (r.stderr.includes('Mock') || r.stderr.includes('mock') || r.stderr.includes('ValidationForge')) {
        return { passed: true, reason: 'exit 2 + mock warning on jest.mock(' };
      }
      return { passed: false, reason: `stderr missing expected warning: "${r.stderr.slice(0, 80)}"` };
    },
  },

  // 6. evidence-quality-check — must exit 2 + stderr warning for empty e2e-evidence file
  {
    name: 'evidence-quality-check',
    run() {
      const r = runHook('evidence-quality-check.js', {
        tool: 'Write',
        tool_input: { file_path: 'e2e-evidence/screenshot.png', content: '' },
      });
      if (r.exitCode !== 2) {
        return { passed: false, reason: `exit code ${r.exitCode}, expected 2` };
      }
      if (r.stderr.includes('empty') || r.stderr.includes('Empty') || r.stderr.includes('ValidationForge')) {
        return { passed: true, reason: 'exit 2 + warning for empty e2e-evidence file' };
      }
      return { passed: false, reason: `stderr missing expected warning: "${r.stderr.slice(0, 80)}"` };
    },
  },

  // 7. validation-state-tracker — must exit 2 + evidence reminder for playwright command
  {
    name: 'validation-state-tracker',
    run() {
      const r = runHook('validation-state-tracker.js', {
        tool: 'Bash',
        tool_input: { command: 'npx playwright test' },
        tool_result: { stdout: 'Ran 5 tests' },
      });
      if (r.exitCode !== 2) {
        return { passed: false, reason: `exit code ${r.exitCode}, expected 2` };
      }
      if (r.stderr.includes('evidence') || r.stderr.includes('ValidationForge') || r.stderr.includes('validation')) {
        return { passed: true, reason: 'exit 2 + evidence reminder for playwright command' };
      }
      return { passed: false, reason: `stderr missing expected reminder: "${r.stderr.slice(0, 80)}"` };
    },
  },
];

// ---------------------------------------------------------------------------
// Runner
// ---------------------------------------------------------------------------

function main() {
  const total = tests.length;
  let passed = 0;
  const results = [];

  for (const test of tests) {
    let outcome;
    try {
      outcome = test.run();
    } catch (err) {
      outcome = { passed: false, reason: `threw: ${err.message}` };
    }

    if (outcome.passed) {
      passed += 1;
      process.stdout.write(`PASS: ${test.name} — ${outcome.reason}\n`);
    } else {
      process.stdout.write(`FAIL: ${test.name} — ${outcome.reason}\n`);
    }
    results.push({ name: test.name, ...outcome });
  }

  process.stdout.write(`\n${passed}/${total} hooks PASS\n`);

  if (passed < total) {
    process.exit(1);
  }
}

main();
