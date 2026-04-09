# Workflow: Ship

**Objective:** Execute Phase 6 — production readiness audit and deploy decision gate.

## Prerequisites

- Phase 5 (Verdict) completed with final report at `e2e-evidence/report.md`
- All feature-level journeys have verdicts (PASS, FAIL, or UNRESOLVED)
- Build succeeds in the current state

## Process

### Step 1: Read Validation Report

Load `e2e-evidence/report.md` and extract:
- Overall result (PASS / FAIL / PARTIAL)
- Count of UNRESOLVED journeys
- Any security-related journey failures
- Any deployment-related journey failures

If `e2e-evidence/report.md` does not exist, STOP — run Phase 5 (Verdict) first.

### Step 2: Run Production Readiness Audit

Invoke the `production-readiness-audit` skill. This runs 8 sub-phases:

```
mkdir -p e2e-evidence/prod-audit
```

| Sub-Phase | Focus | Blocking |
|-----------|-------|---------|
| 1. Code Quality | No secrets, no debug code, deps current | No |
| 2. Security | Auth, authz, HTTPS, headers, CORS | **YES** |
| 3. Performance | Load times, LCP, API response times | No |
| 4. Reliability | Error handling, network resilience | No |
| 5. Observability | Error tracking, logging, health checks | No |
| 6. Documentation | README, env vars, API docs | No |
| 7. Deployment | Build, env config, migrations, rollback | **YES** |
| 8. Final Verdict | Synthesize all sub-phases | — |

Evidence from each sub-phase goes to `e2e-evidence/prod-audit/{sub-phase}/`.

### Step 3: Evaluate Blocking Criteria

Apply the blocking rules:

```
BLOCKING (deploy must not proceed):
  - Any Phase 2 (Security) sub-phase FAIL
  - Any Phase 7 (Deployment) sub-phase FAIL
  - Feature validation result is FAIL with unresolved security journeys

CONDITIONAL (deploy allowed with documented risk acceptance):
  - Phase 1, 3, 4 FAILs
  - Phase 5, 6 FAILs
  - Feature validation PARTIAL (all critical journeys PASS)

READY (deploy can proceed):
  - All prod-audit phases PASS
  - Feature validation result is PASS
```

### Step 4: Compute Ship Verdict

Combine the feature validation result (from Phase 5) with the production readiness audit result (from Step 2):

| Feature Validation | Prod Audit | Ship Verdict |
|-------------------|------------|--------------|
| PASS | READY | **SHIP** |
| PASS | CONDITIONAL | **CONDITIONAL SHIP** |
| PASS | NOT READY | **HOLD** |
| PARTIAL | READY | **CONDITIONAL SHIP** |
| PARTIAL | CONDITIONAL | **CONDITIONAL SHIP** |
| PARTIAL | NOT READY | **HOLD** |
| FAIL | (any) | **HOLD** |

### Step 5: Generate Ship Report

```markdown
# Ship Decision Report

**Project:** {name}
**Platform:** {detected}
**Date:** {timestamp}
**Ship Verdict:** SHIP | CONDITIONAL SHIP | HOLD

## Feature Validation Summary

- **Result:** {PASS / FAIL / PARTIAL}
- **Journeys:** {passed}/{total} passed
- **Report:** `e2e-evidence/report.md`

## Production Readiness Summary

| Sub-Phase | Verdict | Blocking |
|-----------|---------|---------|
| 1. Code Quality | PASS/FAIL | No |
| 2. Security | PASS/FAIL | Yes |
| 3. Performance | PASS/FAIL | No |
| 4. Reliability | PASS/FAIL | No |
| 5. Observability | PASS/FAIL | No |
| 6. Documentation | PASS/FAIL | No |
| 7. Deployment | PASS/FAIL | Yes |

Full audit: `e2e-evidence/prod-audit/report.md`

## Blocking Issues

{List each blocking issue with evidence reference, or "None" if SHIP}

## Conditional Issues (non-blocking)

{List each non-blocking issue with evidence reference, or "None"}

## Deploy Decision

**Verdict: SHIP | CONDITIONAL SHIP | HOLD**

{If SHIP}
All criteria satisfied. Approved for production deployment.

{If CONDITIONAL SHIP}
Approved for deployment with the following acknowledged risks:
- {issue}: {risk description} — accepted by {stakeholder}

{If HOLD}
Deployment blocked. The following issues MUST be resolved first:
- {blocking issue}: {evidence reference}
  Remediation: {specific fix required}
```

### Step 6: Save and Print

Save to `e2e-evidence/ship-report.md`.

Print the one-line ship decision to console:

```
Ship decision: {SHIP|CONDITIONAL SHIP|HOLD} — {reason}. Full report: e2e-evidence/ship-report.md
```

## Outputs

- `e2e-evidence/prod-audit/` — Production readiness audit evidence
- `e2e-evidence/prod-audit/report.md` — Detailed prod audit report
- `e2e-evidence/ship-report.md` — Final ship decision report
- Console ship decision line

## Severity Rules

- **Any Security FAIL** = HOLD (no exceptions)
- **Any Deployment FAIL** = HOLD (no exceptions)
- **Feature FAIL with unresolved security journeys** = HOLD
- **All other FAILs** = document risk, stakeholder must accept before CONDITIONAL SHIP
- **All PASS** = SHIP immediately

## Integration with ValidationForge Pipeline

This workflow is the final gate in the 7-phase pipeline:

```
0. RESEARCH → 1. PLAN → 2. PREFLIGHT → 3. EXECUTE → 4. ANALYZE → 5. VERDICT → 6. SHIP (this)
```

Run this workflow via:
- `/validate` (full pipeline, runs ship automatically after verdict)
- `/validate-ci` (non-interactive; exits 1 if HOLD, 0 if SHIP or CONDITIONAL SHIP)

In CI mode, HOLD exits with code `1` to block the pipeline. CONDITIONAL SHIP exits `0` but prints all conditional issues to stderr.
