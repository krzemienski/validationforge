#!/usr/bin/env node
// PostToolUse hook: Detect mock/stub patterns in written code.
// Matches: Edit, Write, MultiEdit
//
// Profile-driven enforcement via resolve-profile.js:
//   enabled + rules.block_mock_patterns=true  → stderr warn + exit(2) (hard block)
//   enabled + rules.block_mock_patterns=false → advisory stderr, exit 0
//   warn                                      → advisory stderr, exit 0
//   disabled                                  → exit 0 silently
//
// Env overrides (take precedence over everything):
//   DISABLE_OMC=1     → exit 0 silently
//   VF_SKIP_HOOKS=... → exit 0 silently if "mock-detection" is listed

const { MOCK_PATTERNS } = require('./lib/patterns');
const { resolveProfile, hookState, ruleEnabled } = require('./lib/resolve-profile');

const HOOK_NAME = 'mock-detection';

let input = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => input += chunk);
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
    const rawContent = toolInput.content || toolInput.new_string || '';

    if (!rawContent) process.exit(0);

    // Review finding M3 + M7: cap input size to prevent ReDoS on adversarial
    // large writes (bundled JS, minified output). 200KB is well past any
    // handwritten source file; beyond that we short-circuit the scan.
    const MAX_SCAN_BYTES = 200 * 1024;
    const content = rawContent.length > MAX_SCAN_BYTES
      ? rawContent.slice(0, MAX_SCAN_BYTES)
      : rawContent;

    // Use `.some()` for short-circuit on first match (review finding M7).
    const hasMatch = MOCK_PATTERNS.some(p => p.test(content));

    if (hasMatch) {
      process.stderr.write(
        `[ValidationForge] mock-detection [${profile.name}]: Mock/test pattern detected in code being written.\n` +
        'ValidationForge Iron Rule: Never create mocks, stubs, or test harnesses.\n' +
        'Fix the real system instead. Run /validate for proper validation.\n'
      );

      if (state === 'warn' || !ruleEnabled(profile, 'block_mock_patterns')) {
        // warn or rule disabled → advisory only, let write proceed
        process.exit(0);
      }

      // enabled + rule true → hard block
      process.exit(2);
    }

    process.exit(0);
  } catch (e) {
    process.stderr.write(`[ValidationForge] mock-detection hook error: ${e.message}\n`);
    process.exit(0);
  }
});
