#!/usr/bin/env bash
# detect-evidence-type.sh
# Deterministic classifier for validation evidence files. Produces a TSV
# of {file_path, category, bytes, non_empty} + a summary. Lets the LLM
# analyzer skip inline extension/content detection on every run.
#
# Usage:
#   bash detect-evidence-type.sh [--evidence-dir=e2e-evidence] [--write-tsv]
set -u

EVIDENCE_DIR="e2e-evidence"
WRITE_TSV=0

for arg in "$@"; do
  case "$arg" in
    --evidence-dir=*) EVIDENCE_DIR="${arg#*=}" ;;
    --write-tsv)      WRITE_TSV=1 ;;
    -h|--help)
      echo "Usage: $0 [--evidence-dir=PATH] [--write-tsv]"; exit 0 ;;
    *) echo "Unknown arg: $arg" >&2; exit 2 ;;
  esac
done

if [ ! -d "$EVIDENCE_DIR" ]; then
  echo "evidence directory not found: $EVIDENCE_DIR" >&2
  exit 1
fi

classify() {
  local path="$1"
  local lower; lower=$(printf '%s' "$path" | tr '[:upper:]' '[:lower:]')
  local base; base=$(basename "$lower")
  local ext="${lower##*.}"

  case "$ext" in
    png|jpg|jpeg|webp)
      printf 'screenshot'; return ;;
    har)
      printf 'network_trace'; return ;;
    json)
      local peek; peek=$(head -c 200 "$path" 2>/dev/null | tr -d '\n\r\t ')
      if printf '%s' "$peek" | grep -qE '^\{"html"|"document"[[:space:]]*:'; then
        printf 'dom_snapshot'
      else
        printf 'api_response'
      fi
      return ;;
    txt|log)
      if [ "$base" = "${base%-stderr.txt}" ] && ! printf '%s' "$lower" | grep -q '/cli/\|/cli-\|-cli-'; then
        if printf '%s' "$base" | grep -qE '(^|-)cli(-|\.)'; then
          printf 'cli_output'
        else
          printf 'log'
        fi
      else
        printf 'cli_output'
      fi
      return ;;
    md)
      if printf '%s' "$base" | grep -qE 'verdict|^report\.md$'; then
        printf 'verdict'
      else
        printf 'notes'
      fi
      return ;;
  esac
  printf 'unknown'
}

TSV_TMP=$(mktemp 2>/dev/null || echo "/tmp/detect-evidence-$$.tsv")
printf 'file_path\tcategory\tbytes\tnon_empty\n' > "$TSV_TMP"

TOTAL=0; EMPTY=0; BYTES_SUM=0
declare -a CATS
while IFS= read -r -d '' f; do
  cat=$(classify "$f")
  sz=$(wc -c < "$f" | tr -d ' ')
  ne=0; [ "$sz" -gt 10 ] && ne=1
  printf '%s\t%s\t%s\t%s\n' "$f" "$cat" "$sz" "$ne" >> "$TSV_TMP"
  TOTAL=$((TOTAL+1))
  BYTES_SUM=$((BYTES_SUM+sz))
  [ "$ne" -eq 0 ] && EMPTY=$((EMPTY+1))
  CATS+=("$cat")
done < <(find "$EVIDENCE_DIR" -type f -print0 | sort -z)

cat "$TSV_TMP"

if [ "$WRITE_TSV" -eq 1 ]; then
  cp "$TSV_TMP" "$EVIDENCE_DIR/_classified.tsv"
fi

echo ""
echo "=== SUMMARY ==="
echo "total_files: $TOTAL"
echo "empty_files: $EMPTY"
echo "total_bytes: $BYTES_SUM"
echo "--- counts per category ---"
if [ "$TOTAL" -gt 0 ]; then
  printf '%s\n' "${CATS[@]}" | sort | uniq -c | sed 's/^[[:space:]]*/  /'
else
  echo "  (none)"
fi

rm -f "$TSV_TMP"
