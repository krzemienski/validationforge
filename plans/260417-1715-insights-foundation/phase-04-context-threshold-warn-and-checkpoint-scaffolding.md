# Phase 04 — Context-Threshold Warn Hook + Checkpoint Scaffolding

## Context Links
- Plan: `plans/260417-1715-insights-foundation/plan.md`
- Phase 1 (blocker): `phase-01-cross-repo-claude-md-additions.md`
- Phase 2 (blocker): `phase-02-strengthen-rules-and-add-audit-workflow.md`
- Hook reference: `~/.claude/plugins/cache/superpowers-marketplace/superpowers-developing-for-claude-code/0.3.1/skills/working-with-claude-code/references/hooks.md` (UserPromptSubmit event, additionalContext JSON)
- Settings reference: same package, `references/settings.md`
- Project convention: `~/.claude/rules/hooks-and-integrations.md`
- Existing UserPromptSubmit hooks: `~/.claude/hooks/dev-rules-reminder.cjs`, `~/.claude/hooks/skill-activation-forced-eval.js`
- Detector session state dir (to extend): `~/Desktop/yt-transition-shorts-detector/.claude/session-state/`

## Overview
- **Priority:** P2 (parallelizable with Phase 3)
- **Status:** draft
- **Description:** Add a UserPromptSubmit hook that warns Claude when context usage reaches a threshold (60% by default) and instructs saving a debug-checkpoint before `/compact`. Create `~/.claude/state/` with JSON Schemas for `debug-checkpoint.json` and `audit-checkpoint.json` that downstream Plans B/C will consume. Extend (not duplicate) the detector's existing `.claude/session-state/` directory.

## Key Insights
- Insights report cites 16 `Prompt is too long` errors in ralph-mode / observer sessions. Root cause: no proactive checkpoint before the hard compaction. Warning needs to fire EARLY (60%) not at the boundary.
- Claude Code's actual context-% value is not yet exposed to hooks via a stable field. As of the hooks.md schema (PostToolUse/UserPromptSubmit), there's `session_id`, `transcript_path`, `cwd` — no context-usage field. We must either (a) parse `transcript_path` for cumulative token count, (b) count messages as a proxy, or (c) inspect env vars if Claude Code sets one.
- Pragmatic approach: **heuristic via transcript file size** — parse `transcript_path` JSONL, sum message character counts, divide by an assumed token-per-char ratio (~4 chars/token), compare against `CLAUDE_CODE_AUTO_COMPACT_WINDOW` env var (user has this set to `700000` per settings.json). This is coarse but deterministic and stable across Claude Code versions.
- Fallback: if transcript read fails, count JSONL lines. A 60% threshold on line count is a poor proxy — ship the char-count primary + line-count fallback.
- Hook output uses `hookSpecificOutput.additionalContext` (UserPromptSubmit) — context is injected BEFORE Claude sees the prompt, so the reminder arrives at the exact moment the user is about to spend more tokens.
- Checkpoint schemas are JSON Schema draft-07 (broad tool support). Schemas live in `~/.claude/state/schemas/`. The state directory itself (`~/.claude/state/`) is new; schemas are the first content.
- The detector's existing `.claude/session-state/` is a PROJECT-LOCAL checkpoint store. We do NOT duplicate it — we document that a `debug-checkpoint.json` there conforms to the same schema as `~/.claude/state/schemas/debug-checkpoint.schema.json`.

## Requirements
### Functional
- Hook file: `~/.claude/hooks/context-threshold-warn.js` — Node.js, executable.
- Reads UserPromptSubmit JSON from stdin.
- Computes context usage % using transcript file size / `CLAUDE_CODE_AUTO_COMPACT_WINDOW` (fallback 200000 if unset).
- If usage ≥ 60%: emit JSON to stdout with `hookSpecificOutput.additionalContext` containing a checkpoint reminder that cites the active plan dir (from `CK_ACTIVE_PLAN` / env or injected context) and the debug-checkpoint schema path.
- If usage < 60%: silent exit 0, no output.
- Threshold configurable via env var `CONTEXT_WARN_THRESHOLD` (default 60).
- Kill switch: if `DISABLE_OMC=1` or `OMC_SKIP_HOOKS` contains `context-threshold-warn`, silent exit 0 (matches OMC convention per user CLAUDE.md).
- Schemas:
  - `~/.claude/state/schemas/debug-checkpoint.schema.json` — JSON Schema draft-07.
  - `~/.claude/state/schemas/audit-checkpoint.schema.json` — JSON Schema draft-07.
- `~/.claude/state/README.md` — one-paragraph explainer + schema links.
- Detector repo: NO new files; a pointer line is added to `detector-project-conventions.md` (Phase 2) OR `~/Desktop/yt-transition-shorts-detector/.claude/session-state/README.md` (create if missing, ≤ 10 lines) noting that checkpoint JSON here conforms to the user-global schema.

### Non-functional
- Hook file ≤ 120 lines.
- No external npm deps.
- Hook MUST NOT block (UserPromptSubmit + exit 2 would erase the prompt; see hooks.md line 391–394). This hook only ADDS context, never blocks.
- JSON Schema files conform to draft-07 (`$schema` field set).
- Kebab-case filenames. No emojis.

## Architecture

### Directory layout after phase
```
~/.claude/state/                      (CREATE)
├── README.md                         (CREATE — one paragraph + schema links)
└── schemas/                          (CREATE)
    ├── debug-checkpoint.schema.json  (CREATE)
    └── audit-checkpoint.schema.json  (CREATE)

~/.claude/hooks/
└── context-threshold-warn.js         (CREATE)

~/.claude/settings.json               (MODIFY — register hook under UserPromptSubmit)

~/Desktop/yt-transition-shorts-detector/.claude/session-state/
└── README.md                         (CREATE if absent — 10 lines pointing to schema)
```

### Hook skeleton (Node.js)
```javascript
#!/usr/bin/env node
// UserPromptSubmit hook: Warn when context usage crosses threshold.
// Additive only — never blocks.

const { readFileSync, statSync, existsSync } = require('node:fs');

const DEFAULT_WINDOW = 200_000;
const DEFAULT_THRESHOLD_PCT = 60;
const APPROX_CHARS_PER_TOKEN = 4;

function killSwitchActive() {
  if (process.env.DISABLE_OMC === '1') return true;
  const skip = process.env.OMC_SKIP_HOOKS || '';
  return skip.split(',').map(s => s.trim()).includes('context-threshold-warn');
}

function estimateTokens(transcriptPath) {
  if (!transcriptPath || !existsSync(transcriptPath)) return 0;
  try {
    // Fast path: file size / chars-per-token.
    const { size } = statSync(transcriptPath);
    return Math.floor(size / APPROX_CHARS_PER_TOKEN);
  } catch {
    return 0;
  }
}

function activePlanDir() {
  // Match the convention used by dev-rules-reminder.cjs — session temp file.
  try {
    const sess = process.env.CLAUDE_SESSION_TEMP;
    if (sess && existsSync(sess)) {
      const data = JSON.parse(readFileSync(sess, 'utf8'));
      if (data.active_plan_dir) return data.active_plan_dir;
    }
  } catch {}
  return null;
}

let input = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => input += chunk);
process.stdin.on('end', () => {
  try {
    if (killSwitchActive()) process.exit(0);

    const data = JSON.parse(input || '{}');
    const transcriptPath = data.transcript_path;
    const window = parseInt(
      process.env.CLAUDE_CODE_AUTO_COMPACT_WINDOW || DEFAULT_WINDOW, 10
    ) || DEFAULT_WINDOW;
    const threshold = parseInt(
      process.env.CONTEXT_WARN_THRESHOLD || DEFAULT_THRESHOLD_PCT, 10
    ) || DEFAULT_THRESHOLD_PCT;

    const tokens = estimateTokens(transcriptPath);
    const pct = Math.round((tokens / window) * 100);

    if (pct < threshold) process.exit(0);

    const planDir = activePlanDir();
    const checkpointPath = planDir
      ? `${planDir}/checkpoints/debug-checkpoint.json`
      : `~/.claude/state/debug-checkpoint.json`;

    const message =
      `CONTEXT CHECKPOINT — ${pct}% of window used (${tokens} / ${window} tokens).\n` +
      `Before continuing, save a debug-checkpoint:\n` +
      `  Path: ${checkpointPath}\n` +
      `  Schema: ~/.claude/state/schemas/debug-checkpoint.schema.json\n` +
      `After saving, consider /compact with a summary argument.\n` +
      `This is advisory — continuing without checkpoint risks a mid-task truncation ` +
      `(see the 16 "Prompt is too long" incidents in the insights report).`;

    const output = {
      hookSpecificOutput: {
        hookEventName: 'UserPromptSubmit',
        additionalContext: message,
      },
    };
    process.stdout.write(JSON.stringify(output));
    process.exit(0);
  } catch {
    process.exit(0);
  }
});
```

### Settings registration
In `~/.claude/settings.json` UserPromptSubmit block (matcher `""`), append the command. The existing UserPromptSubmit array already has `dev-rules-reminder.cjs`, `documentation-context-check.js`, `skill-activation-forced-eval.js` — append to that list:

```json
{
  "matcher": "",
  "hooks": [
    { "type": "command", "command": "node \"$HOME/.claude/hooks/dev-rules-reminder.cjs\"" },
    { "type": "command", "command": "node \"$HOME/.claude/hooks/documentation-context-check.js\"" },
    { "type": "command", "command": "node \"$HOME/.claude/hooks/skill-activation-forced-eval.js\"" },
    { "type": "command", "command": "node \"$HOME/.claude/hooks/context-threshold-warn.js\"" }
  ]
}
```

### JSON Schemas

#### `debug-checkpoint.schema.json`
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "https://local/claude/state/schemas/debug-checkpoint.schema.json",
  "title": "DebugCheckpoint",
  "description": "Persisted state of a debugging campaign — survives /compact and session resumes.",
  "type": "object",
  "required": ["campaign_id", "target_file", "hypotheses", "fixes_attempted", "current_state", "last_updated"],
  "properties": {
    "campaign_id": {
      "type": "string",
      "description": "Stable slug; e.g. 'ocr-a7-boundary-2026-04' — reused across resumes.",
      "pattern": "^[a-z0-9-]+$"
    },
    "target_file": {
      "type": "string",
      "description": "Primary file under investigation (absolute path or repo-relative)."
    },
    "hypotheses": {
      "type": "array",
      "description": "Ordered list of tested hypotheses from the Root-Cause-First Protocol.",
      "items": {
        "type": "object",
        "required": ["id", "statement", "evidence_path", "result"],
        "properties": {
          "id": { "type": "string", "pattern": "^H[0-9]+$" },
          "statement": { "type": "string", "minLength": 10 },
          "evidence_path": { "type": "string", "description": "Path to trace log, screenshot, or diff." },
          "falsifier": { "type": "string" },
          "result": { "type": "string", "enum": ["pending", "confirmed", "rejected", "inconclusive"] }
        }
      }
    },
    "fixes_attempted": {
      "type": "array",
      "description": "Each fix corresponds to exactly ONE hypothesis (one-fix-at-a-time rule).",
      "items": {
        "type": "object",
        "required": ["id", "hypothesis_id", "diff_sha", "outcome"],
        "properties": {
          "id": { "type": "string", "pattern": "^F[0-9]+$" },
          "hypothesis_id": { "type": "string", "pattern": "^H[0-9]+$" },
          "diff_sha": { "type": "string", "description": "Git SHA of the committed fix (or 'uncommitted')." },
          "outcome": { "type": "string", "enum": ["passed", "reverted", "partial", "pending-validation"] },
          "revert_reason": { "type": "string" }
        }
      }
    },
    "current_state": {
      "type": "string",
      "enum": ["investigating", "awaiting-validation", "blocked", "resolved", "abandoned"]
    },
    "last_updated": {
      "type": "string",
      "format": "date-time"
    },
    "notes": {
      "type": "string",
      "description": "Free-form context that must survive /compact."
    }
  }
}
```

#### `audit-checkpoint.schema.json`
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "https://local/claude/state/schemas/audit-checkpoint.schema.json",
  "title": "AuditCheckpoint",
  "description": "Persisted state of an audit campaign (functional/UI/schema/data).",
  "type": "object",
  "required": ["audit_id", "scope", "findings", "current_phase", "last_updated"],
  "properties": {
    "audit_id": {
      "type": "string",
      "pattern": "^[a-z0-9-]+$"
    },
    "scope": {
      "type": "object",
      "required": ["platforms"],
      "properties": {
        "platforms": {
          "type": "array",
          "items": { "type": "string", "enum": ["web", "ios", "android", "api", "db", "cli", "design"] }
        },
        "journeys": { "type": "array", "items": { "type": "string" } }
      }
    },
    "findings": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["id", "platform", "severity", "evidence_path"],
        "properties": {
          "id": { "type": "string" },
          "platform": { "type": "string" },
          "severity": { "type": "string", "enum": ["blocker", "major", "minor", "info"] },
          "description": { "type": "string" },
          "evidence_path": { "type": "string" }
        }
      }
    },
    "current_phase": {
      "type": "string",
      "enum": ["research", "plan", "preflight", "execute", "analyze", "verdict", "ship"]
    },
    "last_updated": {
      "type": "string",
      "format": "date-time"
    }
  }
}
```

#### `~/.claude/state/README.md`
```markdown
# ~/.claude/state/

Persisted state shared across sessions. Survives `/compact` and
`--continue` resumes.

## Schemas
- `schemas/debug-checkpoint.schema.json` — debugging campaign state
  (consumed by Plan B debug-loop skill and Plan C ambitious workflows).
- `schemas/audit-checkpoint.schema.json` — audit campaign state.

## Project-local checkpoints
Individual projects may store their own checkpoint files (e.g.
`<project>/.claude/session-state/debug-checkpoint.json`). These MUST
validate against the schemas here. Treat these as the authoritative
contract.

## Writers
- `~/.claude/hooks/context-threshold-warn.js` — emits a reminder at
  60% context; does not write files itself.
- Plan B skills (forthcoming) — read/write checkpoints.
```

#### `~/Desktop/yt-transition-shorts-detector/.claude/session-state/README.md` (create if absent)
```markdown
# Detector Session State

Project-local checkpoints for the detection engine and agent system.

JSON files here validate against:
- `~/.claude/state/schemas/debug-checkpoint.schema.json`
- `~/.claude/state/schemas/audit-checkpoint.schema.json`

Naming: `<campaign-slug>-checkpoint.json` (e.g. `ocr-a7-boundary-checkpoint.json`).
Overwrite-in-place is permitted; prior state lives in git.
```

## Related Code Files
### Create
- `~/.claude/hooks/context-threshold-warn.js`
- `~/.claude/state/README.md`
- `~/.claude/state/schemas/debug-checkpoint.schema.json`
- `~/.claude/state/schemas/audit-checkpoint.schema.json`
- `~/Desktop/yt-transition-shorts-detector/.claude/session-state/README.md` (if absent)

### Modify
- `~/.claude/settings.json` — append hook registration to UserPromptSubmit block.

### Delete
- None.

## Implementation Steps
1. `mkdir -p ~/.claude/state/schemas`.
2. Write `~/.claude/state/schemas/debug-checkpoint.schema.json` from the Architecture block.
3. Write `~/.claude/state/schemas/audit-checkpoint.schema.json` from the Architecture block.
4. Write `~/.claude/state/README.md`.
5. Write `~/.claude/hooks/context-threshold-warn.js`; `chmod +x`.
6. Read `~/.claude/settings.json`; locate the UserPromptSubmit entry with `matcher: ""`.
7. Append the new command to that entry's `hooks` array.
8. `python3 -c "import json; json.load(open('$HOME/.claude/settings.json'))"` — JSON-valid.
9. Validate schemas parse: `python3 -c "import json; json.load(open('$HOME/.claude/state/schemas/debug-checkpoint.schema.json'))"` (and audit-checkpoint).
10. `test -d ~/Desktop/yt-transition-shorts-detector/.claude/session-state` — true; write README.md if absent.
11. `/hooks` to confirm registration.
12. Defer runtime validation to Phase 5.

## Todo List
- [ ] Create ~/.claude/state/ and schemas/ dirs
- [ ] Write debug-checkpoint.schema.json
- [ ] Write audit-checkpoint.schema.json
- [ ] Write state README.md
- [ ] Write context-threshold-warn.js + chmod +x
- [ ] Append settings.json registration
- [ ] Validate settings.json + both schemas parse
- [ ] Create detector session-state README.md (if absent)
- [ ] Confirm via /hooks command
- [ ] Handoff to Phase 5

## Success Criteria
- [ ] `test -x ~/.claude/hooks/context-threshold-warn.js` passes.
- [ ] `node --check ~/.claude/hooks/context-threshold-warn.js` passes.
- [ ] `jq '.' ~/.claude/state/schemas/debug-checkpoint.schema.json > /dev/null` passes (valid JSON).
- [ ] `jq '.' ~/.claude/state/schemas/audit-checkpoint.schema.json > /dev/null` passes.
- [ ] Both schemas declare `"$schema": "http://json-schema.org/draft-07/schema#"`.
- [ ] `jq '.hooks.UserPromptSubmit[] | select(.matcher == "") | .hooks[].command' ~/.claude/settings.json | grep context-threshold-warn` returns exactly one match.
- [ ] `/hooks` lists context-threshold-warn.js under UserPromptSubmit.
- [ ] Phase 5 evidence confirms: a UserPromptSubmit with a large transcript (>60% of window) yields stderr reminder; a small transcript is silent.
- [ ] `test -f ~/Desktop/yt-transition-shorts-detector/.claude/session-state/README.md` passes.

## Risk Assessment
| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Char-count heuristic is wildly inaccurate | Med | Low | Warning is advisory, not blocking. Overshoot triggers harmless extra reminder; undershoot defers to auto-compact. |
| Threshold emits on every prompt once crossed (noise) | High | Med | Future: debounce per session via a marker file in ~/.claude/state/. Ship v1 without debounce; revisit if noisy. |
| `CLAUDE_SESSION_TEMP` env var name is wrong | Med | Low | Plan dir fallback to `~/.claude/state/debug-checkpoint.json`; still functional, just less specific. Confirm env var name during Phase 5. |
| Schema files are too strict and break real-world checkpoints | Low | Med | All optional fields left optional (`notes`, `falsifier`). Required fields are minimal and well-reasoned. |
| Hook output invalid JSON breaks UserPromptSubmit | High if malformed | Critical | Outer try/catch → silent exit 0. JSON.stringify on a plain object is reliably valid. |
| User runs with `CLAUDE_CODE_AUTO_COMPACT_WINDOW` unset in a new env | Med | Low | `DEFAULT_WINDOW = 200_000` fallback. |
| Adding another UserPromptSubmit hook slows every prompt | Low | Low | Hook is O(1) — `statSync` + arithmetic; runs in <10ms. Parallel execution per hooks.md line 778. |
| Schemas locked in here; Plan B wants additional fields | Med | Low | `additionalProperties` default allowed by draft-07 → Plan B can add fields without migration. |

## Security Considerations
- Hook reads `transcript_path` passed in hook input. The transcript is in `~/.claude/projects/...` — user's own data, no escalation.
- `statSync(transcriptPath)` does not follow arbitrary symlinks to escalate; `statSync` follows symlinks by default, but the path is user-supplied by Claude Code itself — trusted.
- JSON Schema files are passive data; no execution risk.
- Kill-switch env vars (`DISABLE_OMC`, `OMC_SKIP_HOOKS`) respected — user can opt out instantly.
- No writes to filesystem at hook runtime. Schemas and state files are created only during the phase implementation step, not by the hook itself.
- Detector repo README write is a one-time phase action; no runtime writes.

## Next Steps
- Phase 5 exercises this hook against a real long-transcript session (or synthetic large transcript file).
- Plan B will implement a `/checkpoint-debug` skill that reads/writes `debug-checkpoint.json` conforming to the schema.
- Plan C will orchestrate multi-agent runs where each agent writes its own checkpoint to the schema.

## Unresolved Questions
- **Is `CLAUDE_SESSION_TEMP` the right env var** for discovering active plan dir? Confirm during Phase 5; if wrong, fall back to parsing `~/.claude/plans/` for the latest-modified plan.
- **Threshold: 60%, 70%, or two-stage (60% advisory + 80% strong reminder)**? Ship single-stage 60% for v1 to minimize noise; revisit after Phase 5 evidence.
- **Detector checkpoints: `.claude/session-state/` or a new `.debug/` dir?** Plan A defaults to extending `session-state/` (already exists, already ignored appropriately). User to confirm at validation interview.
- **Debouncing** — should repeated warnings within same session suppress? Maybe a `state/last-warned.json` with a 10-prompt cooldown. Deferred pending Phase 5 noise measurement.
