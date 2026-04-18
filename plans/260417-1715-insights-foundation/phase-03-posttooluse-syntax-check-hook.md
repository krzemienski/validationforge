# Phase 03 — PostToolUse Syntax-Check Hook

## Context Links
- Plan: `plans/260417-1715-insights-foundation/plan.md`
- Phase 1 (blocker): `phase-01-cross-repo-claude-md-additions.md`
- Phase 2 (blocker): `phase-02-strengthen-rules-and-add-audit-workflow.md`
- Hook reference (canonical protocol): `~/.claude/plugins/cache/superpowers-marketplace/superpowers-developing-for-claude-code/0.3.1/skills/working-with-claude-code/references/hooks.md`
- Hooks guide (examples): `~/.claude/plugins/cache/superpowers-marketplace/superpowers-developing-for-claude-code/0.3.1/skills/working-with-claude-code/references/hooks-guide.md`
- Settings reference: same package, `references/settings.md`
- Project convention: `~/.claude/rules/hooks-and-integrations.md` (block = stderr + exit 2, allow = silent exit 0)
- Active hooks list: `~/.claude/rules/hooks-reference.md`
- Existing hook style reference: `~/.claude/hooks/completion-claim-validator.js`, `~/.claude/hooks/evidence-gate-reminder.js`
- Active settings: `~/.claude/settings.json`

## Overview
- **Priority:** P2 (parallelizable with Phase 4)
- **Status:** draft
- **Description:** Add a PostToolUse hook on `Edit|Write|MultiEdit` that runs a per-language syntax check (`python -m py_compile` for `.py`, `node --check` for `.js/.cjs/.mjs`, optionally `tsc --noEmit` for `.ts/.tsx`). On syntax error, writes a diagnostic to stderr and exits 2 (PostToolUse = feedback to Claude). On success, silent exit 0. Matches project hook conventions.

## Key Insights
- No existing hook in `~/.claude/hooks/` performs syntax-checking post-write. Discovery confirmed: `completion-claim-validator.js`, `validation-not-compilation.js`, `dev-server-restart-reminder.js`, `skill-invocation-tracker.js`, `plan-format-kanban.cjs`, `post-edit-simplify-reminder.cjs` — none run a compiler.
- The existing hooks write JSON `hookSpecificOutput.additionalContext` to stdout (advisory) OR stderr + exit 2 (blocking). For syntax errors we want Claude to see the error and fix it → stderr + exit 2 is the correct protocol (per `references/hooks.md` line 385–397).
- PostToolUse on Edit|Write|MultiEdit fires AFTER the write succeeds. We cannot un-write the file — but we CAN feed the compiler error back to Claude, which reliably triggers a follow-up fix. This matches the hook-events-behavior table: "PostToolUse / Exit 2 / Shows stderr to Claude (tool already ran)".
- The hook needs to handle THREE tool shapes: `Write.tool_input.file_path`, `Edit.tool_input.file_path`, `MultiEdit.tool_input.file_path` (plural edits still reference one path per call). Extracting the path from `tool_input.file_path` is consistent across all three.
- `CLAUDE_PROJECT_DIR` is available but we prefer absolute `$HOME/.claude/hooks/...` registration (matches existing pattern in `~/.claude/settings.json`).
- TypeScript support is OPTIONAL (unresolved question in plan.md). We ship with Python + JS today; TS is gated on `command -v tsc` availability, silent-skip if unavailable.

## Requirements
### Functional
- Hook file: `~/.claude/hooks/syntax-check-after-edit.js` — Node.js, executable.
- Reads hook input from stdin (JSON per `references/hooks.md` PostToolUse schema).
- Extracts file path from `tool_input.file_path`. If absent, silent exit 0 (nothing to check).
- Dispatches by extension:
  - `.py` → `python3 -m py_compile <path>`
  - `.js`, `.cjs`, `.mjs` → `node --check <path>`
  - `.ts`, `.tsx` → `tsc --noEmit --allowJs false <path>` ONLY IF `tsc` is on PATH; else silent skip.
  - any other extension → silent exit 0.
- On non-zero compiler exit: write a single-block diagnostic to stderr (file path + compiler stderr, trimmed to 2KB) and exit 2.
- On zero compiler exit: exit 0 silently (no stdout, no stderr).
- Compiler timeout: 10 seconds. If compiler hangs, kill the process and exit 0 (don't block on a hung tool).
- Hook must not throw on missing files (e.g. file deleted by user mid-edit) — fall through to silent exit 0.
- Hook must not block on non-source-file edits (`.md`, `.json`, `.yaml`, etc.) — silent exit 0.

### Non-functional
- Node.js (matches existing `.js` hook style in `~/.claude/hooks/`).
- No external npm deps (uses only `node:child_process`, `node:fs`, `node:path`).
- Executable permission (`chmod +x`).
- File size ≤ 150 lines.
- Registered in `~/.claude/settings.json` under the existing `PostToolUse / Edit|Write|MultiEdit` matcher group (append to the existing array, do NOT create a new matcher block).

## Architecture

### Hook skeleton (Node.js)
```javascript
#!/usr/bin/env node
// PostToolUse hook: Syntax-check edited/written source files.
// Matches: Edit|Write|MultiEdit
// Behavior:
//   - Detect source file by extension
//   - Run per-language syntax check (py_compile / node --check / tsc --noEmit)
//   - On syntax error: stderr + exit 2 (feedback to Claude)
//   - On success or non-source file: silent exit 0

const { execFileSync } = require('node:child_process');
const { existsSync, statSync } = require('node:fs');
const path = require('node:path');

const TIMEOUT_MS = 10_000;
const MAX_STDERR = 2048;

function commandExists(cmd) {
  try {
    execFileSync('which', [cmd], { stdio: 'ignore', timeout: 2_000 });
    return true;
  } catch {
    return false;
  }
}

function checkPython(filePath) {
  return spawnCompile('python3', ['-m', 'py_compile', filePath]);
}

function checkNode(filePath) {
  return spawnCompile('node', ['--check', filePath]);
}

function checkTypeScript(filePath) {
  if (!commandExists('tsc')) return { ok: true, skipped: true };
  // --noEmit: don't emit output files; --allowJs false: pure TS check.
  return spawnCompile('tsc', ['--noEmit', '--allowJs', 'false', filePath]);
}

function spawnCompile(cmd, args) {
  try {
    execFileSync(cmd, args, {
      stdio: ['ignore', 'pipe', 'pipe'],
      timeout: TIMEOUT_MS,
      maxBuffer: 1024 * 1024,
    });
    return { ok: true };
  } catch (err) {
    // Timeout or missing binary → don't block Claude; silent pass.
    if (err.code === 'ETIMEDOUT' || err.code === 'ENOENT') {
      return { ok: true, silent: true };
    }
    const stderr = (err.stderr ? err.stderr.toString() : '') || err.message || '';
    return { ok: false, stderr: stderr.slice(0, MAX_STDERR) };
  }
}

function dispatch(filePath) {
  const ext = path.extname(filePath).toLowerCase();
  if (ext === '.py') return checkPython(filePath);
  if (['.js', '.cjs', '.mjs'].includes(ext)) return checkNode(filePath);
  if (['.ts', '.tsx'].includes(ext)) return checkTypeScript(filePath);
  return { ok: true, skipped: true };
}

let input = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => input += chunk);
process.stdin.on('end', () => {
  try {
    const data = JSON.parse(input || '{}');
    const toolInput = data.tool_input || {};
    const filePath = toolInput.file_path;

    if (!filePath || typeof filePath !== 'string') {
      process.exit(0);
    }
    if (!existsSync(filePath)) {
      process.exit(0);
    }
    // Skip if not a regular file (symlink to missing, dir, etc.)
    try {
      if (!statSync(filePath).isFile()) process.exit(0);
    } catch {
      process.exit(0);
    }

    const result = dispatch(filePath);
    if (result.ok) process.exit(0);

    const msg =
      `SYNTAX ERROR in ${filePath}:\n` +
      result.stderr.trim() + '\n\n' +
      'Fix the syntax error before proceeding. This is a compiler-level ' +
      'block, not advisory. See ~/.claude/rules/instrument-before-theorize.md ' +
      'for root-cause discipline before adding guards or fallbacks.';
    process.stderr.write(msg);
    process.exit(2);
  } catch {
    // Any unexpected error: silent pass — never block Claude on a broken hook.
    process.exit(0);
  }
});
```

### Settings registration
In `~/.claude/settings.json`, append to the EXISTING `PostToolUse` entry with matcher `Edit|Write|MultiEdit`:

```json
{
  "matcher": "Edit|Write|MultiEdit",
  "hooks": [
    { "type": "command", "command": "node \"$HOME/.claude/hooks/dev-server-restart-reminder.js\"" },
    { "type": "command", "command": "node \"$HOME/.claude/hooks/skill-invocation-tracker.js\"" },
    { "type": "command", "command": "node \"$HOME/.claude/hooks/plan-format-kanban.cjs\"" },
    { "type": "command", "command": "node \"$HOME/.claude/hooks/post-edit-simplify-reminder.cjs\"" },
    { "type": "command", "command": "node \"$HOME/.claude/hooks/syntax-check-after-edit.js\"" }
  ]
}
```

Parallelization note: per `references/hooks.md` line 776, all matching hooks run in parallel. Adding this hook does NOT slow other hooks; compiler timeout is bounded at 10s (within the 60s default).

## Related Code Files
### Create
- `~/.claude/hooks/syntax-check-after-edit.js` (Node.js, ~120 lines)

### Modify
- `~/.claude/settings.json` — append registration to existing PostToolUse Edit|Write|MultiEdit block.

### Delete
- None.

## Implementation Steps
1. Write `~/.claude/hooks/syntax-check-after-edit.js` with the skeleton above.
2. `chmod +x ~/.claude/hooks/syntax-check-after-edit.js`.
3. Read current `~/.claude/settings.json`; locate the `PostToolUse` entry whose `matcher` is `"Edit|Write|MultiEdit"`.
4. Append the new hook command to that entry's `hooks` array (do NOT create a new matcher block — this matches project convention).
5. `python3 -c "import json; json.load(open('$HOME/.claude/settings.json'))"` — validate JSON parses cleanly.
6. Run `/hooks` in Claude Code REPL to confirm registration (per hooks.md line 792: "Check configuration — Run `/hooks` to see if your hook is registered").
7. Defer runtime validation to Phase 5.

## Todo List
- [ ] Write syntax-check-after-edit.js
- [ ] chmod +x
- [ ] Append registration to settings.json
- [ ] Validate settings.json parses as JSON
- [ ] Confirm registration via /hooks command
- [ ] Handoff to Phase 5 for functional validation

## Success Criteria
- [ ] `test -x ~/.claude/hooks/syntax-check-after-edit.js` passes.
- [ ] `node --check ~/.claude/hooks/syntax-check-after-edit.js` passes (self-consistency — the hook is itself syntactically valid JS).
- [ ] `jq '.hooks.PostToolUse[] | select(.matcher == "Edit|Write|MultiEdit") | .hooks[].command' ~/.claude/settings.json | grep syntax-check-after-edit` returns exactly one match.
- [ ] `/hooks` slash command in REPL lists `syntax-check-after-edit.js` under PostToolUse / Edit|Write|MultiEdit.
- [ ] Phase 5 evidence confirms: deliberately-broken `.py` write triggers exit 2 + stderr with compiler message; valid `.py` write silently exits 0.

## Risk Assessment
| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Hook blocks on a slow compiler (huge file) | Low | Med | 10s timeout per invocation; timeout → silent exit 0 (never block on a hung tool). |
| `python3` not on PATH on some machine | Low | Med | `commandExists` gate before spawning tsc; for python the `execFileSync` catches ENOENT and silent-passes. |
| `tsc --noEmit <single-file>` requires a tsconfig in most repos | High | Low | TS is opt-in; on tsconfig-less repos, tsc errors unrelated to syntax — mitigated by still printing stderr but Claude will learn to ignore. Alternative: ship TS support disabled until unresolved question is answered. |
| Hook triggers on every Edit including docs | Low | Low | Extension-gated; `.md`, `.json`, `.yaml` → silent exit 0. |
| Hook itself crashes (malformed stdin) | Low | High | Outer try/catch → silent exit 0. Never block Claude on a broken hook. |
| Exit 2 floods Claude's context on a file with 500 errors | Med | Med | `MAX_STDERR = 2048` truncates compiler output. Stderr bounded. |
| Registration collides with existing hook order | Low | Low | Appended to existing array; parallel execution per hooks.md — order doesn't matter. |
| Node version too old (optional chaining) | Low | Low | Skeleton uses Node ≥16 features only; user's system Node is modern. |

## Security Considerations
- `execFileSync(cmd, [args])` — argv is structured, no shell interpolation. Safe against path-injection in `file_path`.
- `commandExists` uses `which` not `sh -c` — no shell evaluation.
- Hook runs with user's credentials. It only reads files and invokes compilers — no writes, no network, no curl.
- `file_path` is passed directly to the compiler. Malicious paths like `-rm-rf` cannot materialize because all compiler CLIs treat the positional arg as a file path, not a flag (py_compile and node --check both.)
- However: defense-in-depth — we could reject paths starting with `-`. Add as a 1-line guard: `if (filePath.startsWith('-')) process.exit(0);` (recommended).
- Reads `~/.claude/settings.json` — no writes to it at runtime. Configuration change is an explicit phase step.
- Timeout prevents a compromised compiler binary from hanging the agent indefinitely.

## Next Steps
- Phase 5 validates this hook end-to-end with a deliberately-broken `.py` edit.
- Future: consider adding Go (`go vet`), Rust (`cargo check --message-format short`), Swift (`swiftc -typecheck`) — deferred to Plan C.

## Unresolved Questions
- Ship TypeScript support in v1, or defer until we decide on the tsconfig-less handling?
  - Option A: Ship TS, accept noisy stderr in tsconfig-less repos.
  - Option B: Gate TS on `tsconfig.json` presence in the edited file's ancestor chain (walk up; skip if no tsconfig found).
- Should the hook include a "fail fast" mode where the first syntax error across N parallel MultiEdit files halts further checks? Default: no — check each independently. User to confirm.
- Should we add a kill switch env var (e.g. `DISABLE_SYNTAX_CHECK=1`) for emergency bypass? Matches existing OMC `DISABLE_OMC` / `OMC_SKIP_HOOKS` pattern.
