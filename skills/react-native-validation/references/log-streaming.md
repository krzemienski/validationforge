# Log Streaming

Capture iOS, Android, and Metro bundler logs during validation to detect JS errors, native errors, and bundler issues.

## iOS App Logs (React Native)
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

## Android App Logs (Logcat)
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

## Metro Bundler Logs
```bash
# Check Metro output for JS errors and bundle warnings
grep -i "error\|warning\|failed" e2e-evidence/rn-metro.txt | tee e2e-evidence/rn-metro-issues.txt
if [ -s e2e-evidence/rn-metro-issues.txt ]; then
  echo "WARN: Metro reported issues — review rn-metro-issues.txt"
else
  echo "PASS: No errors or warnings in Metro output"
fi
```
