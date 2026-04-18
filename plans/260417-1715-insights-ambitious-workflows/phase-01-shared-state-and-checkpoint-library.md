# Phase 1 — Shared State + Checkpoint Library

## 1. Context Links

- Parent plan: `/Users/nick/Desktop/validationforge/plans/260417-1715-insights-ambitious-workflows/plan.md`
- Upstream (Plan A): `~/.claude/state/` (created by foundation plan) — this phase extends it with schemas + lib.
- Upstream (Plan B): `/root-cause-first`, `/gt-perfect`, `/audit` skills — consumers of the lib.
- Refs:
  - `~/.claude/plugins/cache/superpowers-marketplace/superpowers-developing-for-claude-code/0.3.1/skills/working-with-claude-code/references/hooks.md`
  - `~/.claude/plugins/cache/superpowers-marketplace/superpowers-developing-for-claude-code/0.3.1/skills/working-with-claude-code/references/sub-agents.md`
- Existing infra: `yt-transition-shorts-detector/.claude/checkpoints/`, `checkpoints.log`, `session-state/` (integrate, do not replace).

## 2. Overview

- **Priority:** P0 (every downstream phase depends on this)
- **Status:** pending (Plans A + B must complete first)
- **Description:** Ship a single DRY Node.js library (`checkpoint-lib.js`) and three JSON Schema draft-07 schemas that all three ambitious workflows — GT Tuner, Bug-Audit Swarm, Root-Cause Enforcer — consume. No phase after this may define its own JSON read/write logic.

## 3. Key Insights

- Plan A scaffolded `~/.claude/state/`; this phase adds the schemas and lib inside it.
- yt-shorts-detector already has `.claude/checkpoints/` with its own append-only log convention — the lib must NOT overwrite that; it adds a sibling layer under `~/.claude/state/` for cross-repo campaigns while each repo's local `.claude/checkpoints/` stays authoritative for repo-scoped work.
- Checkpoints MUST be append-tolerant (process crash mid-write survives): write-to-temp-then-rename is the pattern.
- `failed-approaches.md` is markdown (human-readable), NOT JSON — but the lib owns its append path so all three workflows log consistently.

## 4. Requirements

### Functional
- F1: `readCheckpoint(path, schemaName)` returns parsed object or throws structured error naming the missing/invalid field.
- F2: `writeCheckpoint(path, obj, schemaName)` validates against schema, writes atomically (tmp + rename), updates `checkpoints.log` append-only.
- F3: `appendFailedApproach(issueId, entry)` appends a timestamped markdown block to `.debug/<issue>/failed-approaches.md` (creates dir if missing).
- F4: Schemas exist for `gt-campaign.json`, `audit-campaign.json`, `debug-checkpoint.json`.
- F5: Lib works from any CWD — resolves `~/.claude/state/` via `os.homedir()`.

### Non-functional / Safety
- NF1: Zero runtime deps (stdlib only — use `fs`, `path`, `os`, `crypto`). Schema validation via hand-rolled draft-07 subset (enough for our schemas) OR bundled `ajv` copy if simpler — default: hand-rolled for zero-install.
- NF2: All writes atomic; crash mid-write leaves prior state intact.
- NF3: Lib file under 200 lines (per project code-standards).
- NF4: No network calls, no child_process spawns.

## 5. Architecture

```
~/.claude/state/
├── schemas/
│   ├── gt-campaign.schema.json
│   ├── audit-campaign.schema.json
│   └── debug-checkpoint.schema.json
├── campaigns/                  (written at runtime)
│   ├── gt/<campaign-id>.json
│   └── audit/<campaign-id>.json
└── checkpoints.log             (append-only audit trail)

~/.claude/scripts/common/
├── checkpoint-lib.js           (public API)
└── checkpoint-lib.test-harness.js  (evidence-generating driver, NOT a test file)
```

### Public API (checkpoint-lib.js)
```js
// ~/.claude/scripts/common/checkpoint-lib.js
const fs = require('fs');
const path = require('path');
const os = require('os');
const crypto = require('crypto');

const STATE_ROOT = path.join(os.homedir(), '.claude', 'state');
const SCHEMA_DIR = path.join(STATE_ROOT, 'schemas');
const LOG_PATH = path.join(STATE_ROOT, 'checkpoints.log');

function readCheckpoint(filePath, schemaName) { /* load + validate */ }
function writeCheckpoint(filePath, obj, schemaName) { /* validate + atomic write + log */ }
function appendFailedApproach(issueId, entry) { /* md append */ }
function validate(obj, schemaName) { /* hand-rolled draft-07 subset */ }

module.exports = { readCheckpoint, writeCheckpoint, appendFailedApproach, validate };
```

### Schema: gt-campaign.schema.json (sketch)
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["campaign_id", "started_at", "iterations", "status"],
  "properties": {
    "campaign_id": {"type": "string", "pattern": "^[a-z0-9-]+$"},
    "started_at": {"type": "string", "format": "date-time"},
    "iterations": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["iter", "proposed_fixes", "merged_fix", "gt_score_before", "gt_score_after"],
        "properties": {
          "iter": {"type": "integer", "minimum": 0},
          "proposed_fixes": {"type": "array"},
          "merged_fix": {"type": ["string", "null"]},
          "gt_score_before": {"type": "number"},
          "gt_score_after": {"type": "number"}
        }
      }
    },
    "status": {"enum": ["running", "paused", "succeeded", "aborted", "budget_exceeded"]},
    "budget": {
      "type": "object",
      "properties": {
        "max_iterations": {"type": "integer"},
        "max_wall_clock_sec": {"type": "integer"},
        "max_tokens": {"type": "integer"}
      }
    }
  }
}
```

### Schema: audit-campaign.schema.json (sketch)
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["campaign_id", "status", "bugs"],
  "properties": {
    "campaign_id": {"type": "string"},
    "status": {"enum": ["scouting", "fixing", "reviewing", "done", "aborted"]},
    "bugs": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["bug_id", "phase", "scout_branch"],
        "properties": {
          "bug_id": {"type": "string"},
          "phase": {"enum": ["scouted", "fixing", "fixed", "reviewed", "merged", "failed"]},
          "scout_branch": {"type": "string"},
          "fix_attempts": {"type": "integer", "maximum": 5},
          "reproduction_path": {"type": "string"}
        }
      }
    }
  }
}
```

### Schema: debug-checkpoint.schema.json (sketch)
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["issue_id", "hypothesis", "evidence_files", "failed_approaches_ref"],
  "properties": {
    "issue_id": {"type": "string"},
    "hypothesis": {"type": "object", "required": ["file", "line", "reason"]},
    "evidence_files": {"type": "array", "items": {"type": "string"}, "minItems": 1},
    "failed_approaches_ref": {"type": "string"},
    "created_at": {"type": "string", "format": "date-time"}
  }
}
```

### Merge predicate helper (shared)
`applyPredicate(beforeMetrics, afterMetrics, predicate)` — used by GT Tuner (net score up, no regressions) and Swarm reviewer.

## 6. Related Code Files

**CREATE:**
- `/Users/nick/.claude/state/schemas/gt-campaign.schema.json`
- `/Users/nick/.claude/state/schemas/audit-campaign.schema.json`
- `/Users/nick/.claude/state/schemas/debug-checkpoint.schema.json`
- `/Users/nick/.claude/scripts/common/checkpoint-lib.js`
- `/Users/nick/.claude/scripts/common/checkpoint-lib.test-harness.js` (functional-validation driver; NOT a unit test)

**MODIFY:**
- `/Users/nick/.claude/state/README.md` (add schemas section if Plan A created it; else create)

**DELETE:** none.

## 7. Implementation Steps

1. Verify Plan A completed — `~/.claude/state/` exists and its README is present. If not, BLOCK.
2. Draft the three JSON Schemas in parallel. Use draft-07. Validate each by hand against a known-good sample object.
3. Implement `checkpoint-lib.js`:
   - `STATE_ROOT` constant derived from `os.homedir()`.
   - `validate()` supports `type`, `required`, `properties`, `items`, `enum`, `minimum`, `maximum`, `minItems`, `pattern` (regex). Error = `{ok:false, path, reason}`.
   - `readCheckpoint`: `fs.readFileSync` + `JSON.parse` + `validate`; throws `CheckpointError` with structured fields.
   - `writeCheckpoint`: validate first, then `fs.writeFileSync(tmp)` + `fs.renameSync(tmp, final)` + append one line to `checkpoints.log` (`<iso> WRITE <file> <sha256-of-payload>`).
   - `appendFailedApproach`: mkdirs `.debug/<issueId>/`, appends fenced markdown block with timestamp + entry fields.
4. Implement `checkpoint-lib.test-harness.js`:
   - Safety gate: refuses to run if `NODE_ENV !== 'harness'` OR `--confirm` flag absent.
   - Runs against `/tmp/vf-checkpoint-harness-<pid>/` — never touches real `~/.claude/state/`.
   - Scenarios: (a) write valid gt-campaign, read back, assert equal; (b) write invalid (missing `status`) — expect structured error; (c) atomic crash sim — write, kill between tmp + rename, restart, confirm prior state intact; (d) append two failed approaches, confirm both present in order.
   - Prints `HARNESS PASS:` / `HARNESS FAIL:` with specific evidence lines. No assertions library.
5. Write `~/.claude/state/README.md` amendment documenting schema purpose + invariants.
6. Run the harness. Capture stdout to Phase 6 evidence dir.

### Safety gates
- Step 3.4 atomic write MUST be `tmp + rename`, never `fs.writeFileSync(final)` directly.
- Step 4 harness MUST NOT write to real state root — path check at start.

## 8. Todo List

- [ ] Verify Plan A deliverables present
- [ ] Write `gt-campaign.schema.json`
- [ ] Write `audit-campaign.schema.json`
- [ ] Write `debug-checkpoint.schema.json`
- [ ] Implement `checkpoint-lib.js` (<200 LOC)
- [ ] Implement `checkpoint-lib.test-harness.js` with isolation gate
- [ ] Update `~/.claude/state/README.md`
- [ ] Run harness, capture output
- [ ] File harness evidence under Phase 6 reports dir

## 9. Success Criteria

- Running `node ~/.claude/scripts/common/checkpoint-lib.test-harness.js --confirm` prints `HARNESS PASS:` for all four scenarios.
- `grep -c WRITE ~/.claude/state/checkpoints.log` increases by the expected number after harness run (observable, not inferred).
- Valid schema file count: 3. Invalid or missing schema: fail phase.
- Lib file ≤ 200 lines (measured with `wc -l`).

## 10. Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Hand-rolled validator misses edge case | Medium | Medium | Schemas deliberately use a narrow draft-07 subset; harness covers each supported keyword. |
| Harness accidentally writes to real state root | Low | High (data loss) | Path assertion at start; abort if path starts with `os.homedir()/.claude/state` (except schema read). |
| Two workflows write same campaign_id | Low | High | `campaign_id` includes timestamp + 6-char hex random; collision probability negligible. |
| Log file grows unbounded | Low | Low | Mitigation deferred (noted); rotation added in a future plan. |
| Breakage of yt-shorts-detector local `.claude/checkpoints/` | Low | High | Lib NEVER touches repo-local checkpoints — only `~/.claude/state/`. |

## 11. Security Considerations

- No `child_process`, no `eval`, no network. Pure fs + crypto(sha256) only.
- Harness MUST run in `/tmp/` — enforced by path guard.
- `appendFailedApproach` treats `issueId` as a path segment — lib MUST reject `issueId` containing `/`, `..`, or leading `.`.
- Schema files are trusted input (shipped by us), but user-supplied checkpoint JSON is validated before any property access.

## 12. Next Steps

Phase 2 (Root-Cause Enforcer hook) consumes `debug-checkpoint.schema.json` and `readCheckpoint`. Phase 3 (GT Tuner) consumes `gt-campaign.schema.json`. Phase 4 (Swarm) consumes `audit-campaign.schema.json`. All three depend on this lib being in place.
