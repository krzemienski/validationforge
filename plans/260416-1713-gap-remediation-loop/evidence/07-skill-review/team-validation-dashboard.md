---
skill: team-validation-dashboard
reviewed_at: 2026-04-16T20:15:00Z
reviewer: R4
---

## Frontmatter Check
- **name:** team-validation-dashboard ✓
- **description:** "Aggregate team validation metrics: posture scores, coverage %, regressions, journey ownership. Identifies critical projects (score <60). Use for CI/CD reporting, team reviews, regression tracking." (168 chars) ✓
- **yaml_parses:** Yes ✓

## Trigger Realism
4 triggers: "team dashboard", "validation posture", "show team metrics", "which projects need attention"
**Realism:** 4/5 — Good coverage. Could add "team metrics" (common variant)

## Body-Description Alignment
**Verdict:** PASS — Aggregates metrics (Step 1). Posture scores/coverage/%/regressions in dashboard columns. Journey ownership in Step 4. Critical projects (<60) identified in Step 3.

## MCP Tool Existence
Bash scripts (collect-team-metrics.sh, team-dashboard.sh, assign-ownership.sh), jq ✓

## Example Invocation Proof
**Prompt:** "show team validation posture for all projects" (8 words, viable)

## Verdict
**Status:** PASS

3-step workflow. Dashboard columns well-defined (Project, Last Validated, Score, Grade, Coverage, Regressions). Color coding (Green 80+, Yellow 60-79, Red <60) provides urgency. Multiple output modes (terminal, markdown, JSON, HTML).

## Data Availability Note
**CONCERN:** coverage_pct, regression_count, journey_count are STUB FIELDS per documentation. Currently display as 0 until validate-benchmark enriches output.

## Notes
- Strong for engineering lead visibility
- Project registry (projects.json) requires manual setup
- Ownership assignment lightweight (JSON append)
- HTML option valuable for team dashboards
