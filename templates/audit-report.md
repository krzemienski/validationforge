# Functional Audit Report

**Project:** {{PROJECT_NAME}}
**Platform:** {{PLATFORM}}
**Date:** {{DATE}}
**Auditor:** ValidationForge
**Mode:** Read-only (no code changes)

## Summary

| Metric | Count |
|--------|-------|
| Features audited | {{TOTAL}} |
| PASS | {{PASS_COUNT}} |
| FAIL | {{FAIL_COUNT}} |
| Critical issues | {{CRITICAL}} |
| High issues | {{HIGH}} |
| Medium issues | {{MEDIUM}} |
| Low issues | {{LOW}} |

## Findings

### {{FEATURE_1}}
**Status:** PASS | FAIL
**Severity:** CRITICAL | HIGH | MEDIUM | LOW | INFO
**Evidence:** `e2e-evidence/{{EVIDENCE_FILE}}`
**Finding:** {{DESCRIPTION}}
**Recommendation:** {{FIX_SUGGESTION}}

---

### {{FEATURE_2}}
**Status:** PASS | FAIL
**Severity:** CRITICAL | HIGH | MEDIUM | LOW | INFO
**Evidence:** `e2e-evidence/{{EVIDENCE_FILE}}`
**Finding:** {{DESCRIPTION}}
**Recommendation:** {{FIX_SUGGESTION}}

## Priority Recommendations

1. **[CRITICAL]** {{RECOMMENDATION_1}}
2. **[HIGH]** {{RECOMMENDATION_2}}
3. **[MEDIUM]** {{RECOMMENDATION_3}}

## Evidence Index

| File | Description |
|------|-------------|
| `e2e-evidence/{{FILE_1}}` | {{DESC_1}} |
| `e2e-evidence/{{FILE_2}}` | {{DESC_2}} |
