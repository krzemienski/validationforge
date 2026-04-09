# FORGE Run Report

**Run ID:** {{RUN_ID}}
**Project:** {{PROJECT_NAME}}
**Platform:** {{PLATFORM}}
**Date:** {{DATE}}
**Duration:** {{DURATION}}
**Config:** {{STRICTNESS}}

## Final Verdict: {{PASS | FAIL}}

---

## Iteration Summary

| Attempt | Journeys Tested | Pass | Fail | Fixes Applied | Build |
|---------|----------------|------|------|---------------|-------|
| {{ATTEMPT_1}} | {{JOURNEYS_TESTED_1}} | {{PASS_COUNT_1}} | {{FAIL_COUNT_1}} | {{FIXES_APPLIED_1}} | {{BUILD_STATUS_1}} |
| {{ATTEMPT_2}} | {{JOURNEYS_TESTED_2}} | {{PASS_COUNT_2}} | {{FAIL_COUNT_2}} | {{FIXES_APPLIED_2}} | {{BUILD_STATUS_2}} |
| {{ATTEMPT_3}} | {{JOURNEYS_TESTED_3}} | {{PASS_COUNT_3}} | {{FAIL_COUNT_3}} | {{FIXES_APPLIED_3}} | {{BUILD_STATUS_3}} |

**Total Iterations:** {{TOTAL_ITERATIONS}}
**Total Fix Attempts:** {{TOTAL_FIX_ATTEMPTS}}
**Strike Limit Reached:** {{YES | NO}}

---

## Journey Results

| Journey | Initial Status | Final Status | Attempts | Resolution |
|---------|---------------|--------------|----------|------------|
| {{J1_NAME}} | PASS/FAIL | PASS/FAIL/PERSISTENT_FAIL | {{J1_ATTEMPTS}} | {{J1_RESOLUTION}} |
| {{J2_NAME}} | PASS/FAIL | PASS/FAIL/PERSISTENT_FAIL | {{J2_ATTEMPTS}} | {{J2_RESOLUTION}} |
| {{J3_NAME}} | PASS/FAIL | PASS/FAIL/PERSISTENT_FAIL | {{J3_ATTEMPTS}} | {{J3_RESOLUTION}} |

---

## Per-Journey Detail

### {{J1_NAME}}

**Final Status:** PASS | FAIL | PERSISTENT_FAIL
**Total Strike Count:** {{J1_STRIKE_COUNT}}/3

#### Strike Log

**Strike 1 — Attempt {{ATTEMPT_NUMBER}}**
- **Build:** {{BUILD_RESULT}}
- **Validation Result:** FAIL
- **Root Cause:** {{ROOT_CAUSE_1}}
- **Evidence:** `e2e-evidence/{{ITERATION_DIR}}/{{EVIDENCE_FILE}}` — {{WHAT_WAS_SEEN}}
- **Fix Applied:** `{{FILE_PATH}}:{{LINE_NUMBER}}` — {{FIX_DESCRIPTION}}
- **Fix Result:** {{PASS | FAIL — DESCRIPTION}}

**Strike 2 — Attempt {{ATTEMPT_NUMBER}}**
- **Build:** {{BUILD_RESULT}}
- **Validation Result:** FAIL
- **Root Cause:** {{ROOT_CAUSE_2}}
- **Evidence:** `e2e-evidence/{{ITERATION_DIR}}/{{EVIDENCE_FILE}}` — {{WHAT_WAS_SEEN}}
- **Fix Applied:** `{{FILE_PATH}}:{{LINE_NUMBER}}` — {{FIX_DESCRIPTION}}
- **Fix Result:** {{PASS | FAIL — DESCRIPTION}}

**Strike 3 — Attempt {{ATTEMPT_NUMBER}}**
- **Build:** {{BUILD_RESULT}}
- **Validation Result:** FAIL
- **Root Cause:** {{ROOT_CAUSE_3}}
- **Evidence:** `e2e-evidence/{{ITERATION_DIR}}/{{EVIDENCE_FILE}}` — {{WHAT_WAS_SEEN}}
- **Fix Applied:** `{{FILE_PATH}}:{{LINE_NUMBER}}` — {{FIX_DESCRIPTION}}
- **Fix Result:** {{PASS | FAIL — DESCRIPTION}}

---

### {{J2_NAME}}

**Final Status:** PASS | FAIL | PERSISTENT_FAIL
**Total Strike Count:** {{J2_STRIKE_COUNT}}/3

#### Strike Log

**Strike 1 — Attempt {{ATTEMPT_NUMBER}}**
- **Build:** {{BUILD_RESULT}}
- **Validation Result:** FAIL
- **Root Cause:** {{ROOT_CAUSE_1}}
- **Evidence:** `e2e-evidence/{{ITERATION_DIR}}/{{EVIDENCE_FILE}}` — {{WHAT_WAS_SEEN}}
- **Fix Applied:** `{{FILE_PATH}}:{{LINE_NUMBER}}` — {{FIX_DESCRIPTION}}
- **Fix Result:** {{PASS | FAIL — DESCRIPTION}}

---

## Fixes Applied

All fixes applied during this FORGE run, with file and line references:

| # | Attempt | Journey | File | Line | Description | Result |
|---|---------|---------|------|------|-------------|--------|
| 1 | {{ATTEMPT_NUMBER}} | {{JOURNEY_NAME}} | `{{FILE_PATH}}` | {{LINE_NUMBER}} | {{FIX_DESCRIPTION}} | PASS/FAIL |
| 2 | {{ATTEMPT_NUMBER}} | {{JOURNEY_NAME}} | `{{FILE_PATH}}` | {{LINE_NUMBER}} | {{FIX_DESCRIPTION}} | PASS/FAIL |
| 3 | {{ATTEMPT_NUMBER}} | {{JOURNEY_NAME}} | `{{FILE_PATH}}` | {{LINE_NUMBER}} | {{FIX_DESCRIPTION}} | PASS/FAIL |

### Fix Detail

#### Fix 1 — {{JOURNEY_NAME}} (Attempt {{ATTEMPT_NUMBER}})
**File:** `{{FILE_PATH}}:{{LINE_NUMBER}}`
**Change:** {{WHAT_CHANGED_AND_WHY}}
**Before:** `{{CODE_BEFORE}}`
**After:** `{{CODE_AFTER}}`

---

## Final Verdict Table

| Journey | Strikes Used | Final Status | Evidence |
|---------|-------------|--------------|----------|
| {{J1_NAME}} | {{J1_STRIKES}}/3 | PASS | `e2e-evidence/{{ITERATION_DIR}}/{{EVIDENCE_FILE}}` |
| {{J2_NAME}} | {{J2_STRIKES}}/3 | PASS | `e2e-evidence/{{ITERATION_DIR}}/{{EVIDENCE_FILE}}` |
| {{J3_NAME}} | {{J3_STRIKES}}/3 | PERSISTENT_FAIL | `e2e-evidence/{{ITERATION_DIR}}/{{EVIDENCE_FILE}}` |

**Overall:** {{PASS_FINAL}}/{{TOTAL_JOURNEYS}} journeys passing

---

## Persistent Failures

Journeys that exhausted all 3 strike attempts without resolution:

### {{PERSISTENT_JOURNEY_NAME}}

**Strikes Exhausted:** 3/3
**Root Cause Analysis:**
{{DEEP_ROOT_CAUSE_EXPLANATION}}

**All Attempted Fixes:**
1. `{{FILE_PATH}}:{{LINE_NUMBER}}` — {{FIX_1_DESCRIPTION}} → {{RESULT_1}}
2. `{{FILE_PATH}}:{{LINE_NUMBER}}` — {{FIX_2_DESCRIPTION}} → {{RESULT_2}}
3. `{{FILE_PATH}}:{{LINE_NUMBER}}` — {{FIX_3_DESCRIPTION}} → {{RESULT_3}}

**Why It Could Not Be Auto-Fixed:**
{{EXPLANATION_OF_BLOCKER}}

**Recommended Manual Action:**
{{MANUAL_FIX_RECOMMENDATION}}

**Blocking Evidence:**
- `e2e-evidence/{{ITERATION_DIR}}/{{EVIDENCE_FILE}}` — {{WHAT_WAS_SEEN}}

---

## Evidence Index

All evidence captured across all iterations:

| Iteration | Journey | File | Description |
|-----------|---------|------|-------------|
| {{ATTEMPT_NUMBER}} | {{JOURNEY_NAME}} | `e2e-evidence/{{ITERATION_DIR}}/{{EVIDENCE_FILE}}` | {{DESCRIPTION}} |
| {{ATTEMPT_NUMBER}} | {{JOURNEY_NAME}} | `e2e-evidence/{{ITERATION_DIR}}/{{EVIDENCE_FILE}}` | {{DESCRIPTION}} |

## Build Log Summary

| Attempt | Command | Status | Output |
|---------|---------|--------|--------|
| {{ATTEMPT_NUMBER}} | `{{BUILD_COMMAND}}` | PASS/FAIL | {{BUILD_OUTPUT_SUMMARY}} |
| {{ATTEMPT_NUMBER}} | `{{BUILD_COMMAND}}` | PASS/FAIL | {{BUILD_OUTPUT_SUMMARY}} |
