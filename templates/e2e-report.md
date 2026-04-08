# E2E Validation Report

**Project:** {{PROJECT_NAME}}
**Platform:** {{PLATFORM}}
**Date:** {{DATE}}
**Config:** {{STRICTNESS}}
**Duration:** {{DURATION}}

## Overall Result: {{PASS | FAIL}}

## Summary

| Journey | Status | Evidence |
|---------|--------|----------|
| {{J1_NAME}} | PASS/FAIL | `e2e-evidence/{{FILE}}` |
| {{J2_NAME}} | PASS/FAIL | `e2e-evidence/{{FILE}}` |
| {{J3_NAME}} | PASS/FAIL | `e2e-evidence/{{FILE}}` |

**Pass Rate:** {{PASS_COUNT}}/{{TOTAL}} ({{PERCENTAGE}}%)

## Journey Details

### {{J1_NAME}}
**Status:** PASS
**Evidence Examined:**
- `e2e-evidence/{{FILE_1}}` — {{WHAT_WAS_SEEN}}
- `e2e-evidence/{{FILE_2}}` — {{WHAT_WAS_SEEN}}

**Criteria Match:**
| Criterion | Evidence | Verdict |
|-----------|----------|---------|
| {{C1}} | {{PROOF}} | PASS |
| {{C2}} | {{PROOF}} | PASS |

---

### {{J2_NAME}}
**Status:** FAIL
**Evidence Examined:**
- `e2e-evidence/{{FILE}}` — {{WHAT_WAS_SEEN}}

**Criteria Match:**
| Criterion | Evidence | Verdict |
|-----------|----------|---------|
| {{C1}} | {{PROOF}} | PASS |
| {{C2}} | Missing | FAIL |

**Root Cause:** {{EXPLANATION}}
**Fix Applied:** {{YES/NO — DESCRIPTION}}

## Error Log
{{ERRORS_ENCOUNTERED_DURING_VALIDATION}}

## Recommendations
1. {{RECOMMENDATION}}
2. {{RECOMMENDATION}}
