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
const path = require('path');

const EVIDENCE_SUBDIR = 'e2e-evidence';

// Review finding M4: never resolve EVIDENCE_DIR against a relative CWD —
// an attacker or a drive-by `cd` in a Bash tool call could redirect the
// gate to an unrelated directory. Prefer, in order:
//   1. CLAUDE_PROJECT_ROOT env var (set by Claude Code for the active project)
//   2. The `cwd` field on the hook JSON payload (project root per CC hook spec)
//   3. process.cwd() as a last-resort fallback
function resolveEvidenceDir(data) {
  const candidates = [
    process.env.CLAUDE_PROJECT_ROOT,
    data && data.cwd,
    process.cwd(),
  ].filter(Boolean);
  for (const root of candidates) {
    try {
      if (fs.existsSync(root)) return path.join(root, EVIDENCE_SUBDIR);
    } catch (_) { /* unreadable → try next */ }
  }
  return path.join(process.cwd(), EVIDENCE_SUBDIR);
}

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
      // Resolve evidence dir against the project root, not the hook's CWD.
      const evidenceDir = resolveEvidenceDir(data);

      // Check evidence exists AND is recent (within last 24 hours) AND
      // non-empty (empty files fail the quality gate — review M4 tightening).
      let hasFreshEvidence = false;
      if (fs.existsSync(evidenceDir)) {
        const entries = fs.readdirSync(evidenceDir);
        const cutoff = Date.now() - 24 * 60 * 60 * 1000;
        hasFreshEvidence = entries.some(entry => {
          try {
            const stat = fs.statSync(path.join(evidenceDir, entry));
            return stat.mtimeMs > cutoff && stat.size > 0;
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
