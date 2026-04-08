#!/usr/bin/env node
// PostToolUse hook: Track validation execution state.
// Fires after Bash commands to detect validation-related operations
// and remind about evidence capture.

let input = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => input += chunk);
process.stdin.on('end', () => {
  try {
    const data = JSON.parse(input);
    const command = data.tool_input?.command || '';

    const validationPatterns = [
      /playwright/i,
      /lighthouse/i,
      /simctl/i,
      /xcrun/i,
      /curl.*localhost/i,
      /npm run (dev|start|build)/i,
      /xcodebuild/i,
      /idb /i,
    ];

    const isValidationRelated = validationPatterns.some(p => p.test(command));

    if (isValidationRelated) {
      process.stderr.write(
        '[ValidationForge] validation-state-tracker: Validation activity detected. Remember to capture evidence\n' +
        '(screenshots, logs, responses) to e2e-evidence/ directory.\n'
      );
      process.exit(2);
    }
  } catch (e) {
    process.stderr.write(`[ValidationForge] validation-state-tracker hook error: ${e.message}\n`);
    process.exit(0);
  }
});
