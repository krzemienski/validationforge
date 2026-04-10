---
name: team-validation-dashboard
description: Aggregate team validation posture into a shared dashboard. Shows coverage, posture scores, regression trends, and ownership assignments across all registered projects.
---

# team-validation-dashboard

Aggregate team validation posture into a shared dashboard. Shows coverage, posture scores, regression trends, and ownership assignments across all registered projects.

## Trigger

- "team dashboard", "validation posture", "show team metrics"
- "which projects need attention", "who owns this journey"
- After running `/validate-team` or requesting an engineering lead summary

## Architecture

```
team-validation-dashboard
├── collect-team-metrics.sh  → .vf/team/snapshot.json
├── team-dashboard.sh        → .vf/team/dashboard.md + terminal table
└── assign-ownership.sh      → .vf/team/ownership.json
```

## Dashboard Columns

| Column | Source | Meaning |
|--------|--------|---------|
| Project | projects.json | Registered project name |
| Last Validated | .vf/benchmarks/ | ISO date of most recent benchmark |
| Posture Score | weighted_score | 0–100, color-coded by threshold |
| Grade | Derived | A/B/C/D/F from score |
| Coverage | coverage_pct | % of journeys with evidence |
| Regressions | regressions | Count of regressions found |

Score colors: Green (80–100), Yellow (60–79), Red (0–59).

## Workflow

### Step 1: Collect Metrics

Run the metrics collector to scan all registered projects:

```bash
bash scripts/collect-team-metrics.sh
```

Reads `.vf/team/projects.json`. Each entry requires `name` and `path`. If no registry
exists, the script creates a template. Add projects before re-running:

```json
{
  "team": "my-team",
  "projects": [
    { "name": "my-app", "path": "/path/to/my-app" }
  ]
}
```

Output: `.vf/team/snapshot.json` with per-project metrics.

### Step 2: Render Dashboard

```bash
bash scripts/team-dashboard.sh
```

Options:
- `--json` — raw snapshot JSON (machine-readable, skips terminal table)
- `--html` — also write `.vf/team/dashboard.html`
- `--no-collect` — skip metrics collection, use cached snapshot
- `--team-dir <path>` — override default `.vf/team` directory

Output: color-coded terminal table + `.vf/team/dashboard.md`

### Step 3: Identify Projects Needing Attention

After rendering, report projects by urgency:

**Critical (score < 60):** Run `/validate` immediately. Assign owners to failing journeys.

**Needs attention (score 60–79):** Review failing journeys. Assign owners. Schedule validation.

**Healthy (score ≥ 80):** No action required. Monitor trend at next benchmark cycle.

Present sorted output:

```markdown
## Projects Needing Attention

### Critical (< 60)
- **project-alpha** — Score: 42% (F). Last validated: 2026-03-01. 3 regressions.

### Needs Attention (60–79)
- **project-beta** — Score: 68% (D). Last validated: 2026-03-28. 1 regression.

### Healthy (≥ 80)
- **project-gamma** — Score: 91% (A). Last validated: 2026-04-09.
```

### Step 4: Assign Ownership

Use `assign-ownership.sh` to record who is responsible for each journey:

```bash
# Assign a journey to a team member
bash scripts/assign-ownership.sh --project my-app --journey login-flow --owner alice

# List all assignments
bash scripts/assign-ownership.sh --list

# List assignments for one project
bash scripts/assign-ownership.sh --list-project my-app

# Remove an assignment
bash scripts/assign-ownership.sh --remove --project my-app --journey login-flow
```

Ownership is stored in `.vf/team/ownership.json` and rendered in the dashboard table.

## Data Formats

`.vf/team/snapshot.json` (written by `collect-team-metrics.sh`):

```json
{
  "generated_at": "2026-04-10T12:00:00Z",
  "team": "engineering",
  "total_projects": 3,
  "avg_posture_score": 74,
  "projects": [
    { "name": "project-alpha", "path": "/path/to/...", "last_validated": "2026-03-01T09:00:00Z",
      "posture_score": 42, "coverage_pct": 35, "regression_count": 3, "journey_count": 8 }
  ]
}
```

`.vf/team/ownership.json` (written by `assign-ownership.sh`):

```json
{
  "assignments": [
    { "project": "project-alpha", "journey": "login-flow", "owner": "alice",
      "assigned_at": "2026-04-10T12:00:00Z" }
  ]
}
```

## Quick Reference

| Goal | Command |
|------|---------|
| Full refresh + render | `bash scripts/team-dashboard.sh` |
| CI/machine output | `bash scripts/team-dashboard.sh --json` |
| Cached render only | `bash scripts/team-dashboard.sh --no-collect` |
| Assign journey owner | `bash scripts/assign-ownership.sh --project P --journey J --owner alice` |
| View all assignments | `bash scripts/assign-ownership.sh --list` |
| Shared team registry | `bash scripts/team-dashboard.sh --team-dir /shared/.vf/team` |
