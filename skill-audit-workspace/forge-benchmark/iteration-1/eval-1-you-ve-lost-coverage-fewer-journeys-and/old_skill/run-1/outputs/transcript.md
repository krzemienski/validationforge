# Transcript — forge-benchmark snapshot eval

## Inputs
- Skill consulted: `skill-audit-workspace/forge-benchmark/skill-snapshot/SKILL.md` (baseline, pre-edit).
- User scenario: fullstack team benchmark dropped 92 -> 76 (A -> C). Coverage 95 -> 70, Evidence Quality 100 -> 60. Enforcement + Speed stable.

## What the snapshot provided
- Weighting: Coverage 35%, Evidence Quality 30%, Enforcement 25%, Speed 10%.
- Coverage formula: journey-subdir tiers (0/50/70/85) + 10 plan-bonus, cap 100.
- Evidence Quality formula: `(non_empty/total)*70 + 30 if VERDICT/report.md present`.
- Benchmark record schema and grade bands.

## Reasoning path
1. Confirmed the 16-point aggregate drop matches the weighted delta of the two dropped dimensions.
2. Mapped Coverage=70 to the "<=4 journeys" tier with lost plan bonus — pinpoints journey count and plans/ markdown as the two levers.
3. Mapped Evidence Quality=60 to the most likely combination: missing verdict file (-30) plus a slight empty-file ratio drop, or alternatively empty files dominating with verdict intact.
4. Generated 2-4 plausible causes per dimension, grounded in the formulas.
5. Produced filesystem-level investigative commands tied directly to the scoring inputs.
6. Proposed remediations that each map to a specific formula term, restoring 92+.

## Gaps in the snapshot
- SKILL.md defines scoring only; it does not explain *why* artifacts disappear. Root cause must be confirmed via filesystem and git history — flagged explicitly in the answer.
- No bundled scripts/ or references/ available to deepen diagnostic tooling.

## Output
- `answer.md` (~500 words) written with dimension analysis, causes, investigative steps, remediation.
