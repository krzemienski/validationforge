#!/usr/bin/env bash
# Build + install + launch + screenshot pipeline for an iOS app on the booted simulator.
# Captures evidence files into $EVIDENCE_DIR for downstream verdict writing.
# Usage:
#   bash scripts/ios-runner.sh \
#     --scheme=MyApp \
#     --workspace-or-project=MyApp.xcworkspace \
#     --simulator-name="iPhone 15" \
#     --bundle-id=com.example.myapp \
#     --evidence-dir=e2e-evidence/ios
set -euo pipefail

# ---------------------------------------------------------------------------
# Parse named arguments (--key=value)
# ---------------------------------------------------------------------------
SCHEME=""
WORKSPACE_OR_PROJECT=""
SIMULATOR_NAME="iPhone 15"
BUNDLE_ID=""
EVIDENCE_DIR=""

for arg in "$@"; do
  case "$arg" in
    --scheme=*)                 SCHEME="${arg#*=}" ;;
    --workspace-or-project=*)   WORKSPACE_OR_PROJECT="${arg#*=}" ;;
    --simulator-name=*)         SIMULATOR_NAME="${arg#*=}" ;;
    --bundle-id=*)              BUNDLE_ID="${arg#*=}" ;;
    --evidence-dir=*)           EVIDENCE_DIR="${arg#*=}" ;;
    *) echo "[ios-runner] ERROR: unknown argument: $arg" >&2; exit 2 ;;
  esac
done

for req in SCHEME WORKSPACE_OR_PROJECT BUNDLE_ID EVIDENCE_DIR; do
  if [ -z "${!req}" ]; then
    echo "[ios-runner] ERROR: --${req,,} is required (use '_' -> '-')" >&2
    echo "Required: --scheme, --workspace-or-project, --bundle-id, --evidence-dir" >&2
    exit 2
  fi
done

mkdir -p "$EVIDENCE_DIR"
echo "[ios-runner] scheme=$SCHEME workspace_or_project=$WORKSPACE_OR_PROJECT simulator='$SIMULATOR_NAME' bundle=$BUNDLE_ID evidence=$EVIDENCE_DIR"

# ---------------------------------------------------------------------------
# Step 1: Verify required tools
# ---------------------------------------------------------------------------
for tool in xcrun xcodebuild; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "[ios-runner] ERROR: $tool not on PATH — install Xcode command line tools" >&2
    exit 1
  fi
done
if ! xcrun simctl help >/dev/null 2>&1; then
  echo "[ios-runner] ERROR: 'xcrun simctl' unavailable — install full Xcode, not just CLT" >&2
  exit 1
fi
echo "[ios-runner] step 1 ok: xcrun, xcodebuild, simctl all available"

# ---------------------------------------------------------------------------
# Step 2: Boot the named simulator (idempotent)
# ---------------------------------------------------------------------------
BOOT_STATE=$(xcrun simctl list devices | awk -v name="$SIMULATOR_NAME" '$0 ~ name { print; exit }' || true)
if [ -z "$BOOT_STATE" ]; then
  echo "[ios-runner] ERROR: no simulator named '$SIMULATOR_NAME' found — run 'xcrun simctl list devices'" >&2
  exit 1
fi
if echo "$BOOT_STATE" | grep -q "(Booted)"; then
  echo "[ios-runner] step 2 ok: simulator '$SIMULATOR_NAME' already booted"
else
  echo "[ios-runner] step 2: booting simulator '$SIMULATOR_NAME'..."
  xcrun simctl boot "$SIMULATOR_NAME" 2>&1 | tee -a "$EVIDENCE_DIR/ios-boot.log" || {
    # Swallow "already booted" race; hard-fail on anything else.
    if ! xcrun simctl list devices | awk -v name="$SIMULATOR_NAME" '$0 ~ name' | grep -q "(Booted)"; then
      echo "[ios-runner] ERROR: failed to boot '$SIMULATOR_NAME'" >&2
      exit 1
    fi
  }
  open -a Simulator >/dev/null 2>&1 || true
fi

# ---------------------------------------------------------------------------
# Step 3: xcodebuild for iphonesimulator SDK
# ---------------------------------------------------------------------------
BUILD_LOG="$EVIDENCE_DIR/ios-build.log"
if [[ "$WORKSPACE_OR_PROJECT" == *.xcworkspace ]]; then
  WS_FLAG=(-workspace "$WORKSPACE_OR_PROJECT")
else
  WS_FLAG=(-project "$WORKSPACE_OR_PROJECT")
fi
echo "[ios-runner] step 3: running xcodebuild (log -> $BUILD_LOG)"
if ! xcodebuild "${WS_FLAG[@]}" \
    -scheme "$SCHEME" \
    -sdk iphonesimulator \
    -destination "platform=iOS Simulator,name=$SIMULATOR_NAME" \
    -configuration Debug \
    build > "$BUILD_LOG" 2>&1; then
  echo "[ios-runner] ERROR: xcodebuild failed — tail of $BUILD_LOG:" >&2
  tail -30 "$BUILD_LOG" >&2
  exit 1
fi
echo "[ios-runner] step 3 ok: build succeeded"

# ---------------------------------------------------------------------------
# Step 4: Extract .app path from build settings
# ---------------------------------------------------------------------------
echo "[ios-runner] step 4: resolving .app path via xcodebuild -showBuildSettings"
SETTINGS=$(xcodebuild "${WS_FLAG[@]}" \
  -scheme "$SCHEME" \
  -sdk iphonesimulator \
  -configuration Debug \
  -showBuildSettings 2>/dev/null)
BUILT_DIR=$(echo "$SETTINGS" | awk -F' = ' '/^ *TARGET_BUILD_DIR/ {print $2; exit}')
APP_NAME=$(echo "$SETTINGS" | awk -F' = ' '/^ *FULL_PRODUCT_NAME/ {print $2; exit}')
APP_PATH="$BUILT_DIR/$APP_NAME"
if [ -z "$BUILT_DIR" ] || [ -z "$APP_NAME" ] || [ ! -d "$APP_PATH" ]; then
  echo "[ios-runner] ERROR: could not resolve .app at '$APP_PATH' from build settings" >&2
  exit 1
fi
echo "[ios-runner] step 4 ok: APP_PATH=$APP_PATH"

# ---------------------------------------------------------------------------
# Step 5: Install app onto booted simulator
# ---------------------------------------------------------------------------
echo "[ios-runner] step 5: installing $APP_PATH on booted simulator"
if ! xcrun simctl install booted "$APP_PATH" 2>&1 | tee "$EVIDENCE_DIR/ios-install.log"; then
  echo "[ios-runner] ERROR: simctl install failed — see $EVIDENCE_DIR/ios-install.log" >&2
  exit 1
fi
echo "[ios-runner] step 5 ok: installed"

# ---------------------------------------------------------------------------
# Step 6: Launch and capture PID
# ---------------------------------------------------------------------------
LAUNCH_LOG="$EVIDENCE_DIR/ios-launch.log"
echo "[ios-runner] step 6: launching $BUNDLE_ID (log -> $LAUNCH_LOG)"
if ! xcrun simctl launch booted "$BUNDLE_ID" > "$LAUNCH_LOG" 2>&1; then
  echo "[ios-runner] ERROR: simctl launch failed — tail of $LAUNCH_LOG:" >&2
  tail -20 "$LAUNCH_LOG" >&2
  exit 1
fi
LAUNCH_PID=$(awk -F': ' '{print $2}' "$LAUNCH_LOG" | tr -d ' ' | tail -1)
echo "[ios-runner] step 6 ok: launched $BUNDLE_ID pid=${LAUNCH_PID:-unknown}"
sleep 3

# ---------------------------------------------------------------------------
# Step 7: Screenshot of launch state
# ---------------------------------------------------------------------------
SHOT="$EVIDENCE_DIR/ios-screenshot-launch.png"
echo "[ios-runner] step 7: capturing launch screenshot -> $SHOT"
if ! xcrun simctl io booted screenshot "$SHOT" >/dev/null 2>&1; then
  echo "[ios-runner] ERROR: simctl screenshot failed" >&2
  exit 1
fi
if [ ! -s "$SHOT" ]; then
  echo "[ios-runner] ERROR: screenshot at $SHOT is empty" >&2
  exit 1
fi
echo "[ios-runner] step 7 ok: screenshot captured ($(wc -c <"$SHOT") bytes)"
echo "[ios-runner] DONE — evidence dir: $EVIDENCE_DIR"
