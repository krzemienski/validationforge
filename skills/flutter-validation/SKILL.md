---
name: flutter-validation
description: "Use for validating Flutter apps on Android emulators, iOS simulators, and connected physical devices. Runs the protocol: flutter doctor check, pub get, analyze, build (APK/AAB for Android, .app/.ipa for iOS), install on device/emulator, launch, screenshot captures at key states, log streaming via flutter logs for os_log/adb logcat, crash detection via error markers in the log stream. Pairs with e2e-validate for orchestration or runs standalone for Flutter-only projects. Reach for it on phrases like 'validate my Flutter app', 'flutter run check', 'test on simulator', 'dart/flutter test failed', 'pub get validation', or before any Flutter release."
triggers:
  - "flutter validation"
  - "flutter run"
  - "dart validation"
  - "flutter app test"
  - "pub get"
  - "flutter doctor"
  - "flutter build apk"
context_priority: standard
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

## Which Build Variant When?

Pick the variant that matches the journey you're validating before you start.

- **debug + simulator/emulator** — fastest; use for most functional journeys (UI, routing, state)
- **debug + physical device** — required for camera, biometrics, Bluetooth, sensors, real network conditions
- **release + simulator/emulator** — validates release-mode assertions are stripped, asset bundling, tree-shaking
- **release + physical device** — final pre-ship check; closest to production
- **appbundle (Android)** — Play Store submission artifact; validate via internal track only

If unsure, start with **debug + simulator/emulator** and escalate to device or release only when a journey demands it.

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

Pick the target platform and mode, then run the matching command.

> For the full command matrix (Android APK debug/release, Android AAB, iOS debug-simulator/release-device, Web) with the "Build complete" / "Built build/" grep assertion, see `references/build-variants.md` — load it before Step 2 if you're building anything other than Android debug APK; the matrix covers every flag combination.

```bash
# Example: Android debug APK
flutter build apk --debug 2>&1 | tee e2e-evidence/flutter-build.txt
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
flutter run 2>&1 | tee e2e-evidence/flutter-run.txt &
FLUTTER_PID=$!
sleep 10   # Wait for app to fully launch
```

To target a specific device, use `flutter devices` to list IDs, then `flutter run -d DEVICE_ID`.

> For device-selection guidance (iOS simulator vs Android emulator vs physical device) and the release-mode (`--release`) launch pattern, see `references/device-and-run.md` — load it during Step 3 if you need to target a specific device or validate in release mode; skip if running on the default debug simulator.

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

Capture screenshots using `flutter screenshot` while the app is running:

```bash
flutter screenshot --out e2e-evidence/flutter-01-launch-screen.png -d DEVICE_ID
```

Capture sequential screenshots at each validation point:
```bash
flutter screenshot --out e2e-evidence/flutter-01-launch-screen.png -d DEVICE_ID
flutter screenshot --out e2e-evidence/flutter-02-main-view.png -d DEVICE_ID
flutter screenshot --out e2e-evidence/flutter-03-interaction-result.png -d DEVICE_ID
```

> For platform-specific screenshot alternatives when `flutter screenshot` fails — `xcrun simctl io booted screenshot` for iOS, `adb shell screencap -p` + `adb pull` for Android — see `references/flutter-logs-crashes.md` — load it during Step 4 only if `flutter screenshot` errors out or the device doesn't respond; the reference also covers Steps 5-7.

## Step 5: Log Streaming

Stream Flutter framework and app logs while the app runs:

```bash
flutter logs -d DEVICE_ID 2>&1 | tee e2e-evidence/flutter-app-logs.txt &
LOG_PID=$!
sleep 15
kill $LOG_PID
wait $LOG_PID 2>/dev/null
```

Check for errors in captured logs:
```bash
if grep -iE "flutter error|unhandled exception|fatal|crash" e2e-evidence/flutter-app-logs.txt; then
  echo "FAIL: Errors found in app logs"
else
  echo "PASS: No errors detected in app logs"
fi
```

> For platform-specific log alternatives — `adb logcat flutter:V *:S` (Android), `xcrun simctl spawn booted log stream --predicate 'process == "Runner"'` (iOS), plus the error-keyword grep — see `references/flutter-logs-crashes.md` — load this during Step 5 if `flutter logs` isn't capturing what you need (e.g. filtered to a process or tag).

## Step 6: Widget Tree Inspection

Capture the widget tree for structural validation (debug mode only). Press `w` in the `flutter run` console to dump the widget hierarchy, or use `adb shell uiautomator dump` for an accessibility-tree equivalent.

> For the `flutter run --debug` widget-tree dump flow plus the `adb shell uiautomator dump /sdcard/ui-dump.xml` + `adb pull` sequence, see `references/flutter-logs-crashes.md` — load it during Step 6 if structural UI validation is part of this journey; skip for pure visual validation.

## Step 7: Crash Detection

Check for crash output in `flutter run` logs:
```bash
if grep -iE "unhandled exception|FlutterError|RenderFlex overflowed|null check operator" \
   e2e-evidence/flutter-run.txt; then
  echo "FAIL: Crash or render error detected in flutter run output"
else
  echo "PASS: No crashes detected in flutter run output"
fi
```

> For the Android `adb logcat -d -s AndroidRuntime:E` FATAL-EXCEPTION check and the iOS `~/Library/Logs/DiagnosticReports/Runner*.ips` `find -newer` snippet, see `references/flutter-logs-crashes.md` — load this at the end of the run when triaging for native-layer crashes; the inline `flutter run` grep above catches only Dart-side errors.

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
