---
name: forge-plan
skill_name: forge-plan
review_date: 2026-04-16
reviewer: P07-R2
---

## Frontmatter Check

| Field | Status | Notes |
|-------|--------|-------|
| name | ✅ PASS | "forge-plan" |
| description | ✅ PASS | 145 chars; concise summary of plan modes |
| triggers | ✅ PASS | 3 trigger phrases; all realistic |
| context_priority | ✅ PASS | "reference" — correct. Planning happens before execution. |
| YAML parses | ✅ PASS | Valid |

## Body-Description Alignment

**Description claims:**
> Create validation plan: discover journeys, define PASS criteria per step, specify evidence types. Modes: quick, standard, consensus (critical/multi-team). Use before /validate.

**Body delivers:**
- Journey discovery (Section: Standard Mode, #1: scan codebase for user-facing interactions)
- PASS criteria per step (Section: Standard Mode, #2: 3-7 steps with specific criteria per step)
- Evidence type specification (line 35: "each step specifies required evidence type")
- Quick mode (lines 18-23: detect → discover → generate → output)
- Standard mode (lines 25-40: discovery → journey generation → coverage analysis → gap filling)
- Consensus mode (lines 42-55: three-perspective analysis with merge/deduplication)
- Use before /validate (line 14: "Before running `/validate` on a new project")

**Verdict:** ✅ **PASS** — Body delivers on all claims.

## Consensus Mode Sophistication

Three independent perspectives (User Advocate, Security Analyst, Quality Engineer) analyze in parallel, then merge with deduplication and conflict resolution. **High maturity for multi-team projects.**

## Verdict

**Status:** ✅ **PASS**

This skill is the planning stage of ValidationForge. Three modes handle different project sizes. Output format is clear, evidence requirements are specific, risk-based prioritization is excellent. No blocking issues.

### Proposed Patches
None required.
