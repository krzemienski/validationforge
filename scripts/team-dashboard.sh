#!/usr/bin/env bash
# Render the team validation dashboard: runs collect-team-metrics.sh, substitutes
# data into templates/team-dashboard-report.md, outputs a color-coded table to
# the terminal, and writes .vf/team/dashboard.md.
#
# Usage: team-dashboard.sh [OPTIONS]
#
# Options:
#   --help             Show this usage information
#   --json             Output raw snapshot JSON (machine-readable)
#   --html             Also write .vf/team/dashboard.html
#   --no-collect       Skip running collect-team-metrics.sh (use cached snapshot)
#   --team-dir <path>  Override default team registry directory (default: .vf/team)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Defaults
TEAM_DIR="$PROJECT_ROOT/.vf/team"
OUTPUT_JSON=0
OUTPUT_HTML=0
RUN_COLLECT=1

# ─── ANSI colour helpers ───────────────────────────────────────────────────────
RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
BOLD='\033[1m'
RESET='\033[0m'

# ─── Argument parsing ──────────────────────────────────────────────────────────
show_help() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Render the team validation dashboard showing aggregate posture across all
registered projects. Runs collect-team-metrics.sh first, then outputs a
colour-coded table to the terminal and writes .vf/team/dashboard.md.

Options:
  --json             Output raw snapshot JSON (machine-readable, skips terminal table)
  --html             Also write .vf/team/dashboard.html alongside dashboard.md
  --no-collect       Skip running collect-team-metrics.sh (use cached snapshot)
  --team-dir <path>  Override default team registry directory (default: .vf/team)
  -h, --help         Show this help message

Output files:
  .vf/team/dashboard.md    Markdown dashboard report
  .vf/team/dashboard.html  HTML report (only with --html)

Posture score colours:
  Green   80-100  Healthy
  Yellow  60-79   Needs attention
  Red     0-59    Critical
EOF
  exit 0
}

while [ $# -gt 0 ]; do
  case "$1" in
    --help|-h) show_help ;;
    --json)        OUTPUT_JSON=1 ; shift ;;
    --html)        OUTPUT_HTML=1 ; shift ;;
    --no-collect)  RUN_COLLECT=0 ; shift ;;
    --team-dir)
      TEAM_DIR="${2:?--team-dir requires a path argument}"
      shift 2
      ;;
    *)
      echo "[VF] ERROR: Unknown argument: $1" >&2
      echo "Run with --help for usage." >&2
      exit 1
      ;;
  esac
done

SNAPSHOT_FILE="$TEAM_DIR/snapshot.json"
OWNERSHIP_FILE="$TEAM_DIR/ownership.json"
DASHBOARD_MD="$TEAM_DIR/dashboard.md"
DASHBOARD_HTML="$TEAM_DIR/dashboard.html"
TEMPLATE_FILE="$PROJECT_ROOT/templates/team-dashboard-report.md"

# ─── Collect metrics ───────────────────────────────────────────────────────────
if [ "$RUN_COLLECT" -eq 1 ]; then
  # In JSON mode, suppress verbosity to stderr so stdout stays machine-readable
  if [ "$OUTPUT_JSON" -eq 1 ]; then
    bash "$SCRIPT_DIR/collect-team-metrics.sh" --team-dir "$TEAM_DIR" >/dev/null 2>&1 || true
  else
    bash "$SCRIPT_DIR/collect-team-metrics.sh" --team-dir "$TEAM_DIR" 2>&1 \
      | grep -v '^$' | sed 's/^/  /'
    echo ""
  fi
fi

# ─── Ensure snapshot exists ────────────────────────────────────────────────────
if [ ! -f "$SNAPSHOT_FILE" ]; then
  echo "[VF] ERROR: Snapshot not found at $SNAPSHOT_FILE" >&2
  echo "Run collect-team-metrics.sh first, or remove --no-collect." >&2
  exit 1
fi

# ─── JSON output mode ─────────────────────────────────────────────────────────
if [ "$OUTPUT_JSON" -eq 1 ]; then
  cat "$SNAPSHOT_FILE"
  exit 0
fi

# ─── Grade helper ──────────────────────────────────────────────────────────────
score_grade() {
  local score="$1"
  if   [ "$score" -ge 90 ]; then echo "A"
  elif [ "$score" -ge 80 ]; then echo "B"
  elif [ "$score" -ge 70 ]; then echo "C"
  elif [ "$score" -ge 60 ]; then echo "D"
  else echo "F"
  fi
}

score_colour() {
  local score="$1"
  if   [ "$score" -ge 80 ]; then printf '%s' "$GREEN"
  elif [ "$score" -ge 60 ]; then printf '%s' "$YELLOW"
  else printf '%s' "$RED"
  fi
}

# ─── Parse snapshot via Python3 ───────────────────────────────────────────────
# Produces tab-separated records: name TAB last_validated TAB score TAB coverage TAB regressions TAB journeys
PARSED_SNAPSHOT=$(python3 - "$SNAPSHOT_FILE" <<'PYEOF'
import json, sys

with open(sys.argv[1]) as f:
    data = json.load(f)

meta = {
    "team":     data.get("team", "unknown"),
    "generated_at": data.get("generated_at", ""),
    "total":    data.get("total_projects", 0),
    "avg":      data.get("avg_posture_score", 0),
}
print("META\t{team}\t{generated_at}\t{total}\t{avg}".format(**meta))

for p in data.get("projects", []):
    print("PROJECT\t{name}\t{last_validated}\t{posture_score}\t{coverage_pct}\t{regression_count}\t{journey_count}".format(
        name            = p.get("name", ""),
        last_validated  = p.get("last_validated", "never"),
        posture_score   = p.get("posture_score", 0),
        coverage_pct    = p.get("coverage_pct", 0),
        regression_count= p.get("regression_count", 0),
        journey_count   = p.get("journey_count", 0),
    ))
PYEOF
)

# Extract META line
team_name=$(echo "$PARSED_SNAPSHOT" | awk -F'\t' '$1=="META"{print $2}')
generated_at=$(echo "$PARSED_SNAPSHOT" | awk -F'\t' '$1=="META"{print $3}')
total_projects=$(echo "$PARSED_SNAPSHOT" | awk -F'\t' '$1=="META"{print $4}')
avg_score=$(echo "$PARSED_SNAPSHOT" | awk -F'\t' '$1=="META"{print $5}')

[ -z "${team_name:-}"     ] && team_name="unknown"
[ -z "${generated_at:-}"  ] && generated_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
[ -z "${total_projects:-}" ] && total_projects=0
[ -z "${avg_score:-}"     ] && avg_score=0

overall_grade=$(score_grade "$avg_score")

# ─── Parse ownership via Python3 ──────────────────────────────────────────────
PARSED_OWNERSHIP=""
if [ -f "$OWNERSHIP_FILE" ]; then
  PARSED_OWNERSHIP=$(python3 - "$OWNERSHIP_FILE" <<'PYEOF'
import json, sys

with open(sys.argv[1]) as f:
    data = json.load(f)

for a in data.get("assignments", []):
    print("ASSIGN\t{journey}\t{project}\t{owner}\t{assigned_at}".format(
        journey     = a.get("journey", ""),
        project     = a.get("project", ""),
        owner       = a.get("owner", ""),
        assigned_at = a.get("assigned_at", "")[:10],
    ))
PYEOF
  ) || PARSED_OWNERSHIP=""
fi

# ─── Terminal header ───────────────────────────────────────────────────────────
echo ""
printf "${BOLD}╔══════════════════════════════════════════════════════════╗${RESET}\n"
printf "${BOLD}║        ValidationForge — Team Validation Dashboard       ║${RESET}\n"
printf "${BOLD}╚══════════════════════════════════════════════════════════╝${RESET}\n"
echo ""
printf "  Team:        %s\n" "$team_name"
printf "  Generated:   %s\n" "$generated_at"
printf "  Projects:    %s\n" "$total_projects"
col=$(score_colour "$avg_score")
printf "  Avg Posture: ${col}%s%% (Grade: %s)${RESET}\n" "$avg_score" "$overall_grade"
echo ""

# ─── Per-project table (terminal) ──────────────────────────────────────────────
printf "${BOLD}%-24s %-22s %7s %8s %9s %8s${RESET}\n" \
  "Project" "Last Validated" "Score" "Grade" "Coverage" "Regress"
printf '%s\n' "────────────────────────────────────────────────────────────────────────────────"

PROJECT_TABLE_ROWS=""
TREND_LINES=""
RECOMMENDATION_LINES=""
project_row_count=0

while IFS="	" read -r rec_type p_name p_lv p_ps p_cp p_rc p_jc; do
  [ "$rec_type" != "PROJECT" ] && continue
  [ -z "$p_name" ] && continue
  p_ps="${p_ps:-0}"
  p_cp="${p_cp:-0}"
  p_rc="${p_rc:-0}"

  grade=$(score_grade "$p_ps")
  col=$(score_colour "$p_ps")

  short_name="${p_name:0:23}"
  short_lv="${p_lv:0:10}"
  [ "$p_lv" = "never" ] && short_lv="never"

  printf "${col}%-24s${RESET} %-22s %6s%% %8s %8s%% %8s\n" \
    "$short_name" "$short_lv" "$p_ps" "$grade" "$p_cp" "$p_rc"

  md_row="| $p_name | $p_lv | ${p_ps}% ($grade) | $p_rc | ${p_cp}% |"
  if [ -z "$PROJECT_TABLE_ROWS" ]; then
    PROJECT_TABLE_ROWS="$md_row"
  else
    PROJECT_TABLE_ROWS="${PROJECT_TABLE_ROWS}
$md_row"
  fi

  if [ "$p_ps" -lt 60 ]; then
    TREND_LINES="${TREND_LINES}
- **${p_name}** — Critical posture (${p_ps}%). Immediate attention required."
    RECOMMENDATION_LINES="${RECOMMENDATION_LINES}
- Run \`/validate\` on **${p_name}** to surface failing journeys."
  elif [ "$p_ps" -lt 80 ]; then
    TREND_LINES="${TREND_LINES}
- **${p_name}** — Posture needs improvement (${p_ps}%)."
    RECOMMENDATION_LINES="${RECOMMENDATION_LINES}
- Review failing journeys in **${p_name}** and assign owners."
  fi

  project_row_count=$((project_row_count + 1))
done <<< "$PARSED_SNAPSHOT"

printf '%s\n' "────────────────────────────────────────────────────────────────────────────────"
echo ""

# ─── Ownership table (terminal) ────────────────────────────────────────────────
OWNERSHIP_TABLE_ROWS=""
ownership_count=0

if [ -n "$PARSED_OWNERSHIP" ]; then
  while IFS="	" read -r rec_type o_journ o_proj o_owner o_at; do
    [ "$rec_type" != "ASSIGN" ] && continue
    [ -z "$o_journ" ] && continue
    if [ "$ownership_count" -eq 0 ]; then
      printf "${BOLD}Ownership Assignments${RESET}\n"
      printf "%-30s %-30s %-20s\n" "Journey" "Project" "Owner"
      printf '%s\n' "──────────────────────────────────────────────────────────────────────────────"
    fi
    printf "%-30s %-30s %-20s\n" "${o_journ:0:29}" "${o_proj:0:29}" "${o_owner:0:19}"
    md_own="| $o_journ | $o_owner | $o_proj | $o_at |"
    OWNERSHIP_TABLE_ROWS="${OWNERSHIP_TABLE_ROWS}${md_own}
"
    ownership_count=$((ownership_count + 1))
  done <<< "$PARSED_OWNERSHIP"
  [ "$ownership_count" -gt 0 ] && echo ""
fi

# ─── 0-project graceful message ────────────────────────────────────────────────
if [ "$project_row_count" -eq 0 ]; then
  printf "${YELLOW}No projects registered yet.${RESET}\n"
  printf "Add projects to %s and re-run.\n\n" "$TEAM_DIR/projects.json"
  PROJECT_TABLE_ROWS="| _(none registered)_ | — | — | — | — |"
fi

[ -z "$OWNERSHIP_TABLE_ROWS" ] && OWNERSHIP_TABLE_ROWS="| _(no assignments)_ | — | — | — |"
[ -z "$TREND_LINES" ]          && TREND_LINES="All projects are within healthy posture thresholds."
[ -z "$RECOMMENDATION_LINES" ] && RECOMMENDATION_LINES="No critical actions required at this time."

# ─── Write dashboard.md via Python3 template substitution ─────────────────────
mkdir -p "$TEAM_DIR"

if [ -f "$TEMPLATE_FILE" ]; then
  python3 - "$TEMPLATE_FILE" "$DASHBOARD_MD" \
      "$team_name" "$generated_at" "${avg_score}% (Grade: ${overall_grade})" \
      "$PROJECT_TABLE_ROWS" "$OWNERSHIP_TABLE_ROWS" "$TREND_LINES" "$RECOMMENDATION_LINES" \
  <<'PYEOF'
import sys

template_path = sys.argv[1]
output_path   = sys.argv[2]
team_name     = sys.argv[3]
report_date   = sys.argv[4]
overall_score = sys.argv[5]
project_table = sys.argv[6]
ownership_table = sys.argv[7]
trend_summary   = sys.argv[8]
recommendations = sys.argv[9]

with open(template_path) as f:
    content = f.read()

content = content.replace("{{TEAM_NAME}}",       team_name)
content = content.replace("{{REPORT_DATE}}",     report_date)
content = content.replace("{{OVERALL_SCORE}}",   overall_score)
content = content.replace("{{PROJECT_TABLE}}",   project_table)
content = content.replace("{{OWNERSHIP_TABLE}}", ownership_table)
content = content.replace("{{TREND_SUMMARY}}",   trend_summary)
content = content.replace("{{RECOMMENDATIONS}}", recommendations)

with open(output_path, "w") as f:
    f.write(content)
PYEOF
else
  # Fallback: write plain markdown without template
  cat > "$DASHBOARD_MD" <<ENDMD
# Team Validation Dashboard

**Team:** $team_name
**Report Date:** $generated_at
**Overall Posture:** ${avg_score}% (Grade: ${overall_grade})

## Project Summary

| Project | Last Validated | Posture Score | Regressions | Journey Coverage |
|---------|---------------|---------------|-------------|-----------------|
$PROJECT_TABLE_ROWS

## Ownership Assignments

| Journey | Owner | Project | Last Reviewed |
|---------|-------|---------|--------------|
$OWNERSHIP_TABLE_ROWS

## Trend Summary

$TREND_LINES

## Recommendations

$RECOMMENDATION_LINES
ENDMD
fi

printf "Dashboard written to %s\n" "$DASHBOARD_MD"

# ─── Optional HTML output ─────────────────────────────────────────────────────
if [ "$OUTPUT_HTML" -eq 1 ]; then
  md_content=$(cat "$DASHBOARD_MD")
  cat > "$DASHBOARD_HTML" <<ENDHTML
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Team Validation Dashboard — ${team_name}</title>
  <style>
    body { font-family: system-ui, sans-serif; max-width: 960px; margin: 2rem auto; padding: 0 1rem; }
    h1   { color: #1a1a2e; }
    table { border-collapse: collapse; width: 100%; margin: 1rem 0; }
    th, td { border: 1px solid #ccc; padding: .5rem .75rem; text-align: left; }
    th { background: #f0f0f5; }
    .healthy  { color: #2d6a4f; font-weight: bold; }
    .warning  { color: #b5451b; }
    .critical { color: #c0392b; font-weight: bold; }
    pre { background: #f8f8f8; padding: 1rem; border-radius: 4px; overflow-x: auto; }
  </style>
</head>
<body>
<h1>Team Validation Dashboard</h1>
<p><strong>Team:</strong> ${team_name}<br>
<strong>Generated:</strong> ${generated_at}<br>
<strong>Overall Posture:</strong> ${avg_score}% (Grade: ${overall_grade})</p>
<h2>Dashboard Report</h2>
<pre>$md_content</pre>
</body>
</html>
ENDHTML
  printf "HTML report written to %s\n" "$DASHBOARD_HTML"
fi
