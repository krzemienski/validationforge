#!/usr/bin/env node
// PreToolUse hook: Block creation of test files, mock files, and stub files.
// Enforces the ValidationForge Iron Rule — no test frameworks, no mocks.
//
// Matches: Write, Edit, MultiEdit
// Blocks if file_path matches test/mock/stub patterns.
//
// Profile-driven enforcement via resolve-profile.js:
//   enabled + rules.block_test_files=true  → deny (permissionDecision: "deny")
//   enabled + rules.block_test_files=false → advisory stderr, exit 0
//   warn                                   → advisory stderr, exit 0
//   disabled                               → exit 0 silently
//
// Env overrides (take precedence over everything):
//   DISABLE_OMC=1         → exit 0 silently
//   VF_SKIP_HOOKS=...     → exit 0 silently if "block-test-files" is listed

const { TEST_PATTERNS, ALLOWLIST } = require('./lib/patterns');
const { resolveProfile, hookState, ruleEnabled } = require('./lib/resolve-profile');

const HOOK_NAME = 'block-test-files';

// H10: cap stdin to 2MB. Hooks should never block a tool call over their
// own input-bound bugs, so we exit 0 (fail-safe) on oversize input rather
// than buffer arbitrarily large TodoWrite / Bash-stdout payloads.
const MAX_INPUT_BYTES = 2 * 1024 * 1024;
let input = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => {
  if (input.length + chunk.length > MAX_INPUT_BYTES) process.exit(0);
  input += chunk;
});
process.stdin.on('end', () => {
  try {
    // Env overrides — highest precedence, exit immediately
    if (process.env.DISABLE_OMC === '1') process.exit(0);
    const skipHooks = (process.env.VF_SKIP_HOOKS || '').split(',').map(s => s.trim());
    if (skipHooks.includes(HOOK_NAME)) process.exit(0);

    const profile = resolveProfile();
    const state   = hookState(profile, HOOK_NAME);

    // disabled → pass through immediately, no enforcement
    if (state === 'disabled') process.exit(0);

    const data      = JSON.parse(input);
    const toolInput = data.tool_input || {};
    const filePath  = toolInput.file_path || toolInput.filePath || '';

    if (!filePath) process.exit(0);

    // Allowlist short-circuit (review finding L4 — single .some() instead
    // of a for-loop keeps the happy path obvious and avoids the visual
    // hiccup of an early `process.exit()` inside a for-of body).
    if (ALLOWLIST.some(re => re.test(filePath))) process.exit(0);

    const matched = TEST_PATTERNS.find(re => re.test(filePath));
    if (matched) {
      if (state === 'warn' || !ruleEnabled(profile, 'block_test_files')) {
        // warn or rule disabled → advisory only, let the write proceed
        process.stderr.write(
          `[ValidationForge] WARNING [${profile.name}]: "${filePath}" matches a test/mock/stub file pattern.\n` +
          `ValidationForge Iron Rule: Never create test files, mock files, or stub files.\n` +
          `Instead: Build and run the real system. Validate through actual user interfaces.\n` +
          `Run /validate to start the correct validation workflow.\n`
        );
        process.exit(0);
      }

      // enabled + rule true → hard block via permissionDecision "deny"
      const output = {
        hookSpecificOutput: {
          hookEventName: 'PreToolUse',
          permissionDecision: 'deny',
          permissionDecisionReason:
            `BLOCKED [${profile.name}]: "${filePath}" matches a test/mock/stub file pattern.\n` +
            `ValidationForge Iron Rule: Never create test files, mock files, or stub files.\n` +
            `Instead: Build and run the real system. Validate through actual user interfaces.\n` +
            `Run /validate to start the correct validation workflow.`
        }
      };
      process.stdout.write(JSON.stringify(output));
      process.exit(0);
    }

    // No match → silent pass-through.
    process.exit(0);
  } catch (e) {
    process.stderr.write(`[ValidationForge] block-test-files hook error: ${e.message}\n`);
    process.exit(0);
  }
});
