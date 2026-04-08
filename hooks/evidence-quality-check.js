#!/usr/bin/env node
// PostToolUse hook: Check evidence quality after file writes.
// Fires after Write/Edit to e2e-evidence/ directories.
// Warns about empty files and missing evidence inventories.

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
    } else {
      process.stdout.write(JSON.stringify({
        hookSpecificOutput: {
          hookEventName: "PostToolUse",
          additionalContext:
            'ValidationForge: Evidence file written. Remember to update evidence-inventory.txt in the journey directory.'
        }
      }));
    }
  } catch (e) {
    process.exit(0);
  }
});
