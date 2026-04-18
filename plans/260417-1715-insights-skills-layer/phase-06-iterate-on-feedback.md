# Phase 06 — Iterate on feedback (iteration-2+ until stable)

## Context Links
- Plan: `plans/260417-1715-insights-skills-layer/plan.md`
- Authoritative iteration protocol: `~/.claude/skills/skill-creator/SKILL.md` §*Improving the skill* and §*The iteration loop*
- Previous phase output: `plans/260417-1715-insights-skills-layer/evals/{skill}/iteration-1/` and `feedback.json`

## Overview
- **Priority:** P1 — the eval + feedback + rewrite loop is the actual mechanism by which skill quality emerges.
- **Status:** pending (blocked by Phase 5)
- **Description:** Read `feedback.json` from the viewer, rewrite each SKILL.md based on user feedback, re-run iteration-N+1 runs (with-skill + baseline), relaunch the viewer with `--previous-workspace` pointing at the prior iteration. Repeat until the user is satisfied, feedback is empty, or progress plateaus.

## Key Insights (from discovery)
- skill-creator §*How to think about improvements* contains four explicit guardrails: (1) generalize from examples, (2) keep the prompt lean, (3) explain the why, (4) look for repeated work across transcripts that should be bundled as scripts.
- Termination criteria are explicit: user happy, feedback all empty, or no meaningful progress. Do not loop forever.
- Empty feedback on a given eval means "this output was fine" — focus improvements only on evals with specific complaints.
- Reading transcripts (not just outputs) is critical — if subagents independently write similar helper scripts, bundle that script into the skill.
- For iteration 2+, the `--previous-workspace` flag gives the user diff-style review — they see old output below the new one and their prior feedback below the input box.

## Requirements

### Functional
- For each skill, loop:
  1. Read `feedback.json` from the prior iteration workspace.
  2. Revise SKILL.md (and bundled scripts/templates) per feedback.
  3. Re-run iteration-N+1 with-skill + baseline spawns (skill-creator §*The iteration loop* step 2).
  4. Relaunch viewer with `--previous-workspace <iter-(N-1)>`.
  5. Wait for user to review, then read the new `feedback.json`.
- Record what changed per iteration in `plans/260417-1715-insights-skills-layer/evals/{skill}/iteration-N/CHANGES.md`.
- Stop criteria: user says "I'm happy", feedback all empty, OR no meaningful improvement between two consecutive iterations.

### Non-functional
- No iteration caps — but budget awareness: each iteration is another 18 subagent spawns per skill. Ask the user before iteration-3.
- Do not make overfitting changes that only help the specific eval prompts — follow skill-creator guardrail #1 (generalize).

## Architecture

### Iteration structure
```
plans/260417-1715-insights-skills-layer/evals/{skill}/
├── iteration-1/        (from Phase 5)
│   ├── feedback.json   (from user Phase 5 review)
│   └── benchmark.json
├── iteration-2/
│   ├── CHANGES.md      (what we changed and why, cites specific feedback entries)
│   ├── eval-*/
│   ├── benchmark.json
│   └── feedback.json
└── iteration-3/
    └── ...
```

### Improvement decision tree
```
feedback.json entry:
  ├─ empty string → no change for this eval
  ├─ specific complaint about output content → rewrite relevant SKILL.md section; cite in CHANGES.md
  ├─ "too verbose" / "too much ceremony" → trim SKILL.md; guardrail #2 (keep lean)
  ├─ "why does it do X" → add the WHY to SKILL.md; guardrail #3
  └─ "it keeps reinventing wheel Y" → bundle wheel Y as a script; guardrail #4
```

## Related Code Files

### CREATE per iteration
- `plans/260417-1715-insights-skills-layer/evals/{skill}/iteration-N/CHANGES.md`
- `plans/260417-1715-insights-skills-layer/evals/{skill}/iteration-N/eval-*/` (full run tree)
- `plans/260417-1715-insights-skills-layer/evals/{skill}/iteration-N/benchmark.{json,md}`

### MODIFY per iteration
- `~/.claude/skills/{skill}/SKILL.md` (or `yt-transition-shorts-detector/.claude/skills/gt-perfect/SKILL.md`)
- bundled scripts / templates as feedback dictates
- `plans/260417-1715-insights-skills-layer/evals/{skill}/evals.json` only if the user asks to modify prompts (version bump the old one)

### DELETE
- None. Keep all iteration workspaces — they are the audit trail.

## Implementation Steps

Follow skill-creator §*The iteration loop* exactly.

1. **(skill-creator §Step 5)** Read `feedback.json` for the current iteration. Classify each entry per the decision tree above.
2. **(skill-creator §How to think about improvements)** Before editing, read the transcripts from runs the user complained about — not just the final outputs. Look for repeated helper-script writing across subagents.
3. **(skill-creator guardrail #1)** Draft revisions to SKILL.md. Avoid hyper-specific instructions tied to the exact eval prompts. Prefer metaphors and general principles.
4. **(skill-creator guardrail #2)** Cut anything not pulling its weight. Compare revised SKILL.md word count to previous — flag if it grew significantly without the user asking for more content.
5. **(skill-creator guardrail #3)** For any new instruction added, write one sentence of *why*. If the why is not obvious, the instruction is probably wrong.
6. **(skill-creator guardrail #4)** If transcripts show subagents writing similar throwaway scripts, bundle that script under `scripts/` and reference it from SKILL.md.
7. Write `CHANGES.md` in the new iteration dir: one bullet per change, citing the feedback entry that motivated it.
8. Apply revisions.
9. Re-run all evals (with-skill + baseline) per Phase 5 protocol, saving to `iteration-N/`.
10. Grade + aggregate + analyst pass per Phase 5 Steps 4.1–4.3.
11. Launch viewer with `--previous-workspace iteration-(N-1)`.
12. Wait for user feedback on new iteration. Read new `feedback.json`.
13. Termination check:
    - User says happy → stop.
    - All feedback entries empty → stop.
    - Two consecutive iterations with no meaningful pass_rate improvement AND no new complaints → stop.
    - Else → increment N, loop.
14. When stopped, mark the current SKILL.md as the *final* and stage for Phase 7 description optimization.

## Todo List
- [ ] Read iteration-1 feedback.json for each skill
- [ ] Read transcripts for complained-about runs
- [ ] Classify each feedback entry per decision tree
- [ ] Draft revision per SKILL.md (generalize, keep lean, explain why, bundle repeated scripts)
- [ ] Write CHANGES.md citing each change's feedback source
- [ ] Apply revisions
- [ ] Re-run evals for iteration-N+1
- [ ] Grade + aggregate
- [ ] Launch viewer with --previous-workspace
- [ ] Read new feedback.json
- [ ] Termination check; loop or finalize

## Success Criteria
- Each skill reaches a terminating iteration (user-happy, empty feedback, or plateau).
- `CHANGES.md` per iteration shows a clear audit trail: every change cites the feedback entry that motivated it.
- Final iteration's `benchmark.json` shows non-negative pass_rate delta vs iteration-1 for the with_skill configuration.
- No SKILL.md grew beyond 500 lines without explicit user acceptance.

## Risk Assessment
| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Overfitting: skill gets brittle to the specific eval prompts | High | High | Guardrail #1 (generalize); Phase 7 held-out test queries catch overfit descriptions |
| Infinite iteration loop (user never fully satisfied) | Medium | Medium | Plateau rule: two flat iterations → stop and ship with known-limitations note |
| Improvements regress pass_rate | Medium | Medium | Analyst pass explicitly compares iteration-N vs N-1; roll back if regression ≥ 10% |
| SKILL.md grows uncontrollably | Medium | Medium | Word-count check per iteration; compress into references/*.md when >500 lines |
| Budget blowout across multiple iterations | Medium | High | Ask user before iteration-3; default cap = 3 iterations unless explicit extension |

## Security Considerations
- Same as Phase 5: no credentials in prompts; localhost-only viewer; kill server on cycle end.
- Version-control the SKILL.md changes — each iteration should commit to a branch so rollback is trivial.

## Next Steps
- Phase 7 (description optimization) takes the final SKILL.md as input.
- Phase 8 (functional validation) uses the final SKILL.md against a real scenario.
