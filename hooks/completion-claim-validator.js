#!/usr/bin/env node
// PostToolUse hook: Catch completion claims that lack validation evidence.
// Matches: Bash (after commands that might indicate "done")
//
// Config-driven enforcement via resolve-profile.js:
//   enabled  → exit(2) when completion claimed without evidence (hard block)
//   warn     → write warning to stderr but exit(0) (advisory only)
//   disabled → exit immediately, no action

const { COMPLETION_PATTERNS } = require('./lib/patterns');
const { resolveProfile, hookState } = require('./lib/resolve-profile');
const { shouldSkip } = require('./lib/env-overrides');
const fs = require('fs');
const path = require('path');

const EVIDENCE_SUBDIR = 'e2e-evidence';

// Review finding L3 (tightened): resolve EVIDENCE_DIR only from trusted
// roots. `data.cwd` on the hook payload is attacker-influenceable (a
// crafted Bash tool_input can set it to point at a pre-seeded directory
// with fake fresh evidence), so it is intentionally excluded. Prefer,
// in order:
//   1. CLAUDE_PROJECT_ROOT env var (set by Claude Code for the active project)
//   2. process.cwd() as the last-resort fallback
function resolveEvidenceDir(/* data */) {
  const candidates = [
    process.env.CLAUDE_PROJECT_ROOT,
    process.cwd(),
  ].filter(Boolean);
  for (const root of candidates) {
    try {
      if (fs.existsSync(root)) return path.join(root, EVIDENCE_SUBDIR);
    } catch (_) { /* unreadable → try next */ }
  }
  return path.join(process.cwd(), EVIDENCE_SUBDIR);
}

// H10: cap stdin to 2MB. Fail-safe exit 0 on oversize input.
const MAX_INPUT_BYTES = 2 * 1024 * 1024;
let input = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => {
  if (input.length + chunk.length > MAX_INPUT_BYTES) process.exit(0);
  input += chunk;
});
process.stdin.on('end', () => {
  try {
    if (shouldSkip('completion-claim-validator')) process.exit(0);
    const profile = resolveProfile();
    const hookMode = hookState(profile, 'completion-claim-validator');

    // disabled → pass through immediately, no enforcement
    if (hookMode === 'disabled') {
      process.exit(0);
    }

    const data = JSON.parse(input);
    const result = data.tool_result || {};
    const rawOutput = typeof result === 'string' ? result : (result.stdout || '');
    // H3: cap stdout scan to 200KB. Completion markers ("all tests pass",
    // "done") appear at the tail of build output, so slice from the end.
    const MAX_SCAN_BYTES = 200 * 1024;
    const output = rawOutput.length > MAX_SCAN_BYTES
      ? rawOutput.slice(-MAX_SCAN_BYTES)
      : rawOutput;
    // command available via data.tool_input?.command if needed

    const isCompletionClaim = COMPLETION_PATTERNS.some(p => p.test(output));

    if (isCompletionClaim) {
      // Resolve evidence dir against the project root, not the hook's CWD.
      const evidenceDir = resolveEvidenceDir();

      // Check evidence exists AND is recent (within last 24 hours) AND
      // non-empty (empty files fail the quality gate — review M4 tightening).
      //
      // H4: cap top-level scan at 200 entries so a runaway evidence dir
      //     can't stall the hot path with O(N) sync syscalls.
      // H5: stat.size > 0 is a no-op on directory inodes (APFS), so a
      //     journey dir with no content falsely passes the fresh-evidence
      //     check. When the entry is a directory, descend one level and
      //     verify at least one regular file is fresh and non-empty.
      let hasFreshEvidence = false;
      if (fs.existsSync(evidenceDir)) {
        const entries = fs.readdirSync(evidenceDir, { withFileTypes: true }).slice(0, 200);
        const cutoff = Date.now() - 24 * 60 * 60 * 1000;
        hasFreshEvidence = entries.some(ent => {
          try {
            const entPath = path.join(evidenceDir, ent.name);
            if (ent.isFile()) {
              const s = fs.statSync(entPath);
              return s.mtimeMs > cutoff && s.size > 0;
            }
            if (ent.isDirectory()) {
              // Descend one level; "fresh" iff any child file is recent + non-empty.
              const inner = fs.readdirSync(entPath, { withFileTypes: true }).slice(0, 100);
              return inner.some(child => {
                if (!child.isFile()) return false;
                try {
                  const s = fs.statSync(path.join(entPath, child.name));
                  return s.mtimeMs > cutoff && s.size > 0;
                } catch { return false; }
              });
            }
            return false;
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
