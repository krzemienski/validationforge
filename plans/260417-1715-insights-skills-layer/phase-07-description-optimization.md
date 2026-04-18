# Phase 07 — Description optimization via `run_loop.py`

## Context Links
- Plan: `plans/260417-1715-insights-skills-layer/plan.md`
- Authoritative protocol: `~/.claude/skills/skill-creator/SKILL.md` §*Description Optimization* (Steps 1–4)
- Trigger eval review template: `~/.claude/skills/skill-creator/assets/eval_review.html`
- Optimization script: `~/.claude/skills/skill-creator/scripts/run_loop.py`

## Overview
- **Priority:** P2 — quality-of-life tuning; skill still works without it but triggers less reliably at the margin.
- **Status:** pending (blocked by Phase 6; requires stable final SKILL.md per skill)
- **Description:** For each of the three skills, generate 20 trigger-eval queries (mix of should-trigger and should-not-trigger including near-misses), review via the `eval_review.html` template, run `run_loop.py` with 5 max iterations and 3 samples per query, apply the returned `best_description` to each SKILL.md frontmatter.

## Key Insights (from discovery)
- skill-creator explicitly notes Claude currently *undertriggers* skills — pushy descriptions beat neutral ones.
- The triggering mechanism: Claude sees skill `name + description` in `available_skills` and decides per query. Simple one-step prompts do not trigger skills regardless of description — eval queries must be substantive.
- 20 queries × 3 samples × 5 iterations × 3 skills = 900 `claude -p` invocations. This is the budget question flagged in plan.md Unresolved Questions.
- `run_loop.py` returns `best_description` selected on *held-out test score*, not train score — protects against overfitting to the 60% training split.
- The `--model` argument must match the model powering the user's real sessions (today: the Opus 4.7 1M-context model ID). Mismatching the model degrades the signal.
- Should-not-trigger queries must be genuinely tricky near-misses — "write a fibonacci" as a negative for `/root-cause-first` tests nothing.

## Requirements

### Functional
- Per skill: 20 trigger-eval queries saved to `plans/260417-1715-insights-skills-layer/evals/{skill}/trigger-eval.json`.
  - 8–10 should-trigger (varied phrasings, including casual/abbreviated/typo-laden)
  - 8–10 should-not-trigger (genuine near-misses — adjacent domains, keyword overlaps that should route elsewhere)
- Per skill: open the populated `eval_review.html` in browser for user sign-off. Capture the exported `eval_set.json` from `~/Downloads/`.
- Per skill: run `run_loop.py` in background with `--max-iterations 5 --verbose`. Tail output and update user periodically.
- Per skill: apply `best_description` from the returned JSON to SKILL.md frontmatter. Record before/after in `plans/260417-1715-insights-skills-layer/evals/{skill}/description-optimization-report.md`.

### Non-functional
- Budget confirmation *before* firing the loop — 900 invocations is significant and must be user-approved.
- Use the current session's model ID for `--model` (pulled from system prompt).
- Near-miss negatives must not be trivially irrelevant.

## Architecture

### Per-skill trigger-eval schema
```json
[
  {"query": "the detector said 12 shorts on seq_B but GT says 14 can u look", "should_trigger": true},
  {"query": "add a GT file for new clip seq_E", "should_trigger": true},
  {"query": "what's the schema for the groundtruth json", "should_trigger": false},
  ...
]
```

### Trigger query diversity matrix (per skill)
| Category | Count | Purpose |
|----------|-------|---------|
| Formal should-trigger | 3 | "Please investigate the discrepancy between detected stall count and ground truth on sequence A." |
| Casual / typo should-trigger | 3 | "detector is lyin, stall count off on seq a fix pls" |
| Uncommon-use should-trigger | 2 | "show me every GT clip with >1 boundary delta" |
| Wins-vs-competing-skill should-trigger | 2 | "the detector crashed on seq_D, figure out why" (wins over generic `/root-cause-first`) |
| Keyword-overlap near-miss (should-not) | 3 | "what's inside the ground_truth JSON schema?" (docs query, not debugging) |
| Adjacent-domain near-miss (should-not) | 3 | "write a unit test for the OCR module" (banned by no-mocks anyway, but different intent) |
| Ambiguous keyword-match near-miss (should-not) | 2 | "ground truth my coworker says X — settle this" (idiom, not detection) |

### Optimization loop command
```bash
python -m scripts.run_loop \
  --eval-set /Users/nick/Desktop/validationforge/plans/260417-1715-insights-skills-layer/evals/<skill>/trigger-eval.json \
  --skill-path <abs path to skill> \
  --model <current-model-id> \
  --max-iterations 5 \
  --verbose
```
Run from `~/.claude/skills/skill-creator/` so the module path resolves. Execute in background; periodically tail log file.

## Related Code Files

### CREATE
- `plans/260417-1715-insights-skills-layer/evals/gt-perfect/trigger-eval.json`
- `plans/260417-1715-insights-skills-layer/evals/root-cause-first/trigger-eval.json`
- `plans/260417-1715-insights-skills-layer/evals/audit/trigger-eval.json`
- `plans/260417-1715-insights-skills-layer/evals/{skill}/description-optimization-report.md`
- `/tmp/eval_review_{skill}.html` (temp preview for user sign-off)

### MODIFY
- `~/.claude/skills/root-cause-first/SKILL.md` — frontmatter `description`
- `~/.claude/skills/audit/SKILL.md` — frontmatter `description`
- `yt-transition-shorts-detector/.claude/skills/gt-perfect/SKILL.md` — frontmatter `description`

### DELETE
- `/tmp/eval_review_{skill}.html` after user signs off (cleanup).

## Implementation Steps

Follow skill-creator §*Description Optimization* Steps 1–4 exactly.

1. **(Budget gate)** Before doing anything, confirm with the user that 900 `claude -p` invocations is acceptable. If no, offer reductions: 10 queries × 3 samples × 3 iterations × 3 skills = 270, or single-skill-at-a-time.
2. **(skill-creator §Step 1)** For each skill, draft 20 queries per the diversity matrix. Queries must include filepaths, IDs, casual speech, typos. Avoid obviously-irrelevant negatives.
3. **(skill-creator §Step 2)** For each skill, populate `eval_review.html`:
   - Read template from `~/.claude/skills/skill-creator/assets/eval_review.html`.
   - Replace `__EVAL_DATA_PLACEHOLDER__` with the JSON array (as a JS variable assignment, no surrounding quotes).
   - Replace `__SKILL_NAME_PLACEHOLDER__` and `__SKILL_DESCRIPTION_PLACEHOLDER__`.
   - Write to `/tmp/eval_review_{skill}.html`, open with `open /tmp/eval_review_{skill}.html`.
   - User edits queries, clicks Export Eval Set.
   - Pick up latest `eval_set*.json` from `~/Downloads/` and copy into the workspace.
4. **(skill-creator §Step 3)** For each skill, save eval set to workspace, then run `run_loop.py` in background with the command shown above. Tail the log file periodically to surface progress.
5. Per skill, while run_loop is in flight, update the user each time a new iteration completes (e.g., "iteration 3/5 test score 78% → 82%").
6. **(skill-creator §Step 4)** When each run_loop finishes, read the returned JSON, extract `best_description`, show the user before/after, apply to SKILL.md frontmatter.
7. Write `description-optimization-report.md` per skill:
   - Before / after descriptions
   - Per-iteration train and test scores
   - Held-out test score of final description
   - Any near-misses that still flip trigger direction after optimization (residual risk)
8. Stage for Phase 8 functional validation.

## Todo List
- [ ] Budget confirmation with user (900 runs or reduced)
- [ ] Draft 20 trigger queries per skill per diversity matrix
- [ ] Populate and open `eval_review.html` per skill; capture user's exported eval_set
- [ ] Save eval sets to workspace
- [ ] Run `run_loop.py` per skill in background; tail log
- [ ] Apply best_description to each SKILL.md frontmatter
- [ ] Write description-optimization-report.md per skill
- [ ] Verify held-out test score ≥ 80% per plan.md success criteria

## Success Criteria
- Each skill's final `description` has held-out test score ≥ 80% (per plan.md success criteria).
- 20-query trigger-eval.json exists per skill; user-approved.
- `description-optimization-report.md` per skill documents the score progression.
- SKILL.md frontmatter updated with best_description in each of the three skills.
- Any residual near-miss flips are documented as known limitations.

## Risk Assessment
| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Budget exceeds user's tolerance | High | High | Gate with explicit confirmation; offer reduced-scope variant (270 runs) |
| Near-miss queries too easy → inflated test scores | Medium | High | Diversity matrix forces genuine near-miss categories; sample-review before running |
| Model ID mismatch between run_loop and user's actual session | Low | High | Pull model ID from system prompt directly; document in the report |
| `run_loop.py` errors out mid-iteration | Medium | Medium | Tail log file; if error, re-run with same seed where possible |
| Applied best_description undertriggers on real user phrasings not in eval set | Medium | Medium | Phase 8 functional validation catches this; if regression, iterate trigger queries and re-run |
| Overfitting to train split | Low | Medium | run_loop selects on held-out test, not train — already mitigated by design |

## Security Considerations
- Trigger queries may contain example company names / URLs — use obvious placeholders.
- `run_loop.py` calls `claude -p` which uses the user's API credentials — ensure budget alarms are in place.
- Temp HTML files in `/tmp/` — clean up after user signs off to avoid leftover eval data on disk.

## Next Steps
- Phase 8 (functional validation) is the final gate before marking the plan complete.
- Optional: package skills via `package_skill.py` if `present_files` tool is available (per plan.md success criteria).
