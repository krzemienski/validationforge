#!/usr/bin/env node
// PostToolUse hook: Remind that compilation success is NOT validation.
// Matches: Bash (after build/compile commands)

const { BUILD_PATTERNS } = require('./patterns');

let input = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => input += chunk);
process.stdin.on('end', () => {
  try {
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
      process.exit(2);
    }
  } catch (e) {
    process.stderr.write(`[ValidationForge] validation-not-compilation hook error: ${e.message}\n`);
    process.exit(0);
  }
});
