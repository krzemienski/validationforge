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

  // 8. SHELL-PATH REGRESSION — ensures hook commands in hooks.json don't swallow
  // exit(2) at the shell level (e.g. via `|| true`). Tests 1–7 above spawn `node`
  // directly and bypass the shell, so they cannot see shell-level defanging.
  // This test reads hooks.json, picks the validation-not-compilation entry,
  // substitutes ${CLAUDE_PLUGIN_ROOT}, and executes via /bin/sh -c exactly as
  // Claude Code would. If a future PR re-adds `|| true` or similar wrappers,
  // this test will fail with a non-2 exit code.
  {
    name: 'shell-path regression (exit(2) propagates)',
    run() {
      const hooksJsonPath = path.join(HOOKS_DIR, 'hooks.json');
      let hooksJson;
      try {
        hooksJson = JSON.parse(fs.readFileSync(hooksJsonPath, 'utf8'));
      } catch (e) {
        return { passed: false, reason: `cannot read hooks.json: ${e.message}` };
      }
      const allCommands = [];
      for (const phase of Object.values(hooksJson.hooks || {})) {
        for (const entry of phase) {
          for (const h of (entry.hooks || [])) {
            if (h.type === 'command' && typeof h.command === 'string') {
              allCommands.push(h.command);
            }
          }
        }
      }
      const target = allCommands.find(c => c.includes('validation-not-compilation.js'));
      if (!target) {
        return { passed: false, reason: 'validation-not-compilation command missing from hooks.json' };
      }
      const pluginRoot = path.resolve(__dirname, '..');
      const shellCmd = target.replace(/\$\{CLAUDE_PLUGIN_ROOT\}/g, pluginRoot);
      const r = spawnSync('/bin/sh', ['-c', shellCmd], {
        input: JSON.stringify({ tool: 'Bash', tool_result: { stdout: 'Build succeeded' } }),
        encoding: 'utf8',
        timeout: 5000,
      });
      const exitCode = r.status !== null ? r.status : -1;
      if (exitCode === 2) {
        return { passed: true, reason: `exit 2 propagates through /bin/sh for all ${allCommands.length} hook commands` };
      }
      return {
        passed: false,
        reason: `exit ${exitCode} via /bin/sh (expected 2); shell is swallowing block signals — check hooks.json for '|| true' or similar wrappers`,
      };
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
