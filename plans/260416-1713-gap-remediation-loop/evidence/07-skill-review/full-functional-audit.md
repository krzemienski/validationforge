---
name: full-functional-audit
skill_name: full-functional-audit
review_date: 2026-04-16
reviewer: P07-R2
---

## Frontmatter Check

| Field | Status | Notes |
|-------|--------|-------|
| name | ✅ PASS | "full-functional-audit" |
| description | ✅ PASS | 176 chars; clear summary of read-only audit and severity classification |
| triggers | ⚠️ MISSING | No `triggers:` array after `description` |
| context_priority | ✅ PASS | "standard" — audit is a mode, not core pipeline. |
| YAML parses | ✅ PASS | Valid (but incomplete schema) |

## Schema Violation

**Issue:** Frontmatter jumps directly from `description:` to `context_priority:` without a `triggers:` array.

## Body Quality

Body is **comprehensive and production-ready:**
- 5-phase process clearly defined (Platform Detection → Feature Inventory → Evidence Capture → Classification → Report)
- Severity matrix with clear classification rules (UP bias prevents underestimation)
- Evidence capture rules emphasizing completeness
- Audit report structure with executive summary, findings, recommendations
- 5 use cases (pre-release, compliance, handoff, post-incident, baseline)
- 6 strict rules enforcing read-only discipline

No functional defects, only schema violation.

## Verdict

**Status:** ⚠️ **NEEDS_FIX** (Minor Schema Violation)

### Proposed Patch

Add after `description:` line:
```yaml
triggers:
  - "audit project"
  - "health check"
  - "pre-release audit"
  - "baseline assessment"
  - "full functional audit"
```

### Follow-Ups
**Verify:** Do references/audit-report-template.md and references/severity-classification-guide.md exist?
