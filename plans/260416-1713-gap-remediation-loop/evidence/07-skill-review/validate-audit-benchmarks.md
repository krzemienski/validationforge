---
skill: validate-audit-benchmarks
reviewed_at: 2026-04-16T20:15:00Z
reviewer: R4
---

## Frontmatter Check
- **name:** validate-audit-benchmarks ✓
- **description:** "Score ValidationForge primitives: hooks (60% weight), skills (20%), commands (20%). Produces A-F grade, compares against prior benchmarks. Run before releases, after modifications, during audits." (168 chars) ✓
- **yaml_parses:** Yes ✓

## Trigger Realism
4 triggers: "audit benchmarks", "run benchmark suite", "score hook correctness", "validate primitives"
**Realism:** 4/5 — Good but "quality metrics" (mentioned in description triggers) missing from list

## Body-Description Alignment
**Verdict:** PASS — Scoring rubric shows 60/20/20 weights. Grades table maps to A-F with semantics. Baseline comparison stated. Three validators invoked separately or together.

## MCP Tool Existence
Bash scripts (test-hooks.sh, validate-skills.sh, validate-cmds.sh, aggregate-results.sh), jq ✓

## Example Invocation Proof
**Prompt:** "audit benchmarks for skill quality" (5 words, viable)

## Verdict
**Status:** PASS

Meta-validation skill for VF infrastructure. Scoring rubric clear. Top 10 Skills list (functional-validation, e2e-validate, create-validation-plan, etc.) valuable for prioritization.

## Scripts Assumption
Assumes 4 bash scripts exist in scripts/benchmark/. Scripts not yet in repo (per R1/R2 status). FUTURE DEPENDENCY.

## Notes
- Infrastructure-level skill, not execution
- Output: audit-artifacts/benchmark-baseline.json
- Top 10 list useful for audit prioritization
