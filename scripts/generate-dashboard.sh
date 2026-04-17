#!/usr/bin/env bash
# Generate the ValidationForge Evidence Summary Dashboard (markdown + HTML).
#
# Usage:
#   ./generate-dashboard.sh [--evidence-dir DIR] [--project-name NAME]
#                           [--format md|html|both] [--no-history]
#
# Defaults:
#   --evidence-dir  e2e-evidence
#   --project-name  basename of current working directory
#   --format        both
#   history archival is ON by default; --no-history disables it
#
# Exit codes:
#   0  success
#   1  missing evidence dir / usage error
#   2  template missing
#
# Security: rejects absolute paths and ".." traversal in --evidence-dir,
# mirroring scripts/evidence-collector.sh.

set -euo pipefail

# ------------------------------------------------------------------
# Paths
# ------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TMPL_MD="$PROJECT_ROOT/templates/dashboard.md.tmpl"
TMPL_HTML="$PROJECT_ROOT/templates/dashboard.html.tmpl"

# ------------------------------------------------------------------
# Defaults & argument parsing
# ------------------------------------------------------------------
EVIDENCE_DIR="e2e-evidence"
PROJECT_NAME="$(basename "$(pwd)")"
FORMAT="both"
NO_HISTORY=0

usage() {
  cat <<'USAGE'
Usage: generate-dashboard.sh [options]
  --evidence-dir DIR     Evidence directory (default: e2e-evidence, must be relative, no ..)
  --project-name NAME    Project name for the dashboard header (default: basename of cwd)
  --format md|html|both  Output format (default: both)
  --no-history           Skip history archival
  -h, --help             Show this help and exit
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    --evidence-dir)      EVIDENCE_DIR="${2:?--evidence-dir requires a value}"; shift 2 ;;
    --evidence-dir=*)    EVIDENCE_DIR="${1#*=}"; shift ;;
    --project-name)      PROJECT_NAME="${2:?--project-name requires a value}"; shift 2 ;;
    --project-name=*)    PROJECT_NAME="${1#*=}"; shift ;;
    --format)            FORMAT="${2:?--format requires a value}"; shift 2 ;;
    --format=*)          FORMAT="${1#*=}"; shift ;;
    --no-history)        NO_HISTORY=1; shift ;;
    -h|--help)           usage; exit 0 ;;
    *)
      echo "[VF] ERROR: Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

# ------------------------------------------------------------------
# Input validation
# ------------------------------------------------------------------
# Reject absolute paths and ".." traversal (mirrors evidence-collector.sh)
case "$EVIDENCE_DIR" in
  /*)
    echo "[VF] ERROR: Evidence dir must be a relative path. Got: $EVIDENCE_DIR" >&2
    exit 1
    ;;
  *../*|..|../*|*/..)
    echo "[VF] ERROR: Evidence dir must not contain traversal (..). Got: $EVIDENCE_DIR" >&2
    exit 1
    ;;
esac

case "$FORMAT" in
  md|html|both) ;;
  *)
    echo "[VF] ERROR: --format must be md, html, or both. Got: $FORMAT" >&2
    exit 1
    ;;
esac

if [ ! -d "$EVIDENCE_DIR" ]; then
  echo "[VF] ERROR: Evidence directory not found: $EVIDENCE_DIR" >&2
  exit 1
fi

if [ "$FORMAT" = "md" ] || [ "$FORMAT" = "both" ]; then
  if [ ! -f "$TMPL_MD" ]; then
    echo "[VF] ERROR: Template missing: $TMPL_MD" >&2
    exit 2
  fi
fi
if [ "$FORMAT" = "html" ] || [ "$FORMAT" = "both" ]; then
  if [ ! -f "$TMPL_HTML" ]; then
    echo "[VF] ERROR: Template missing: $TMPL_HTML" >&2
    exit 2
  fi
fi

# ------------------------------------------------------------------
# Escaping helpers
# ------------------------------------------------------------------
html_escape() {
  local s="$1"
  s="${s//&/&amp;}"
  s="${s//</&lt;}"
  s="${s//>/&gt;}"
  s="${s//\"/&quot;}"
  s="${s//\'/&#39;}"
  printf '%s' "$s"
}

json_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  # Strip control chars (keep printable text)
  s="$(printf '%s' "$s" | tr -d '\000-\037')"
  printf '%s' "$s"
}

# ------------------------------------------------------------------
# Discover journey directories
# ------------------------------------------------------------------
# Use $TMPDIR when provided (respects sandboxed environments); otherwise
# default to the system default via mktemp.
if [ -n "${TMPDIR:-}" ]; then
  TMP_WORK="$(mktemp -d "${TMPDIR%/}/vf-dashboard.XXXXXX")"
else
  TMP_WORK="$(mktemp -d 2>/dev/null || mktemp -d -t vf-dashboard)"
fi
trap 'rm -rf "$TMP_WORK"' EXIT

JOURNEYS_LIST="$TMP_WORK/journeys.txt"
: > "$JOURNEYS_LIST"

# Use find with maxdepth 1 so we only get direct subdirectories.
# Sort for deterministic output. Skip hidden dirs (.history etc) and 'baseline'.
while IFS= read -r -d '' dir; do
  jname="$(basename "$dir")"
  case "$jname" in
    .*) continue ;;          # skip hidden (.history, .gitkeep-style)
    baseline) continue ;;    # skip baseline snapshots dir
  esac
  printf '%s\n' "$jname" >> "$JOURNEYS_LIST"
done < <(find "$EVIDENCE_DIR" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null | sort -z)

# ------------------------------------------------------------------
# Per-journey analysis
# ------------------------------------------------------------------
# Per-journey data is stored in parallel arrays keyed by index.
J_NAMES=()
J_VERDICTS=()
J_CONFIDENCES=()
J_EVIDENCE_COUNTS=()
J_EMPTY_COUNTS=()
J_QUALITY_SCORES=()
J_VERDICT_PATHS=()      # relative path to VERDICT.md (or empty)
J_FILES_FILE=()         # path to temp file with list of evidence files

PASS_COUNT=0
FAIL_COUNT=0
TOTAL=0
TOTAL_QUALITY=0

# Extract verdict (PASS / FAIL / UNKNOWN) from a VERDICT.md file.
extract_verdict() {
  local file="$1"
  [ -f "$file" ] || { printf '%s' "UNKNOWN"; return; }
  # Look for "Overall Verdict" line first (most reliable)
  local line
  line="$(grep -iE '^[[:space:]]*(#+[[:space:]]*)?(\*\*)?Overall[[:space:]]+Verdict' "$file" 2>/dev/null | head -1 || true)"
  if [ -z "$line" ]; then
    line="$(grep -iE '^[[:space:]]*(\*\*)?Verdict[[:space:]]*(\*\*)?[[:space:]]*:' "$file" 2>/dev/null | head -1 || true)"
  fi
  if printf '%s' "$line" | grep -qiE '\bPASS\b'; then
    printf '%s' "PASS"
    return
  fi
  if printf '%s' "$line" | grep -qiE '\bFAIL\b'; then
    printf '%s' "FAIL"
    return
  fi
  # Fall back to scanning the whole file for a strong PASS/FAIL signal.
  if grep -qiE '\*\*PASS\*\*' "$file" 2>/dev/null && ! grep -qiE '\*\*FAIL\*\*' "$file" 2>/dev/null; then
    printf '%s' "PASS"
    return
  fi
  if grep -qiE '\*\*FAIL\*\*' "$file" 2>/dev/null; then
    printf '%s' "FAIL"
    return
  fi
  printf '%s' "UNKNOWN"
}

# Extract confidence (HIGH / MEDIUM / LOW) from a VERDICT.md file.
extract_confidence() {
  local file="$1"
  [ -f "$file" ] || { printf '%s' ""; return; }
  local line
  line="$(grep -iE '(\*\*)?Confidence(\*\*)?[[:space:]]*:' "$file" 2>/dev/null | head -1 || true)"
  if printf '%s' "$line" | grep -qiE '\bHIGH\b'; then printf '%s' "HIGH"; return; fi
  if printf '%s' "$line" | grep -qiE '\bMEDIUM\b'; then printf '%s' "MEDIUM"; return; fi
  if printf '%s' "$line" | grep -qiE '\bLOW\b'; then printf '%s' "LOW"; return; fi
  printf '%s' ""
}

# Derive confidence from evidence signals when VERDICT.md doesn't state it.
derive_confidence() {
  local nonempty="$1"
  local has_verdict="$2"   # 1 if VERDICT.md exists
  local cite_count="$3"    # number of evidence-file references found in VERDICT.md
  if [ "$has_verdict" -eq 1 ] && [ "$nonempty" -ge 3 ] && [ "$cite_count" -ge 3 ]; then
    printf '%s' "HIGH"
  elif [ "$has_verdict" -eq 1 ] && [ "$nonempty" -ge 1 ]; then
    printf '%s' "MEDIUM"
  else
    printf '%s' "LOW"
  fi
}

idx=0
while IFS= read -r jname; do
  [ -n "$jname" ] || continue
  jdir="$EVIDENCE_DIR/$jname"
  verdict_file="$jdir/VERDICT.md"

  # List evidence files (relative to $EVIDENCE_DIR) — recursive, files only.
  files_list="$TMP_WORK/files-$idx.txt"
  (cd "$EVIDENCE_DIR" && find "$jname" -type f -print 2>/dev/null | LC_ALL=C sort) > "$files_list"

  evidence_count=0
  empty_count=0
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    evidence_count=$((evidence_count + 1))
    full="$EVIDENCE_DIR/$f"
    if [ -f "$full" ] && [ ! -s "$full" ]; then
      empty_count=$((empty_count + 1))
    fi
  done < "$files_list"
  nonempty_count=$((evidence_count - empty_count))

  # Verdict + confidence
  has_verdict=0
  verdict="UNKNOWN"
  confidence=""
  cite_count=0
  if [ -f "$verdict_file" ]; then
    has_verdict=1
    verdict="$(extract_verdict "$verdict_file")"
    confidence="$(extract_confidence "$verdict_file")"

    # Count how many evidence filenames are referenced inside VERDICT.md.
    # We only consider files OTHER than VERDICT.md itself.
    while IFS= read -r f; do
      [ -n "$f" ] || continue
      fbase="$(basename "$f")"
      case "$fbase" in
        VERDICT.md) continue ;;
      esac
      if grep -qF "$fbase" "$verdict_file" 2>/dev/null; then
        cite_count=$((cite_count + 1))
      fi
    done < "$files_list"
  fi

  if [ -z "$confidence" ]; then
    confidence="$(derive_confidence "$nonempty_count" "$has_verdict" "$cite_count")"
  fi

  # If still no verdict from VERDICT.md, infer from evidence presence:
  # - any non-empty files but no VERDICT.md → UNKNOWN (dashboard treats as non-PASS)
  # - no files at all → FAIL
  if [ "$verdict" = "UNKNOWN" ] && [ "$evidence_count" -eq 0 ]; then
    verdict="FAIL"
  fi

  # ---------- Quality score rubric (0-100) ----------
  # evidence_exists (30)
  if [ "$nonempty_count" -gt 0 ]; then
    score_exists=30
  else
    score_exists=0
  fi

  # evidence_cites_specific_files (25): scale by cite_count vs (files minus VERDICT.md)
  citable=$((evidence_count > 0 ? evidence_count : 0))
  # don't count VERDICT.md itself
  if [ "$has_verdict" -eq 1 ] && [ "$citable" -gt 0 ]; then citable=$((citable - 1)); fi
  if [ "$has_verdict" -eq 1 ] && [ "$cite_count" -gt 0 ] && [ "$citable" -gt 0 ]; then
    # Cap the ratio at 1.
    if [ "$cite_count" -ge "$citable" ]; then
      score_cite=25
    else
      score_cite=$(( cite_count * 25 / citable ))
    fi
  elif [ "$has_verdict" -eq 1 ] && [ "$cite_count" -gt 0 ]; then
    score_cite=25
  else
    score_cite=0
  fi

  # screenshots_describe_observations (20): look for observation keywords in VERDICT.md
  score_observe=0
  if [ "$has_verdict" -eq 1 ]; then
    # Count occurrences of observation words (case-insensitive).
    obs=$(grep -ioE '\b(shows?|displays?|rendered|visible|confirms?|captured|observed|depicts?|contains?|presents?)\b' \
           "$verdict_file" 2>/dev/null | wc -l | tr -d ' ')
    if [ -z "$obs" ]; then obs=0; fi
    # Full credit at 5+ observation cues, scaled below that.
    if [ "$obs" -ge 5 ]; then
      score_observe=20
    else
      score_observe=$(( obs * 4 ))   # 0..16
    fi
  fi

  # verdicts_cite_evidence (15): VERDICT.md exists with a PASS/FAIL and at least one file cite
  if [ "$has_verdict" -eq 1 ] && { [ "$verdict" = "PASS" ] || [ "$verdict" = "FAIL" ]; } && [ "$cite_count" -gt 0 ]; then
    score_verdict_cite=15
  elif [ "$has_verdict" -eq 1 ] && { [ "$verdict" = "PASS" ] || [ "$verdict" = "FAIL" ]; }; then
    score_verdict_cite=7
  else
    score_verdict_cite=0
  fi

  # no_false_claims (10): 10 minus penalty for empty files
  penalty=$(( empty_count * 5 ))
  score_no_false=$(( 10 - penalty ))
  if [ "$score_no_false" -lt 0 ]; then score_no_false=0; fi

  quality=$(( score_exists + score_cite + score_observe + score_verdict_cite + score_no_false ))
  if [ "$quality" -gt 100 ]; then quality=100; fi
  if [ "$quality" -lt 0 ]; then quality=0; fi

  # ---------- Record ----------
  J_NAMES+=("$jname")
  J_VERDICTS+=("$verdict")
  J_CONFIDENCES+=("$confidence")
  J_EVIDENCE_COUNTS+=("$nonempty_count")
  J_EMPTY_COUNTS+=("$empty_count")
  J_QUALITY_SCORES+=("$quality")
  if [ -f "$verdict_file" ]; then
    J_VERDICT_PATHS+=("$jname/VERDICT.md")
  else
    J_VERDICT_PATHS+=("")
  fi
  J_FILES_FILE+=("$files_list")

  case "$verdict" in
    PASS) PASS_COUNT=$((PASS_COUNT + 1)) ;;
    FAIL) FAIL_COUNT=$((FAIL_COUNT + 1)) ;;
    *)    FAIL_COUNT=$((FAIL_COUNT + 1)) ;;  # treat UNKNOWN as non-PASS
  esac
  TOTAL=$((TOTAL + 1))
  TOTAL_QUALITY=$((TOTAL_QUALITY + quality))

  idx=$((idx + 1))
done < "$JOURNEYS_LIST"

# ------------------------------------------------------------------
# Aggregate score & grade
# ------------------------------------------------------------------
if [ "$TOTAL" -gt 0 ]; then
  AGG_QUALITY=$(( TOTAL_QUALITY / TOTAL ))
else
  AGG_QUALITY=0
fi

GRADE="F"
[ "$AGG_QUALITY" -ge 60 ] && GRADE="D"
[ "$AGG_QUALITY" -ge 70 ] && GRADE="C"
[ "$AGG_QUALITY" -ge 80 ] && GRADE="B"
[ "$AGG_QUALITY" -ge 90 ] && GRADE="A"

if [ "$TOTAL" -eq 0 ]; then
  OVERALL_VERDICT="UNKNOWN"
  OVERALL_VERDICT_CLASS="unknown"
elif [ "$FAIL_COUNT" -eq 0 ]; then
  OVERALL_VERDICT="PASS"
  OVERALL_VERDICT_CLASS="pass"
else
  OVERALL_VERDICT="FAIL"
  OVERALL_VERDICT_CLASS="fail"
fi

RUN_DATE="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# ------------------------------------------------------------------
# Build rendered sections
# ------------------------------------------------------------------
JOURNEY_TABLE_MD=""
JOURNEY_TABLE_HTML=""
JOURNEY_CARDS_HTML=""
EVIDENCE_INDEX_MD=""
EVIDENCE_INDEX_HTML=""

if [ "$TOTAL" -eq 0 ]; then
  JOURNEY_TABLE_MD="| _(no journeys found)_ | - | - | 0 | 0 | - |"
  JOURNEY_TABLE_HTML="<tr><td colspan=\"6\"><em>No journeys found.</em></td></tr>"
  JOURNEY_CARDS_HTML="<p><em>No journey evidence directories were discovered under <code>$(html_escape "$EVIDENCE_DIR")</code>.</em></p>"
  EVIDENCE_INDEX_MD="_(no evidence files captured)_"
  EVIDENCE_INDEX_HTML="<p><em>No evidence files captured.</em></p>"
else
  for i in "${!J_NAMES[@]}"; do
    jname="${J_NAMES[$i]}"
    verdict="${J_VERDICTS[$i]}"
    conf="${J_CONFIDENCES[$i]}"
    ecount="${J_EVIDENCE_COUNTS[$i]}"
    empty="${J_EMPTY_COUNTS[$i]}"
    quality="${J_QUALITY_SCORES[$i]}"
    vpath="${J_VERDICT_PATHS[$i]}"
    flist="${J_FILES_FILE[$i]}"

    # ---- Markdown table row ----
    if [ -n "$vpath" ]; then
      link_md="[VERDICT.md]($vpath)"
    else
      link_md="[$jname/]($jname/)"
    fi
    conf_md="${conf:-N/A}"
    JOURNEY_TABLE_MD+="| $jname | $verdict | $conf_md | $ecount | $quality | $link_md |"$'\n'

    # ---- HTML table row ----
    jname_h="$(html_escape "$jname")"
    verdict_h="$(html_escape "$verdict")"
    verdict_class="$(printf '%s' "$verdict" | tr '[:upper:]' '[:lower:]')"
    case "$verdict_class" in pass|fail) ;; *) verdict_class="unknown" ;; esac
    conf_h="$(html_escape "${conf:-N/A}")"
    conf_class=""
    case "${conf:-}" in
      HIGH)   conf_class="conf-high" ;;
      MEDIUM) conf_class="conf-medium" ;;
      LOW)    conf_class="conf-low" ;;
      *)      conf_class="" ;;
    esac

    if [ -n "$vpath" ]; then
      vpath_h="$(html_escape "$vpath")"
      link_html="<a href=\"${vpath_h}\">VERDICT.md</a>"
    else
      jname_href="$(html_escape "$jname/")"
      link_html="<a href=\"${jname_href}\">${jname_h}/</a>"
    fi

    conf_span=""
    if [ -n "$conf_class" ]; then
      conf_span="<span class=\"confidence ${conf_class}\">${conf_h}</span>"
    else
      conf_span="${conf_h}"
    fi

    JOURNEY_TABLE_HTML+="<tr>"
    JOURNEY_TABLE_HTML+="<td class=\"journey-name\">${jname_h}</td>"
    JOURNEY_TABLE_HTML+="<td><span class=\"verdict-badge verdict-${verdict_class}\">${verdict_h}</span></td>"
    JOURNEY_TABLE_HTML+="<td>${conf_span}</td>"
    JOURNEY_TABLE_HTML+="<td>${ecount}</td>"
    JOURNEY_TABLE_HTML+="<td>${quality} / 100</td>"
    JOURNEY_TABLE_HTML+="<td>${link_html}</td>"
    JOURNEY_TABLE_HTML+="</tr>"$'\n'

    # ---- HTML journey card (collapsible) ----
    card="<details class=\"journey-card\">"
    card+="<summary><span>${jname_h} <span class=\"verdict-badge verdict-${verdict_class}\">${verdict_h}</span></span><span class=\"mono\">${quality}/100</span></summary>"
    card+="<div class=\"journey-body\">"
    card+="<div class=\"meta\">"
    card+="<span><strong>Confidence:</strong> ${conf_h}</span>"
    card+="<span><strong>Evidence files:</strong> ${ecount}</span>"
    if [ "$empty" -gt 0 ]; then
      card+="<span><strong>Zero-byte files:</strong> ${empty}</span>"
    fi
    if [ -n "$vpath" ]; then
      card+="<span><strong>Verdict:</strong> <a href=\"$(html_escape "$vpath")\">VERDICT.md</a></span>"
    fi
    card+="</div>"
    card+="<h3>Evidence files</h3><ul>"
    while IFS= read -r f; do
      [ -n "$f" ] || continue
      fbase="$(basename "$f")"
      f_h="$(html_escape "$f")"
      fbase_h="$(html_escape "$fbase")"
      full="$EVIDENCE_DIR/$f"
      size_note=""
      if [ -f "$full" ] && [ ! -s "$full" ]; then
        size_note=" <span class=\"mono\" style=\"color:#991b1b\">(0 bytes — low quality)</span>"
      fi
      card+="<li><a href=\"${f_h}\"><code>${fbase_h}</code></a>${size_note}</li>"
    done < "$flist"
    card+="</ul></div></details>"
    JOURNEY_CARDS_HTML+="$card"$'\n'

    # ---- Evidence index (markdown + HTML) ----
    EVIDENCE_INDEX_MD+="### $jname"$'\n\n'
    EVIDENCE_INDEX_HTML+="<h3>$(html_escape "$jname")</h3>"$'\n'
    if [ -s "$flist" ]; then
      EVIDENCE_INDEX_HTML+="<ul>"
      while IFS= read -r f; do
        [ -n "$f" ] || continue
        full="$EVIDENCE_DIR/$f"
        empty_tag=""
        empty_tag_md=""
        if [ -f "$full" ] && [ ! -s "$full" ]; then
          empty_tag=" <em>(0 bytes — low quality)</em>"
          empty_tag_md=" _(0 bytes — low quality)_"
        fi
        EVIDENCE_INDEX_MD+="- [\`$f\`]($f)${empty_tag_md}"$'\n'
        f_h="$(html_escape "$f")"
        EVIDENCE_INDEX_HTML+="<li><a href=\"${f_h}\"><code>${f_h}</code></a>${empty_tag}</li>"
      done < "$flist"
      EVIDENCE_INDEX_HTML+="</ul>"$'\n'
    else
      EVIDENCE_INDEX_MD+="_(no evidence files)_"$'\n'
      EVIDENCE_INDEX_HTML+="<p><em>No evidence files.</em></p>"$'\n'
    fi
    EVIDENCE_INDEX_MD+=$'\n'
  done

  # Strip trailing newline from markdown table rows for cleaner substitution.
  JOURNEY_TABLE_MD="${JOURNEY_TABLE_MD%$'\n'}"
fi

# Historical delta table — placeholder content. Phase 2 will replace this
# with real comparison logic. For now we emit a baseline message when history
# is empty or archival is disabled.
HISTORY_DIR="$EVIDENCE_DIR/.history"
HIST_COUNT=0
if [ -d "$HISTORY_DIR" ]; then
  HIST_COUNT=$(find "$HISTORY_DIR" -maxdepth 1 -type f -name 'run-*.json' 2>/dev/null | wc -l | tr -d ' ')
fi
HISTORICAL_DELTA_TABLE_MD="_No prior runs yet — this is baseline._"
HISTORICAL_DELTA_TABLE_HTML="<p><em>No prior runs yet — this is baseline.</em></p>"

# ------------------------------------------------------------------
# Template rendering (safe literal substitution)
# ------------------------------------------------------------------
render_template() {
  local tmpl="$1"
  local output="$2"
  local is_html="$3"    # 1 for HTML, 0 for markdown
  local content

  # Load template
  content="$(cat "$tmpl")"

  # Choose values depending on output type
  local project_name run_date overall_verdict overall_verdict_class
  local journey_table evidence_index historical_delta
  local journey_cards_html

  if [ "$is_html" -eq 1 ]; then
    project_name="$(html_escape "$PROJECT_NAME")"
    run_date="$(html_escape "$RUN_DATE")"
    overall_verdict="$(html_escape "$OVERALL_VERDICT")"
    overall_verdict_class="$(html_escape "$OVERALL_VERDICT_CLASS")"
    journey_table="$JOURNEY_TABLE_HTML"
    evidence_index="$EVIDENCE_INDEX_HTML"
    historical_delta="$HISTORICAL_DELTA_TABLE_HTML"
    journey_cards_html="$JOURNEY_CARDS_HTML"
  else
    project_name="$PROJECT_NAME"
    run_date="$RUN_DATE"
    overall_verdict="$OVERALL_VERDICT"
    overall_verdict_class="$OVERALL_VERDICT_CLASS"
    journey_table="$JOURNEY_TABLE_MD"
    evidence_index="$EVIDENCE_INDEX_MD"
    historical_delta="$HISTORICAL_DELTA_TABLE_MD"
    journey_cards_html=""
  fi

  # Substitute. Bash's ${var//pat/replacement} treats replacement literally,
  # so multi-line values (tables, cards) substitute correctly without needing
  # escape-dance for &, /, \, or $.
  content="${content//\{\{PROJECT_NAME\}\}/$project_name}"
  content="${content//\{\{RUN_DATE\}\}/$run_date}"
  content="${content//\{\{OVERALL_VERDICT\}\}/$overall_verdict}"
  content="${content//\{\{OVERALL_VERDICT_CLASS\}\}/$overall_verdict_class}"
  content="${content//\{\{PASS_COUNT\}\}/$PASS_COUNT}"
  content="${content//\{\{FAIL_COUNT\}\}/$FAIL_COUNT}"
  content="${content//\{\{TOTAL_JOURNEYS\}\}/$TOTAL}"
  content="${content//\{\{QUALITY_SCORE\}\}/$AGG_QUALITY}"
  content="${content//\{\{QUALITY_GRADE\}\}/$GRADE}"
  content="${content//\{\{JOURNEY_TABLE\}\}/$journey_table}"
  content="${content//\{\{JOURNEY_TABLE_HTML\}\}/$journey_table}"
  content="${content//\{\{JOURNEY_CARDS_HTML\}\}/$journey_cards_html}"
  content="${content//\{\{EVIDENCE_INDEX\}\}/$evidence_index}"
  content="${content//\{\{EVIDENCE_INDEX_HTML\}\}/$evidence_index}"
  content="${content//\{\{HISTORICAL_DELTA_TABLE\}\}/$historical_delta}"
  content="${content//\{\{HISTORICAL_DELTA_TABLE_HTML\}\}/$historical_delta}"

  printf '%s\n' "$content" > "$output"
}

# ------------------------------------------------------------------
# Write outputs
# ------------------------------------------------------------------
OUT_MD="$EVIDENCE_DIR/dashboard.md"
OUT_HTML="$EVIDENCE_DIR/dashboard.html"

if [ "$FORMAT" = "md" ] || [ "$FORMAT" = "both" ]; then
  render_template "$TMPL_MD" "$OUT_MD" 0
fi
if [ "$FORMAT" = "html" ] || [ "$FORMAT" = "both" ]; then
  render_template "$TMPL_HTML" "$OUT_HTML" 1
fi

# History archival hook (phase 2 will implement). Present here so the
# --no-history flag has an observable effect even at this stage.
if [ "$NO_HISTORY" -eq 0 ]; then
  : # archival is implemented in subtask-2-1-history-archival
fi

# ------------------------------------------------------------------
# Emit machine-readable JSON summary (single line to stdout)
# ------------------------------------------------------------------
out_md_json="$(json_escape "$OUT_MD")"
out_html_json="$(json_escape "$OUT_HTML")"
grade_json="$(json_escape "$GRADE")"

printf '{"dashboard_md":"%s","dashboard_html":"%s","quality_score":%d,"grade":"%s","pass":%d,"fail":%d,"total":%d}\n' \
  "$out_md_json" "$out_html_json" "$AGG_QUALITY" "$grade_json" "$PASS_COUNT" "$FAIL_COUNT" "$TOTAL"

exit 0
