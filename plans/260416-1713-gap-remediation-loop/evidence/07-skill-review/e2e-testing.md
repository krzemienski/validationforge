---
name: e2e-testing
skill_name: e2e-testing
review_date: 2026-04-16
reviewer: P07-R2
---

## Frontmatter Check

| Field | Status | Notes |
|-------|--------|-------|
| name | ✅ PASS | "e2e-testing" |
| description | ✅ PASS | 180 chars; strategic summary (not tactical execution) |
| triggers | ✅ PASS | 5 trigger phrases; all realistic |
| context_priority | ✅ PASS | "standard" — strategy skill, invoked on demand |
| YAML parses | ✅ PASS | Valid |

## Trigger Realism

| Phrase | Realism | Note |
|--------|---------|-------|
| "e2e testing patterns" | 5/5 | Direct user question |
| "end to end patterns" | 5/5 | Variant |
| "journey design" | 5/5 | Key concept from body |
| "flaky flow" | 5/5 | Real problem; high-value trigger |
| "e2e strategy" | 4/5 | Good; slightly broad |

## Body-Description Alignment

**Description claims:**
> E2E patterns: journey design (one goal per journey, precondition→action→assertion), evidence management (step-NN naming, inventory), flaky flow diagnosis (3 runs, capture delta, fix root).

**Body delivers all three domains completely:**
- Journey design with precondition→action→assertion structure (Section 2)
- Evidence management with step-NN naming and inventory generation (Section: Evidence Management)
- Flaky flow diagnosis: 3 runs, delta analysis, root cause fixing (Section: Flaky Flow Handling)

**Verdict:** ✅ **PASS** — Body fully delivers on description.

## Verdict

**Status:** ✅ **PASS**

This skill is well-designed. It correctly positions itself as strategy (not execution), provides concrete patterns with examples, and teaches root-cause thinking for flaky tests. No blocking issues.

### Proposed Patches
None. Skill is solid.
