# Phase 4 — Bug-Audit Swarm

## 1. Context Links

- Parent plan: `/Users/nick/Desktop/validationforge/plans/260417-1715-insights-ambitious-workflows/plan.md`
- Upstream Phase 1: `checkpoint-lib.js`, `audit-campaign.schema.json`
- Upstream Plan B: `/audit` skill (reviewer role template)
- Refs:
  - `~/.claude/skills/skill-creator/SKILL.md` — skill authoring protocol (required for the skill we ship)
  - `~/.claude/plugins/cache/superpowers-marketplace/superpowers-developing-for-claude-code/0.3.1/skills/working-with-claude-code/references/sub-agents.md` — Task tool dispatch
  - `~/.claude/rules/team-coordination-rules.md` — if using `/team` instead of plain subagents
  - `~/.claude/rules/orchestration-protocol.md` — status protocol
- Project constraint: `CLAUDE.md` forbids mock/test files. Scouts produce REAL failing invocations (CLI/HTTP), not `*.test.*` or `*.spec.*`.

## 2. Overview

- **Priority:** P1
- **Status:** pending (Phases 1 + 2 required)
- **Description:** A skill + coordinator script that spawns Scout → Fixer → Reviewer role subagents in a bounded loop. Scouts discover bugs and write real failing reproductions (CLI invocations or HTTP calls, committed to `bug/<id>` branches). Fixers consume scout branches and iterate (max 5 attempts) to make the reproduction pass. Reviewers gate PRs on diff shape. State persists to `.audit/checkpoint.json` for cross-session resume.

## 3. Key Insights

- The one-shot audit that inspired this found 18 bugs / fixed 12. The swarm turns that into a continuous pipeline.
- The no-mocks rule means "failing reproduction" is a bash script or curl command that exits non-zero, NOT a jest/pytest file. `hooks/block-test-files.js` will reject `.test.` or `.spec.` files under `src/`/`lib/` — scouts write to `reproductions/bug-<id>.sh` instead.
- Unresolved question from plan.md: `/team` vs plain Task-tool subagents. Default: plain Task subagents (less setup). `/team` option documented but gated behind a config flag.
- Cross-session resume matters because a full swarm run may exceed a single session's context; checkpoint must be the source of truth.
- Skill-creator protocol requires: `SKILL.md` with pushy description, scripts dir, per-role prompts, worked example.

## 4. Requirements

### Functional
- F1: `bug-audit-swarm` skill at `~/.claude/skills/bug-audit-swarm/SKILL.md` with invocation triggers.
- F2: Coordinator `swarm-coordinator.js` spawns Scout/Fixer/Reviewer via Task tool, gated by `audit-campaign.json` state.
- F3: Scouts produce `reproductions/bug-<id>.sh` (or `.py`) — real invocation, exit-coded, NO mocks/stubs/test-files. Commits to branch `bug/<id>`.
- F4: Fixers consume one scout branch at a time, iterate up to 5 attempts. Success = reproduction script exits 0.
- F5: Reviewers gate: diff <50 LOC unless `reviewer_override:` tag in commit; no unrelated files; no reverted-then-reapplied pattern (detected via commit graph).
- F6: `.audit/checkpoint.json` updated after EVERY role turn (not every iter — finer granularity).
- F7: Resume from checkpoint in a fresh session with no state loss.
- F8: Termination: 2 consecutive scout passes find no new bugs OR hard budget hit.
- F9: Final report written to `.audit/report.md` with table `{bugs_found, fixed, failed, files_touched, pct_reviewed}`.
- F10: Configurable: `/team` mode OR plain Task mode, set in `.audit/config.json`.

### Non-functional / Safety
- NF1: Bounded budget — `max_scouts`, `max_fixers_per_bug=5`, `max_total_iters`, `max_wall_clock_sec`, `max_tokens`.
- NF2: Scouts' `allowedTools` whitelist: `Read, Grep, Glob, Bash(rw only within repo)`. No Edit/Write to src files — scouts commit only to `reproductions/` and docs.
- NF3: Kill switch: `.audit/ABORT` sentinel → coordinator drains, checkpoints, exits.
- NF4: Every PR created by the swarm has `[bug-audit-swarm]` prefix for traceability.

## 5. Architecture

### Role definitions
| Role | Allowed Tools | Inputs | Outputs | Status codes |
|------|---------------|--------|---------|--------------|
| Scout | Read, Grep, Glob, Bash (bounded) | codebase, previously-found bug list | `reproductions/bug-<id>.{sh,py}` + bug metadata JSON on branch `bug/<id>` | DONE / NEEDS_CONTEXT / BLOCKED |
| Fixer | Read, Edit, Write (src only), Bash | scout branch | fix commits on branch `fix/<id>` (branches off scout branch) | DONE / BLOCKED after 5 attempts |
| Reviewer | Read, Bash (git only) | fix branch | PR created + approval label OR rejection with reasons | DONE / DONE_WITH_CONCERNS / BLOCKED |

### State transitions (audit-campaign.json)
```
scouted → fixing → fixed → reviewed → merged
                 ↘ failed (max attempts)
                 ↘ rejected (reviewer)
```

### Checkpoint structure (per schema in Phase 1)
```json
{
  "campaign_id": "audit-20260417-a3f2c1",
  "status": "fixing",
  "bugs": [
    {
      "bug_id": "b-001",
      "phase": "fixing",
      "scout_branch": "bug/b-001",
      "fix_attempts": 2,
      "reproduction_path": "reproductions/bug-b-001.sh",
      "last_turn_at": "2026-04-17T17:20:00Z"
    }
  ],
  "budget": {"max_total_iters": 30, "max_wall_clock_sec": 7200, "max_tokens": 3000000},
  "consecutive_empty_scouts": 0
}
```

### Coordinator flow
```
for iter in 0..max_total_iters:
  if status == scouting:
    spawn ≤ max_scouts in parallel
    collect results; if any returns new bugs → audit-campaign.bugs += new; consecutive_empty = 0
    else consecutive_empty++
    if consecutive_empty >= 2 AND no bugs still in fixing/reviewing → TERMINATE DONE
  for each bug in phase=scouted|fixing:
    spawn Fixer (one at a time per bug); bug.fix_attempts++
    if reproduction passes → phase=fixed
    if attempts >= 5 → phase=failed
  for each bug in phase=fixed:
    spawn Reviewer
    DONE → create PR, phase=reviewed
    BLOCKED → phase=rejected
  writeCheckpoint(...)
  if .audit/ABORT exists → drain + exit
```

### Prompt templates (sketches)

**scouts/scout-prompt.md**
```
You are a Scout in the Bug-Audit Swarm. Campaign: {{campaign_id}}.
Known bugs (do NOT re-report): {{known_bugs_list}}.
Goal: find ONE real bug. Produce a REAL failing reproduction:
  - Bash script (`reproductions/bug-<id>.sh`) OR Python driver (NOT pytest/unittest)
  - Script must exit non-zero when the bug is present
  - NO mocks/stubs/test-files (hooks will block you)
Commit to branch `bug/<id>` (id = 8-char hex).
Return JSON: {"bug_id","reproduction_path","one_line_summary","hypothesized_area","status":"DONE"}.
If no new bug found after thorough search, return {"status":"DONE","bug_id":null}.
```

**fixers/fixer-prompt.md**
```
You are a Fixer. Bug: {{bug_id}}. Branch: {{scout_branch}}. Attempt: {{attempt}}/5.
Reproduction script: {{reproduction_path}}. Goal: make it exit 0.
Constraints:
  - You MUST run /root-cause-first; evidence.md required (enforcer will block otherwise)
  - ONE logical fix per attempt
  - If attempt fails, DO NOT retry blindly — re-diagnose or return BLOCKED
Return {"status":"DONE|BLOCKED","sha","files_changed","notes"}.
```

**reviewers/reviewer-prompt.md**
```
You are a Reviewer. Fix branch: {{fix_branch}}. Reproduction: {{reproduction_path}}.
Checks:
  - `git diff --stat {{base}}..{{fix_branch}}`: total LOC ≤ 50 unless commit message contains `reviewer_override:`
  - No files outside the hypothesized area unless commit message justifies
  - No reverted-then-reapplied commits in the branch's log
  - Reproduction still passes (exit 0)
Return {"status":"DONE|BLOCKED","reasons":[],"pr_url"}.
```

## 6. Related Code Files

**CREATE:**
- `/Users/nick/.claude/skills/bug-audit-swarm/SKILL.md`
- `/Users/nick/.claude/skills/bug-audit-swarm/scripts/swarm-coordinator.js`
- `/Users/nick/.claude/skills/bug-audit-swarm/scripts/lib/state.js` (thin wrapper around `checkpoint-lib.js`)
- `/Users/nick/.claude/skills/bug-audit-swarm/scouts/scout-prompt.md`
- `/Users/nick/.claude/skills/bug-audit-swarm/fixers/fixer-prompt.md`
- `/Users/nick/.claude/skills/bug-audit-swarm/reviewers/reviewer-prompt.md`
- `/Users/nick/.claude/skills/bug-audit-swarm/.audit/config.json.template`
- `/Users/nick/.claude/skills/bug-audit-swarm/examples/worked-example.md`
- `/Users/nick/.claude/skills/bug-audit-swarm/README.md`

**MODIFY:** none (skill is self-contained).

**DELETE:** none.

## 7. Implementation Steps

1. Re-read `skill-creator/SKILL.md` for the exact SKILL.md structure (name, description, triggers, how-to-invoke).
2. Draft prompt templates FIRST — they define the contract the coordinator enforces.
3. Implement `lib/state.js` on top of `checkpoint-lib.js` — add methods: `transitionBug(bugId, newPhase)`, `incrementAttempts(bugId)`, `listBugsInPhase(phase)`.
4. Implement `swarm-coordinator.js`:
   - Parse CLI args: `--campaign <id> | --new`, `--config <path>`, `--resume`.
   - Load or create campaign JSON.
   - Main loop as in §5. Subagents dispatched via Task tool with the appropriate prompt template and `allowedTools` whitelist.
   - Per-turn checkpoint write.
   - Budget + ABORT + termination checks at the top of each iter.
5. Write `SKILL.md` with pushy description ("Invoke for any full-codebase bug audit or continuous bug-find campaign"). Include invocation triggers (regex patterns), how-to-invoke (one command).
6. Write `worked-example.md` — a small fixture with a seeded bug, showing scout → fixer → reviewer transcripts.
7. Write `README.md` documenting: config fields, kill switch, resume, `/team` mode toggle.
8. Prepare Phase 6 fixture: a small seeded module (under Phase 6 scratch dir) with an obvious bug the swarm can find, fix, and merge.

### Safety gates
- Step 4 Task dispatch MUST pass explicit `allowedTools` per role (Phase 5 also enforces this at the outer shell layer — defense in depth).
- Step 4 coordinator MUST check `.audit/ABORT` inside the main loop, not only at iter boundary — drains within 60s.
- Step 5 SKILL.md triggers must be specific enough not to auto-fire on unrelated "audit" mentions. Use `bug-audit-swarm`, `swarm audit`, or explicit invocation — not bare `audit`.

## 8. Todo List

- [ ] Re-read skill-creator protocol
- [ ] Draft scout/fixer/reviewer prompt templates
- [ ] Implement `lib/state.js` on top of Phase 1 lib
- [ ] Implement `swarm-coordinator.js` with bounded loop + checkpoint + resume
- [ ] Write `SKILL.md` (pushy description, triggers, how-to-invoke)
- [ ] Write `worked-example.md` with transcripts
- [ ] Write `README.md` (config, kill switch, resume, /team toggle)
- [ ] Prepare Phase 6 seeded-bug fixture

## 9. Success Criteria

- Phase 6 run: swarm finds the seeded bug, fixer makes reproduction exit 0, reviewer opens a PR with `[bug-audit-swarm]` prefix. **Evidence = PR URL + diff + reviewer JSON.**
- `.audit/checkpoint.json` updates after every role turn; running `wc -l .audit/checkpoint.json` over time shows growth.
- Kill test: `touch .audit/ABORT` mid-fixer turn → coordinator exits cleanly in <60s with checkpoint consistent.
- Resume test: kill coordinator between Scout and Fixer phases → restart with `--resume <id>` → next fixer picks up from correct state.
- Final `.audit/report.md` contains the required table with non-zero counts.
- SKILL.md triggers do NOT fire on bare "audit" — verified by feeding 10 unrelated prompts containing "audit" and confirming skill invocation rate <10%.

## 10. Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Scout produces a `*.test.*` file | High (LLM habit) | High | `hooks/block-test-files.js` already blocks; prompt reinforces; reviewer rejects if any slips through. |
| Fixer loops on same wrong fix 5 times | Medium | Medium | Fixer prompt mandates re-diagnosis; after 5 attempts → `failed` phase, coordinator moves on. |
| Reviewer rubber-stamps | Medium | High | Reviewer checks are scripted + deterministic (`git diff --stat`, revert-pattern grep), not LLM judgment alone. |
| Consecutive empty scouts terminates too early on large repo | Low | Medium | Configurable threshold (default 2, raise to 3 for monorepos). |
| Branch explosion — many `bug/*` and `fix/*` branches | High | Low | Reviewer archives branches after merge or rejection to `archived/<date>/<branch>`. |
| `/team` mode not-yet-tested diverges from plain mode | Medium | Medium | Default to plain mode; `/team` gated behind explicit config flag with "beta" warning. |
| Scout allowedTools leak Bash → dangerous commands | Low | Critical | Whitelist explicit; rely on Phase 5 outer `--allowedTools` as second defense. |
| Checkpoint corruption mid-write | Low | High | Phase 1 atomic-write pattern (tmp+rename) guarantees prior state intact. |
| Skill description too pushy fires on every prompt | Medium | Medium | Specific triggers (`bug-audit-swarm`, `swarm audit`); validated by trigger-rate test in success criteria. |

## 11. Security Considerations

- Scouts allowed bash but only repo-local reads + `git add/commit/push` to `bug/*` branches. NO `rm`, NO network fetch beyond `git fetch`. Phase 5 headless wrapper enforces this via outer `--allowedTools`.
- Fixers must pass through Root-Cause Enforcer (Phase 2) — they CANNOT bypass with `CLAUDE_SKIP_ROOT_CAUSE_GATE=1` unless explicitly configured (and the bypass is logged).
- Reviewers never execute source code they're reviewing — only `git` commands and the reproduction script itself (which is designed to be run).
- PRs are NOT auto-merged — reviewer approval opens the PR; a human merges.
- Checkpoint files are validated against schema before any property access.
- All subagent prompts are template files shipped by us; values are interpolated with escape-safe substitution.

## 12. Next Steps

Phase 5 wraps the coordinator in a `claude -p` headless runner with explicit `--allowedTools`. Phase 6 runs an end-to-end swarm against a seeded fixture and captures transcripts as evidence.
