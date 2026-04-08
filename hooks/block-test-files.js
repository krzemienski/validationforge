#!/usr/bin/env node
// PreToolUse hook: Block creation of test files, mock files, and stub files.
// Enforces the ValidationForge Iron Rule — no test frameworks, no mocks.
//
// Matches: Write, Edit, MultiEdit
// Blocks if file_path matches test/mock/stub patterns.
//
// Protocol: hookSpecificOutput.permissionDecision = "deny" (current CC spec)

const TEST_PATTERNS = [
  /\.test\.[jt]sx?$/,
  /\.spec\.[jt]sx?$/,
  /_test\.go$/,
  /test_[^/]+\.py$/,
  /Tests?\.swift$/,
  /\.test\.py$/,
  /\/__tests__\//,
  /\/test\/.*\.(ts|js|tsx|jsx|py|go|swift)$/,
  /\.mock\.[jt]sx?$/,
  /\.stub\.[jt]sx?$/,
  /\/mocks\//,
  /\/stubs\//,
  /\/fixtures\//,
  /\/test-utils\//,
  /\.stories\.[jt]sx?$/,
];

const ALLOWLIST = [
  /e2e-evidence/,
  /validation-evidence/,
  /\.claude\//,
  /validationforge\//,
];

let input = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => input += chunk);
process.stdin.on('end', () => {
  try {
    const data = JSON.parse(input);
    const toolInput = data.tool_input || {};
    const filePath = toolInput.file_path || toolInput.filePath || '';

    if (!filePath) {
      process.exit(0);
    }

    for (const allow of ALLOWLIST) {
      if (allow.test(filePath)) {
        process.exit(0);
      }
    }

    for (const pattern of TEST_PATTERNS) {
      if (pattern.test(filePath)) {
        // Use current CC spec: hookSpecificOutput with permissionDecision "deny"
        const output = {
          hookSpecificOutput: {
            hookEventName: "PreToolUse",
            permissionDecision: "deny",
            permissionDecisionReason:
              `BLOCKED: "${filePath}" matches a test/mock/stub file pattern.\n` +
              `ValidationForge Iron Rule: Never create test files, mock files, or stub files.\n` +
              `Instead: Build and run the real system. Validate through actual user interfaces.\n` +
              `Run /validate to start the correct validation workflow.`
          }
        };
        process.stdout.write(JSON.stringify(output));
        process.exit(0);
      }
    }

    process.exit(0);
  } catch (e) {
    // Log error to stderr so the harness can surface it, then exit cleanly
    process.stderr.write(`[ValidationForge] block-test-files hook error: ${e.message}\n`);
    process.exit(0);
  }
});
