#!/usr/bin/env node
// PostToolUse hook: Catch completion claims that lack validation evidence.
// Matches: Bash (after commands that might indicate "done")
//
// Config-driven enforcement via config-loader.js:
//   enabled  → exit(2) when completion claimed without evidence (hard block)
//   warn     → write warning to stderr but exit(0) (advisory only)
//   disabled → exit immediately, no action

const { COMPLETION_PATTERNS } = require('./lib/patterns');
const { loadConfig } = require('./lib/config-loader');
const fs = require('fs');

const EVIDENCE_DIR = 'e2e-evidence';

let input = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => input += chunk);
process.stdin.on('end', () => {
  try {
    const config = loadConfig();
    const hookMode = config.getHookConfig('completion-claim-validator');

    // disabled → pass through immediately, no enforcement
    if (hookMode === 'disabled') {
      process.exit(0);
    }

    const data = JSON.parse(input);
    const result = data.tool_result || {};
    const output = typeof result === 'string' ? result : (result.stdout || '');
    // command available via data.tool_input?.command if needed

    const isCompletionClaim = COMPLETION_PATTERNS.some(p => p.test(output));

    if (isCompletionClaim) {
      // Check evidence exists AND is recent (within last 24 hours)
      let hasFreshEvidence = false;
      if (fs.existsSync(EVIDENCE_DIR)) {
        const entries = fs.readdirSync(EVIDENCE_DIR);
        const cutoff = Date.now() - 24 * 60 * 60 * 1000;
        hasFreshEvidence = entries.some(entry => {
          try {
            const stat = fs.statSync(`${EVIDENCE_DIR}/${entry}`);
            return stat.mtimeMs > cutoff;
          } catch { return false; }
        });
      }

      if (!hasFreshEvidence) {
        process.stderr.write(
          '[ValidationForge] completion-claim-validator: Completion claimed but no validation evidence found in e2e-evidence/.\n' +
          'ValidationForge requires real evidence before any completion claim.\n' +
          'Run /validate to capture proper evidence through real system interaction.\n'
        );
        if (hookMode === 'warn') {
          // warn → advisory only, let execution continue
          process.exit(0);
        }
        // enabled → hard block
        process.exit(2);
      }
    }
  } catch (e) {
    process.stderr.write(`[ValidationForge] completion-claim-validator hook error: ${e.message}\n`);
    process.exit(0);
  }
});
