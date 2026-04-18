#!/bin/bash
# capture-terminal.sh
#
# Standardized terminal screenshot capture for the ValidationForge launch
# campaign. Configures iTerm2 (or Terminal.app fallback) to the campaign's
# brand-spec dimensions, font, and theme so every screenshot looks consistent.
#
# Usage:
#   ./capture-terminal.sh <output-name>           # captures current terminal window
#   ./capture-terminal.sh <output-name> --window  # interactive window selection
#   ./capture-terminal.sh <output-name> --area    # interactive area selection
#
# Output: assets/campaigns/260418-validationforge-launch/creatives/screenshots/<output-name>.png
#
# Requirements: macOS (uses screencapture). For iTerm2 dimension presets,
# also requires the user to have applied the "VF-Launch" profile manually
# (see "Profile setup" comment at the bottom of this file).

set -euo pipefail

# ----- Configuration (matches creatives/visual-content-spec.md) -----
CAMPAIGN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCREENSHOTS_DIR="$CAMPAIGN_DIR/screenshots"
DEFAULT_WIDTH=1600   # X / Twitter optimal width
DEFAULT_HEIGHT=900   # X 16:9 ratio
LINKEDIN_WIDTH=1200  # LinkedIn optimal width
LINKEDIN_HEIGHT=627  # LinkedIn 1.91:1 ratio

# ----- Argument parsing -----
if [ $# -lt 1 ]; then
  cat <<EOF
Usage: $0 <output-name> [--window | --area | --linkedin]

Examples:
  $0 personal-brand-hero                  # Active window, X dimensions
  $0 verdict-citation --window            # Click a specific window
  $0 evidence-tree --area                 # Click and drag selection
  $0 og-image --linkedin                  # 1200x627 active window

Output: $SCREENSHOTS_DIR/<output-name>.png
EOF
  exit 1
fi

OUTPUT_NAME="$1"
MODE="${2:-active}"

mkdir -p "$SCREENSHOTS_DIR"
OUT_PATH="$SCREENSHOTS_DIR/${OUTPUT_NAME}.png"

# ----- Capture mode dispatch -----
case "$MODE" in
  --window)
    echo "→ Click the window you want to capture..."
    screencapture -W -t png "$OUT_PATH"
    ;;
  --area)
    echo "→ Click and drag to select the area..."
    screencapture -i -t png "$OUT_PATH"
    ;;
  --linkedin)
    # Active window, then will be flagged for LinkedIn aspect-ratio crop
    echo "→ Capturing active window. Will need 1200x627 crop afterward."
    screencapture -t png "$OUT_PATH"
    echo ""
    echo "⚠️  CROP REQUIRED: open in Preview, crop to 1200×627 (1.91:1 LinkedIn ratio)"
    echo "    Tools menu → Adjust Size → uncheck 'Scale proportionally' → 1200×627"
    ;;
  active|*)
    echo "→ Capturing active window..."
    screencapture -o -t png "$OUT_PATH"
    ;;
esac

if [ ! -f "$OUT_PATH" ]; then
  echo "✗ Capture failed (file not written)"
  exit 1
fi

# ----- Report -----
SIZE_KB=$(du -k "$OUT_PATH" | awk '{print $1}')
DIMS=$(sips -g pixelWidth -g pixelHeight "$OUT_PATH" 2>/dev/null | grep pixel | awk '{print $2}' | paste -sd 'x' -)

echo ""
echo "✓ Saved: $OUT_PATH"
echo "  Size:    ${SIZE_KB} KB"
echo "  Dims:    ${DIMS} px"

# ----- Aspect ratio sanity check -----
W=$(echo "$DIMS" | cut -d'x' -f1)
H=$(echo "$DIMS" | cut -d'x' -f2)
if [ -n "$W" ] && [ -n "$H" ] && [ "$H" -gt 0 ]; then
  RATIO=$(echo "scale=2; $W / $H" | bc)
  echo "  Ratio:   ${RATIO}:1"

  case "$MODE" in
    --linkedin)
      EXPECTED="1.91"
      ;;
    *)
      EXPECTED="1.78"  # 16:9 for X
      ;;
  esac
  echo "  Target:  ${EXPECTED}:1 (will need crop if off)"
fi

# ----- Open for preview -----
open "$OUT_PATH"

# ============================================================================
# iTerm2 PROFILE SETUP (one-time, manual)
# ============================================================================
# Create an iTerm2 profile called "VF-Launch" with these settings:
#
#   Window
#     Cols:                120
#     Rows:                32
#     Style:               Normal
#     Transparency:        0
#     Background:          Solid
#
#   Colors
#     Background:          #0a0a0a
#     Foreground:          #e5e5e5
#     Bold:                #fafafa
#     Cursor:              #cc785c (Claude orange — accent only)
#
#   Text
#     Font:                JetBrains Mono Regular 14
#     Bold font:           JetBrains Mono Bold 14
#     Use bold font:       checked
#     Anti-aliased:        checked
#
#   Window
#     Disable smart placement: checked (so window opens at consistent size)
#
# To activate before screenshots:
#   iTerm2 → Profiles → VF-Launch (or `Cmd+I` → Other Actions → Set as Default)
#
# Then run this script.
# ============================================================================

# ============================================================================
# WORKFLOW EXAMPLES (per creatives/visual-content-spec.md asset checklist)
# ============================================================================
#
# Personal-brand launch hero (LinkedIn 1200x627):
#   $ /validate examples/saas-template
#   # ... wait for verdict line "PASS — 6/6 journeys, 13/13 criteria"
#   $ ./capture-terminal.sh personal-brand-launch-hero --linkedin
#
# Show the e2e-evidence directory tree:
#   $ tree e2e-evidence/self-validation/
#   $ ./capture-terminal.sh personal-brand-launch-evidence-tree
#
# Show a curl response file (for inline screenshot):
#   $ bat --paging=never e2e-evidence/self-validation/journey-3/step-04-curl-response.json
#   $ ./capture-terminal.sh personal-brand-launch-evidence-curl
#
# Show the no-mock hook denying a tool call (for X D3 thread T7):
#   $ # In Claude Code: ask claude to write src/auth/login.test.ts, watch hook deny it
#   $ ./capture-terminal.sh x-d3-hook-denial
#
# ============================================================================
