#!/usr/bin/env node
// PostToolUse hook: Check evidence quality after file writes.
// Fires after Write/Edit to e2e-evidence/ directories.
// Only warns on empty files — does NOT output on successful writes (reduces noise).

let input = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => input += chunk);
process.stdin.on('end', () => {
  try {
    const data = JSON.parse(input);
    const toolInput = data.tool_input || {};
    const filePath = toolInput.file_path || toolInput.path || '';

    // Only check evidence files
    if (!filePath.includes('e2e-evidence')) {
      process.exit(0);
    }

    const content = toolInput.content || toolInput.new_string || '';

    if (content.length === 0) {
      process.stdout.write(JSON.stringify({
        hookSpecificOutput: {
          hookEventName: "PostToolUse",
          additionalContext:
            'ValidationForge WARNING: Empty evidence file detected.\n' +
            '0-byte files are INVALID evidence. Capture real content (screenshots, logs, API responses).'
        }
      }));
    }
    // Successful evidence writes: exit silently (no noise)
  } catch (e) {
    process.stderr.write(`[ValidationForge] evidence-quality-check hook error: ${e.message}\n`);
    process.exit(0);
  }
});
