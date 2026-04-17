---
skill: production-readiness-audit
reviewer: R3
date: 2026-04-16
verdict: PASS
---

# production-readiness-audit review

## Frontmatter check
- name: `production-readiness-audit`
- description: `Audit app readiness across 8 phases: code quality, security, performance, reliability, observability, documentation, deployment. Produces READY/NOT READY/CONDITIONAL verdict with blocking issues.`
- description_chars: 151
- yaml_parses: yes

## Trigger realism
- Trigger phrases: `production readiness`, `deploy audit`, `is this ready for production`, `production checklist`, `readiness review`
- Realism score (5/5): Triggers match real pre-deployment decision points

## Body-description alignment
- Verdict: PASS
- Evidence: Description matches body exactly. Eight phases are documented with concrete checklists: (1) Code Quality, (2) Security, (3) Performance, (4) Reliability, (5) Observability, (6) Documentation, (7) Deployment, (8) Final Verdict. Each phase has checklist items with verification methods and evidence requirements. Severity Rules section enforces blocking conditions: "Any Phase 2 FAIL = NOT READY" and "Any Phase 7 FAIL = NOT READY".

## MCP tool existence
- Tools referenced: grep, npm audit, Lighthouse, curl, helm (deployment)
- Confirmed: yes (standard CLI tools; Lighthouse is web standard)

## Example invocation
"Run the production readiness audit before deploying to production"

## Verdict
PASS
- Eight phases provide comprehensive coverage (quality, security, performance, reliability, observability, docs, deployment)
- Each phase has 4-8 concrete checklist items
- How to Verify column for each item is actionable
- Evidence column specifies what to capture
- Severity Rules are explicit: Phase 2 and Phase 7 failures are blocking
- Final Verdict template is provided with blocking/non-blocking issue sections
- Integration section clearly states: "Run this AFTER all feature-level validations have passed"
- Related Skills section links to complementary audits (full-functional-audit, baseline-quality-assessment)
