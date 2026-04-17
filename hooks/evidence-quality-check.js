#!/usr/bin/env node
// PostToolUse hook: Check evidence quality after file writes.
// Fires after Write/Edit to e2e-evidence/ directories.
// Only warns on empty files — does NOT output on successful writes (reduces noise).
//
// Profile-driven enforcement via resolve-profile.js:
//   enabled + rules.reject_empty_evidence=true  → stderr warn + exit(2) (hard block)
//   enabled + rules.reject_empty_evidence=false → advisory stderr, exit 0
//   warn                                        → advisory stderr, exit 0
//   disabled                                    → exit 0 silently
//
// Env overrides (take precedence over everything):
//   DISABLE_OMC=1     → exit 0 silently
//   VF_SKIP_HOOKS=... → exit 0 silently if "evidence-quality-check" is listed

const { resolveProfile, hookState, ruleEnabled } = require('./lib/resolve-profile');

const HOOK_NAME = 'evidence-quality-check';

let input = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => input += chunk);
process.stdin.on('end', () => {
  try {
    // Env overrides — highest precedence, exit immediately
    if (process.env.DISABLE_OMC === '1') process.exit(0);
    const skipHooks = (process.env.VF_SKIP_HOOKS || '').split(',').map(s => s.trim());
    if (skipHooks.includes(HOOK_NAME)) process.exit(0);

    const profile = resolveProfile();
    const state   = hookState(profile, HOOK_NAME);

    // disabled → pass through immediately, no enforcement
    if (state === 'disabled') process.exit(0);

    const data      = JSON.parse(input);
    const toolInput = data.tool_input || {};
    const filePath  = toolInput.file_path || toolInput.path || '';

    // Only check evidence files
    if (!filePath.includes('e2e-evidence')) process.exit(0);

    const content = toolInput.content || toolInput.new_string || '';

    if (content.length === 0) {
      process.stderr.write(
        `[ValidationForge] evidence-quality-check [${profile.name}]: Empty evidence file detected.\n` +
        '0-byte files are INVALID evidence. Capture real content (screenshots, logs, API responses).\n'
      );

      if (state === 'warn' || !ruleEnabled(profile, 'reject_empty_evidence')) {
        // warn or rule disabled → advisory only, let execution continue
        process.exit(0);
      }

      // enabled + rule true → hard block
      process.exit(2);
    }
    // Successful evidence writes: exit silently (no noise)
    process.exit(0);
  } catch (e) {
    process.stderr.write(`[ValidationForge] evidence-quality-check hook error: ${e.message}\n`);
    process.exit(0);
  }
});
