---
name: full-functional-audit
description: "Use for read-only health checks of a project where you want to know 'what's the real state right now' WITHOUT fixing anything along the way. Exercises every discoverable feature through the real UI, captures evidence, and classifies each finding by severity (CRITICAL/HIGH/MEDIUM/LOW/INFO). Produces e2e-evidence/audit-report.md with prioritized recommendations but doesn't apply fixes — that's for follow-up work. Reach for it on phrases like 'audit the app', 'pre-release audit', 'compliance check', 'health report', 'what's the current state', or before a major refactor when you want a baseline that documents every existing issue."
triggers:
  - "audit project"
  - "project audit"
  - "pre-release audit"
  - "compliance audit"
  - "health check report"
  - "document existing state"
  - "catalog known issues"
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

## Phase 2: Feature Inventory Techniques

Most audits fail here — not because the auditor can't execute features, but because they never catalog them all. Use source-based discovery so you don't miss anything that's real; use journey grouping so the audit scales when there are more than 20 features.

### Source-based discovery (pick what matches your stack)

```sh
# Next.js / React Router — extract routes from the filesystem
find app pages src/pages src/app -name 'page.*' -o -name 'route.*' 2>/dev/null \
  | sort | tee e2e-evidence/audit/routes.txt

# Flask / Django — extract route handlers
grep -rE '@app\.route|path\(|url\(|router\.(get|post|put|delete)' \
  --include='*.py' . | tee e2e-evidence/audit/routes.txt

# Express / Fastify — find middleware + route declarations
grep -rnE '\.(get|post|put|delete|patch)\(' --include='*.ts' --include='*.js' src/ \
  | tee e2e-evidence/audit/routes.txt

# OpenAPI / Swagger — enumerate documented endpoints
jq -r '.paths | keys[]' openapi.json 2>/dev/null \
  || yq '.paths | keys' openapi.yaml | tee e2e-evidence/audit/routes.txt

# iOS / SwiftUI — view structs (coarse but useful)
grep -rnE 'struct [A-Z][A-Za-z0-9]*View' Sources/ | tee e2e-evidence/audit/views.txt

# CLI — subcommands from argparse / cobra / commander
grep -rnE 'add_parser|AddCommand|\.command\(' . | tee e2e-evidence/audit/subcommands.txt
```

Every feature file a user can reach is a candidate feature. Dedupe, then promote to the numbered feature list in the next step.

### Journey grouping (scales past 20 features)

When the raw count exceeds ~20, auditing each individually bloats the report and loses signal. Group related features into user journeys:

```
Journey A — Authentication (login, signup, forgot password, logout, session timeout)
Journey B — Product discovery (home, search, category, filters, detail)
Journey C — Checkout (cart, address, payment, review, confirmation, receipt email)
Journey D — Account (profile, orders, saved items, notifications)
Journey E — Admin (dashboard, users, content, reports, settings)
```

Audit each journey end-to-end. A broken step *within* a journey (e.g. checkout payment fails) is a HIGH/CRITICAL even if every surrounding feature works — the journey is what the user cares about.

### Target-feature sizing

Aim for ~5–15 top-level journeys for any non-trivial app. Fewer than 5 usually means you missed admin/settings/error-recovery paths; more than 15 means you're auditing at the wrong granularity — collapse adjacent features into a single journey entry instead.

## Phase 3: Evidence Capture

Exercise each feature from the Phase 2 inventory against the real running system and record what you observe.

- Exercise EVERY feature, not just the happy path — capture both success and failure states
- Use platform-specific capture commands (see **Concrete capture commands by platform** below)
- Name evidence files `e2e-evidence/audit/feature-{NN}-{name}.{ext}` to match the numbered inventory
- Record error messages verbatim and note response times >2s (UI) / >500ms (API)
- If a feature can't be reached, that IS the finding — record it as UNKNOWN, never guess

See **Evidence Capture Rules** below for the full rule set.

## Phase 4: Classification

Rate each captured finding using the severity matrix — never leave a finding unclassified.

- Use the 5-level severity scale: CRITICAL / HIGH / MEDIUM / LOW / INFO
- Security issues and data loss are ALWAYS CRITICAL, no exceptions
- When in doubt, classify UP — it's safer to over-report than miss a release-blocker
- "Works but looks wrong" is at least MEDIUM, never LOW

See **Severity Matrix** above for full definitions and classification rules.

## Phase 5: Report

Synthesize all classified findings into `e2e-evidence/audit-report.md` — stakeholders read this first.

- Lead with a 1-paragraph Executive Summary (features audited, PASS/FAIL counts, overall health)
- Include a Findings Summary severity count table and per-feature Findings list with evidence paths
- Order Priority Recommendations by impact — CRITICAL first
- Include an Evidence Index mapping every evidence file to its description
- Use `references/audit-report-template.md` as the canonical structure

See **Audit Report Structure** below for the full section list.

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

### Concrete capture commands by platform

```sh
# Web (Chrome DevTools or Playwright MCP)
take_snapshot && take_screenshot filePath=e2e-evidence/audit/feature-01-home.png

# API (curl with status + headers + body captured)
curl -sS -D - -w '\nHTTP %{http_code}  %{time_total}s\n' \
  https://api.local/v1/users | tee e2e-evidence/audit/feature-02-users-api.txt

# CLI (stdout + stderr + exit code)
{ mytool --flag arg 2>&1; echo "exit=$?"; } | tee e2e-evidence/audit/feature-03-mytool.txt

# iOS simulator (screenshot of current state)
xcrun simctl io booted screenshot e2e-evidence/audit/feature-04-ios-home.png
```

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
