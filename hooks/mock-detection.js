#!/usr/bin/env node
// PostToolUse hook: Detect mock/stub patterns in written code.
// Matches: Edit, Write, MultiEdit
//
// Config-driven enforcement via config-loader.js:
//   enabled  → warn to stderr and exit(2) (hard block)
//   warn     → warn to stderr but exit(0) (advisory only)
//   disabled → exit immediately, no action

const { MOCK_PATTERNS } = require('./patterns');
const { loadConfig } = require('./config-loader');

let input = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => input += chunk);
process.stdin.on('end', () => {
  try {
    const config = loadConfig();
    const hookMode = config.getHookConfig('mock-detection');

    // disabled → pass through immediately, no enforcement
    if (hookMode === 'disabled') {
      process.exit(0);
    }

    const data = JSON.parse(input);
    const toolInput = data.tool_input || {};
    const content = toolInput.content || toolInput.new_string || '';

    if (!content) {
      process.exit(0);
    }

    const detectedPatterns = MOCK_PATTERNS.filter(p => p.test(content));

    if (detectedPatterns.length > 0) {
      process.stderr.write(
        '[ValidationForge] mock-detection: Mock/test pattern detected in code being written.\n' +
        'ValidationForge Iron Rule: Never create mocks, stubs, or test harnesses.\n' +
        'Fix the real system instead. Run /validate for proper validation.\n'
      );

      if (hookMode === 'warn') {
        // warn → surface advisory to stderr, let the write proceed
        process.exit(0);
      }

      // enabled → hard block
      process.exit(2);
    }
  } catch (e) {
    process.stderr.write(`[ValidationForge] mock-detection hook error: ${e.message}\n`);
    process.exit(0);
  }
});
