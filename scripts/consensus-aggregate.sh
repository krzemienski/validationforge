#!/usr/bin/env bash
# Aggregate CONSENSUS engine validator evidence into a consolidated summary.
# Inventories e2e-evidence/consensus/validator-*/ subdirectories, parses
# per-journey Verdict: PASS / Verdict: FAIL lines, and emits a machine-readable
# JSON-ish summary on stdout that the consensus-synthesizer agent consumes.
#
# Strictly READ-ONLY: this script performs no writes inside $EVIDENCE_DIR and
# makes no network calls. It is safe to run at any time against a partial or
# complete consensus run. Ownership of files inside $EVIDENCE_DIR remains with
# the validator and synthesizer agents — see rules/consensus-engine.md.
#
# Usage:
#   [EVIDENCE_DIR=e2e-evidence/consensus] bash scripts/consensus-aggregate.sh
#
# Exit codes:
#   0 — >= 2 validator subdirectories with both report.md and evidence-inventory.txt
#   1 — fewer than 2 valid validators, missing evidence dir, or missing files

set -euo pipefail

EVIDENCE_DIR="${EVIDENCE_DIR:-e2e-evidence/consensus}"

# --- Helper functions -------------------------------------------------------

ok()      { echo "  [OK] $1"      >&2; }
missing() { echo "  [MISSING] $1" >&2; }

emit_empty_summary() {
  local error_code="$1"
  cat <<EOF
{
  "error": "$error_code",
  "evidence_dir": "$EVIDENCE_DIR",
  "validator_count": 0,
  "invalid_validators": 0,
  "evidence_totals": { "files": 0 },
  "validators": [],
  "journeys": []
}
EOF
}

# --- 1. Precondition: evidence dir must exist ------------------------------

echo "=== Consensus Evidence Aggregation ===" >&2
echo "Evidence dir: $EVIDENCE_DIR"            >&2
echo ""                                        >&2

echo "Evidence directory:" >&2
if [ ! -d "$EVIDENCE_DIR" ]; then
  missing "Evidence dir not found: $EVIDENCE_DIR"
  emit_empty_summary "evidence_dir_missing"
  exit 1
fi
ok "Evidence dir exists: $EVIDENCE_DIR"

# --- 2. Enumerate validator-* subdirectories -------------------------------

echo ""           >&2
echo "Validators:" >&2

VALIDATOR_DIRS=()
while IFS= read -r dir; do
  [ -n "$dir" ] && VALIDATOR_DIRS+=("$dir")
done < <(find "$EVIDENCE_DIR" -mindepth 1 -maxdepth 1 -type d -name 'validator-*' 2>/dev/null | sort)

if [ "${#VALIDATOR_DIRS[@]}" -eq 0 ]; then
  missing "No validator-* subdirectories found in $EVIDENCE_DIR"
  emit_empty_summary "no_validators"
  exit 1
fi

# --- 3. Per-validator aggregation ------------------------------------------

VALID_COUNT=0
INVALID_COUNT=0
TOTAL_EVIDENCE_FILES=0
VALIDATORS_JSON=""

# Journey tally buffer — newline-separated "journey|PASS" / "journey|FAIL" lines.
# Kept in-memory (no tempfile) so the script stays strictly read-only on disk.
JOURNEY_TALLY=""

for dir in "${VALIDATOR_DIRS[@]}"; do
  vname=$(basename "$dir")
  report="$dir/report.md"
  inventory="$dir/evidence-inventory.txt"
  valid=1

  if [ -f "$report" ]; then
    ok "$vname/report.md"
  else
    missing "$vname/report.md"
    valid=0
  fi

  if [ -f "$inventory" ]; then
    ok "$vname/evidence-inventory.txt"
  else
    missing "$vname/evidence-inventory.txt"
    valid=0
  fi

  if [ "$valid" -ne 1 ]; then
    INVALID_COUNT=$((INVALID_COUNT + 1))
    continue
  fi

  # Count evidence files (exclude the two bookkeeping files)
  evidence_count=$(find "$dir" -type f \
    ! -name 'report.md' \
    ! -name 'evidence-inventory.txt' \
    2>/dev/null | wc -l | tr -d ' ')
  TOTAL_EVIDENCE_FILES=$((TOTAL_EVIDENCE_FILES + evidence_count))

  # Count overall PASS/FAIL verdicts in this validator's report.
  # Regex tolerates both plain "Verdict: PASS" and markdown "**Verdict:** PASS".
  pass_count=$(grep -cE 'Verdict:[*[:space:]]*PASS' "$report" 2>/dev/null || true)
  fail_count=$(grep -cE 'Verdict:[*[:space:]]*FAIL' "$report" 2>/dev/null || true)
  pass_count=${pass_count:-0}
  fail_count=${fail_count:-0}

  # Extract per-journey verdicts. Each "## Journey: NAME" header is paired
  # with the first subsequent "Verdict: PASS|FAIL" line in that block.
  journey_lines=$(awk '
    /^##[[:space:]]+Journey:/ {
      line = $0
      sub(/^##[[:space:]]+Journey:[[:space:]]*/, "", line)
      sub(/[[:space:]]+$/, "", line)
      journey = line
      verdict_seen = 0
      next
    }
    journey != "" && verdict_seen == 0 && /Verdict:[*[:space:]]*PASS/ {
      print journey "|PASS"
      verdict_seen = 1
      next
    }
    journey != "" && verdict_seen == 0 && /Verdict:[*[:space:]]*FAIL/ {
      print journey "|FAIL"
      verdict_seen = 1
      next
    }
  ' "$report")

  if [ -n "$journey_lines" ]; then
    if [ -n "$JOURNEY_TALLY" ]; then
      JOURNEY_TALLY="${JOURNEY_TALLY}"$'\n'"${journey_lines}"
    else
      JOURNEY_TALLY="${journey_lines}"
    fi
  fi

  # Append to JSON array fragment
  if [ -n "$VALIDATORS_JSON" ]; then
    VALIDATORS_JSON="${VALIDATORS_JSON},"
  fi
  VALIDATORS_JSON="${VALIDATORS_JSON}
    {\"name\":\"$vname\",\"evidence_files\":$evidence_count,\"pass\":$pass_count,\"fail\":$fail_count}"

  VALID_COUNT=$((VALID_COUNT + 1))
done

# --- 4. Aggregate per-journey vote counts across validators ----------------

JOURNEYS_JSON=""
if [ -n "$JOURNEY_TALLY" ]; then
  aggregated=$(printf '%s\n' "$JOURNEY_TALLY" | awk -F'|' '
    NF == 2 {
      pass[$1] += ($2 == "PASS" ? 1 : 0)
      fail[$1] += ($2 == "FAIL" ? 1 : 0)
      seen[$1] = 1
    }
    END {
      for (n in seen) {
        printf "{\"journey\":\"%s\",\"pass\":%d,\"fail\":%d}\n", n, pass[n], fail[n]
      }
    }
  ' | sort)

  while IFS= read -r line; do
    [ -z "$line" ] && continue
    if [ -n "$JOURNEYS_JSON" ]; then
      JOURNEYS_JSON="${JOURNEYS_JSON},"
    fi
    JOURNEYS_JSON="${JOURNEYS_JSON}
    ${line}"
  done <<< "$aggregated"
fi

# --- 5. Emit JSON-ish consolidated summary on stdout -----------------------

cat <<EOF
{
  "evidence_dir": "$EVIDENCE_DIR",
  "validator_count": $VALID_COUNT,
  "invalid_validators": $INVALID_COUNT,
  "evidence_totals": {
    "files": $TOTAL_EVIDENCE_FILES
  },
  "validators": [$VALIDATORS_JSON
  ],
  "journeys": [$JOURNEYS_JSON
  ]
}
EOF

# --- 6. Stderr summary + exit code ------------------------------------------

echo ""                                           >&2
echo "=== Summary ==="                            >&2
echo "  Valid validators:   $VALID_COUNT"         >&2
echo "  Invalid validators: $INVALID_COUNT"       >&2
echo "  Evidence files:     $TOTAL_EVIDENCE_FILES" >&2
echo ""                                           >&2

if [ "$VALID_COUNT" -ge 2 ]; then
  echo "  [OK] $VALID_COUNT validators with valid reports (>= 2 required)" >&2
  exit 0
else
  echo "  [FAIL] only $VALID_COUNT validators with valid reports (>= 2 required)" >&2
  exit 1
fi
