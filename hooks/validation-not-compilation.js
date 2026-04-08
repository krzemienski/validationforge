#!/usr/bin/env node
// PostToolUse hook: Remind that compilation success is NOT validation.
// Matches: Bash (after build/compile commands)

const BUILD_PATTERNS = [
  /build succeeded/i,
  /compiled successfully/i,
  /compilation succeeded/i,
  /webpack.*compiled/i,
  /next.*build/i,
  /tsc.*--noEmit/i,
  /cargo build/i,
  /go build/i,
  /xcodebuild.*succeeded/i,
  /BUILD SUCCEEDED/,
];

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
      process.stdout.write(JSON.stringify({
        hookSpecificOutput: {
          hookEventName: "PostToolUse",
          additionalContext:
            'Build succeeded, but compilation is NOT validation.\n' +
            'ValidationForge reminder: Run /validate to verify through real user interfaces.\n' +
            'A successful build only proves syntax is correct, not that features work.'
        }
      }));
    }
  } catch (e) {
    process.exit(0);
  }
});
