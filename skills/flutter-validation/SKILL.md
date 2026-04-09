---
name: flutter-validation
description: >
  Flutter platform validation through dependency installation, build, device
  launch, and screenshot capture via flutter screenshot. Captures logs, widget
  trees, and crash output as validation evidence across Android and iOS targets.
---

# Flutter Validation

## Prerequisites

| Requirement | How to verify |
|-------------|---------------|
| Flutter SDK installed | `flutter --version` |
| Dart SDK available | `dart --version` |
| Flutter doctor passes | `flutter doctor` |
| Connected device or emulator | `flutter devices` |
| Android emulator running (if targeting Android) | `flutter emulators --launch EMULATOR_ID` |
| iOS Simulator booted (if targeting iOS) | `xcrun simctl list devices booted` |
| Evidence directory exists | `mkdir -p e2e-evidence` |

If no device is available, launch an emulator:
```bash
# List available emulators
flutter emulators

# Launch a specific emulator
flutter emulators --launch EMULATOR_ID

# Or boot an iOS Simulator directly
xcrun simctl boot "iPhone 16"
open -a Simulator
```

Confirm a device is now connected:
```bash
flutter devices
```

## Step 1: Install Dependencies

```bash
flutter pub get 2>&1 | tee e2e-evidence/flutter-pub-get.txt
```

Check result:
```bash
if grep -q "Got dependencies" e2e-evidence/flutter-pub-get.txt; then
  echo "PASS: Dependencies resolved"
else
  echo "FAIL: pub get failed — check pubspec.yaml and network access"
  cat e2e-evidence/flutter-pub-get.txt
  exit 1
fi
```

## Step 2: Build

Choose the target platform and build mode:

```bash
# Android APK (debug)
flutter build apk --debug 2>&1 | tee e2e-evidence/flutter-build.txt

# Android APK (release)
flutter build apk --release 2>&1 | tee e2e-evidence/flutter-build.txt

# iOS (debug, simulator)
flutter build ios --debug --simulator 2>&1 | tee e2e-evidence/flutter-build.txt

# iOS (release, device)
flutter build ios --release 2>&1 | tee e2e-evidence/flutter-build.txt

# Web
flutter build web 2>&1 | tee e2e-evidence/flutter-build.txt
```

Check result:
```bash
if grep -q "Build complete" e2e-evidence/flutter-build.txt || \
   grep -q "Built build/" e2e-evidence/flutter-build.txt; then
  echo "PASS: Build succeeded"
else
  echo "FAIL: Build failed — read full output above"
  exit 1
fi
```

## Step 3: Run on Device

Launch the app on the connected device or emulator:

```bash
# Run on the default connected device (foreground, streams logs)
flutter run 2>&1 | tee e2e-evidence/flutter-run.txt &
FLUTTER_PID=$!
sleep 10   # Wait for app to fully launch
```

To target a specific device:
```bash
# Get device ID
flutter devices

# Run on specific device
flutter run -d DEVICE_ID 2>&1 | tee e2e-evidence/flutter-run.txt &
FLUTTER_PID=$!
sleep 10
```

To run in release mode (closer to production):
```bash
flutter run --release -d DEVICE_ID 2>&1 | tee e2e-evidence/flutter-run.txt &
FLUTTER_PID=$!
sleep 10
```

Verify the app launched:
```bash
if grep -q "Flutter run key commands" e2e-evidence/flutter-run.txt || \
   grep -q "Syncing files to device" e2e-evidence/flutter-run.txt; then
  echo "PASS: App launched on device"
else
  echo "FAIL: App did not launch — check flutter-run.txt for errors"
fi
```

## Step 4: Screenshot Capture

Capture screenshots using the `flutter screenshot` command while the app is running:

```bash
# Capture screenshot of current app state
flutter screenshot --out e2e-evidence/flutter-01-launch-screen.png -d DEVICE_ID
echo "Exit code: $?" >> e2e-evidence/flutter-01-launch-screen.png.txt
```

Capture sequential screenshots at each validation point:
```bash
flutter screenshot --out e2e-evidence/flutter-01-launch-screen.png -d DEVICE_ID
flutter screenshot --out e2e-evidence/flutter-02-main-view.png -d DEVICE_ID
flutter screenshot --out e2e-evidence/flutter-03-interaction-result.png -d DEVICE_ID
```

For iOS Simulator targets, you can also use simctl directly:
```bash
xcrun simctl io booted screenshot e2e-evidence/flutter-01-launch-screen.png
```

For Android emulators via adb:
```bash
adb shell screencap -p /sdcard/screenshot.png
adb pull /sdcard/screenshot.png e2e-evidence/flutter-01-launch-screen.png
```

## Step 5: Log Streaming

Stream Flutter framework and app logs while the app runs:

```bash
# Stream logs from connected device (all Flutter output)
flutter logs -d DEVICE_ID 2>&1 | tee e2e-evidence/flutter-app-logs.txt &
LOG_PID=$!
sleep 15   # Capture logs during interaction
kill $LOG_PID
wait $LOG_PID 2>/dev/null
```

For Android, capture logcat filtered to Flutter:
```bash
adb logcat flutter:V *:S 2>&1 | head -200 | tee e2e-evidence/flutter-logcat.txt
```

For iOS Simulator, capture system logs:
```bash
xcrun simctl spawn booted log stream \
  --predicate 'process == "Runner"' \
  --level debug \
  --timeout 15 2>&1 | tee e2e-evidence/flutter-ios-logs.txt
```

Check for errors in captured logs:
```bash
if grep -iE "flutter error|unhandled exception|fatal|crash" e2e-evidence/flutter-app-logs.txt; then
  echo "FAIL: Errors found in app logs"
else
  echo "PASS: No errors detected in app logs"
fi
```

## Step 6: Widget Tree Inspection

Capture the widget tree for structural validation (requires debug mode):

```bash
# Using flutter inspector via CLI (requires debug session active)
# Press 'w' in the flutter run console to dump the widget tree, or:
flutter run --debug -d DEVICE_ID 2>&1 &
sleep 10
# Send 'w' command to dump widget hierarchy to stdout
```

Alternatively, capture accessibility tree on Android via adb:
```bash
adb shell uiautomator dump /sdcard/ui-dump.xml
adb pull /sdcard/ui-dump.xml e2e-evidence/flutter-widget-tree.xml
```

## Step 7: Crash Detection

Check for crash output in logs:
```bash
# Check flutter run output for unhandled exceptions
if grep -iE "unhandled exception|FlutterError|RenderFlex overflowed|null check operator" \
   e2e-evidence/flutter-run.txt; then
  echo "FAIL: Crash or render error detected in flutter run output"
else
  echo "PASS: No crashes detected in flutter run output"
fi
```

For Android crash logs:
```bash
adb logcat -d -s AndroidRuntime:E 2>&1 | tee e2e-evidence/flutter-android-crashes.txt
if grep -q "FATAL EXCEPTION" e2e-evidence/flutter-android-crashes.txt; then
  echo "FAIL: Android fatal exception detected"
else
  echo "PASS: No Android fatal exceptions found"
fi
```

For iOS Simulator crash logs:
```bash
CRASH_DIR="$HOME/Library/Logs/DiagnosticReports"
RECENT_CRASHES=$(find "$CRASH_DIR" -name "Runner*.ips" -newer e2e-evidence/flutter-build.txt 2>/dev/null)
if [ -n "$RECENT_CRASHES" ]; then
  echo "FAIL: iOS crash logs found:"
  echo "$RECENT_CRASHES"
  cp $RECENT_CRASHES e2e-evidence/
else
  echo "PASS: No iOS crash logs detected"
fi
```

## Step 8: Stop the App

```bash
# Stop flutter run
kill $FLUTTER_PID
wait $FLUTTER_PID 2>/dev/null

# Or terminate from adb (Android)
adb shell am force-stop PACKAGE_NAME
```

## Evidence Quality

**GOOD evidence description:**
> Screenshot shows the home feed screen with a blue AppBar titled "My App", three ListTile rows each with an icon and text label, and a FloatingActionButton in the bottom-right corner.

**BAD evidence description:**
> Screenshot captured.

Every screenshot MUST be accompanied by a description of what is VISIBLE, not what you expect to see.

## Common Failures

| Symptom | Likely Cause | Fix |
|---------|--------------|-----|
| `flutter pub get` fails | Missing dependency, bad pubspec.yaml, or no network | Check pubspec.yaml for typos; verify network access; run `flutter pub cache repair` |
| `flutter doctor` reports issues | Missing SDK, toolchain, or license | Follow `flutter doctor --android-licenses` and SDK installation instructions |
| No devices found | No emulator running, device not connected | Run `flutter emulators --launch ID` or connect physical device with USB debugging |
| Build fails with Gradle error | Android SDK or build tools version mismatch | Update `compileSdkVersion` in `android/app/build.gradle`; run `flutter clean` |
| Build fails with Xcode error | Missing provisioning profile or certificate | Run `open ios/Runner.xcworkspace` and fix signing in Xcode |
| App crashes on launch | Missing asset, bad route, or uninitialized dependency | Check `e2e-evidence/flutter-run.txt` for the stack trace |
| `flutter screenshot` fails | No device connected or app not running | Verify `flutter devices` shows the target device and app is active |
| Black/blank screenshot | App still loading or permission dialog blocking | Add additional `sleep` before screenshot; dismiss system dialogs |
| RenderFlex overflow errors | Widget layout exceeds screen bounds | Check for missing `Expanded`, `Flexible`, or `SingleChildScrollView` wrappers |
| Hot reload instead of fresh launch | `flutter run` reusing a prior session | Kill prior `flutter run` process; run `flutter clean` then rebuild |

## PASS Criteria Template

- [ ] `flutter pub get` resolves all dependencies without errors
- [ ] App builds successfully for target platform (exit code 0, "Build complete" in output)
- [ ] App launches on device or emulator without crash
- [ ] Launch screen renders with expected content (cite screenshot evidence)
- [ ] No unhandled exceptions or FlutterErrors in `flutter-run.txt` or `flutter-app-logs.txt`
- [ ] No crash logs detected in platform diagnostic reports
- [ ] User flow completes end-to-end (cite sequential screenshots)
- [ ] No error dialogs visible in any screenshot
- [ ] Log streaming captures expected output with no fatal errors
- [ ] Widget tree or accessibility dump shows expected UI structure (if applicable)
