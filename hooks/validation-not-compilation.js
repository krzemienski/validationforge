#!/usr/bin/env node
// PostToolUse hook: Remind that compilation success is NOT validation.
// Matches: Bash (after build/compile commands)
//
// Config-driven enforcement via config-loader.js:
//   enabled  → exit(2) when build succeeds (hard block reminder)
//   warn     → write warning to stderr but exit(0) (advisory only)
//   disabled → exit immediately, no action

const { BUILD_PATTERNS } = require('./lib/patterns');
const { loadConfig } = require('./lib/config-loader');

let input = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => input += chunk);
process.stdin.on('end', () => {
  try {
    const config = loadConfig();
    const hookMode = config.getHookConfig('validation-not-compilation');

    // disabled → pass through immediately, no enforcement
    if (hookMode === 'disabled') {
      process.exit(0);
    }

    const data = JSON.parse(input);
    const result = data.tool_result || {};
    const output = typeof result === 'string' ? result : (result.stdout || '');

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
