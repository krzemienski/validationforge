# Validation Plan: {{PROJECT_NAME}}

**Platform:** {{PLATFORM}}
**Date:** {{DATE}}
**Config:** {{STRICTNESS}}
**Validator:** ValidationForge

## Preflight Status
- [ ] Prerequisites verified
- [ ] Evidence directory created
- [ ] Server/app running

## Journeys

### J1: {{PRIMARY_JOURNEY_NAME}}
**Priority:** Critical
**Steps:**
1. {{STEP_1}}
2. {{STEP_2}}
3. {{STEP_3}}

**PASS Criteria:**
- [ ] {{CRITERION_1}}
- [ ] {{CRITERION_2}}
- [ ] {{CRITERION_3}}

**Evidence Required:**
- {{EVIDENCE_TYPE}}: `e2e-evidence/{{EVIDENCE_FILE}}`

---

### J2: {{SECONDARY_JOURNEY_NAME}}
**Priority:** High
**Steps:**
1. {{STEP_1}}
2. {{STEP_2}}

**PASS Criteria:**
- [ ] {{CRITERION_1}}
- [ ] {{CRITERION_2}}

**Evidence Required:**
- {{EVIDENCE_TYPE}}: `e2e-evidence/{{EVIDENCE_FILE}}`

---

### J3: {{ERROR_JOURNEY_NAME}}
**Priority:** Medium
**Steps:**
1. {{STEP_1}}
2. {{STEP_2}}

**PASS Criteria:**
- [ ] {{CRITERION_1}}
- [ ] {{CRITERION_2}}

**Evidence Required:**
- {{EVIDENCE_TYPE}}: `e2e-evidence/{{EVIDENCE_FILE}}`

## Execution Order
J1 → J2 → J3

## Approval
- [ ] Plan reviewed and approved
