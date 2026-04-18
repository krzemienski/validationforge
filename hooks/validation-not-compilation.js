#!/usr/bin/env node
// PostToolUse hook: Remind that compilation success is NOT validation.
// Matches: Bash (after build/compile commands)
//
// Config-driven enforcement via resolve-profile.js:
//   enabled  → exit(2) when build succeeds (hard block reminder)
//   warn     → write warning to stderr but exit(0) (advisory only)
//   disabled → exit immediately, no action

const { BUILD_PATTERNS } = require('./lib/patterns');
const { resolveProfile, hookState } = require('./lib/resolve-profile');
const { shouldSkip } = require('./lib/env-overrides');

// H10: cap stdin to 2MB. Fail-safe exit 0 on oversize input.
const MAX_INPUT_BYTES = 2 * 1024 * 1024;
let input = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => {
  if (input.length + chunk.length > MAX_INPUT_BYTES) process.exit(0);
  input += chunk;
});
process.stdin.on('end', () => {
  try {
    if (shouldSkip('validation-not-compilation')) process.exit(0);
    const profile = resolveProfile();
    const hookMode = hookState(profile, 'validation-not-compilation');

    // disabled → pass through immediately, no enforcement
    if (hookMode === 'disabled') {
      process.exit(0);
    }

    const data = JSON.parse(input);
    const result = data.tool_result || {};
    const rawOutput = typeof result === 'string' ? result : (result.stdout || '');
    // H3: cap stdout scan to 200KB to bound regex cost on large/adversarial
    // Bash stdout. Slice from the tail — build success markers live at the
    // end of output, not the start.
    const MAX_SCAN_BYTES = 200 * 1024;
    const output = rawOutput.length > MAX_SCAN_BYTES
      ? rawOutput.slice(-MAX_SCAN_BYTES)
      : rawOutput;

    const isBuildSuccess = BUILD_PATTERNS.some(p => p.test(output));

    if (isBuildSuccess) {
      process.stderr.write(
        '[ValidationForge] validation-not-compilation: Build succeeded, but compilation is NOT validation.\n' +
        'Run /validate to verify through real user interfaces.\n' +
        'A successful build only proves syntax is correct, not that features work.\n'
      );
      if (hookMode === 'warn') {
        // warn → advisory only, let execution continue
        process.exit(0);
      }
      // enabled → hard block
      process.exit(2);
    }
  } catch (e) {
    process.stderr.write(`[ValidationForge] validation-not-compilation hook error: ${e.message}\n`);
    process.exit(0);
  }
});
