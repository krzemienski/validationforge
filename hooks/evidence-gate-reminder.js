#!/usr/bin/env node
// PreToolUse hook: Inject evidence checklist when marking tasks complete.
// Matches: TaskUpdate (when status = "completed")

let input = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => input += chunk);
process.stdin.on('end', () => {
  try {
    const data = JSON.parse(input);
    const toolInput = data.tool_input || {};
    const status = toolInput.status || '';

    if (status !== 'completed') {
      process.exit(0);
    }

    const message =
      'ValidationForge Evidence Gate:\n' +
      '[ ] Did you PERSONALLY examine the evidence (not just receive a report)?\n' +
      '[ ] Did you VIEW screenshots and confirm their CONTENT (not just existence)?\n' +
      '[ ] Did you EXAMINE command output (not just exit codes)?\n' +
      '[ ] Can you CITE specific evidence for each validation criterion?\n' +
      '[ ] Would a skeptical reviewer agree this is complete?\n\n' +
      'If ANY checkbox is unchecked, run /validate --fix first.';

    process.stdout.write(JSON.stringify({
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        additionalContext: message
      }
    }));
  } catch (e) {
    process.stderr.write(`[ValidationForge] evidence-gate-reminder hook error: ${e.message}\n`);
    process.exit(0);
  }
});
