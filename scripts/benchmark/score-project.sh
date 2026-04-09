#!/usr/bin/env bash
# Score a project's validation posture across 4 dimensions:
#   Coverage (35%), Evidence Quality (30%), Enforcement (25%), Speed (10%)
# Usage: bash scripts/benchmark/score-project.sh [PROJECT_DIR]
# Outputs a markdown report to stdout and JSON to PROJECT_DIR/.vf/benchmarks/.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJ_DIR="$(cd "${1:-.}" && pwd)"

echo "=== ValidationForge 4-Dimension Benchmark Scorer ==="
echo "Project: $PROJ_DIR"
echo ""

# ---------------------------------------------------------------------------
# 1. ENFORCEMENT (max 100)
# ---------------------------------------------------------------------------
enforcement=0

# +20: hooks/hooks.json or .claude/hooks/ exists
if [ -f "$PROJ_DIR/hooks/hooks.json" ] || [ -d "$PROJ_DIR/.claude/hooks" ]; then
  enforcement=$((enforcement + 20))
  echo "[enforcement] +20: hooks infrastructure found"
else
  echo "[enforcement]  +0: no hooks/hooks.json or .claude/hooks/"
fi

# +20: no *.test.* or *.spec.* files found in src/ or lib/
test_files_found=0
for scan_dir in "$PROJ_DIR/src" "$PROJ_DIR/lib"; do
  if [ -d "$scan_dir" ]; then
    count=$(find "$scan_dir" -type f \( -name "*.test.*" -o -name "*.spec.*" \) 2>/dev/null | wc -l | tr -d ' ')
    test_files_found=$((test_files_found + count))
  fi
done
if [ "$test_files_found" -eq 0 ]; then
  enforcement=$((enforcement + 20))
  echo "[enforcement] +20: no test/spec files in src/ or lib/"
else
  echo "[enforcement]  +0: $test_files_found test/spec file(s) found in src/ or lib/"
fi

# +20: no jest.mock/sinon/.mock(/.stub( patterns in src/
mock_patterns_found=0
if [ -d "$PROJ_DIR/src" ]; then
  mock_patterns_found=$(grep -rl --include="*.js" --include="*.ts" --include="*.jsx" --include="*.tsx" \
    -e "jest\.mock" -e "sinon\." -e "\.mock(" -e "\.stub(" \
    "$PROJ_DIR/src" 2>/dev/null | wc -l | tr -d ' ')
fi
if [ "$mock_patterns_found" -eq 0 ]; then
  enforcement=$((enforcement + 20))
  echo "[enforcement] +20: no mock/stub patterns in src/"
else
  echo "[enforcement]  +0: $mock_patterns_found file(s) with mock/stub patterns in src/"
fi

# +20: .claude/rules/ has *.md files
rules_count=0
if [ -d "$PROJ_DIR/.claude/rules" ]; then
  rules_count=$(find "$PROJ_DIR/.claude/rules" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
fi
if [ "$rules_count" -gt 0 ]; then
  enforcement=$((enforcement + 20))
  echo "[enforcement] +20: .claude/rules/ has $rules_count markdown rule file(s)"
else
  echo "[enforcement]  +0: no markdown files in .claude/rules/"
fi

# +10: e2e-evidence/ directory exists
if [ -d "$PROJ_DIR/e2e-evidence" ]; then
  enforcement=$((enforcement + 10))
  echo "[enforcement] +10: e2e-evidence/ directory exists"
else
  echo "[enforcement]  +0: no e2e-evidence/ directory"
fi

# +10: .vf/config.json exists
if [ -f "$PROJ_DIR/.vf/config.json" ]; then
  enforcement=$((enforcement + 10))
  echo "[enforcement] +10: .vf/config.json exists"
else
  echo "[enforcement]  +0: no .vf/config.json"
fi

echo ""
echo "Enforcement score: $enforcement / 100"

# ---------------------------------------------------------------------------
# 2. EVIDENCE QUALITY (max 100)
# ---------------------------------------------------------------------------
echo ""
evidence_quality=0

if [ ! -d "$PROJ_DIR/e2e-evidence" ]; then
  echo "[evidence]  score 0: e2e-evidence/ directory does not exist"
else
  # Count total files (excluding .gitkeep)
  total_files=$(find "$PROJ_DIR/e2e-evidence" -type f ! -name ".gitkeep" 2>/dev/null | wc -l | tr -d ' ')

  # Count non-empty files (>10 bytes)
  non_empty=0
  while IFS= read -r -d '' f; do
    size=$(wc -c < "$f" 2>/dev/null || echo 0)
    if [ "$size" -gt 10 ]; then
      non_empty=$((non_empty + 1))
    fi
  done < <(find "$PROJ_DIR/e2e-evidence" -type f ! -name ".gitkeep" -print0 2>/dev/null)

  # Count verdict/report files
  verdict_count=$(find "$PROJ_DIR/e2e-evidence" -type f \( -name "*VERDICT*" -o -name "report.md" \) 2>/dev/null | wc -l | tr -d ' ')

  echo "[evidence] total files: $total_files"
  echo "[evidence] non-empty (>10 bytes): $non_empty"
  echo "[evidence] verdict/report files: $verdict_count"

  if [ "$total_files" -gt 0 ]; then
    # quality = (non_empty/total)*70 + (verdicts>0 ? 30 : 0)
    quality_base=$(( non_empty * 70 / total_files ))
    verdict_bonus=0
    [ "$verdict_count" -gt 0 ] && verdict_bonus=30
    evidence_quality=$(( quality_base + verdict_bonus ))
  fi
fi

echo "Evidence Quality score: $evidence_quality / 100"

# ---------------------------------------------------------------------------
# 3. COVERAGE (max 100)
# ---------------------------------------------------------------------------
echo ""
coverage=0

# Count subdirectories in e2e-evidence/ (each subdir = one journey)
journey_count=0
if [ -d "$PROJ_DIR/e2e-evidence" ]; then
  journey_count=$(find "$PROJ_DIR/e2e-evidence" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
fi

echo "[coverage] evidence journey subdirs: $journey_count"

if [ "$journey_count" -eq 0 ]; then
  coverage=0
elif [ "$journey_count" -le 2 ]; then
  coverage=50
elif [ "$journey_count" -le 4 ]; then
  coverage=70
else
  coverage=85
fi

# +10 if plans/ dir has *.md files
plans_count=0
if [ -d "$PROJ_DIR/plans" ]; then
  plans_count=$(find "$PROJ_DIR/plans" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
fi
if [ "$plans_count" -gt 0 ]; then
  coverage=$((coverage + 10))
  echo "[coverage] +10: plans/ has $plans_count markdown plan file(s)"
else
  echo "[coverage]  +0: no markdown files in plans/"
fi

# Cap at 100
[ "$coverage" -gt 100 ] && coverage=100

echo "Coverage score: $coverage / 100"

# ---------------------------------------------------------------------------
# 4. SPEED (max 100)
# ---------------------------------------------------------------------------
echo ""
speed=80  # default

if [ -f "$PROJ_DIR/.vf/last-run.json" ]; then
  duration=$(grep -o '"duration_seconds":[0-9]*' "$PROJ_DIR/.vf/last-run.json" 2>/dev/null | cut -d: -f2 || echo "")
  if [ -n "$duration" ]; then
    echo "[speed] last run duration: ${duration}s"
    if [ "$duration" -lt 120 ]; then
      speed=100
    elif [ "$duration" -lt 300 ]; then
      speed=80
    elif [ "$duration" -lt 600 ]; then
      speed=60
    else
      speed=40
    fi
  else
    echo "[speed] .vf/last-run.json found but no duration_seconds key — using default"
  fi
else
  echo "[speed] no .vf/last-run.json — using default speed score"
fi

echo "Speed score: $speed / 100"

# ---------------------------------------------------------------------------
# 5. AGGREGATE
# ---------------------------------------------------------------------------
echo ""
aggregate=$(( (coverage * 35 + evidence_quality * 30 + enforcement * 25 + speed * 10) / 100 ))

grade="F"
[ "$aggregate" -ge 60 ] && grade="D"
[ "$aggregate" -ge 70 ] && grade="C"
[ "$aggregate" -ge 80 ] && grade="B"
[ "$aggregate" -ge 90 ] && grade="A"

echo "=== BENCHMARK RESULTS ==="
echo ""
echo "| Dimension        | Weight | Score |"
echo "|------------------|--------|-------|"
echo "| Coverage         |   35%  |  $coverage  |"
echo "| Evidence Quality |   30%  |  $evidence_quality  |"
echo "| Enforcement      |   25%  |  $enforcement  |"
echo "| Speed            |   10%  |  $speed  |"
echo ""
echo "Aggregate: $aggregate / 100"
echo "Grade: $grade"

# ---------------------------------------------------------------------------
# 6. Write JSON to .vf/benchmarks/
# ---------------------------------------------------------------------------
benchmark_dir="$PROJ_DIR/.vf/benchmarks"
mkdir -p "$benchmark_dir"
benchmark_file="$benchmark_dir/benchmark-$(date +%Y-%m-%d).json"

cat > "$benchmark_file" << ENDJSON
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "project_dir": "$PROJ_DIR",
  "dimensions": {
    "coverage": {
      "score": $coverage,
      "weight": 35,
      "journey_count": $journey_count,
      "plans_found": $plans_count
    },
    "evidence_quality": {
      "score": $evidence_quality,
      "weight": 30
    },
    "enforcement": {
      "score": $enforcement,
      "weight": 25
    },
    "speed": {
      "score": $speed,
      "weight": 10
    }
  },
  "aggregate": $aggregate,
  "grade": "$grade"
}
ENDJSON

echo ""
echo "Benchmark saved to $benchmark_file"

# ---------------------------------------------------------------------------
# 7. Final summary JSON line
# ---------------------------------------------------------------------------
echo '{"coverage":'$coverage',"evidence":'$evidence_quality',"enforcement":'$enforcement',"speed":'$speed',"aggregate":'$aggregate',"grade":"'$grade'"}'
