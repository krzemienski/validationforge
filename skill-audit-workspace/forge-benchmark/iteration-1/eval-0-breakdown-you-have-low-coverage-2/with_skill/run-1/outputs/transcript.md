# Skill Consultation Transcript

## Files read (in order)

1. `/Users/nick/Desktop/validationforge/skills/forge-benchmark/SKILL.md` — full read.
2. `/Users/nick/Desktop/validationforge/skills/forge-benchmark/scripts/score-project.sh` — full read for exact scoring logic.

## Key content I relied on

From **SKILL.md** — dimensions table and weights:
> "Coverage | 35% | Journey subdirs in e2e-evidence/ + plan files | >80"
> "Evidence Quality | 30% | Non-empty evidence files ratio + verdict file bonus | >90"
> "Enforcement | 25% | Hooks, no test/mock files, rules, e2e-evidence dir, .vf/config | >80"
> "Speed | 10% | Validation duration from .vf/last-run.json | <120s=100"

Coverage tiers:
> "Journey count tiers: 0 dirs=0, ≤2=50, ≤4=70, >4=85. +10 bonus if plans/ has markdown files. Cap at 100."

Evidence formula:
> "quality = (non_empty / total) * 70 + verdict_bonus" where verdict_bonus = 30 if any `*VERDICT*` or `report.md`.

Grade table:
> "A 90-100 | B 80-89 | C 70-79 | D 60-69 | F <60"

Aggregate formula:
> "aggregate = (coverage * 35 + evidence_quality * 30 + enforcement * 25 + speed * 10) / 100"

Regression patterns section helped me give concrete root causes for the Enforcement 60 score — rules deleted, mock pattern appeared, hooks removed, or missing .vf/config.json.

From **score-project.sh** — confirmed the exact six enforcement slots (+20/+20/+20/+20/+10/+10) so I could enumerate which were missing when score=60.

## What the skill did NOT give me
The skill doesn't prescribe a canonical ordering of fixes or projected-grade math — I derived the (100-score)×weight priority ranking and the 97 projected aggregate myself from the formulas.
