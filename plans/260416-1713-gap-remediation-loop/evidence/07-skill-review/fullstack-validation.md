---
name: fullstack-validation
skill_name: fullstack-validation
review_date: 2026-04-16
reviewer: P07-R2
---

## Frontmatter Check

| Field | Status | Notes |
|-------|--------|-------|
| name | ✅ PASS | "fullstack-validation" |
| description | ✅ PASS | 172 chars; clear summary of bottom-up validation |
| triggers | ⚠️ MISSING | No `triggers:` array after `description` |
| context_priority | ✅ PASS | "standard" — platform-specific skill |
| YAML parses | ✅ PASS | Valid (but incomplete schema) |

## Schema Violation

**Issue:** Frontmatter jumps directly from `description:` to `context_priority:` without a `triggers:` array.

## Body Quality

Body is **comprehensive and production-ready:**
- Bottom-up rule clearly justified (visual + explanation: "A frontend bug might actually be a backend bug...")
- 4-layer validation structure: DB → API → Frontend → Integration
- Each layer has explicit PASS gate before proceeding
- Integration testing covers all data flow directions: frontend→API→DB, DB→API→frontend, update propagation, delete cascade
- Cross-reference validation (API count = DB count) proves integration
- Evidence standards section teaches specificity and traceability
- 6-entry common failures table
- 17-item PASS criteria template

No functional defects, only schema violation.

## Verdict

**Status:** ⚠️ **NEEDS_FIX** (Minor Schema Violation)

### Proposed Patch

Add after `description:` line:
```yaml
triggers:
  - "fullstack validation"
  - "multi-layer validation"
  - "end-to-end data flow"
  - "database to frontend"
  - "validate layers"
```

### Follow-Ups
None after patch applied.
