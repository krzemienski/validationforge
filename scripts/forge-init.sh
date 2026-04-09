#!/usr/bin/env bash
# Initialize .validationforge/ directory with forge-state.json
# Usage: ./forge-init.sh [target_dir]

set -euo pipefail

TARGET_DIR="${1:-.}"
FORGE_DIR="$TARGET_DIR/.validationforge"

mkdir -p "$FORGE_DIR"

STATE_FILE="$FORGE_DIR/forge-state.json"

# Only write initial state if file does not already exist
if [ ! -f "$STATE_FILE" ]; then
  TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  cat > "$STATE_FILE" << EOF
{
  "status": "idle",
  "journeys": [],
  "created_at": "$TIMESTAMP",
  "updated_at": "$TIMESTAMP"
}
EOF
fi

echo "[VF] Forge initialized: $FORGE_DIR/"
echo "  $STATE_FILE  — forge state (status: idle)"
echo ""
echo "Run /forge-execute to begin a build-validate-fix loop."
