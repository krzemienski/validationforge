# Flutter Validation Reference

Platform-specific commands, tools, and patterns for validating Flutter applications on Android and iOS targets using the Flutter CLI and platform-native tooling.

## Build

```bash
# Install dependencies
flutter pub get

# Check for dependency issues
flutter pub deps 2>&1 | head -30

# Android APK (debug)
flutter build apk --debug 2>&1 | tee e2e-evidence/flutter-build.txt

# Android APK (release)
flutter build apk --release 2>&1 | tee e2e-evidence/flutter-build.txt

# Android App Bundle (release)
flutter build appbundle --release 2>&1 | tee e2e-evidence/flutter-build.txt

# iOS for simulator (debug)
flutter build ios --debug --simulator 2>&1 | tee e2e-evidence/flutter-build.txt

# iOS for physical device (release)
flutter build ios --release 2>&1 | tee e2e-evidence/flutter-build.txt

# Web
flutter build web 2>&1 | tee e2e-evidence/flutter-build.txt

# Success indicator: "Build complete." or "✓  Built build/"
# Failure indicator: "FAILURE" or "Error:" lines

# Clean build if needed
flutter clean && flutter pub get && flutter build apk --debug
```

## Flutter Run

```bash
# List connected devices and emulators
flutter devices

# Launch available emulator
flutter emulators
flutter emulators --launch EMULATOR_ID

# Run on default device (debug)
flutter run 2>&1 | tee e2e-evidence/flutter-run.txt &
FLUTTER_PID=$!
sleep 10

# Run on specific device
flutter run -d DEVICE_ID 2>&1 | tee e2e-evidence/flutter-run.txt &
FLUTTER_PID=$!
sleep 10

# Run in release mode (closer to production)
flutter run --release -d DEVICE_ID 2>&1 | tee e2e-evidence/flutter-run.txt &
FLUTTER_PID=$!
sleep 10

# Run with verbose output
flutter run --verbose -d DEVICE_ID 2>&1 | tee e2e-evidence/flutter-run-verbose.txt &
FLUTTER_PID=$!
sleep 10

# Terminate flutter run
kill $FLUTTER_PID 2>/dev/null
wait $FLUTTER_PID 2>/dev/null

# Terminate app on Android via adb
adb shell am force-stop PACKAGE_NAME

# Terminate app on iOS Simulator
xcrun simctl terminate booted BUNDLE_ID
```

## Flutter Test

```bash
# Run all unit and widget tests (no device required)
flutter test 2>&1 | tee e2e-evidence/flutter-test.txt

# Run a specific test file
flutter test test/widget_test.dart 2>&1 | tee e2e-evidence/flutter-test.txt

# Run integration tests (requires connected device)
flutter test integration_test/app_test.dart -d DEVICE_ID 2>&1 | tee e2e-evidence/flutter-integration-test.txt

# Run with coverage
flutter test --coverage 2>&1 | tee e2e-evidence/flutter-test.txt

# Success indicator: "All tests passed!" or "00:XX +N: All tests passed!"
# Failure indicator: "Some tests failed." or "FAILED" lines
```

## Screenshot Capture

### Via Flutter CLI

```bash
# Capture screenshot from connected device while app is running
flutter screenshot --out e2e-evidence/flutter-01-launch-screen.png -d DEVICE_ID
flutter screenshot --out e2e-evidence/flutter-02-main-view.png -d DEVICE_ID
flutter screenshot --out e2e-evidence/flutter-03-detail-view.png -d DEVICE_ID
```

### Via iOS Simulator (simctl)

```bash
# Screenshot from booted iOS Simulator
xcrun simctl io booted screenshot e2e-evidence/flutter-01-launch-screen.png

# Screenshot with explicit format
xcrun simctl io booted screenshot --type=png e2e-evidence/flutter-01-launch-screen.png
```

### Via Android ADB

```bash
# Capture screenshot on device and pull
adb shell screencap -p /sdcard/flutter-screenshot.png
adb pull /sdcard/flutter-screenshot.png e2e-evidence/flutter-01-launch-screen.png
adb shell rm /sdcard/flutter-screenshot.png

# One-liner
adb exec-out screencap -p > e2e-evidence/flutter-01-launch-screen.png
```

## Log Streaming

### Via Flutter CLI

```bash
# Stream logs from connected device (all Flutter/Dart output)
flutter logs -d DEVICE_ID 2>&1 | tee e2e-evidence/flutter-app-logs.txt &
LOG_PID=$!
sleep 15
kill $LOG_PID
wait $LOG_PID 2>/dev/null
```

### Via Android Logcat (ADB)

```bash
# List connected devices
adb devices

# Stream all Flutter-tagged logs
adb logcat flutter:V *:S 2>&1 | timeout 15 cat | tee e2e-evidence/flutter-logcat.txt

# Stream logs filtered to app process
adb logcat --pid=$(adb shell pidof PACKAGE_NAME) \
  2>/dev/null | timeout 15 cat | tee e2e-evidence/flutter-app-logcat.txt

# Filter by Flutter/Dart tags
adb logcat -s flutter:V dart:V 2>/dev/null | timeout 15 cat | tee e2e-evidence/flutter-dart-logs.txt

# Stream crash and error logs
adb logcat AndroidRuntime:E flutter:E *:S 2>/dev/null | timeout 10 cat | tee e2e-evidence/flutter-error-logs.txt

# Install APK directly from build output (Android)
adb install build/app/outputs/flutter-apk/app-debug.apk
adb install -r build/app/outputs/flutter-apk/app-debug.apk  # reinstall

# Launch app via adb
adb shell am start -n PACKAGE_NAME/.MainActivity

# Stop app
adb shell am force-stop PACKAGE_NAME
```

### Via iOS Simulator (simctl)

```bash
# Stream logs from the Flutter runner process
xcrun simctl spawn booted log stream \
  --predicate 'process == "Runner"' \
  --level debug \
  --timeout 15 2>&1 | tee e2e-evidence/flutter-ios-logs.txt

# Filter for error-level entries only
xcrun simctl spawn booted log stream \
  --predicate 'process == "Runner" AND messageType == error' \
  --timeout 10 2>&1 | tee e2e-evidence/flutter-ios-errors.txt

# Stream logs filtered by app bundle ID subsystem
xcrun simctl spawn booted log stream \
  --predicate 'subsystem == "BUNDLE_ID"' \
  --timeout 15 2>&1 | tee e2e-evidence/flutter-ios-logs.txt

# Install and launch Flutter iOS app
APP_PATH=$(find build/ios/iphonesimulator -name "*.app" -type d | head -1)
xcrun simctl install booted "$APP_PATH"
xcrun simctl launch booted BUNDLE_ID
```

## Widget Tree and Accessibility Inspection

```bash
# Dump Android UI hierarchy (while app is running)
adb shell uiautomator dump /sdcard/ui-dump.xml
adb pull /sdcard/ui-dump.xml e2e-evidence/flutter-widget-tree.xml
adb shell rm /sdcard/ui-dump.xml

# iOS Simulator accessibility tree (if idb available)
UDID=$(xcrun simctl list devices booted | grep -Eo '[0-9A-F-]{36}' | head -1)
idb ui describe-all --udid "$UDID" 2>&1 | tee e2e-evidence/flutter-accessibility-tree.txt
```

## Crash Detection

```bash
# Check flutter run output for unhandled exceptions
if grep -iE "unhandled exception|FlutterError|RenderFlex overflowed|null check operator" \
   e2e-evidence/flutter-run.txt; then
  echo "FAIL: Crash or render error detected"
else
  echo "PASS: No crashes detected in flutter run output"
fi

# Android: check for fatal exceptions in logcat
adb logcat -d -s AndroidRuntime:E 2>&1 | tee e2e-evidence/flutter-android-crashes.txt
if grep -q "FATAL EXCEPTION" e2e-evidence/flutter-android-crashes.txt; then
  echo "FAIL: Android fatal exception detected"
fi

# iOS: check DiagnosticReports for crash logs
CRASH_DIR="$HOME/Library/Logs/DiagnosticReports"
RECENT_CRASHES=$(find "$CRASH_DIR" -name "Runner*.ips" -newer e2e-evidence/flutter-build.txt 2>/dev/null)
if [ -n "$RECENT_CRASHES" ]; then
  echo "FAIL: iOS crash logs found: $RECENT_CRASHES"
  cp $RECENT_CRASHES e2e-evidence/
else
  echo "PASS: No iOS crash logs detected"
fi
```

## App Data Access

```bash
# Android — read shared preferences
adb shell run-as PACKAGE_NAME \
  cat /data/data/PACKAGE_NAME/shared_prefs/FlutterSharedPreferences.xml

# Android — list SQLite databases
adb shell run-as PACKAGE_NAME ls /data/data/PACKAGE_NAME/databases/

# Android — pull SQLite database
adb pull /data/data/PACKAGE_NAME/databases/app.db /tmp/app.db
sqlite3 /tmp/app.db ".tables"

# iOS — get app data container path
xcrun simctl get_app_container booted BUNDLE_ID data

# iOS — read stored files
CONTAINER=$(xcrun simctl get_app_container booted BUNDLE_ID data)
ls "$CONTAINER/Documents/"
ls "$CONTAINER/Library/Application Support/"
```

## Evidence Quality Examples

**GOOD screenshot review:**
> "Screenshot flutter-01-launch-screen.png shows: status bar at top (9:41 AM),
> white scaffold with blue AppBar titled 'Home', 3 ListTile widgets each with
> a leading circular avatar, a title ('Item 1', 'Item 2', 'Item 3'), and a
> subtitle showing a date. FloatingActionButton with '+' icon in bottom-right corner."

**BAD screenshot review:**
> "Screenshot captured of home screen"

**GOOD flutter run log review:**
> "flutter-run.txt shows: `Syncing files to device Pixel 8...` followed by
> `Flutter run key commands.`, no `FlutterError` or `unhandled exception` lines,
> `[VERBOSE-2] Dart_Initialize` startup sequence completed in 1.2s"

**BAD flutter run log review:**
> "App launched successfully"

**GOOD logcat review:**
> "flutter-logcat.txt shows: `I/flutter (12345): [API] GET /items returned 200 with 3 items`,
> `I/flutter (12345): [Auth] Token valid, user logged in`, zero E/ or W/ lines from
> flutter or AndroidRuntime tags during the capture window"

**BAD logcat review:**
> "No errors in logcat"

**GOOD flutter pub get review:**
> "flutter-pub-get.txt shows: `Resolving dependencies... (2.1s)`,
> `Got dependencies!`, 42 packages resolved, 0 warnings, 0 conflicts"

**BAD flutter pub get review:**
> "Dependencies installed"

## Common Flutter Validation Journeys

| Journey | Entry | Key Evidence |
|---------|-------|-------------|
| App Launch (Android) | `flutter run -d DEVICE_ID` / `adb shell am start` | Screenshot of first screen, logcat confirms app start, no FATAL EXCEPTION |
| App Launch (iOS) | `flutter run -d DEVICE_ID` / `xcrun simctl launch` | Screenshot of first screen, iOS log shows Runner process, no crash logs |
| Data Display | Navigate to list/detail screen | Screenshot showing real data loaded, API call in flutter logs |
| Form Input | Fill and submit form | Screenshot of success state, POST request confirmed in logs |
| Navigation | Tap through routes | Sequential screenshots of each screen, route names in logs |
| Deep Link | `xcrun simctl openurl` / `adb shell am start -d` | Screenshot of correct destination screen |
| Offline / Error State | Disable network | Screenshot showing error widget or offline indicator, no crash |
| Flutter Test Suite | `flutter test` | Test output showing all tests passed, zero failures |
| Integration Test | `flutter test integration_test/` | Test output with PASS for all scenarios, screenshots in evidence |
| Release Build | `flutter build apk --release` | APK artifact exists, install and launch succeeds on clean device |
