---
name: react-native-validation
description: "Use for validating React Native apps built with any workflow (Expo Go, Expo prebuild/EAS, bare RN CLI) on iOS simulators, Android emulators, and physical devices. Covers: Metro bundler starts cleanly, platform build succeeds, app installs + launches, screenshots at key states, JS console errors captured, native crashes detected, deep links route correctly. Reach for it on phrases like 'validate my React Native app', 'metro bundler check', 'expo validation', 'test RN on simulator', 'does the deep link work in RN', or before an RN release."
triggers:
  - "react native validation"
  - "validate RN app"
  - "metro bundler check"
  - "expo validation"
  - "react native build"
  - "RN simulator test"
  - "RN deep link"
context_priority: standard
---

# React Native Validation

## Prerequisites

| Requirement | How to verify |
|-------------|---------------|
| Node.js installed | `node --version` |
| npm or yarn available | `npm --version` or `yarn --version` |
| React Native CLI or Expo CLI installed | `npx react-native --version` or `npx expo --version` |
| iOS Simulator available (for iOS target) | `xcrun simctl list devices booted` |
| Android emulator available (for Android target) | `emulator -list-avds` or `adb devices` |
| Metro bundler port free (8081) | `lsof -i :8081` (should be empty) |
| Evidence directory exists | `mkdir -p e2e-evidence` |

If no iOS simulator is booted, boot one:
```bash
xcrun simctl boot "iPhone 16"
open -a Simulator
```

If no Android emulator is running, start one:
```bash
emulator -avd EMULATOR_NAME &
sleep 10
adb wait-for-device
```

## Step 1: Metro Startup

Start the Metro bundler in the background before launching the app:

```bash
npx react-native start --reset-cache 2>&1 | tee e2e-evidence/rn-metro.txt &
METRO_PID=$!

# Wait for Metro to be ready
sleep 8
if kill -0 $METRO_PID 2>/dev/null; then
  echo "PASS: Metro bundler running (PID $METRO_PID)" | tee -a e2e-evidence/rn-metro.txt
else
  echo "FAIL: Metro bundler exited unexpectedly"
  cat e2e-evidence/rn-metro.txt
  exit 1
fi
```

For Expo projects, use the Expo dev server instead:
```bash
npx expo start --clear 2>&1 | tee e2e-evidence/rn-metro.txt &
METRO_PID=$!
sleep 10
```

Verify Metro is listening:
```bash
curl -s http://localhost:8081/status 2>&1 | tee -a e2e-evidence/rn-metro.txt
# Expected output: packager-status:running
```

## Step 2: Build and Launch (React Native CLI)

For bare React Native projects:

### iOS Target
```bash
npx react-native run-ios \
  --simulator "iPhone 16" \
  2>&1 | tee e2e-evidence/rn-build-ios.txt

if grep -q "BUILD SUCCEEDED\|success" e2e-evidence/rn-build-ios.txt; then
  echo "PASS: iOS build and launch succeeded"
else
  echo "FAIL: iOS build failed — read full output"
  exit 1
fi
```

### Android Target
```bash
npx react-native run-android \
  2>&1 | tee e2e-evidence/rn-build-android.txt

if grep -q "BUILD SUCCESSFUL\|success" e2e-evidence/rn-build-android.txt; then
  echo "PASS: Android build and launch succeeded"
else
  echo "FAIL: Android build failed — read full output"
  exit 1
fi
```

## Step 3: Build and Launch (Expo CLI)

For Expo-managed projects:

### iOS Target
```bash
npx expo run:ios --simulator "iPhone 16" \
  2>&1 | tee e2e-evidence/rn-expo-build-ios.txt

if grep -q "Installed\|success\|BUILD SUCCEEDED" e2e-evidence/rn-expo-build-ios.txt; then
  echo "PASS: Expo iOS build and launch succeeded"
else
  echo "FAIL: Expo iOS build failed"
  exit 1
fi
```

### Android Target
```bash
npx expo run:android \
  2>&1 | tee e2e-evidence/rn-expo-build-android.txt

if grep -q "BUILD SUCCESSFUL\|success\|Installed" e2e-evidence/rn-expo-build-android.txt; then
  echo "PASS: Expo Android build and launch succeeded"
else
  echo "FAIL: Expo Android build failed"
  exit 1
fi
```

For Expo Go (development client, no native build required):
```bash
# Press 'i' for iOS or 'a' for Android in the Expo terminal
# Or use the Expo Go app to scan the QR code
npx expo start --ios 2>&1 | tee e2e-evidence/rn-expo-go.txt &
EXPO_PID=$!
sleep 15
```

## Step 4: Screenshot Capture

### iOS Simulator Screenshots
```bash
xcrun simctl io booted screenshot e2e-evidence/rn-ios-01-launch-screen.png
sleep 2
xcrun simctl io booted screenshot e2e-evidence/rn-ios-02-main-view.png
```

### Android Emulator Screenshots
```bash
adb exec-out screencap -p > e2e-evidence/rn-android-01-launch-screen.png
sleep 2
adb exec-out screencap -p > e2e-evidence/rn-android-02-main-view.png
```

Capture screenshots at each key validation point with sequential naming:
```bash
# iOS
xcrun simctl io booted screenshot e2e-evidence/rn-ios-03-navigation.png
xcrun simctl io booted screenshot e2e-evidence/rn-ios-04-feature-screen.png

# Android
adb exec-out screencap -p > e2e-evidence/rn-android-03-navigation.png
adb exec-out screencap -p > e2e-evidence/rn-android-04-feature-screen.png
```

## Step 5: Log Streaming

### iOS App Logs (React Native)
```bash
# Stream Metro/JS logs from the React Native packager output
# Metro logs appear in the terminal where Metro is running

# Stream device logs filtered to the app
xcrun simctl spawn booted log stream \
  --predicate 'process == "APP_NAME" OR subsystem == "BUNDLE_ID"' \
  --level debug \
  --timeout 15 2>&1 | tee e2e-evidence/rn-ios-logs.txt
```

For React Native error logs specifically:
```bash
xcrun simctl spawn booted log stream \
  --predicate 'eventMessage CONTAINS "Error" OR eventMessage CONTAINS "Warning" OR eventMessage CONTAINS "RCT"' \
  --level error \
  --timeout 10 2>&1 | tee e2e-evidence/rn-ios-error-logs.txt
```

### Android App Logs (Logcat)
```bash
# Clear existing logs first
adb logcat -c

# Stream React Native logs (tag ReactNative and ReactNativeJS)
adb logcat ReactNative:V ReactNativeJS:V *:S \
  --timeout 15 2>&1 | head -200 | tee e2e-evidence/rn-android-logs.txt
```

For error-level Android logs:
```bash
adb logcat *:E --timeout 10 2>&1 | head -100 | tee e2e-evidence/rn-android-error-logs.txt
```

### Metro Bundler Logs
```bash
# Check Metro output for JS errors and bundle warnings
grep -i "error\|warning\|failed" e2e-evidence/rn-metro.txt | tee e2e-evidence/rn-metro-issues.txt
if [ -s e2e-evidence/rn-metro-issues.txt ]; then
  echo "WARN: Metro reported issues — review rn-metro-issues.txt"
else
  echo "PASS: No errors or warnings in Metro output"
fi
```

## Step 6: Deep Link Testing

### iOS Deep Links
```bash
xcrun simctl openurl booted "SCHEME://PATH?param=value"
sleep 2
xcrun simctl io booted screenshot e2e-evidence/rn-ios-deeplink-result.png
```

Test multiple deep link routes:
```bash
DEEP_LINKS=(
  "myapp://home"
  "myapp://profile/123"
  "myapp://settings"
  "myapp://invalid/route"
)
for i in "${!DEEP_LINKS[@]}"; do
  xcrun simctl openurl booted "${DEEP_LINKS[$i]}"
  sleep 2
  xcrun simctl io booted screenshot "e2e-evidence/rn-ios-deeplink-$i.png"
done
```

### Android Deep Links
```bash
adb shell am start \
  -W \
  -a android.intent.action.VIEW \
  -d "SCHEME://PATH?param=value" \
  PACKAGE_NAME
sleep 2
adb exec-out screencap -p > e2e-evidence/rn-android-deeplink-result.png
```

Test multiple Android deep link routes:
```bash
DEEP_LINKS=(
  "myapp://home"
  "myapp://profile/123"
  "myapp://settings"
)
for i in "${!DEEP_LINKS[@]}"; do
  adb shell am start -W -a android.intent.action.VIEW -d "${DEEP_LINKS[$i]}" PACKAGE_NAME
  sleep 2
  adb exec-out screencap -p > "e2e-evidence/rn-android-deeplink-$i.png"
done
```

### Universal Links / App Links Verification
```bash
# iOS Universal Links
xcrun simctl openurl booted "https://yourdomain.com/path"

# Android App Links
adb shell am start \
  -W \
  -a android.intent.action.VIEW \
  -d "https://yourdomain.com/path"
```

## Step 7: Crash Detection

### iOS Crash Detection
```bash
CRASH_DIR="$HOME/Library/Logs/DiagnosticReports"
RECENT_CRASHES=$(find "$CRASH_DIR" -name "*.ips" -newer e2e-evidence/rn-build-ios.txt 2>/dev/null)
if [ -n "$RECENT_CRASHES" ]; then
  echo "FAIL: Crash logs found:"
  echo "$RECENT_CRASHES"
  cp $RECENT_CRASHES e2e-evidence/
else
  echo "PASS: No iOS crash logs detected"
fi
```

### Android Crash Detection
```bash
adb logcat -d | grep -i "FATAL\|AndroidRuntime\|crash" | tee e2e-evidence/rn-android-crashes.txt
if [ -s e2e-evidence/rn-android-crashes.txt ]; then
  echo "FAIL: Android crash or fatal errors detected"
else
  echo "PASS: No Android crash logs detected"
fi
```

### Metro Red Screen Detection
```bash
# Check Metro output for the red screen of death patterns
grep -i "invariant violation\|null is not an object\|undefined is not a function\|ReferenceError\|TypeError" \
  e2e-evidence/rn-metro.txt | tee e2e-evidence/rn-js-errors.txt
if [ -s e2e-evidence/rn-js-errors.txt ]; then
  echo "FAIL: JavaScript errors detected (Red Screen of Death)"
else
  echo "PASS: No JavaScript errors in Metro output"
fi
```

## Cleanup

Stop Metro when done:
```bash
kill $METRO_PID 2>/dev/null
wait $METRO_PID 2>/dev/null
echo "Metro bundler stopped"
```

## Evidence Quality

**GOOD evidence description:**
> Screenshot shows the app's home screen with a white background, blue navigation bar titled "Home", and a list of 5 items with icons. The bottom tab bar shows "Home", "Search", and "Profile" tabs.

**BAD evidence description:**
> Screenshot captured.

Every screenshot MUST be accompanied by a description of what is VISIBLE, not what you expect to see.

## Common Failures

| Symptom | Likely Cause | Fix |
|---------|--------------|-----|
| Metro fails to start | Port 8081 in use or missing `node_modules` | Kill port: `lsof -ti:8081 \| xargs kill`; run `npm install` |
| "Unable to resolve module" in Metro | Missing dependency or wrong import path | Run `npm install MODULE_NAME` or fix the import path |
| Red Screen of Death (JS error) | JavaScript runtime error | Read the error in Metro output, fix the code |
| iOS build fails with "no scheme" | Wrong scheme name | Run `xcodebuild -list` to see available schemes |
| Android build fails with SDK error | Missing Android SDK or wrong `ANDROID_HOME` | Set `ANDROID_HOME` and install SDK via Android Studio |
| App launches but shows blank/white screen | Metro not running or bundle not loaded | Ensure Metro is running and reload: `Cmd+R` (iOS) or `R,R` (Android) |
| Deep link not handled | Linking not configured or scheme not registered | Check `scheme` in `app.json` or `Info.plist` / `AndroidManifest.xml` |
| Emulator/simulator not found | Device not booted | Boot simulator or start emulator before running |
| `adb: command not found` | Android SDK platform-tools not in PATH | Add `$ANDROID_HOME/platform-tools` to PATH |
| Expo Go shows "Something went wrong" | JS error or incompatible Expo SDK version | Check Metro logs, verify `expo` package version matches `expo-cli` |

## PASS Criteria Template

- [ ] Metro bundler starts and reports `packager-status:running`
- [ ] App builds without errors (cite build output)
- [ ] App launches on target platform without crash
- [ ] Launch screen renders with expected content (cite screenshot evidence)
- [ ] Primary navigation flow works end-to-end (cite sequential screenshots)
- [ ] No Red Screen of Death or JavaScript errors in Metro output
- [ ] No crash logs in DiagnosticReports (iOS) or logcat FATAL entries (Android)
- [ ] Deep links navigate to correct screens (if applicable)
- [ ] No error-level entries in app logs (iOS log stream or Android logcat)
- [ ] Performance acceptable: app loads within 5s on first launch after Metro ready
