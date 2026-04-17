# Coordinated Report Format

Loaded by `coordinated-validation` when the Verdict Writer produces `coordinated-report.md`. Follow this structure exactly.

```markdown
# Coordinated Validation Report

**Date:** YYYY-MM-DD
**Platforms detected:** {list}
**Waves executed:** {N}
**Overall verdict:** PASS | CONDITIONAL | FAIL | INCOMPLETE

## Dependency Graph

DB -> API -> Web
          -> iOS

## Wave Results

### Wave 0 — Independent

| Platform | Verdict | Evidence |
|----------|---------|---------|
| DB | PASS | e2e-evidence/db/report.md |
| Design | PASS | e2e-evidence/design/report.md |

### Wave 1 — API Layer

| Platform | Verdict | Evidence | Blocked By |
|----------|---------|---------|-----------|
| API | PASS | e2e-evidence/api/report.md | — |

### Wave 2 — Frontend Layer

| Platform | Verdict | Evidence | Blocked By |
|----------|---------|---------|-----------|
| Web | PASS | e2e-evidence/web/report.md | — |
| iOS | CONDITIONAL | e2e-evidence/ios/report.md | — |

## Cross-Platform Evidence Consistency

| Check | Result | Notes |
|-------|--------|-------|
| API user count matches Web display | PASS | API: 3, Web: 3 |
| API create -> DB record exists | PASS | Record id=42 confirmed |
| iOS API responses match API evidence | PASS | Same endpoint, same payload |

## Platform Summaries

### API (Wave 1) — PASS
{summary from api/report.md}

### Web (Wave 2) — PASS
{summary from web/report.md}

### iOS (Wave 2) — CONDITIONAL
{summary from ios/report.md}

## Issues Requiring Attention
{list of CONDITIONAL or FAIL items with evidence citations}

## Final Verdict Rationale
{explanation of overall verdict}
```
