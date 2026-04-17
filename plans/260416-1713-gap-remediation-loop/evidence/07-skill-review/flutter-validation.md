---
name: flutter-validation
skill_name: flutter-validation
review_date: 2026-04-16
reviewer: P07-R2
---

## Frontmatter Check

| Field | Status | Notes |
|-------|--------|-------|
| name | ✅ PASS | "flutter-validation" |
| description | ✅ PASS | 179 chars; concrete steps and scope |
| triggers | ⚠️ MISSING | No `triggers:` array after `description` |
| context_priority | ✅ PASS | "standard" — platform-specific skill |
| YAML parses | ✅ PASS | Valid (but incomplete schema) |

## Schema Violation

**Issue:** Frontmatter jumps directly from `description:` to `context_priority:` without a `triggers:` array. This violates VF skill schema.

## Body Quality

Body is **comprehensive and production-ready:**
- Prerequisites checklist (7 items)
- 8 sequential steps: dependencies → build → run → screenshot → logs → widget tree → crash detection → cleanup
- Evidence quality guidance
- 10-entry common failures table
- 17-item PASS criteria template

No functional defects, only schema violation.

## Verdict

**Status:** ⚠️ **NEEDS_FIX** (Minor Schema Violation)

### Proposed Patch

Add after `description:` line:
```yaml
triggers:
  - "flutter validation"
  - "flutter app testing"
  - "flutter build and launch"
  - "flutter device validation"
  - "flutter crash detection"
```

### Follow-Ups
None after patch applied.
