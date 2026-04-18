---
name: Insights Ambitious Workflows — GT Tuner, Bug-Audit Swarm, Root-Cause Enforcer
status: revised-post-redteam
revision: 2026-04-17-safety-additions
mode: deep
blocks: []
blockedBy: [260417-1715-insights-foundation, 260417-1715-insights-skills-layer]
created: 2026-04-17
owner: nick
authorities:
  - ~/.claude/skills/skill-creator/SKILL.md
  - ~/.claude/plugins/cache/superpowers-marketplace/superpowers-developing-for-claude-code/0.3.1/skills/working-with-claude-code/SKILL.md
---

# Plan C — Insights Ambitious Workflows

## Why this plan exists

Three multi-agent / enforcement workflows from the insights report's "On the Horizon" section. Each turns a manual grind into an autonomous pipeline:

1. **GT Autonomous Tuner** — parallel video-owner subagents propose single-root-cause fixes; a coordinator runs full regression per proposed fix and merges only net-improvements. Turns multi-day GT-perfection campaigns into overnight runs.
2. **Bug-Audit Swarm** — Scout → Fixer → Reviewer role pipeline: scouts write failing tests first, fixers iterate to green, reviewers gate PRs. Evolves the one-shot audit that found 18/fixed 12 into a continuous pipeline with cross-session checkpointing.
3. **Root-Cause Enforcer** — PreToolUse hook that blocks Edit/Write to `src/` until `.debug/<issue-id>/evidence.md` exists and passes a checklist. Pairs with `failed-approaches.md` log that auto-appends on revert.

## Dependencies on Plans A + B

- Plan A's `~/.claude/state/` schema underpins the swarm's shared scoreboard.
- Plan A's `detector-project-conventions.md` defines the GT-success metric the tuner optimizes for.
- Plan B's `/root-cause-first` skill is the skill the Root-Cause Enforcer hook invokes.
- Plan B's `/gt-perfect` skill is the per-video subagent template for the GT Tuner.
- Plan B's `/audit` skill is the review role template in the Bug-Audit Swarm.

Without Plans A and B, this plan has no substrate.

## Safety posture

These workflows spawn many subagents and write to many files. Guardrails:

- Every subagent writes to a git worktree — `yt-transition-shorts-detector_worktrees/` already exists as the convention.
- Coordinators merge only via PR (no direct main commits).
- Every merge runs the full regression suite; net-regression = auto-revert.
- Every campaign is bounded (max iterations, max subagents, max wall-clock).
- Headless runners use `claude -p --allowedTools` with a restricted tool whitelist (no arbitrary bash).

## Targets

| Workflow | Location | Entry point |
|----------|----------|-------------|
| GT Autonomous Tuner | `yt-transition-shorts-detector/.claude/commands/gt-tuner.md` + `scripts/gt-tuner/` | `/gt-tuner` slash command |
| Bug-Audit Swarm | `~/.claude/skills/bug-audit-swarm/SKILL.md` + `scripts/bug-audit-swarm/` | `/bug-audit-swarm` skill |
| Root-Cause Enforcer | `~/.claude/hooks/root-cause-enforce-pre.js` + `~/.claude/settings.json` (hook registration) | PreToolUse(Edit,Write) hook |

## Phases

| # | Phase | Subsystem | Key deliverable |
|---|-------|-----------|-----------------|
| 1 | Shared state + checkpoint library | cross-cutting | `~/.claude/state/schemas/` + `scripts/common/checkpoint-lib.js` (single DRY source) |
| 2 | Root-Cause Enforcer hook | enforcer | `root-cause-enforce-pre.js` + `failed-approaches.md.autolog` + settings registration |
| 3 | GT Autonomous Tuner — coordinator + video-owner subagent + arbiter | tuner | 3 role definitions + SQLite scoreboard + merge-on-improve logic |
| 4 | Bug-Audit Swarm — scout / fixer / reviewer roles | swarm | 3 role skills + `.audit/checkpoint.json` + resume protocol |
| 5 | Headless runners (`claude -p` bounded loops) | cross-cutting | `scripts/headless/gt-tuner.sh`, `scripts/headless/bug-audit.sh` with `--allowedTools` whitelists |
| 6 | Functional validation — run each workflow end-to-end against a seeded scenario | all three | evidence in `plans/reports/ambitious-validation-{tuner,swarm,enforcer}-260417.md` |

## Success criteria

### GT Autonomous Tuner
- [ ] One command (`/gt-tuner`) runs to completion against all videos in `ground_truth/`.
- [ ] Per-video subagents propose structured `{root_cause, fix_diff, expected_delta, risk}` JSON.
- [ ] Coordinator runs regression across ALL videos for each proposed fix IN ISOLATION (via worktree).
- [ ] Merge predicate: net GT-score improvement, zero regressions on previously-matching videos.
- [ ] Failed approaches append to `.gt-tuner/failed-approaches.md` with reason.
- [ ] Bounded: stops at 8/8 match OR 20 iterations OR wall-clock budget.

### Bug-Audit Swarm
- [ ] Scout role produces failing reproductions (real invocations, not mock tests).
- [ ] Fixer role bounded to 5 iterations per bug before escalation.
- [ ] Reviewer role checks diff size (<50 lines unless justified) and flags reverted-then-reapplied patterns.
- [ ] `.audit/checkpoint.json` saved after every role turn; resume works across fresh sessions.
- [ ] Final report: `{bugs_found, fixed, failed, files_touched}` table.

### Root-Cause Enforcer
- [ ] PreToolUse hook blocks Edit/Write to `src/` with exit code 2 + stderr reason when `.debug/<issue-id>/evidence.md` is missing or checklist-incomplete.
- [ ] Checklist validation: file exists, mentions input/output, mentions visual-evidence file, names ONE root-cause line, cross-references failed-approaches.md.
- [ ] `failed-approaches.md` auto-appends when a commit is reverted (via post-commit git hook or reflog watcher).
- [ ] "One-fix-at-a-time" guard: rejects edits spanning >1 logical change (heuristic: diff touches >3 unrelated files, or >2 distinct function signatures).
- [ ] Verified against a seeded bug from yt-shorts-detector — hook fires, user writes evidence.md, hook passes, fix lands.

## Out of scope

- Productizing the GT Tuner beyond yt-shorts-detector (generalization to other repos is a future plan).
- Integrating the Bug-Audit Swarm with CI (local-only for now).
- Any UI/dashboard for campaign progress — JSON + markdown reports only.

## Unresolved questions

- GT Tuner parallelism: spawn one subagent per video (8 subagents) or batched (2 subagents × 4 videos)? System has 64GB RAM but each subagent runs full detection.
- Bug-Audit Swarm: use Claude Code Agent Teams (`/team`) or plain Task-tool subagents? Teams give richer coordination but cost more setup.
- Root-Cause Enforcer "one-fix-at-a-time" heuristic: is the 3-file / 2-function threshold right, or should it be configurable?
- Should the enforcer block ALL Edit/Write operations or only those touching `src/`/`lib/`? Excluding docs and configs reduces friction.
- Headless budget: each `/gt-tuner` run could consume 500K+ tokens. Cap per-run budget in config?
