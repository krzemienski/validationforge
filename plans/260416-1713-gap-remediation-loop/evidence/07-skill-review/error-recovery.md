---
name: error-recovery
skill_name: error-recovery
review_date: 2026-04-16
reviewer: P07-R2
---

## Frontmatter Check

| Field | Status | Notes |
|-------|--------|-------|
| name | ✅ PASS | "error-recovery" |
| description | ✅ PASS | 171 chars; concise summary of 3-strike protocol |
| triggers | ✅ PASS | 5 trigger phrases; all realistic |
| context_priority | ✅ PASS | **"critical"** — correct. Core validation repair mechanism. |
| YAML parses | ✅ PASS | Valid |

## Body-Description Alignment

**Description claims:**
> 3-strike recovery: strike 1 (targeted fix, same step), strike 2 (alt tool/path), strike 3 (rethink assumptions). Never mock; fix real cause. Covers build fails, crashes, network/auth/DB errors.

**Body delivers all three strike types, never-mock rule, and 9-category error classification:**
- Strike 1: Targeted fix (lines 28-32)
- Strike 2: Alternative approach (lines 37-42)
- Strike 3: Broader rethink (lines 47-53)
- Never mock (Section: Rules, #2)
- Fix real cause (Section: Rules, #4)
- Error classification covers: build, runtime, network, auth, database, file not found, port in use, dependency, config

**Verdict:** ✅ **PASS** — Body comprehensively delivers on all claims.

## Escalation Clarity

After 3 strikes, escalate with: full error output, all 3 attempts, root cause hypothesis, suggested next steps. Excellent structure.

## Verdict

**Status:** ✅ **PASS**

This skill is the repair mechanism for ValidationForge. No blocking issues.

### Proposed Patches
None required.
