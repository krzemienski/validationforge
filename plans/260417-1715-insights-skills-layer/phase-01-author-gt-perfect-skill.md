# Phase 01 — Author `/gt-perfect` SKILL.md + bundled GT-diff script

## Context Links
- Plan: `plans/260417-1715-insights-skills-layer/plan.md`
- Authoritative skill authoring guide: `~/.claude/skills/skill-creator/SKILL.md` (sections: *Capture Intent*, *Write the SKILL.md*, *Skill Writing Guide*, *Progressive Disclosure*)
- Schema reference: `~/.claude/skills/skill-creator/references/schemas.md`
- Official Claude Code skill format: `~/.claude/plugins/cache/superpowers-marketplace/superpowers-developing-for-claude-code/0.3.1/skills/working-with-claude-code/references/skills.md`
- Plan A deliverables this skill depends on:
  - `yt-transition-shorts-detector/.claude/rules/detector-project-conventions.md` (project invariants)
  - `~/.claude/rules/instrument-before-theorize.md` (strengthened)

## Overview
- **Priority:** P1 — foundational skill for the detector workflow; every future GT-regression session should invoke it.
- **Status:** pending (blocked by Plan A delivery of `detector-project-conventions.md`)
- **Description:** Author a project-local skill at `yt-transition-shorts-detector/.claude/skills/gt-perfect/` that encodes the GT-comparison debug loop (diff detection JSON vs ground_truth/*.json → frame-inspect the first mismatch → ONE root-cause fix → commit → repeat until 8/8 on all clips). Bundles a deterministic GT-diff script so each invocation does not re-discover the diff format.

## Key Insights (from discovery)
- Detector repo already has ~80 `*.groundtruth.json` files under `videos/`, and canonical test clips under `stall-test-clips/clips-sequential/`. The skill does not need to invent fixtures.
- Past sessions wasted hours on threshold tweaks before visual frame inspection. The skill must make "dump the frame first" step 1, not step N.
- The detector has a canonical smoke-test command (`python3 -m yt_shorts_detector detect <video> <out> --detect-stalls --debug-json`) that must run cleanly with 4 stalls, 0 errors on `seq_A_0-30s.mp4` as the sanity baseline.
- Project-local location (not `~/.claude/skills/`) is correct because the workflow assumes detector-specific invariants — it would overtrigger in unrelated projects.
- skill-creator explicitly warns about under-triggering — the description must be pushy.

## Requirements

### Functional
- SKILL.md frontmatter includes `name: gt-perfect` and a pushy `description` that triggers on phrases like "ground truth", "GT mismatch", "detection count wrong", "stall count off", "detector regression", "validate against ground_truth".
- SKILL.md body encodes a numbered workflow: (1) run smoke baseline, (2) run full GT sweep via `scripts/gt-diff.py`, (3) for first mismatched clip: extract frame → visually inspect, (4) name ONE specific root cause (function + line), (5) cross-check failed-approaches log, (6) apply minimal fix, (7) commit with `fix-NNN: <cause> -> <result>` format, (8) re-run diff, (9) repeat until the delta table is empty.
- Bundled `scripts/gt-diff.py` reads detection JSON output from a results dir and `ground_truth/*.json`, prints a structured per-clip delta table (expected vs actual stall count, transition count, and per-segment boundary deltas).
- SKILL.md explicitly references (with relative paths) `~/.claude/rules/instrument-before-theorize.md` and the project-local `detector-project-conventions.md` so the model picks up the strengthened Plan A content.

### Non-functional
- SKILL.md <500 lines (progressive disclosure layer 2).
- `scripts/gt-diff.py` <200 lines, single-file, uses only stdlib + already-installed repo deps — no new packages.
- No `MUST`/`NEVER` walls of caps — explain the *why* per skill-creator's writing style guidance.
- Cite the existing smoke-test expected output (`4 stalls, 0 errors`) as the pass signal so the model knows when to stop.

## Architecture

### Skill directory layout
```
yt-transition-shorts-detector/.claude/skills/gt-perfect/
├── SKILL.md                        # Layer 2 — workflow + why
├── scripts/
│   └── gt-diff.py                  # Layer 3 — deterministic GT diff
└── references/
    └── commit-format.md            # Layer 3 — fix-NNN commit convention (loaded only when committing)
```

### Progressive disclosure layers
1. **Metadata** (always in context): `name` + pushy `description`.
2. **SKILL.md body**: workflow steps with explicit pointers like "Before editing any detector code, run `scripts/gt-diff.py` and read the first failing row."
3. **Bundled resources**: `scripts/gt-diff.py` (executed, not loaded) + `references/commit-format.md` (loaded only when model is drafting the commit message).

### Frontmatter shape (example, not final copy)
```yaml
---
name: gt-perfect
description: Drive a yt-shorts detector against the ground_truth/*.json corpus until every clip matches 8/8 exactly. Use WHENEVER the user mentions ground truth, GT mismatch, detection count off, stall count wrong, transition regression, seq_A/seq_B/seq_C clips, or any detector accuracy issue — even if they don't name "GT" explicitly. The workflow is strictly visual-first: frame inspection precedes any code edit; threshold tweaks are the last resort, not the first.
---
```

### Data flow
```
detector --detect-stalls --debug-json  →  <out>/{clip}.detect.json
                                              │
                                              ▼
                         scripts/gt-diff.py ← ground_truth/{clip}.groundtruth.json
                                              │
                                              ▼
                     structured delta table → model inspects first mismatch
                                              │
                                              ▼
                                  frame extraction + OCR pipeline test
                                              │
                                              ▼
                                    single-root-cause edit → commit
                                              │
                                              ▼
                                   re-run gt-diff.py (loop until empty)
```

## Related Code Files

### CREATE
- `/Users/nick/Desktop/validationforge/../yt-transition-shorts-detector/.claude/skills/gt-perfect/SKILL.md`
- `/Users/nick/Desktop/validationforge/../yt-transition-shorts-detector/.claude/skills/gt-perfect/scripts/gt-diff.py`
- `/Users/nick/Desktop/validationforge/../yt-transition-shorts-detector/.claude/skills/gt-perfect/references/commit-format.md`

> Absolute paths above assume the detector repo is a sibling of `validationforge` under `~/Desktop/`. Confirm exact path at execution time.

### MODIFY
- None in this phase. Plan A delivers the referenced rules.

### DELETE
- None.

## Implementation Steps

Follow skill-creator's *Capture Intent → Write the SKILL.md → Skill Writing Guide* sequence.

1. **(skill-creator §Capture Intent)** Confirm the three triggering phrases the user actually says in session. Read the last 3 GT-regression sessions from detector git history (`git log --all --grep="GT\|ground truth"`) and extract real user openers.
2. **(skill-creator §Write the SKILL.md)** Draft frontmatter. Description must name all the trigger phrases explicitly and close with a pushy sentence combating undertriggering.
3. Draft SKILL.md body. Structure:
   - "When to use" (mirror the description).
   - "Workflow" — numbered 1 through 9 as in Requirements above.
   - "Why visual-first" — two paragraphs explaining the past failure mode (hours on threshold tweaks).
   - "Commit format" — pointer to `references/commit-format.md`.
   - "Cross-references" — explicit paths to Plan A's two rules files.
4. **(skill-creator §Skill Writing Guide — Writing Patterns)** Add one worked example block showing a real delta row from a past GT mismatch and the single-line fix that resolved it. Use the *Example 1 / Input / Output* pattern.
5. Implement `scripts/gt-diff.py`:
   - Inputs: `--detection-dir`, `--gt-dir` (default `videos/`), `--clips` (optional glob).
   - Output: stdout table with columns `clip | expected_stalls | actual_stalls | expected_transitions | actual_transitions | first_boundary_delta_frames | status`.
   - Exit code 0 if all match, 1 otherwise. No extra dependencies.
6. Write `references/commit-format.md` — one page explaining `fix-NNN: <root cause> -> <result>` and why atomic single-cause commits beat batched ones (so `git bisect` narrows to a real cause).
7. Self-check against the *Principle of Lack of Surprise* — the skill cannot silently modify source or ground truth; it only reads GT and detection output and proposes edits that the model performs via normal Edit tool.
8. Stage for Phase 4 eval design — do NOT run evals yet.

## Todo List
- [ ] Extract 3 real trigger phrases from detector git history
- [ ] Draft pushy frontmatter `description`
- [ ] Draft SKILL.md body (workflow + why + example + cross-refs), under 500 lines
- [ ] Implement `scripts/gt-diff.py` with the specified CLI and exit code
- [ ] Author `references/commit-format.md`
- [ ] Lack-of-surprise self-check
- [ ] Verify all referenced Plan A files exist before committing this skill

## Success Criteria
- `yt-transition-shorts-detector/.claude/skills/gt-perfect/SKILL.md` loads in a fresh session and the frontmatter is valid YAML (`python -c "import yaml; yaml.safe_load(open('.../SKILL.md').read().split('---')[1])"` returns without error).
- `scripts/gt-diff.py` run against a known-good clip dir produces an empty delta (exit 0).
- `scripts/gt-diff.py` run against a clip dir with a seeded one-frame boundary shift prints exactly one row with status `FAIL` and the correct `first_boundary_delta_frames`.
- A cold-read review by a teammate yields zero "what does this mean" questions on the workflow section.

## Risk Assessment
| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Skill overtriggers outside detector work | Low | Medium | Project-local location + description names `yt-shorts detector` explicitly |
| Undertriggers because description is too narrow | Medium | High | Pushy description with 7+ trigger phrases; validated in Phase 7 |
| `gt-diff.py` brittle to GT schema drift | Medium | Medium | Gracefully skip clips missing either side of the diff; one-line warning per skip |
| Plan A files not yet in place when this phase runs | High | High | Phase gate: Phase 1 cannot start until Plan A Phase 3 completes (see `blockedBy` in plan.md) |
| Script path assumptions break in subagent CWD | Low | Medium | Script resolves paths via arguments, not CWD; document usage with absolute paths in SKILL.md |

## Security Considerations
- `scripts/gt-diff.py` is read-only on filesystem; explicitly never calls `os.remove`, `shutil.rmtree`, or `open(..., 'w')` on anything under `videos/` or `ground_truth/`.
- Document script provenance in a header comment: author, date, purpose, no network calls.
- The skill instructs the model to read GT files, never to regenerate them (GT is reference data — see `~/.claude/rules/philosophy.md` §Reference Data Protection).

## Next Steps
- Phase 2 (`/root-cause-first`) can run in parallel with this phase — different skill dirs, no file ownership overlap.
- Phase 4 (eval design) depends on this phase being complete.
- Phase 8 (functional validation) invokes this skill against a real detector regression.
