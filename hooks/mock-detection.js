#!/usr/bin/env node
// PostToolUse hook: Detect mock/stub patterns in written code.
// Matches: Edit, Write, MultiEdit

const { MOCK_PATTERNS } = require('./patterns');

let input = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => input += chunk);
process.stdin.on('end', () => {
  try {
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
      process.exit(2);
    }
  } catch (e) {
    process.stderr.write(`[ValidationForge] mock-detection hook error: ${e.message}\n`);
    process.exit(0);
  }
});
