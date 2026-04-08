#!/usr/bin/env node
// PostToolUse hook: Detect mock/stub patterns in written code.
// Matches: Edit, Write, MultiEdit

const MOCK_PATTERNS = [
  /jest\.mock\(/,
  /sinon\.stub\(/,
  /unittest\.mock/,
  /from unittest\.mock import/,
  /mockImplementation/,
  /\.mockReturnValue/,
  /\.mockResolvedValue/,
  /vi\.mock\(/,
  /cy\.intercept\(/,
  /nock\(/,
  /httptest\.NewRecorder/,
  /gomock\.NewController/,
  /XCTestCase/,
  /@testable import/,
  /class.*Tests.*XCTestCase/,
  /func test.*\(\)/,
  /describe\(['"].*['"],\s*\(\)\s*=>/,
  /it\(['"].*['"],\s*\(\)\s*=>/,
  /expect\(.*\)\.(to|not)/,
  /assert\.\w+\(/,
];

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
      process.stdout.write(JSON.stringify({
        hookSpecificOutput: {
          hookEventName: "PostToolUse",
          additionalContext:
            `Mock/test pattern detected in code being written.\n` +
            `ValidationForge Iron Rule: Never create mocks, stubs, or test harnesses.\n` +
            `Fix the real system instead. Run /validate for proper validation.`
        }
      }));
    }
  } catch (e) {
    process.stderr.write(`[ValidationForge] mock-detection hook error: ${e.message}\n`);
    process.exit(0);
  }
});
