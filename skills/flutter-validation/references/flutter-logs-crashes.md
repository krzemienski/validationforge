# Flutter Screenshots, Logs, Widget Tree, and Crashes

*Loaded by `flutter-validation` when executing Steps 4-7 (Screenshot Capture, Log Streaming, Widget Tree Inspection, Crash Detection) and you need platform-specific alternatives — `xcrun simctl`, `adb logcat flutter:V`, `adb shell uiautomator dump`, and iOS DiagnosticReports scans.*

Platform-specific capture commands for iOS + Android. Use during and after `flutter run`.

## Screenshot Capture

Capture screenshots using `flutter screenshot` while the app is running:

```bash
flutter screenshot --out e2e-evidence/flutter-01-launch-screen.png -d DEVICE_ID
echo "Exit code: $?" >> e2e-evidence/flutter-01-launch-screen.png.txt
```

Sequential screenshots at each validation point:
```bash
flutter screenshot --out e2e-evidence/flutter-01-launch-screen.png -d DEVICE_ID
flutter screenshot --out e2e-evidence/flutter-02-main-view.png -d DEVICE_ID
flutter screenshot --out e2e-evidence/flutter-03-interaction-result.png -d DEVICE_ID
```

For iOS Simulator via simctl:
```bash
xcrun simctl io booted screenshot e2e-evidence/flutter-01-launch-screen.png
```

For Android emulators via adb:
```bash
adb shell screencap -p /sdcard/screenshot.png
adb pull /sdcard/screenshot.png e2e-evidence/flutter-01-launch-screen.png
```

## Log Streaming

Stream Flutter framework and app logs while the app runs:

```bash
flutter logs -d DEVICE_ID 2>&1 | tee e2e-evidence/flutter-app-logs.txt &
LOG_PID=$!
sleep 15
kill $LOG_PID
wait $LOG_PID 2>/dev/null
```

Android logcat filtered to Flutter:
```bash
adb logcat flutter:V *:S 2>&1 | head -200 | tee e2e-evidence/flutter-logcat.txt
```

iOS Simulator system logs:
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

## Widget Tree Inspection

Capture the widget tree for structural validation (requires debug mode):

```bash
# Press 'w' in the flutter run console to dump the widget tree, or:
flutter run --debug -d DEVICE_ID 2>&1 &
sleep 10
# Send 'w' command to dump widget hierarchy to stdout
```

Accessibility tree on Android via adb:
```bash
adb shell uiautomator dump /sdcard/ui-dump.xml
adb pull /sdcard/ui-dump.xml e2e-evidence/flutter-widget-tree.xml
```

## Crash Detection

Check flutter run output for unhandled exceptions:
```bash
if grep -iE "unhandled exception|FlutterError|RenderFlex overflowed|null check operator" \
   e2e-evidence/flutter-run.txt; then
  echo "FAIL: Crash or render error detected in flutter run output"
else
  echo "PASS: No crashes detected in flutter run output"
fi
```

Android fatal exceptions via logcat:
```bash
adb logcat -d -s AndroidRuntime:E 2>&1 | tee e2e-evidence/flutter-android-crashes.txt
if grep -q "FATAL EXCEPTION" e2e-evidence/flutter-android-crashes.txt; then
  echo "FAIL: Android fatal exception detected"
else
  echo "PASS: No Android fatal exceptions found"
fi
```

iOS Simulator crash logs:
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

## Stop the App

```bash
kill $FLUTTER_PID
wait $FLUTTER_PID 2>/dev/null

# Or terminate from adb (Android)
adb shell am force-stop PACKAGE_NAME
```
