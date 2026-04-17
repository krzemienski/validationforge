---
name: forge-execute
skill_name: forge-execute
review_date: 2026-04-16
reviewer: P07-R2
---

## Frontmatter Check

| Field | Status | Notes |
|-------|--------|-------|
| name | ✅ PASS | "forge-execute" |
| description | ✅ PASS | 167 chars; clear overview of execution loop and fix protocol |
| triggers | ✅ PASS | 3 trigger phrases; all realistic |
| context_priority | ✅ PASS | "reference" — correct. Execution happens after planning. |
| YAML parses | ✅ PASS | Valid |

## Body-Description Alignment

**Description claims:**
> Execute validation journeys with autonomous fix loop: run, capture evidence, analyze, rebuild, re-execute (max 3 strikes). Use after plan exists; maintains attempt history in isolated directories.

**Body delivers all claims:**
- Run journeys (Phase 2: Execute Journeys)
- Capture evidence (lines 51-54: per-attempt directories with screenshots/API responses)
- Analyze failures (Phase 3: sequential thinking, root cause classification)
- Rebuild rule (line 93: "MUST compile before re-validating")
- Re-execute with isolated directories (lines 84-91: forge-attempt-{N}/ structure)
- Max 3 strikes (line 86: while strike < 3)
- Use after plan exists (lines 36-37: fallback to forge-plan)

**Verdict:** ✅ **PASS** — Body delivers on all claims.

## Evidence Isolation Excellence

Per-attempt directories (`forge-attempt-1/`, `forge-attempt-2/`, `forge-attempt-3/`) prevent evidence overwriting. Each fix attempt gets fresh evidence. Critical feature.

## Verdict

**Status:** ✅ **PASS**

This skill is the execution engine of ValidationForge. Phases are clearly defined, fix loop is rigorous, evidence isolation is excellent. No blocking issues.

### Proposed Patches
None required.
