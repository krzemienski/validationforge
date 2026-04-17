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
// Config-driven enforcement via config-loader.js:
//   enabled  → inject evidence checklist (advisory)
//   warn     → inject evidence checklist (advisory, same as enabled)
//   disabled → exit immediately, no action

const { loadConfig } = require('./lib/config-loader');

let input = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => input += chunk);
process.stdin.on('end', () => {
  try {
    const config = loadConfig();
    const hookMode = config.getHookConfig('evidence-gate-reminder');

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
