---
name: e2e-validate
skill_name: e2e-validate
review_date: 2026-04-16
reviewer: P07-R2
---

## Frontmatter Check

| Field | Status | Notes |
|-------|--------|-------|
| name | ✅ PASS | "e2e-validate" |
| description | ✅ PASS | 190 chars; orchestrator summary with scope notes |
| triggers | ✅ PASS | 5 trigger phrases; all realistic |
| context_priority | ✅ PASS | **"critical"** — correct. Orchestrator for all validation workflows. |
| YAML parses | ✅ PASS | Valid |

## Body-Description Alignment

**Description claims:**
> Orchestrator: detect platform → map journeys → PASS criteria → capture evidence → verdicts (zero mocks). Supports iOS/RN/Flutter/web/API/CLI/Django/fullstack. Bottom-up order, 3-strike fix loop.

**Body delivers all claims:**
- Platform detection (9 platform types listed, lines 30-44)
- Journey mapping, PASS criteria definition, evidence capture, verdicts (Workflow section references)
- Zero mocks (Iron Rule, lines 21-26: explicitly prohibits mocks/stubs/test doubles)
- Platform support: iOS, react-native, flutter, cli, api, web, django, fullstack, generic
- Bottom-up validation order (line 64-66)
- 3-strike fix loop (error-recovery skill referenced as critical)

**Verdict:** ✅ **PASS** — Body comprehensively delivers on all claims.

## Architecture Sophistication

Lines 125-154 address "Context Budget" — skills tiered by priority (critical/standard/reference) to prevent context overload. **Excellent architectural thinking.**

## Verdict

**Status:** ✅ **PASS**

This skill is the orchestrator heart of ValidationForge. Frontmatter valid, triggers realistic, scope clearly defined, architecture sophisticated (context budget, progressive disclosure). No blocking issues.

### Proposed Patches
None required.
