#!/usr/bin/env bash
# Initialize evidence directory structure for ValidationForge
# Usage: ./evidence-collector.sh [evidence_dir]

set -euo pipefail

EVIDENCE_DIR="${1:-e2e-evidence}"

# Validate path does not escape project directory
case "$EVIDENCE_DIR" in
  /*) echo "[VF] ERROR: Evidence dir must be a relative path. Got: $EVIDENCE_DIR" >&2; exit 1 ;;
  *../*) echo "[VF] ERROR: Evidence dir must not contain traversal (../). Got: $EVIDENCE_DIR" >&2; exit 1 ;;
esac

mkdir -p "$EVIDENCE_DIR/baseline"

cat > "$EVIDENCE_DIR/.gitkeep" << 'EOF'
EOF

echo "Evidence directory initialized: $EVIDENCE_DIR/"
echo "  $EVIDENCE_DIR/baseline/  — pre-change snapshots"
echo ""
echo "Capture evidence into $EVIDENCE_DIR/ during validation."
echo "Baseline snapshots go into $EVIDENCE_DIR/baseline/"
