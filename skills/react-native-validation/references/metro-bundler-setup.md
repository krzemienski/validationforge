# Metro Bundler Setup

*Loaded by `react-native-validation` when executing Steps 1-3 (Metro startup, React Native CLI build, Expo CLI build) and you need the full bash invocations with flags, tee-to-evidence patterns, and expected-output grep strings.*

Detailed commands for starting Metro and building the app via React Native CLI or Expo CLI.

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

## Cleanup

Stop Metro when done:
```bash
kill $METRO_PID 2>/dev/null
wait $METRO_PID 2>/dev/null
echo "Metro bundler stopped"
```
