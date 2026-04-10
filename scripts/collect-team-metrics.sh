#!/usr/bin/env bash
# Collect team validation metrics across all registered projects.
# Scans .vf/team/projects.json to find registered projects, reads each project's
# .vf/benchmarks/ data, and writes an aggregated snapshot to .vf/team/snapshot.json.
#
# Usage: collect-team-metrics.sh [--help] [--team-dir <path>]
#
# Options:
#   --help             Show this usage information
#   --team-dir <path>  Override default team registry directory (default: .vf/team)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Defaults
TEAM_DIR="$PROJECT_ROOT/.vf/team"

# ─── Argument parsing ──────────────────────────────────────────────────────────
show_help() {
  cat <<EOF
Usage: collect-team-metrics.sh [--help] [--team-dir <path>]

Scans .vf/team/projects.json to find registered projects, reads each project's
.vf/benchmarks/ data, and writes an aggregated snapshot to .vf/team/snapshot.json.

Options:
  --help             Show this usage information
  --team-dir <path>  Override default team registry directory (default: .vf/team)

Output:
  .vf/team/snapshot.json  Aggregated metrics for all registered projects

Snapshot format:
  {
    "generated_at": "<ISO8601>",
    "total_projects": N,
    "avg_posture_score": N,
    "projects": [
      {
        "name": "<project name>",
        "path": "<absolute path>",
        "last_validated": "<ISO8601 or never>",
        "posture_score": N,
        "coverage_pct": N,
        "regression_count": N,
        "journey_count": N
      }
    ]
  }
EOF
  exit 0
}

while [ $# -gt 0 ]; do
  case "$1" in
    --help|-h) show_help ;;
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

# ─── Registry bootstrap ────────────────────────────────────────────────────────
mkdir -p "$TEAM_DIR"

PROJECTS_FILE="$TEAM_DIR/projects.json"
SNAPSHOT_FILE="$TEAM_DIR/snapshot.json"

if [ ! -f "$PROJECTS_FILE" ]; then
  echo "[VF] No projects.json found — creating registry template at $PROJECTS_FILE"
  cat > "$PROJECTS_FILE" <<'ENDJSON'
{
  "team": "my-team",
  "projects": []
}
ENDJSON
  echo "[VF] Edit $PROJECTS_FILE to register your projects, then re-run this script."
  generated_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  cat > "$SNAPSHOT_FILE" <<ENDJSON
{
  "generated_at": "$generated_at",
  "total_projects": 0,
  "avg_posture_score": 0,
  "projects": []
}
ENDJSON
  echo "[VF] Empty snapshot written to $SNAPSHOT_FILE"
  exit 0
fi

# ─── Parse projects registry ───────────────────────────────────────────────────
# Extract team name (optional, falls back to "unknown")
team_name=$(grep -o '"team"[[:space:]]*:[[:space:]]*"[^"]*"' "$PROJECTS_FILE" 2>/dev/null \
  | sed 's/.*"team"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' \
  | head -1) || true
[ -z "${team_name:-}" ] && team_name="unknown"

# Use awk to extract name|path pairs from the projects array.
# Each project object is expected to have "name" and "path" keys.
# Uses POSIX awk (2-arg match + substr/index) — compatible with macOS awk.
# Output format per line: name<TAB>path
PAIRS_FILE="$TEAM_DIR/.pairs.tmp"
awk '
BEGIN { name=""; path="" }
{
  line = $0

  # Extract "name": "value"
  if (match(line, /"name"[[:space:]]*:[[:space:]]*"/) > 0) {
    rest = substr(line, RSTART + RLENGTH)
    end = index(rest, "\"")
    if (end > 0) name = substr(rest, 1, end - 1)
  }

  # Extract "path": "value" — once found, emit the pair and reset
  if (match(line, /"path"[[:space:]]*:[[:space:]]*"/) > 0) {
    rest = substr(line, RSTART + RLENGTH)
    end = index(rest, "\"")
    if (end > 0) {
      path = substr(rest, 1, end - 1)
      print name "\t" path
      name = ""
      path = ""
    }
  }
}
' "$PROJECTS_FILE" > "$PAIRS_FILE" 2>/dev/null || true

total_projects=$(wc -l < "$PAIRS_FILE" | tr -d ' ')

echo "=== ValidationForge Team Metrics Collector ==="
echo "Team: $team_name"
echo "Registry: $PROJECTS_FILE"
echo "Projects found: $total_projects"
echo ""

# ─── Collect per-project metrics ───────────────────────────────────────────────
projects_json=""
total_score=0
project_count=0

while IFS="	" read -r proj_name proj_path; do
  [ -z "$proj_path" ] && continue

  # Resolve relative paths against PROJECT_ROOT
  case "$proj_path" in
    /*) : ;;
    *)  proj_path="$PROJECT_ROOT/$proj_path" ;;
  esac

  # Derive name from path if not provided
  [ -z "$proj_name" ] && proj_name="$(basename "$proj_path")"

  echo "--- Scanning: $proj_name ($proj_path) ---"

  benchmarks_dir="$proj_path/.vf/benchmarks"

  # Defaults for projects with no validation data
  last_validated="never"
  posture_score=0
  coverage_pct=0
  regression_count=0
  journey_count=0

  if [ ! -d "$benchmarks_dir" ]; then
    echo "  Status: never validated (no .vf/benchmarks/ directory)"
  else
    latest_benchmark=$(ls -t "$benchmarks_dir"/*.json 2>/dev/null | head -1) || true

    if [ -z "${latest_benchmark:-}" ]; then
      echo "  Status: never validated (empty .vf/benchmarks/ directory)"
    else
      echo "  Latest benchmark: $(basename "$latest_benchmark")"

      # Extract fields from the benchmark JSON
      last_validated=$(grep -o '"timestamp"[[:space:]]*:[[:space:]]*"[^"]*"' "$latest_benchmark" 2>/dev/null \
        | sed 's/"timestamp"[[:space:]]*:[[:space:]]*"\([^"]*\)"/\1/' \
        | head -1) || true
      [ -z "${last_validated:-}" ] && last_validated="unknown"

      posture_score=$(grep -o '"weighted_score"[[:space:]]*:[[:space:]]*[0-9]*' "$latest_benchmark" 2>/dev/null \
        | sed 's/"weighted_score"[[:space:]]*:[[:space:]]*\([0-9]*\)/\1/' \
        | head -1) || true
      [ -z "${posture_score:-}" ] && posture_score=0

      coverage_pct=$(grep -o '"coverage"[[:space:]]*:[[:space:]]*[0-9]*' "$latest_benchmark" 2>/dev/null \
        | sed 's/"coverage"[[:space:]]*:[[:space:]]*\([0-9]*\)/\1/' \
        | head -1) || true
      [ -z "${coverage_pct:-}" ] && coverage_pct=0

      regression_count=$(grep -o '"regressions"[[:space:]]*:[[:space:]]*[0-9]*' "$latest_benchmark" 2>/dev/null \
        | sed 's/"regressions"[[:space:]]*:[[:space:]]*\([0-9]*\)/\1/' \
        | head -1) || true
      [ -z "${regression_count:-}" ] && regression_count=0

      journey_count=$(grep -o '"journey_count"[[:space:]]*:[[:space:]]*[0-9]*' "$latest_benchmark" 2>/dev/null \
        | sed 's/"journey_count"[[:space:]]*:[[:space:]]*\([0-9]*\)/\1/' \
        | head -1) || true
      [ -z "${journey_count:-}" ] && journey_count=0

      echo "  Last validated: $last_validated"
      echo "  Posture score:  $posture_score"
      echo "  Coverage:       ${coverage_pct}%"
      echo "  Regressions:    $regression_count"
      echo "  Journeys:       $journey_count"
    fi
  fi

  total_score=$((total_score + posture_score))
  project_count=$((project_count + 1))

  entry="    {
      \"name\": \"$proj_name\",
      \"path\": \"$proj_path\",
      \"last_validated\": \"$last_validated\",
      \"posture_score\": $posture_score,
      \"coverage_pct\": $coverage_pct,
      \"regression_count\": $regression_count,
      \"journey_count\": $journey_count
    }"

  if [ -z "$projects_json" ]; then
    projects_json="$entry"
  else
    projects_json="${projects_json},
${entry}"
  fi

  echo ""
done < "$PAIRS_FILE"

rm -f "$PAIRS_FILE"

# ─── Compute aggregate ─────────────────────────────────────────────────────────
avg_posture_score=0
if [ "$project_count" -gt 0 ]; then
  avg_posture_score=$(( total_score / project_count ))
fi

echo "=== AGGREGATE ==="
echo "Total projects:    $total_projects"
echo "Avg posture score: $avg_posture_score"

# ─── Write snapshot ────────────────────────────────────────────────────────────
generated_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
cat > "$SNAPSHOT_FILE" <<ENDJSON
{
  "generated_at": "$generated_at",
  "team": "$team_name",
  "total_projects": $total_projects,
  "avg_posture_score": $avg_posture_score,
  "projects": [
$projects_json
  ]
}
ENDJSON

echo ""
echo "Snapshot written to $SNAPSHOT_FILE"
