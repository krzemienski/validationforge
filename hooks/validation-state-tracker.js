#!/usr/bin/env node
// PostToolUse hook: Track validation execution state.
// Fires after Bash commands to detect validation-related operations
// and remind about evidence capture.
//
// Config-driven enforcement via config-loader.js:
//   enabled  → exit(2) when validation activity detected (hard block reminder)
//   warn     → write warning to stderr but exit(0) (advisory only)
//   disabled → exit immediately, no action

const { VALIDATION_COMMAND_PATTERNS } = require('./lib/patterns');
const { loadConfig } = require('./lib/config-loader');

let input = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => input += chunk);
process.stdin.on('end', () => {
  try {
    const config = loadConfig();
    const hookMode = config.getHookConfig('validation-state-tracker');

    // disabled → pass through immediately, no enforcement
    if (hookMode === 'disabled') {
      process.exit(0);
    }

    const data = JSON.parse(input);
    const command = data.tool_input?.command || '';

    const isValidationRelated = VALIDATION_COMMAND_PATTERNS.some(p => p.test(command));

    if (isValidationRelated) {
      process.stderr.write(
        '[ValidationForge] validation-state-tracker: Validation activity detected. Remember to capture evidence\n' +
        '(screenshots, logs, responses) to e2e-evidence/ directory.\n'
      );
      if (hookMode === 'warn') {
        // warn → advisory only, let execution continue
        process.exit(0);
      }
      // enabled → hard block
      process.exit(2);
    }
  } catch (e) {
    process.stderr.write(`[ValidationForge] validation-state-tracker hook error: ${e.message}\n`);
    process.exit(0);
  }
});
