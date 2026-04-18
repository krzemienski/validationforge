#!/usr/bin/env node
// PreToolUse hook: Inject evidence checklist when marking a task/todo complete.
//
// Supports two payload shapes so the hook works both in stock Claude Code
// (TodoWrite tool — todos array) and in environments with a custom task
// manager (TaskUpdate tool — single status field):
//
//   TodoWrite:  { tool_input: { todos: [{ id, status, ... }, ...] } }
//   TaskUpdate: { tool_input: { status: "completed", ... } }
//
// The hook fires when ANY todo is being marked completed, or when the
// TaskUpdate status is "completed".
//
// Config-driven enforcement via resolve-profile.js:
//   enabled  → inject evidence checklist (advisory)
//   warn     → inject evidence checklist (advisory, same as enabled)
//   disabled → exit immediately, no action

const { resolveProfile, hookState } = require('./lib/resolve-profile');
const { shouldSkip } = require('./lib/env-overrides');

// H10: cap stdin to 2MB. Fail-safe exit 0 on oversize input — hooks should
// never block a tool call over their own input-bound bugs.
const MAX_INPUT_BYTES = 2 * 1024 * 1024;
let input = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => {
  if (input.length + chunk.length > MAX_INPUT_BYTES) process.exit(0);
  input += chunk;
});
process.stdin.on('end', () => {
  try {
    if (shouldSkip('evidence-gate-reminder')) process.exit(0);
    const profile = resolveProfile();
    const hookMode = hookState(profile, 'evidence-gate-reminder');

    // disabled → pass through immediately, no enforcement
    if (hookMode === 'disabled') {
      process.exit(0);
    }

    const data = JSON.parse(input);
    const toolInput = data.tool_input || {};

    // Detect "completing a task" across both payload shapes.
    const singleStatus = toolInput.status || '';
    const todos = Array.isArray(toolInput.todos) ? toolInput.todos : [];
    const isCompleting =
      singleStatus === 'completed' ||
      todos.some((t) => t && t.status === 'completed');

    if (!isCompleting) {
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
