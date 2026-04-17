---
name: full-functional-audit
description: "Audit project health without code changes: exercise all features, capture evidence, classify findings by severity (CRITICAL/HIGH/MEDIUM/LOW/INFO). Pre-release gates, compliance, baselines."
context_priority: standard
---

# Full Functional Audit

## Scope

Applies to any project requiring a comprehensive health check. Performs a read-only
assessment — NEVER modifies source code. Produces `e2e-evidence/audit-report.md` with
severity-classified findings and prioritized recommendations.

An audit answers one question: **"What is the real state of this application right now?"**

## The Audit Rule

**Observe, document, classify — but NEVER modify code.** Changing source code during an
audit invalidates every finding captured before the change.

## 5-Phase Process

| Phase | Action | Output |
|-------|--------|--------|
| 1. Platform Detection | Identify project type from signals | Platform type + validation approach |
| 2. Feature Inventory | Map every user-facing feature before executing | Numbered feature list with expected behavior |
| 3. Evidence Capture | Exercise each feature, capture screenshots/responses/output | `e2e-evidence/audit/` directory |
| 4. Classification | Rate every finding using severity matrix | Classified findings list |
| 5. Report | Produce structured audit report | `e2e-evidence/audit-report.md` |

## Severity Matrix

| Severity | Definition | Action |
|----------|-----------|--------|
| **CRITICAL** | Completely broken, data loss, security vulnerability | Immediate fix before release |
| **HIGH** | Partially broken, workaround exists but not obvious | Fix before release |
| **MEDIUM** | Works but notable usability issues | Fix in current cycle |
| **LOW** | Minor cosmetic/UX, no functional impact | Fix when convenient |
| **INFO** | Observation worth noting, not a defect | Document for awareness |

**Classification rules:** When in doubt, classify UP. Security = always CRITICAL.
Data loss = always CRITICAL. "Works but looks wrong" = at least MEDIUM.

## Evidence Capture Rules

- Exercise EVERY feature, not just ones you expect to work
- Capture BOTH success and failure states
- Include error messages verbatim — do not paraphrase
- Record response times when notably slow (>2s UI, >500ms API)
- If a feature cannot be reached (dead link, missing route), that IS the finding
- Name evidence: `e2e-evidence/audit/feature-{NN}-{name}.{ext}`

## Audit Report Structure

See `references/audit-report-template.md` for the full template. Key sections:

1. **Executive Summary** — 1 paragraph: features audited, pass/fail counts, overall health
2. **Findings Summary** — Severity count table + status count table
3. **Findings by Feature** — Per-feature: status, severity, evidence path, expected vs observed
4. **Priority Recommendations** — Ordered by impact (CRITICAL first)
5. **Evidence Index** — Table mapping all evidence files to descriptions

## Use Cases

| Scenario | Scope |
|----------|-------|
| Pre-Release Gate | Full audit of all features |
| Compliance Review | Targeted audit of specific areas |
| Project Handoff | Full audit with extra documentation |
| Post-Incident | Targeted audit of affected systems |
| Baseline Assessment | Full audit to establish current state |

## Rules

1. **NEVER modify source code** during an audit
2. **NEVER suggest mocks or test files** as remediation
3. **ALWAYS capture evidence** for every finding — no evidence, no finding
4. **ALWAYS audit every discoverable feature** — selective audits miss critical issues
5. **ALWAYS record UNKNOWN** for features you cannot reach — never guess
6. **ALWAYS include executive summary** — stakeholders read this first

## Security Policy

Audit reports may contain sensitive findings (security vulnerabilities, exposed endpoints).
Store reports in `e2e-evidence/` (gitignored). Never commit audit reports with security
findings to public repositories without redaction.

## Related Skills

- **functional-validation** — Active validation of changes (audit is passive assessment)
- **baseline-quality-assessment** — Lighter initial assessment (audit is comprehensive)
- **verification-before-completion** — Uses audit findings as completion evidence
- **e2e-validate** — End-to-end workflow (audit is one mode within e2e-validate)

## References

- `references/audit-report-template.md` — Full markdown template for the audit report
- `references/severity-classification-guide.md` — Extended examples and edge cases per severity level
