#!/bin/bash
# phase-4 static substitute for subtask-4-1 (live session slash-commands).
# Enumerate all 15 commands, parse each .md, and verify any primitives they
# reference (skills, hooks, agents, scripts) exist on disk.
set -u
cd "$(dirname "$0")/../../.." || exit 1

OUT="e2e-evidence/plugin-load-verification/phase-4/step-17-command-references.txt"

echo "=== phase-4 subtask-4-1 (static substitute): command primitive references ===" > "$OUT"
echo "Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$OUT"
echo "" >> "$OUT"

CMDS=(validate validate-plan validate-audit validate-fix validate-ci validate-team validate-sweep validate-benchmark vf-setup forge-setup forge-plan forge-execute forge-team forge-benchmark forge-install-rules)

echo "Expected 15 user-facing commands. Validating each exists as commands/<name>.md:" >> "$OUT"
PASS=0
FAIL=0
for c in "${CMDS[@]}"; do
  if [ -f "commands/$c.md" ]; then
    SIZE=$(wc -c < "commands/$c.md" | tr -d ' ')
    echo "  PASS  commands/$c.md (size=$SIZE)" >> "$OUT"
    PASS=$((PASS+1))
  else
    echo "  FAIL  commands/$c.md MISSING" >> "$OUT"
    FAIL=$((FAIL+1))
  fi
done
echo "" >> "$OUT"
echo "Total: $PASS PASS, $FAIL FAIL (of ${#CMDS[@]})" >> "$OUT"
echo "" >> "$OUT"

echo "--- Per-command primitive references (skills/hooks/agents/scripts) ---" >> "$OUT"
for c in "${CMDS[@]}"; do
  F="commands/$c.md"
  if [ ! -f "$F" ]; then continue; fi
  echo "" >> "$OUT"
  echo "### $c ###" >> "$OUT"
  # Extract referenced skills (e.g., "skills/xyz" or "via skill: xyz")
  SKILL_REFS=$(grep -oE 'skills/[a-z0-9_-]+' "$F" | sort -u)
  AGENT_REFS=$(grep -oE 'agents/[a-z0-9_-]+' "$F" | sort -u)
  # Only treat "hooks/<name>.js" as a hook reference (hooks/hooks.json is a manifest mention, not a code ref).
  # Anchor with whitespace/punctuation boundary so .json doesn't match the .js prefix.
  HOOK_REFS=$(grep -oE 'hooks/[a-z0-9_-]+\.js([^a-z]|$)' "$F" | sed 's/[^a-z/.0-9_-]*$//' | grep -E '\.js$' | sort -u)
  SCRIPT_REFS=$(grep -oE 'scripts/[a-z0-9_/.-]+\.(sh|js|py)' "$F" | sort -u)
  if [ -z "$SKILL_REFS$AGENT_REFS$HOOK_REFS$SCRIPT_REFS" ]; then
    echo "  (no primitive references in this command markdown)" >> "$OUT"
  fi
  for ref in $SKILL_REFS; do
    # skills are directories with SKILL.md inside
    NAME=$(echo "$ref" | sed 's|skills/||')
    if [ -f "skills/$NAME/SKILL.md" ]; then
      echo "  PASS  skill ref: skills/$NAME/SKILL.md" >> "$OUT"
    else
      echo "  FAIL  skill ref: skills/$NAME (missing SKILL.md)" >> "$OUT"
    fi
  done
  for ref in $AGENT_REFS; do
    NAME=$(echo "$ref" | sed 's|agents/||')
    if [ -f "agents/$NAME.md" ]; then
      echo "  PASS  agent ref: agents/$NAME.md" >> "$OUT"
    else
      echo "  FAIL  agent ref: agents/$NAME (missing)" >> "$OUT"
    fi
  done
  for ref in $HOOK_REFS; do
    NAME=$(echo "$ref" | sed 's|hooks/||; s|\.js$||')
    if [ -f "hooks/$NAME.js" ]; then
      echo "  PASS  hook ref: hooks/$NAME.js" >> "$OUT"
    else
      echo "  FAIL  hook ref: hooks/$NAME (missing)" >> "$OUT"
    fi
  done
  for ref in $SCRIPT_REFS; do
    if [ -f "$ref" ]; then
      echo "  PASS  script ref: $ref" >> "$OUT"
    else
      echo "  FAIL  script ref: $ref (missing)" >> "$OUT"
    fi
  done
done

echo "" >> "$OUT"
echo "=== done ===" >> "$OUT"

# Summary to stdout
tail -200 "$OUT"
echo "---"
grep -c 'FAIL  ' "$OUT" | awk '{print "Total FAIL lines:", $1}'
grep -c 'PASS  ' "$OUT" | awk '{print "Total PASS lines:", $1}'
