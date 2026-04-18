# Phase 3 — GT Autonomous Tuner

## 1. Context Links

- Parent plan: `/Users/nick/Desktop/validationforge/plans/260417-1715-insights-ambitious-workflows/plan.md`
- Upstream Phase 1: `checkpoint-lib.js`, `gt-campaign.schema.json`
- Upstream Plan B: `/gt-perfect` skill (per-video subagent template)
- Upstream Plan A: `detector-project-conventions.md` (GT scoring definition)
- Refs:
  - `~/.claude/plugins/cache/superpowers-marketplace/superpowers-developing-for-claude-code/0.3.1/skills/working-with-claude-code/references/sub-agents.md` — Task tool dispatch
  - `~/.claude/plugins/cache/superpowers-marketplace/superpowers-developing-for-claude-code/0.3.1/skills/working-with-claude-code/references/slash-commands.md` — `/gt-tuner` definition pattern
  - `~/.claude/rules/orchestration-protocol.md` — DONE / BLOCKED / NEEDS_CONTEXT status
- Existing infra: `yt-transition-shorts-detector_worktrees/` (sibling worktree dir — isolation convention).

## 2. Overview

- **Priority:** P1
- **Status:** pending (Phases 1 + 2 required — enforcer must be live so subagents can't skip root-cause)
- **Description:** A bounded multi-agent campaign. One slash command, `/gt-tuner`, spins up N video-owner subagents that each propose ONE root-cause fix as structured JSON. A coordinator spawns per-proposal git worktrees, runs full GT regression in each, applies a merge predicate (net improvement AND zero previous-match regressions), merges the winner, logs the rest to `.gt-tuner/failed-approaches.md`, and iterates.

## 3. Key Insights

- yt-shorts-detector's current GT score is 7/8. We don't need 8 parallel subagents — we need per-failing-video subagents plus a few on passing videos to surveil for regressions.
- Running full regression for every proposed fix is expensive. Parallelizing via worktrees amortizes wall-clock but multiplies token + CPU cost. Bounded budget is non-negotiable.
- `yt-transition-shorts-detector_worktrees/` is already the sibling dir convention — we reuse it.
- Per-video subagents must return STRUCTURED JSON (not prose) so the coordinator's ranking logic is deterministic.
- "Merge only on net improvement with zero regressions" means a proposed fix that turns 7→8 on video A but 3→2 on video B is auto-rejected.

## 4. Requirements

### Functional
- F1: `/gt-tuner` slash command in `yt-transition-shorts-detector/.claude/commands/gt-tuner.md` — invokes coordinator.
- F2: Coordinator reads `.gt-tuner/config.json` for bounds; rejects run if any bound missing.
- F3: Spawns per-video subagents via Task tool, passing `video-worker.prompt.md` + the failing-video fixture path.
- F4: Each subagent returns JSON: `{"root_cause": {file, line, reason}, "fix_diff": "<unified diff>", "expected_delta": {"videoId": +1/-0/-1}, "risk": "low|med|high"}`.
- F5: Arbiter applies each proposed `fix_diff` inside a fresh git worktree under `../yt-transition-shorts-detector_worktrees/tuner-<campaign-id>-<iter>-<proposalHash>/`, runs the full GT regression script, captures score.
- F6: Merge predicate: sum(Δscore) > 0 AND ∀ previously-matching video: post-score ≥ pre-score. Reject otherwise.
- F7: On accept, coordinator cherry-picks/creates PR; on reject, appends to `.gt-tuner/failed-approaches.md` with root_cause + reason + counterexample video.
- F8: Checkpoint after every iter to `~/.claude/state/campaigns/gt/<campaign-id>.json` via `writeCheckpoint`. Resume supported.
- F9: Bounded: `max_iterations=20`, `max_parallel_subagents=8`, `max_wall_clock_sec=1800` per iter, `max_tokens` from config.
- F10: SQLite scoreboard captures per-iter per-video scores for post-hoc analysis.

### Non-functional / Safety
- NF1: Coordinator NEVER commits to main. Worktrees + PR only.
- NF2: All subagents inherit `CLAUDE_SKIP_ROOT_CAUSE_GATE=0` (enforcer stays on) — but coordinator pre-writes a stub `evidence.md` skeleton per video and requires subagent to fill it.
- NF3: Kill switch: `.gt-tuner/ABORT` sentinel file → coordinator drains in-flight, checkpoints, exits.
- NF4: Worktrees are auto-pruned after success/failure (configurable retain-on-fail).

## 5. Architecture

### Role definitions
| Role | Location | Responsibility | Returns |
|------|----------|---------------|---------|
| Coordinator | `scripts/gt-tuner/coordinator.js` | Orchestration, budget tracking, checkpointing | exit code + campaign JSON |
| Video-Owner Subagent | invoked via Task tool using `video-worker.prompt.md` | Diagnose ONE video, propose ONE fix | JSON proposal |
| Arbiter | `scripts/gt-tuner/arbiter.js` | Apply fix in worktree, run regression, score | per-fix scoreboard row |
| Scoreboard | `scoreboard.sqlite` | Persist all iter/video/fix metrics | SQL views |

### Message passing
```
coordinator.js
  ├── reads .gt-tuner/config.json
  ├── ensures .gt-tuner/failed-approaches.md
  ├── for iter in 0..max_iterations:
  │    ├── select target videos (failing + sentinel passing)
  │    ├── Task dispatch subagents in parallel (≤ max_parallel)
  │    ├── collect JSON proposals (timeout per subagent)
  │    ├── for each proposal: arbiter.runInWorktree(proposal) → score row
  │    ├── rank + apply merge predicate
  │    ├── if winner: git-merge-to-campaign-branch + PR; else: log all to failed-approaches
  │    ├── writeCheckpoint(campaign-id, state)
  │    └── stop if goal met OR budget exceeded OR ABORT sentinel present
```

### Merge predicate (pseudocode)
```js
function acceptFix(pre, post, previouslyPassing) {
  const delta = sum(post) - sum(pre);
  const regression = previouslyPassing.some(v => post[v] < pre[v]);
  return delta > 0 && !regression;
}
```

### SQLite schema (scoreboard.sqlite.schema.sql)
```sql
CREATE TABLE IF NOT EXISTS campaigns (
  id TEXT PRIMARY KEY,
  started_at TEXT NOT NULL,
  ended_at TEXT,
  status TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS iterations (
  campaign_id TEXT, iter INTEGER,
  started_at TEXT, ended_at TEXT,
  PRIMARY KEY (campaign_id, iter)
);
CREATE TABLE IF NOT EXISTS proposals (
  campaign_id TEXT, iter INTEGER, proposal_hash TEXT,
  video_id TEXT, root_cause_file TEXT, root_cause_line INTEGER,
  risk TEXT, accepted INTEGER,
  PRIMARY KEY (campaign_id, iter, proposal_hash)
);
CREATE TABLE IF NOT EXISTS regressions (
  campaign_id TEXT, iter INTEGER, proposal_hash TEXT,
  video_id TEXT, pre_score INTEGER, post_score INTEGER,
  PRIMARY KEY (campaign_id, iter, proposal_hash, video_id)
);
CREATE VIEW iter_summary AS
  SELECT campaign_id, iter,
         COUNT(DISTINCT proposal_hash) AS proposals,
         SUM(CASE WHEN accepted=1 THEN 1 ELSE 0 END) AS accepted
  FROM proposals GROUP BY campaign_id, iter;
```

### config.json shape
```json
{
  "max_iterations": 20,
  "max_parallel_subagents": 8,
  "max_wall_clock_sec_per_iter": 1800,
  "max_tokens_total": 2000000,
  "regression_script": "python3 scripts/groundtruth/compare_all_gt_vs_detection.py",
  "videos_root": "videos/",
  "retain_failed_worktrees": false,
  "campaign_branch_prefix": "gt-tuner/"
}
```

### video-worker.prompt.md (sketch)
```
You own ONE video: {{video_path}} (GT: {{gt_path}}). Current detection score: {{score}}.
Task: diagnose the SINGLE root cause of the mismatch. Propose ONE minimal fix.
Constraints:
  - You MUST run /root-cause-first and produce .debug/{{issue_id}}/evidence.md
  - You MUST return ONLY JSON: {"root_cause":{"file","line","reason"},"fix_diff":"...","expected_delta":{...},"risk":"low|med|high"}
  - If you cannot isolate a single root cause, return {"status":"NEEDS_CONTEXT","reason":"..."}
  - Do not edit the detector directly — return the diff; the coordinator applies it.
Status: DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
```

## 6. Related Code Files

**CREATE:**
- `/Users/nick/Desktop/yt-transition-shorts-detector/.claude/commands/gt-tuner.md`
- `/Users/nick/Desktop/yt-transition-shorts-detector/scripts/gt-tuner/coordinator.js`
- `/Users/nick/Desktop/yt-transition-shorts-detector/scripts/gt-tuner/arbiter.js`
- `/Users/nick/Desktop/yt-transition-shorts-detector/scripts/gt-tuner/video-worker.prompt.md`
- `/Users/nick/Desktop/yt-transition-shorts-detector/scripts/gt-tuner/scoreboard.sqlite.schema.sql`
- `/Users/nick/Desktop/yt-transition-shorts-detector/.gt-tuner/config.json` (template + committed default)
- `/Users/nick/Desktop/yt-transition-shorts-detector/.gt-tuner/failed-approaches.md` (empty sentinel)
- `/Users/nick/Desktop/yt-transition-shorts-detector/.gt-tuner/README.md` (kill-switch + resume docs)

**MODIFY:**
- `/Users/nick/Desktop/yt-transition-shorts-detector/.gitignore` — ignore `.gt-tuner/scoreboard.sqlite`, worktree dirs are already external.

**DELETE:** none.

## 7. Implementation Steps

1. Read `/gt-perfect` skill (Plan B output) — the video-worker prompt extends it.
2. Draft `video-worker.prompt.md` first (contract drives coordinator design).
3. Create SQLite schema file; smoke-check with `sqlite3 :memory: < schema.sql`.
4. Implement `arbiter.js`:
   - `createWorktree(campaignId, iter, proposalHash)` — `git worktree add ../yt-transition-shorts-detector_worktrees/tuner-<id>-<iter>-<hash> <base-sha>`.
   - `applyDiff(worktreePath, diffText)` — write to tmp, `git apply --index`.
   - `runRegression(worktreePath)` — spawn the `regression_script`, capture stdout, parse per-video scores.
   - `cleanupWorktree(path, retain)` — `git worktree remove --force` unless retain flag.
5. Implement `coordinator.js`:
   - Load config, validate, resolve campaign-id = `<iso-date>-<6hex>`.
   - On resume, load existing campaign JSON from `~/.claude/state/campaigns/gt/` and continue from `iterations.length`.
   - Per iter: pick target videos → Task-dispatch subagents with bounded parallelism → collect JSON → arbiter scoring → predicate → merge or log.
   - After each iter: `writeCheckpoint`, check `.gt-tuner/ABORT`, check budgets.
6. Write `.claude/commands/gt-tuner.md` — thin wrapper that invokes `node scripts/gt-tuner/coordinator.js --config .gt-tuner/config.json`.
7. Write `.gt-tuner/README.md` documenting: kill switch (`touch .gt-tuner/ABORT`), resume (`node coordinator.js --resume <campaign-id>`), inspect scoreboard (`sqlite3 .gt-tuner/scoreboard.sqlite 'SELECT * FROM iter_summary'`), reading failed-approaches.
8. Prepare Phase 6 fixture scenario: run one iteration against current 7/8 state, capture evidence.

### Safety gates
- Step 4.4 worktree cleanup MUST be idempotent — coordinator aborts must still clean up eventually (add startup orphan-worktree sweep).
- Step 5.3 subagent dispatch MUST wrap each Task call with a per-subagent timeout; hung subagents are marked BLOCKED and do not block the iter.
- Step 5.5 budget check happens BEFORE dispatching next iter — never mid-iter (which would orphan worktrees).

## 8. Todo List

- [ ] Read `/gt-perfect` skill
- [ ] Draft `video-worker.prompt.md`
- [ ] Create SQLite schema + smoke check
- [ ] Implement `arbiter.js` (worktree lifecycle + regression runner)
- [ ] Implement `coordinator.js` (orchestration + budget + checkpoint + resume)
- [ ] Write `.claude/commands/gt-tuner.md`
- [ ] Write `.gt-tuner/config.json` template
- [ ] Write `.gt-tuner/README.md` with kill-switch + resume docs
- [ ] Orphan-worktree sweep at startup
- [ ] Phase 6 fixture prep

## 9. Success Criteria

- `/gt-tuner` runs one full iter without errors against current yt-shorts-detector 7/8 state.
- Scoreboard SQLite contains at least one `proposals` row and at least one `regressions` row.
- Campaign JSON at `~/.claude/state/campaigns/gt/<id>.json` validates against `gt-campaign.schema.json`.
- At least one proposal is correctly accepted or correctly rejected by the merge predicate (Phase 6 validates which).
- Kill switch tested: `touch .gt-tuner/ABORT` during an iter → coordinator exits cleanly within 60s, checkpoint written, no orphan worktrees.
- Resume tested: kill coordinator mid-iter → restart with `--resume <id>` → continues from the next iter.

## 10. Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Subagent returns malformed JSON | High | Medium | Coordinator validates against a small JSON Schema; malformed → mark BLOCKED, log, continue. |
| Worktree creation fails (path clash) | Medium | Medium | Unique dir name per proposal; orphan sweep at startup. |
| Full regression too slow — wall-clock blowout | High | High | Bounded `max_wall_clock_sec_per_iter`; coordinator kills iter if exceeded, logs partial. |
| Proposed fix introduces hidden regression on unscored video | Medium | High | Merge predicate checks ALL previously-passing videos, not just failing targets. |
| Token burn exceeds user budget | High | High | `max_tokens_total` pre-iter check; `/validate-telemetry` style accounting written to campaign JSON. |
| Two parallel subagents propose conflicting diffs | Medium | Low (by design) | Arbiter runs them independently in separate worktrees; merge predicate picks winner. |
| Worktree dir fills disk | Low | High | `retain_failed_worktrees=false` default; startup sweep of stale dirs >7 days. |
| Subagent bypasses enforcer via `CLAUDE_SKIP_ROOT_CAUSE_GATE=1` | Low | High | Coordinator explicitly unsets the env var when spawning subagents. |
| SQLite corruption from crash | Low | Medium | `PRAGMA journal_mode=WAL`; campaign JSON is the authoritative state — SQLite is an index. |

## 11. Security Considerations

- Coordinator spawns subagents via Task tool — no arbitrary bash exposure to them; subagent `--allowedTools` whitelist (also enforced in Phase 5 headless wrapper).
- `git apply` runs in isolated worktree; if the patch targets paths outside the worktree (e.g. `../`), `git apply` rejects it naturally.
- Regression script is invoked via `execFile` with argv array (no shell) to prevent injection from a malformed config.
- Campaign JSON is validated before read and before write (via Phase 1 lib).
- Subagents do NOT have network access beyond what Claude Code normally permits — no external calls from worker prompts.

## 12. Next Steps

Phase 4 (Swarm) mirrors this architecture for a different domain. Phase 5 wraps the coordinator in a headless runner. Phase 6 validates an end-to-end campaign against yt-shorts-detector.
