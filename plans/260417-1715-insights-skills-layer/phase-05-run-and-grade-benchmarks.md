# Phase 05 — Run + grade benchmarks (with-skill vs baseline), iteration-1

## Context Links
- Plan: `plans/260417-1715-insights-skills-layer/plan.md`
- Authoritative execution protocol: `~/.claude/skills/skill-creator/SKILL.md` §*Running and evaluating test cases* (Steps 1–5)
- Schemas: `~/.claude/skills/skill-creator/references/schemas.md` §*grading.json*, §*timing.json*, §*benchmark.json*
- Grader protocol: `~/.claude/skills/skill-creator/agents/grader.md`
- Aggregation script: `~/.claude/skills/skill-creator/scripts/aggregate_benchmark.py` (invoked via `python -m scripts.aggregate_benchmark` from skill-creator dir)

## Overview
- **Priority:** P1 — produces the quantitative signal that drives Phase 6 iteration.
- **Status:** pending (blocked by Phase 4)
- **Description:** For each skill, spawn a with-skill and a baseline (no-skill) subagent per eval case *in the same turn* (skill-creator Step 1). Capture timing from task notifications, grade via the grader agent, aggregate into `benchmark.json`, and launch the eval viewer.

## Key Insights (from discovery)
- skill-creator Step 1 is emphatic: launch with-skill and baseline **in the same turn**. Sequencing them loses cache locality and introduces model-version drift.
- `timing.json` can only be captured from the task completion notification — the `total_tokens` and `duration_ms` are *not* persisted elsewhere. Missing this data means Phase 6 cannot do the tokens-delta analysis.
- Grader field names are strict: `text`, `passed`, `evidence` — the viewer fails silently on `name`/`met` variants.
- `benchmark.json` field names are strict: `configuration` must be exactly `"with_skill"` or `"without_skill"` (see `schemas.md` §*benchmark.json*).
- User is on macOS with a browser — use `generate_review.py` in default interactive mode, not `--static`.
- Runs-per-configuration defaults to 3 in skill-creator to surface variance. For three skills × three evals × two configs × three runs = 54 subagent spawns for iteration-1. Budget this.

## Requirements

### Functional
- Per skill: iteration-1 workspace at `plans/260417-1715-insights-skills-layer/evals/{skill}/iteration-1/` with per-eval subdirs (`eval-<descriptive-name>/`).
- Each eval dir contains: `with_skill/outputs/`, `without_skill/outputs/`, `with_skill/transcript.md`, `without_skill/transcript.md`, `eval_metadata.json`, `timing.json` per config.
- Assertions added to each `eval_metadata.json` and the skill's `evals.json` in parallel with Step 2 (while runs are in progress).
- Grader runs produce `grading.json` per run directory with the exact field names required.
- `benchmark.json` at `plans/.../evals/{skill}/iteration-1/benchmark.json` and `benchmark.md` adjacent.
- Analyst pass: `notes[]` in benchmark.json surfaces non-discriminating assertions, high-variance evals, and token/time tradeoffs.
- Eval viewer launched with `--benchmark` flag; user walks through outputs tab and benchmark tab.

### Non-functional
- Parallelism: all with-skill AND baseline runs for a given skill fire in the same turn (at least per-skill; across skills is also fine if capacity allows).
- Budget: explicitly surface to the user before firing — 3 skills × 3 evals × 2 configs × 3 runs = 54 subagent invocations for iteration-1 (see Risk section).

## Architecture

### Workspace layout (per skill, per iteration)
```
plans/260417-1715-insights-skills-layer/evals/gt-perfect/
└── iteration-1/
    ├── eval-seq_a-12-vs-16/
    │   ├── eval_metadata.json
    │   ├── with_skill/
    │   │   ├── outputs/...
    │   │   ├── transcript.md
    │   │   ├── timing.json
    │   │   └── grading.json
    │   └── without_skill/
    │       ├── outputs/...
    │       ├── transcript.md
    │       ├── timing.json
    │       └── grading.json
    ├── eval-full-gt-sweep/
    │   └── ...
    ├── benchmark.json
    └── benchmark.md
```

### Data flow
```
evals.json → for each eval:
    spawn Task(with-skill)  ─┐   same turn
    spawn Task(baseline)    ─┘
         │
         ▼
 task notifications (total_tokens, duration_ms) → timing.json per run
         │
         ▼
 spawn grader subagent (reads agents/grader.md) → grading.json per run
         │
         ▼
 python -m scripts.aggregate_benchmark <iter-dir> --skill-name <name>
         │
         ▼
 benchmark.json + benchmark.md
         │
         ▼
 generate_review.py <iter-dir> --benchmark <iter-dir>/benchmark.json
         │
         ▼
 user reviews → feedback.json (Phase 6 entry point)
```

### Subagent prompt templates (skill-creator §Step 1)

**With-skill run:**
```
Execute this task.
- Skill path: <abs path to skill>
- Task: <eval.prompt>
- Input files: <eval.files or "none">
- Save outputs to: <iter-dir>/eval-<name>/with_skill/outputs/
- Outputs to save: <what the user cares about per eval>
```

**Baseline run** (no skill, same prompt, save to `without_skill/outputs/`):
```
Execute this task WITHOUT reference to any skill at <skills path>.
- Task: <eval.prompt>
- Input files: <eval.files or "none">
- Save outputs to: <iter-dir>/eval-<name>/without_skill/outputs/
```

## Related Code Files

### CREATE (per skill × per eval × per config)
- `plans/260417-1715-insights-skills-layer/evals/{skill}/iteration-1/eval-<name>/with_skill/{outputs/,transcript.md,timing.json,grading.json}`
- `plans/260417-1715-insights-skills-layer/evals/{skill}/iteration-1/eval-<name>/without_skill/{outputs/,transcript.md,timing.json,grading.json}`
- `plans/260417-1715-insights-skills-layer/evals/{skill}/iteration-1/benchmark.json`
- `plans/260417-1715-insights-skills-layer/evals/{skill}/iteration-1/benchmark.md`

### MODIFY
- `plans/260417-1715-insights-skills-layer/evals/{skill}/evals.json` — add `expectations` field per eval, drafted during Step 2.

### DELETE
- None.

## Implementation Steps

Follow skill-creator §*Running and evaluating test cases* Steps 1–5 precisely.

1. **(skill-creator §Step 1)** Per skill, spawn all with-skill + baseline runs in the same turn. Use the Task tool with the prompt templates above. Aim to spawn *all three skills × all evals* in one mega-turn if capacity allows — otherwise one skill per turn is acceptable.
2. **(skill-creator §Step 2)** While runs are in flight, draft assertions per eval. Update `eval_metadata.json` and the source `evals.json`. Target discriminating assertions (grader.md §Step 6) — e.g., "did the model invoke `gt-diff.py` at least once?" rather than "output file exists".
3. **(skill-creator §Step 3)** As each task notification arrives, immediately write `timing.json` with `total_tokens`, `duration_ms`, `total_duration_seconds`. Do NOT batch.
4. **(skill-creator §Step 4.1)** Once all runs complete, spawn a grader subagent per run directory. The grader reads `agents/grader.md` and writes `grading.json` using exactly the field names `text`, `passed`, `evidence`.
5. **(skill-creator §Step 4.2)** Aggregate:
   ```bash
   python -m scripts.aggregate_benchmark \
     /Users/nick/Desktop/validationforge/plans/260417-1715-insights-skills-layer/evals/<skill>/iteration-1 \
     --skill-name <skill>
   ```
   Run from `~/.claude/skills/skill-creator/` so the module path resolves.
6. **(skill-creator §Step 4.3)** Analyst pass — read benchmark.json, fill `notes[]` with observations per `agents/analyzer.md` patterns (non-discriminating assertions, high-variance evals, time/token tradeoffs).
7. **(skill-creator §Step 4.4)** Launch the viewer (default interactive mode since user has browser):
   ```bash
   nohup python ~/.claude/skills/skill-creator/eval-viewer/generate_review.py \
     <iter-dir> \
     --skill-name "<skill>" \
     --benchmark <iter-dir>/benchmark.json \
     > /dev/null 2>&1 &
   VIEWER_PID=$!
   ```
8. Tell the user: "Two tabs — Outputs and Benchmark. Leave feedback in the textboxes, click Submit All Reviews when done. Come back here."
9. On user's return, Phase 6 takes over.

## Todo List
- [ ] Confirm capacity for 54 subagent runs (interview user if uncertain)
- [ ] Spawn with-skill + baseline pairs in the same turn per skill
- [ ] Capture timing.json on each notification as it arrives
- [ ] Draft assertions in parallel; update evals.json + eval_metadata.json
- [ ] Spawn grader subagents per run dir
- [ ] Run aggregate_benchmark per skill
- [ ] Analyst pass on each benchmark.json
- [ ] Launch eval viewer per skill (or a single viewer cycling through)
- [ ] Hand off to Phase 6

## Success Criteria
- Every run directory contains non-empty `timing.json`, `transcript.md`, `grading.json`, `outputs/`.
- `benchmark.json` parses per schemas.md exactly (configuration = `with_skill`/`without_skill`, result fields nested).
- For each skill, `benchmark.md` shows pass_rate mean+stddev for both configs and the delta.
- Viewer opens in browser and renders both tabs; Outputs tab shows transcripts; Benchmark tab shows per-eval and aggregate pass_rate.
- User confirms they have left feedback and submitted (triggering `feedback.json` download).

## Risk Assessment
| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| 54 parallel subagents exceeds concurrency limits | Medium | High | Batch per skill (18 runs × 3 skills sequential); document per-skill spawn protocol |
| Missed timing notifications → no token data | Medium | High | Set up a notification handler that writes timing.json immediately; never batch |
| Grader uses wrong field names → viewer shows empty | Low | High | Grader subagent explicitly reads schemas.md §grading.json; sample-check first grading.json before doing the rest |
| Transcripts not saved by executor subagents | Medium | Medium | Prompt template explicitly requires `transcript.md` in output dir |
| Viewer crashes on malformed benchmark.json | Low | Medium | Run `python -c "import json; json.load(open(...))"` before launching viewer |
| Budget shock for user (cost of 54 runs) | Medium | Medium | Surface estimate to user before firing; allow 1-run-per-config fallback |

## Security Considerations
- Subagent prompts are the only surface touching user data — do NOT include API keys or staging credentials in prompts. Use fixture artifacts under `evals/{skill}/files/`.
- Viewer runs on localhost; do not expose to external network.
- Kill the viewer server when Phase 6 completes: `kill $VIEWER_PID 2>/dev/null`.

## Next Steps
- Phase 6 consumes `feedback.json`.
- Phase 7 uses the final (post-iteration) SKILL.md, so is blocked until iterations stabilize.
