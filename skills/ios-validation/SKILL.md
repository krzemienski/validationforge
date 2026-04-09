---
name: ios-validation
description: >
  iOS/macOS platform validation through Xcode build, simulator launch, and
  real device interaction via simctl and idb. Captures screenshots, video,
  and accessibility tree as validation evidence.
context_priority: reference
---

# iOS Validation

## Prerequisites

| Requirement | How to verify |
|-------------|---------------|
| Xcode installed | `xcodebuild -version` |
| Simulator runtime available | `xcrun simctl list runtimes` |
| Simulator booted | `xcrun simctl list devices booted` |
| App scheme configured | `xcodebuild -list` |
| idb installed (optional, for UI automation) | `idb --help` |
| Evidence directory exists | `mkdir -p e2e-evidence` |

If no simulator is booted, boot one:
```bash
xcrun simctl boot "iPhone 16"
open -a Simulator
```

## Step 1: Build

```bash
xcodebuild \
  -scheme SCHEME \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -derivedDataPath build/ \
  build 2>&1 | tail -20 | tee e2e-evidence/ios-build-output.txt
```

Check result:
```bash
if grep -q "BUILD SUCCEEDED" e2e-evidence/ios-build-output.txt; then
  echo "PASS: Build succeeded"
else
  echo "FAIL: Build failed — read full output above"
  exit 1
fi
```

Find the .app bundle:
```bash
APP_PATH=$(find build/ -name "*.app" -type d | head -1)
echo "App bundle: $APP_PATH"
```

## Step 2: Install

```bash
xcrun simctl install booted "$APP_PATH" 2>&1 | tee e2e-evidence/ios-install-output.txt
```

## Step 3: Launch

```bash
xcrun simctl launch --console-pty booted BUNDLE_ID 2>&1 | tee e2e-evidence/ios-launch-output.txt &
LAUNCH_PID=$!
sleep 3
```

Verify the app is running:
```bash
xcrun simctl listapps booted 2>/dev/null | grep BUNDLE_ID
```

## Step 4: Screenshot Capture

Capture named screenshots at each validation point:
```bash
xcrun simctl io booted screenshot e2e-evidence/ios-01-launch-screen.png
xcrun simctl io booted screenshot e2e-evidence/ios-02-main-view.png
xcrun simctl io booted screenshot e2e-evidence/ios-03-detail-view.png
```

## Step 5: Video Recording

Start recording before performing a user flow, stop after:
```bash
# Start recording (runs in background)
xcrun simctl io booted recordVideo --codec=h264 e2e-evidence/ios-flow-recording.mp4 &
VIDEO_PID=$!

# ... perform UI interactions here ...

# Stop recording
kill -INT $VIDEO_PID
wait $VIDEO_PID 2>/dev/null
```

## Step 6: Log Capture

Stream logs filtered to the app's subsystem:
```bash
xcrun simctl spawn booted log stream \
  --predicate 'subsystem == "BUNDLE_ID"' \
  --level debug \
  --timeout 10 2>&1 | tee e2e-evidence/ios-app-logs.txt
```

For crash-related logs:
```bash
xcrun simctl spawn booted log stream \
  --predicate 'eventMessage CONTAINS "crash" OR eventMessage CONTAINS "fatal"' \
  --level error \
  --timeout 10 2>&1 | tee e2e-evidence/ios-error-logs.txt
```

## Step 7: Deep Link Testing

```bash
xcrun simctl openurl booted "SCHEME://PATH?param=value"
sleep 2
xcrun simctl io booted screenshot e2e-evidence/ios-deeplink-result.png
```

Test multiple deep link routes:
```bash
DEEP_LINKS=(
  "myapp://home"
  "myapp://settings"
  "myapp://item/123"
  "myapp://invalid/route"
)
for i in "${!DEEP_LINKS[@]}"; do
  xcrun simctl openurl booted "${DEEP_LINKS[$i]}"
  sleep 2
  xcrun simctl io booted screenshot "e2e-evidence/ios-deeplink-$i.png"
done
```

## Step 8: UI Automation

Choose one of two approaches based on your environment.

### Option A: CLI idb

Use when `idb` is installed and you are running commands in a terminal:

```bash
# Get accessibility tree (find tap targets)
idb ui describe-all --udid booted 2>&1 | tee e2e-evidence/ios-accessibility-tree.txt

# Tap at coordinates
idb ui tap --udid booted --x 200 --y 400

# Swipe (scroll down)
idb ui swipe --udid booted --x 200 --y 600 --delta-x 0 --delta-y -300

# Type text into focused field
idb ui text --udid booted "hello world"

# Press hardware button
idb ui button --udid booted HOME
```

### Option B: Xcode MCP tools

Use when the Xcode MCP server is connected in your Claude Code session:

```
# Get accessibility tree (find tap targets)
idb_describe_all

# Tap at coordinates
idb_tap x=200 y=400

# Type text into focused field
idb_input text="search query"

# Swipe (scroll)
idb_gesture gesture_type=swipe start_x=200 start_y=600 end_x=200 end_y=300

# Find element by accessibility label
idb_find_element query="Submit"
```

## Step 9: Crash Detection

Check for crash logs after validation:
```bash
CRASH_DIR="$HOME/Library/Logs/DiagnosticReports"
RECENT_CRASHES=$(find "$CRASH_DIR" -name "*.ips" -newer e2e-evidence/ios-build-output.txt 2>/dev/null)
if [ -n "$RECENT_CRASHES" ]; then
  echo "FAIL: Crash logs found:"
  echo "$RECENT_CRASHES"
  cp $RECENT_CRASHES e2e-evidence/
else
  echo "PASS: No crash logs detected"
fi
```

## Evidence Quality

**GOOD evidence description:**
> Screenshot shows 3 items in list view with blue navigation header, each item displaying a title and subtitle. The "Add" button is visible in the top-right corner.

**BAD evidence description:**
> Screenshot captured.

Every screenshot MUST be accompanied by a description of what is VISIBLE, not what you expect to see.

## Common Failures

| Symptom | Likely Cause | Fix |
|---------|--------------|-----|
| `xcodebuild` fails with "no scheme" | Wrong scheme name or missing `.xcodeproj` | Run `xcodebuild -list` to see available schemes |
| Simulator won't boot | Runtime not installed or device unavailable | `xcrun simctl list runtimes`, install via Xcode preferences |
| App crashes on launch | Missing entitlements, bad provisioning, or runtime error | Check `e2e-evidence/ios-app-logs.txt` for crash reason |
| Deep link doesn't open app | URL scheme not registered in Info.plist | Verify `CFBundleURLSchemes` in Info.plist |
| `simctl install` fails | Architecture mismatch or corrupt build | Clean build folder: `rm -rf build/`, rebuild |
| Black screenshot | App not fully loaded yet | Add `sleep 3` before screenshot, or wait for specific log message |
| idb not found | idb not installed | `brew install idb-companion` or use simctl/Xcode MCP instead |

## PASS Criteria Template

- [ ] App builds without errors
- [ ] App installs on simulator without errors
- [ ] App launches without crash (no crash logs in DiagnosticReports)
- [ ] Target screen renders with expected content (cite screenshot evidence)
- [ ] User flow completes end-to-end (cite video or sequential screenshots)
- [ ] No error dialogs visible in any screenshot
- [ ] No error-level entries in app logs
- [ ] Deep links navigate to correct screens (if applicable)
- [ ] Performance acceptable: launch < 3s, transitions < 0.5s
