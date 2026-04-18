# Phase 2 — Root-Cause Enforcer Hook

## 1. Context Links

- Parent plan: `/Users/nick/Desktop/validationforge/plans/260417-1715-insights-ambitious-workflows/plan.md`
- Upstream Phase 1: `~/.claude/scripts/common/checkpoint-lib.js`, `debug-checkpoint.schema.json`
- Upstream Plan B: `/root-cause-first` skill (this hook enforces its use)
- Refs:
  - `~/.claude/plugins/cache/superpowers-marketplace/superpowers-developing-for-claude-code/0.3.1/skills/working-with-claude-code/references/hooks.md` — exit codes, stdin JSON shape
  - `~/.claude/rules/hooks-and-integrations.md` — project hook conventions
- Existing sibling hooks: `~/.claude/hooks/read-before-edit.js`, `evidence-gate-reminder.js`, `completion-claim-validator.js`, `validation-not-compilation.js` — same Node.js + exit-code pattern.

## 2. Overview

- **Priority:** P1
- **Status:** pending (Phase 1 required)
- **Description:** A PreToolUse hook that blocks `Edit|Write|MultiEdit` against `src/**` or `lib/**` unless a `.debug/<issue-id>/evidence.md` exists and passes a structural checklist. Enforces one-fix-at-a-time by diff-shape analysis. Pairs with a git post-commit hook that auto-appends to `failed-approaches.md` on revert commits.

## 3. Key Insights

- Report noted Claude undertriggers skills — this hook makes triggering the `/root-cause-first` flow mandatory by gating the tool call itself, not by reminder.
- Existing sibling hooks write reason to stderr + exit 2 to block; we follow that exact protocol (per `hooks.md`). `{"decision":"block"}` JSON is deprecated — do not use.
- Issue ID resolution order matches developer ergonomics: branch name → env var → error (we do NOT prompt — hooks should not block on interactive input).
- "One-fix-at-a-time" heuristic is configurable per the unresolved question in plan.md (default: 3 files / 2 function signatures).

## 4. Requirements

### Functional
- F1: Triggers on `PreToolUse` for `Edit`, `Write`, `MultiEdit`.
- F2: Allows (exit 0) when target file is outside `src/**` and `lib/**`.
- F3: Resolves issue-id: `CLAUDE_ISSUE_ID` env var → git branch pattern `*/<issue-id>/*` or `issue-<id>-*` → if neither, exit 2 with instructions.
- F4: Verifies `<repo-root>/.debug/<issue-id>/evidence.md` exists and contains required sections (see §5 checklist).
- F5: Runs diff-shape guard: if staged+unstaged diff touches >3 files (excluding tests/docs) OR >2 distinct function signatures → exit 2.
- F6: Bypass via `CLAUDE_SKIP_ROOT_CAUSE_GATE=1`. Bypass logs to `~/.claude/state/bypass.log`.
- F7: Git post-commit hook template auto-appends to `failed-approaches.md` when commit message starts with `Revert ` or `git revert` parent set.

### Non-functional / Safety
- NF1: Hook runs in <300ms for the allow path (no network, minimal IO).
- NF2: Zero runtime deps. Node stdlib only. Reuses `checkpoint-lib.js` via `require`.
- NF3: Hook never auto-modifies source — only blocks and prints reason.
- NF4: Under 200 lines.

## 5. Architecture

### Hook invocation (per `hooks.md`)
- Stdin: JSON with `tool_name`, `tool_input.file_path` (Edit/Write) or `tool_input.edits[]` (MultiEdit).
- Block: write reason to `process.stderr`, `process.exit(2)`.
- Allow: `process.exit(0)` with no stdout.

### evidence.md checklist
Required sections (matched by regex on `##` headers):
1. `## Inputs & Outputs` — body must contain at least one `Input:` and `Output:` line.
2. `## Visual Evidence` — must reference a file under `.debug/<id>/evidence/` or an absolute path to a real file (validator stat-checks existence).
3. `## Minimal Reproduction` — must contain a fenced code block.
4. `## Hypothesis` — must contain `File:` and `Line:` fields, pointing to ONE location.
5. `## Failed Approaches Cross-Check` — must reference `.debug/<id>/failed-approaches.md` (exists check optional — empty is OK).

### Diff-shape guard
- Run `git diff --name-only HEAD` + `git diff --cached --name-only` → file list.
- Filter out `*.test.*`, `*.spec.*`, `docs/**`, `*.md`.
- If remaining unique files >3 → block.
- For each .js/.ts/.py/.go source file in the diff, grep `^(function |def |func |export function|class ) ` to count touched signatures via `git diff -U0`. If >2 distinct → block.

### JS skeleton
```js
// ~/.claude/hooks/root-cause-enforce-pre.js
#!/usr/bin/env node
const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const BYPASS = process.env.CLAUDE_SKIP_ROOT_CAUSE_GATE === '1';
const MAX_FILES = Number(process.env.CLAUDE_ROOT_CAUSE_MAX_FILES || 3);
const MAX_SIGS  = Number(process.env.CLAUDE_ROOT_CAUSE_MAX_SIGS  || 2);

function block(reason) {
  process.stderr.write(`[root-cause-enforce] BLOCK: ${reason}\n`);
  process.stderr.write(`To bypass (rare): CLAUDE_SKIP_ROOT_CAUSE_GATE=1 <cmd>\n`);
  process.exit(2);
}

function readHookInput() {
  const raw = fs.readFileSync(0, 'utf8');
  return raw ? JSON.parse(raw) : {};
}

function resolveTargetPath(input) { /* handles Edit, Write, MultiEdit shapes */ }
function isSourcePath(p, repoRoot) { /* src/** or lib/** */ }
function resolveIssueId(repoRoot) {
  if (process.env.CLAUDE_ISSUE_ID) return process.env.CLAUDE_ISSUE_ID;
  const branch = execSync('git rev-parse --abbrev-ref HEAD', {cwd: repoRoot}).toString().trim();
  const m = branch.match(/(?:^|\/)(issue-[\w-]+|[A-Z]+-\d+)(?:\/|$)/);
  return m ? m[1] : null;
}
function validateEvidence(evPath) { /* §5 checklist, returns {ok, missing[]} */ }
function diffShapeOK(repoRoot) { /* §5 diff-shape, returns {ok, reason} */ }

try {
  if (BYPASS) { /* log + exit 0 */ }
  const input = readHookInput();
  if (!['Edit','Write','MultiEdit'].includes(input.tool_name)) process.exit(0);
  const target = resolveTargetPath(input);
  const repoRoot = execSync('git rev-parse --show-toplevel').toString().trim();
  if (!isSourcePath(target, repoRoot)) process.exit(0);
  const issueId = resolveIssueId(repoRoot);
  if (!issueId) block('no issue id (set CLAUDE_ISSUE_ID or use branch pattern issue-<id>/*)');
  const evPath = path.join(repoRoot, '.debug', issueId, 'evidence.md');
  if (!fs.existsSync(evPath)) block(`evidence.md missing at ${evPath} — run /root-cause-first`);
  const ev = validateEvidence(evPath);
  if (!ev.ok) block(`evidence.md missing sections: ${ev.missing.join(', ')}`);
  const ds = diffShapeOK(repoRoot);
  if (!ds.ok) block(`one-fix-at-a-time violated: ${ds.reason}`);
  process.exit(0);
} catch (e) {
  // Fail-open on hook internal errors, log, do not block dev work
  process.stderr.write(`[root-cause-enforce] internal error (allowing): ${e.message}\n`);
  process.exit(0);
}
```

### Git post-commit hook template
```bash
# ~/.claude/hooks/git/post-commit-failed-approach.sh
#!/usr/bin/env bash
set -euo pipefail
msg=$(git log -1 --pretty=%B)
if [[ "$msg" =~ ^Revert ]] || [[ "$msg" =~ "git revert" ]]; then
  issue_id="${CLAUDE_ISSUE_ID:-$(git rev-parse --abbrev-ref HEAD | sed -E 's|.*/([^/]+)$|\1|')}"
  [[ -z "$issue_id" ]] && exit 0
  node ~/.claude/scripts/common/checkpoint-lib.js append-failed-approach "$issue_id" \
    "{\"reverted_sha\":\"$(git rev-parse HEAD)\",\"reason\":\"auto-logged from revert\"}"
fi
```

Install instructions in `~/.claude/hooks/git/README.md`: `ln -s ~/.claude/hooks/git/post-commit-failed-approach.sh <repo>/.git/hooks/post-commit`.

## 6. Related Code Files

**CREATE:**
- `/Users/nick/.claude/hooks/root-cause-enforce-pre.js`
- `/Users/nick/.claude/hooks/git/post-commit-failed-approach.sh`
- `/Users/nick/.claude/hooks/git/README.md` (install guide)
- `/Users/nick/.claude/scripts/common/checkpoint-lib-cli.js` (thin CLI wrapper so the shell hook can call it)

**MODIFY:**
- `/Users/nick/.claude/settings.json` — register hook under `hooks.PreToolUse` with matcher `Edit|Write|MultiEdit`.

**DELETE:** none.

## 7. Implementation Steps

1. Read at least two existing sibling hooks (`read-before-edit.js`, `evidence-gate-reminder.js`) to match conventions (per hook rule 2).
2. Re-read canonical protocol in `hooks.md` (exit 2 + stderr; no `{"decision":"block"}`).
3. Implement `resolveTargetPath` handling Edit/Write/MultiEdit input shapes defensively.
4. Implement `validateEvidence` with regex matchers for each required section. Return structured `{ok, missing[]}`.
5. Implement `diffShapeOK` invoking `git diff --name-only` twice (staged + unstaged), de-dupe, filter, apply thresholds.
6. Wire fail-open catch-all: any internal hook error → stderr log + exit 0. Blocking on our own bug is worse than missing enforcement.
7. Add bypass log write to `~/.claude/state/bypass.log` with timestamp + user + target path + issue id (or `null`).
8. Register in `~/.claude/settings.json`:
   ```json
   "PreToolUse": [
     {"matcher": "Edit|Write|MultiEdit", "hooks": [{"type":"command","command":"node ~/.claude/hooks/root-cause-enforce-pre.js"}]}
   ]
   ```
9. Write git post-commit template + install doc.
10. Create a seeded bug fixture for Phase 6 validation — a yt-shorts-detector branch `issue-rc-enforcer-test/*` with `src/` edit pending.

### Safety gates
- Step 6 fail-open is mandatory — a broken enforcer must not halt all edits.
- Step 8 settings change MUST preserve existing hooks; use a JSON edit that merges into the PreToolUse array, not overwrites it.

## 8. Todo List

- [ ] Read sibling hooks for conventions
- [ ] Implement `root-cause-enforce-pre.js` (<200 LOC)
- [ ] Add `validateEvidence` + unit-free validation via harness input file
- [ ] Add `diffShapeOK` with configurable thresholds
- [ ] Fail-open error handling
- [ ] Bypass env var + bypass log
- [ ] Register in `~/.claude/settings.json` (preserve other hooks)
- [ ] Write git post-commit template + install README
- [ ] Prepare seeded bug fixture for Phase 6

## 9. Success Criteria

- Phase 6 seeded scenario: attempt `Edit` on yt-shorts-detector `src/yt_shorts_detector/motion_analyzer.py` on branch `issue-rc-enforcer-test/probe` without `.debug/rc-enforcer-test/evidence.md` → hook exits 2, stderr names the missing file. **Captured as evidence.**
- Write valid `evidence.md`, retry → hook exits 0, edit proceeds. **Captured as evidence.**
- Force a 5-file diff → hook exits 2 with reason `one-fix-at-a-time violated: 5 files touched`. **Captured as evidence.**
- `CLAUDE_SKIP_ROOT_CAUSE_GATE=1 Edit ...` → exit 0, bypass.log gains one entry.
- Hook overhead for non-`src/` edit (e.g. editing a doc): measured <300ms.

## 10. Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Hook blocks legitimate refactors | Medium | High | `CLAUDE_SKIP_ROOT_CAUSE_GATE=1` bypass; thresholds configurable via env. |
| Hook has a bug and blocks ALL edits | Low | Critical | Fail-open catch-all at top-level try/catch. |
| Issue-id heuristic misses valid branch naming | Medium | Medium | Explicit env var always wins; branch pattern is the fallback; document both. |
| `evidence.md` format drift from `/root-cause-first` skill template | Medium | High (dev friction) | Hook + Plan B skill share one canonical template — update both together; Phase 6 validates round-trip. |
| Diff-shape guard too coarse | Medium | Medium | Thresholds overridable via `CLAUDE_ROOT_CAUSE_MAX_FILES` / `_MAX_SIGS`. |
| Settings.json corruption on merge | Low | High | Edit via read→parse→mutate→write-to-tmp→rename; backup of prior file to `settings.json.bak` before write. |

## 11. Security Considerations

- Hook uses `execSync` for `git` — args are hardcoded, not user-supplied. No shell injection surface.
- Hook reads evidence.md contents but never executes them. Regex matching only.
- `CLAUDE_ISSUE_ID` env var is treated as a path segment — hook rejects values containing `/`, `..`, or NUL.
- Bypass log captures bypass attempts for audit — add it to docs so users know bypass is visible.

## 12. Next Steps

Phase 6 runs the seeded validation scenarios above. Phase 3 (GT Tuner) and Phase 4 (Swarm) may invoke code paths that tempt the Enforcer — both use `CLAUDE_SKIP_ROOT_CAUSE_GATE=1` explicitly inside their orchestrators, never silently.
