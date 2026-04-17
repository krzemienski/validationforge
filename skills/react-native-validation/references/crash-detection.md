# Crash Detection

Post-run checks for native crashes (iOS DiagnosticReports, Android logcat FATAL) and JavaScript runtime errors (Metro Red Screen of Death).

## iOS Crash Detection
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

## Android Crash Detection
```bash
adb logcat -d | grep -i "FATAL\|AndroidRuntime\|crash" | tee e2e-evidence/rn-android-crashes.txt
if [ -s e2e-evidence/rn-android-crashes.txt ]; then
  echo "FAIL: Android crash or fatal errors detected"
else
  echo "PASS: No Android crash logs detected"
fi
```

## Metro Red Screen Detection
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
