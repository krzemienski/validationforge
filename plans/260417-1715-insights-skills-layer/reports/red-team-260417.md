# Red-Team Review — Plan B (Insights Skills Layer)
Date: 2026-04-17
Reviewer: oh-my-claudecode:critic (findings returned inline; this file persists them for the audit trail since the critic role cannot write reports itself)
Verification: Claims below independently re-verified against filesystem by parent orchestrator — see "Verification" section at bottom.

## Verdict

**REJECT.** Plan B has two load-bearing structural flaws that will waste the entire Phase 5–7 investment if shipped as-is: (1) three of the three proposed skills collide head-on with already-installed skills the user (and the global trigger gate) will reach first, and (2) the entire plan is blocked on Plan A deliverables that do not exist yet and whose final schemas the plan merely assumes. Additionally, Phase 7's 900-invocation budget is locked in without the budget gate being a blocking decision point, and plan.md leaves three unresolved questions that later phases answer inconsistently. Fix the collisions and the dependency model before any authoring work begins; otherwise the benchmark deltas in Phase 5 will measure noise against already-triggered incumbents rather than against a baseline.

## Pre-commitment Predictions

Before reading the phases the reviewer predicted the most likely failure modes:

1. Trigger collision with `full-functional-audit` / `ck-debug` / `fix` — confirmed, worse than expected (C1, C2).
2. Phase 5 budget runaway — confirmed (M3).
3. Schema drift between `eval_metadata.json` and `benchmark.json` — confirmed (M2).
4. Plan A ↔ Plan B coupling without contract — confirmed (C3).
5. Near-miss negatives in Phase 7 gamed into tautologies — partial, one example is already gamed (m5).

Four of five predictions landed. The one not predicted but uncovered: a project-local `/audit` skill that already exists at `yt-transition-shorts-detector/.claude/skills/audit/SKILL.md` with `user-invocable: true`.

## Critical Findings (blocks execution)

### C1. `/audit` collides with an already-installed project-local skill of the same exact name
- **Evidence:** `/Users/nick/Desktop/yt-transition-shorts-detector/.claude/skills/audit/SKILL.md` exists, frontmatter `name: audit`, `user-invocable: true`, description: `"Orchestrates parallel multi-agent codebase audits with domain-specific prompts for yt-shorts-detector and GT agent. Spawns 12 scoped agents across 4 tiers... Triggers: audit, review, scan, check, pre-commit quality, code quality."`
- **Why this matters:** Two skills with the same `name:` create undefined behavior. Phase 3's Risk Assessment lists "Overlaps with existing VF validation skills" but misses this exact-name collision with the detector.
- **Fix:** Rename global skill to `visual-first-audit` or `audit-gate`; defer to detector's `audit` when CWD is the detector repo.

### C2. `/gt-perfect` is redundant with FIVE existing detector skills that already out-trigger it
- **Evidence (verified):** Detector repo has at `/Users/nick/Desktop/yt-transition-shorts-detector/.claude/skills/`:
  - `fix-detection` — description: `"Root-cause-first debugging protocol for detection pipeline bugs. Enforces visual inspection, hypothesis approval, and regression validation... Use when fixing detection failures, GT mismatches, wrong S/A/T counts, boundary errors..."` — this IS Phase 1's workflow.
  - `algorithm-mismatch-debugging` — `"Diagnoses algorithm output mismatches against ground truth — wrong counts, boundary errors, false positives, or missed detections. Mandates CODE fixes over parameter tuning."`
  - `gt-batch`, `ground-truth-generation`, `fix-loop`, `visual-debugging-process`, `video-detection-workflow`, `observer-protocol`, `ocr-debug-start`, `yt-shorts-detector-guidelines`.
- **Why this matters:** Phase 1 does not mention any of these. Inside the detector repo, `fix-detection` + `algorithm-mismatch-debugging` already own the trigger space. A new `/gt-perfect` either competes badly or demands deletions that Phase 1's `DELETE:` section does not declare.
- **Fix:** Add Phase 0.5 "Consolidation Decision" — either (a) cancel `/gt-perfect` authoring in favor of modifying `fix-detection` in place (preferred — YAGNI), or (b) explicitly deprecate `fix-detection` + `algorithm-mismatch-debugging` with redirect frontmatter and declare DELETE list.

### C3. Entire plan is blocked on Plan A artifacts that do not exist, with schemas guessed at
- **Evidence:**
  - Phase 1 depends on `yt-transition-shorts-detector/.claude/rules/detector-project-conventions.md` — not yet shipped by Plan A.
  - Phase 2 depends on `~/.claude/state/schemas/checkpoint.schema.json` — directory does not exist.
  - Phase 2 line 10: references Plan C `.debug/<issue>/evidence.md` shape as a Plan B invention. If Plan A's actual schema differs, Plan C hook + Plan B template disagree → silent failure.
  - Phase 3 depends on `~/.claude/rules/audit-workflow.md` — does not exist at `~/.claude/rules/`.
- **Fix:** Add Phase 0 "Schema Contract Freeze" owned by Plan A; block Plan B Phase 1–3 authoring until A ships `checkpoint.schema.json` + `detector-project-conventions.md` + `audit-workflow.md` with final content.

### C4. Phase 7 locks in 900-invocation budget before a "budget gate" that fires too late
- **Evidence:** Phase 7 Step 1 says "confirm budget with user" but Success Criteria hard-codes "held-out test score ≥ 80%" which only the full 5×20×3×3 scope reliably achieves. Plan.md Unresolved Q #3 pushes this decision downstream, but Phase 7 pretends it's resolved.
- **Fix:** Two-tier success criteria — Full budget → ≥80% held-out; Reduced budget (270 runs) → ≥70% held-out, documented tolerance for 1 residual near-miss. Resolve the budget decision in Phase 0.

## Major Findings (significant rework)

### M1. `/root-cause-first` trigger-space collision with `ck-debug` and `fix`
- **Evidence:** Existing `fix` skill: `"ALWAYS activate this skill before fixing ANY bug..."`. Existing `ck-debug`: `"Debug systematically with root cause analysis before fixes."` Proposed `/root-cause-first` triggers on `"debug", "fix this bug", "why is X failing"` — same vocabulary. The `"ALWAYS activate"` phrasing means Claude reaches `fix` first.
- **Fix:** Phase 5 baselines must run with incumbent skills discoverable. Add a third "incumbent" config running only `fix`/`ck-debug` and report a three-way delta.

### M2. `evals.json` vs `eval_metadata.json` schema field drift
- **Evidence:** Phase 4 line 25 uses `expectations`; Phase 5 lines 192–196 use `assertions`. These are different field names for the same concept per `skill-creator/references/schemas.md`.
- **Fix:** Phase 4 Implementation Step 4 must state: "In evals.json use `expectations`; in eval_metadata.json use `assertions`. They hold the same values. Confirm via `jq .evals[0].expectations` vs `jq .assertions`."

### M3. "Same turn" parallel spawn unimplementable at 54 runs
- **Evidence:** Phase 5 line 36: 3 × 3 × 2 × 3 = 54 subagents same-turn. Risk #1 admits "exceeds concurrency limits" but mitigation ("batch per skill sequentially") contradicts skill-creator's cache-locality guidance.
- **Fix:** Drop runs-per-config from 3 → 2 for iteration-1 (36 total, 18 per two-skill batch). Only expand if variance exceeds threshold.

### M4. Phase 6 iteration cap contradicts plan.md
- **Evidence:** plan.md line 42: "iterate until stable" (no cap). Phase 6 line 127: "cap = 3 iterations". Phase 6 line 34: "no iteration caps."
- **Fix:** Pick hard cap = 3; update plan.md + Phase 6 consistently.

### M5. Phase 8's "seeded bug" for `/root-cause-first` validation is mocking
- **Evidence:** Phase 8 line 105: "introduce a real bug (off-by-one, wrong conditional)..." VF's `no-mocks.md` prohibits synthetic scenarios. Phase 8 line 21 itself admits "'No mocks' applies recursively." Contradiction.
- **Fix:** Pick an actually-open bug from one of the three projects' issue trackers. No open bug → `/root-cause-first` validation is deferred.

## Minor Findings

- **m1.** Phase 5 `nohup … &` stores `VIEWER_PID=$!` in bash local; doesn't survive phase hand-off → viewer leaks. Fix: persist PID to `.viewer.pid` file.
- **m2.** Phase 1 line 86 uses `..` in absolute path: `/Users/nick/Desktop/validationforge/../yt-transition-shorts-detector/...`. Replace with canonical `/Users/nick/Desktop/yt-transition-shorts-detector/...`.
- **m3.** Phase 7 `--model <current-model-id>` left as placeholder. Set explicitly: `--model claude-opus-4-7[1m]`.
- **m4.** Phase 4 line 54: "detector looks fine but add a new GT clip" is a false near-miss (should route to `gt-batch`, not trigger `/gt-perfect`).
- **m5.** Phase 7 near-miss "write a unit test for the OCR module" is a genuinely-irrelevant trap — `no-mocks.md` blocks test creation. Replace with `"explain the OCR preprocessing pipeline to me"`.
- **m6.** Phase 5 missing `--static <output>` headless fallback for ssh/tmux environments.
- **m7.** Phase 2 contradicts itself on `.debug/` git-tracked vs gitignored (line 136 vs line 76).

## What's Missing
- Rollback plan if a new skill degrades triggering
- Contract test between Plan C hook and Plan B evidence.md template
- DELETE list declaration for the detector skill collisions
- Capacity check of `package_skill.py` / `present_files` availability
- Phase 8 wall-clock estimate (realistically 1–3 hours per skill)
- `user-invocable:` frontmatter handling in new skills

## Ambiguity Risks
- Phase 5 Step 1 "spawn all skills in one mega-turn if capacity allows" — interpretations A (54 at once) and B (18 per turn) both problematic.
- Phase 6 "user says they're happy" terminator undefined for agentic (autopilot/ralph) runs.
- Phase 3 `/audit` trigger-carve fails against M1 three-way collision.

## Answered unresolved questions
1. **`/gt-perfect` location** (plan.md Q1): Phase 1 answers "project-local." Plan.md must be updated. But C2 implies `/gt-perfect` should likely be CANCELLED entirely — consolidate into `fix-detection` instead.
2. **Eval count** (plan.md Q2): Phase 4 answers "2–3 now." Plan.md should be updated.
3. **Budget** (plan.md Q3): Resolve up front with two-tiered criteria per C4.

## What the plan gets RIGHT
- Phase 4's prompt-realism emphasis (filepaths, typos, casual speech) is aligned with skill-creator's §Description Optimization.
- Phase 5 correctly enforces `text`/`passed`/`evidence` field names.
- Phase 6's four-improvement-guardrails decision tree faithfully translates skill-creator guidance.
- Phase 7's diversity matrix (formal/casual/typo/competing/adjacent/idiom) is thoughtful and mostly-discriminating.
- Phase 8 honors the no-mocks mandate in principle (if M5 is fixed).

## Multi-Perspective Notes
- **Executor POV:** "I don't have Plan A's audit-workflow.md, detector-project-conventions.md, or checkpoint schema. Do I stub and hope, or block?" Plan does not answer.
- **Stakeholder POV:** "5.4M tokens + 900 invocations → a `/root-cause-first` skill whose real-world delta is measured against a baseline that excludes the already-installed `fix` incumbent."
- **Skeptic POV:** "Three new skills in a 350+ skill universe, each competing with an incumbent. Marginal lift ≈ 0. Plan should MODIFY `fix-detection`, `ck-debug`, `full-functional-audit` in place." No counter-answer in the plan.

## Risk Estimate
- Ship-as-is net-positive: ~15%
- Ship-as-is measurable regression: ~40%
- Ship with C1–C4 + M1–M5 fixes: ~70%

**Recommendation:** REVISE via new Phase 0 — (a) freeze Plan A schemas; (b) resolve three-way collision with renames or in-place modifications; (c) tier Phase 7 budget; (d) fix Phase 8 synthetic-bug contradiction; (e) update plan.md unresolved questions. Block Phase 1–3 on Phase 0 completion.

## Verification (performed by parent orchestrator)
The critic could not access the filesystem to verify claims. The parent independently confirmed:

```
$ ls /Users/nick/Desktop/yt-transition-shorts-detector/.claude/skills/
algorithm-mismatch-debugging  audit  device-matrix  fix-detection  fix-loop
ground-truth-generation  gt-batch  observer-protocol  ocr-debug-start
phased-exec  python-ocr-expertise  tmux-self-heal  trace-callbacks  validate-tui
video-detection-workflow  visual-debugging-process  yt-shorts-detector-guidelines
```

Frontmatter checked for `audit`, `fix-detection`, `algorithm-mismatch-debugging` — all three exactly as the critic described. **C1 and C2 confirmed, HIGH confidence.**
