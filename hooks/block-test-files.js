#!/usr/bin/env node
// PreToolUse hook: Block creation of test files, mock files, and stub files.
// Enforces the ValidationForge Iron Rule — no test frameworks, no mocks.
//
// Matches: Write, Edit, MultiEdit
// Blocks if file_path matches test/mock/stub patterns.
//
// Config-driven enforcement via config-loader.js:
//   enabled  → deny (hard block, permissionDecision: "deny")
//   warn     → log warning to stderr, let the write proceed
//   disabled → exit immediately, no action
//
// Protocol: hookSpecificOutput.permissionDecision = "deny" (current CC spec)

const { TEST_PATTERNS, ALLOWLIST } = require('./patterns');
const { loadConfig } = require('./config-loader');

let input = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => input += chunk);
process.stdin.on('end', () => {
  try {
    const config = loadConfig();
    const hookMode = config.getHookConfig('block-test-files');

    // disabled → pass through immediately, no enforcement
    if (hookMode === 'disabled') {
      process.exit(0);
    }

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
        if (hookMode === 'warn') {
          // warn → surface advisory to stderr, let the write proceed
          process.stderr.write(
            `[ValidationForge] WARNING: "${filePath}" matches a test/mock/stub file pattern.\n` +
            `ValidationForge Iron Rule: Never create test files, mock files, or stub files.\n` +
            `Instead: Build and run the real system. Validate through actual user interfaces.\n` +
            `Run /validate to start the correct validation workflow.\n`
          );
          process.exit(0);
        }

        // enabled → hard block via permissionDecision "deny"
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
