# React Native Validation Reference

Platform-specific commands, tools, and patterns for validating React Native applications on iOS and Android.

## Build and Start

### Expo Projects

```bash
# Install dependencies
npm install
# or
yarn install

# Start Expo dev server (background)
npx expo start &
EXPO_PID=$!

# Start targeting a specific platform
npx expo start --ios &
npx expo start --android &

# Build for iOS simulator (Expo)
npx expo run:ios --simulator "iPhone 16"

# Build for Android emulator (Expo)
npx expo run:android

# Prebuild (generate native projects)
npx expo prebuild --clean

# Wait for Metro to be ready
for i in $(seq 1 30); do
  curl -sf http://localhost:8081 > /dev/null 2>&1 && break
  sleep 1
done
echo "Metro bundler ready"
```

### Bare React Native Projects

```bash
# Install dependencies
npm install
# or
yarn install

# Install iOS CocoaPods (required for iOS)
cd ios && pod install && cd ..

# Build and run iOS
npx react-native run-ios
npx react-native run-ios --simulator "iPhone 16"
npx react-native run-ios --device "My iPhone"

# Build and run Android
npx react-native run-android
npx react-native run-android --deviceId emulator-5554

# Build release variant (Android)
cd android && ./gradlew assembleRelease && cd ..

# Success indicator (iOS): "BUILD SUCCEEDED" in Xcode output
# Success indicator (Android): "BUILD SUCCESSFUL" in Gradle output
```

## Metro Bundler

```bash
# Start Metro bundler manually (background)
npx react-native start &
METRO_PID=$!

# Start with cache reset
npx react-native start --reset-cache &

# Check Metro health
curl -sf http://localhost:8081/status

# Bundle for production (iOS)
npx react-native bundle \
  --platform ios \
  --dev false \
  --entry-file index.js \
  --bundle-output ios/main.jsbundle \
  --assets-dest ios

# Bundle for production (Android)
npx react-native bundle \
  --platform android \
  --dev false \
  --entry-file index.js \
  --bundle-output android/app/src/main/assets/index.android.bundle \
  --assets-dest android/app/src/main/res

# Stop Metro
kill $METRO_PID 2>/dev/null
```

## iOS Simulator (React Native)

```bash
# List available simulators
xcrun simctl list devices available

# Boot a simulator
xcrun simctl boot "iPhone 16"

# Check boot status
xcrun simctl list devices | grep Booted

# Install and launch app (after build)
xcrun simctl install booted /path/to/MyApp.app
xcrun simctl launch booted com.company.MyApp

# Reload JS bundle (equivalent to Cmd+R)
xcrun simctl io booted sendkey 114  # key 'r'

# Open developer menu
xcrun simctl io booted sendkey 109  # key 'm'

# Screenshot from iOS simulator
xcrun simctl io booted screenshot e2e-evidence/j1-home-screen.png

# Stream logs from app
xcrun simctl spawn booted log stream \
  --predicate 'subsystem == "com.company.MyApp"' \
  --timeout 10 2>&1 | tee e2e-evidence/j1-logs.txt
```

## Android Device and Emulator (ADB)

```bash
# List connected devices and emulators
adb devices

# Launch an emulator
emulator -avd Pixel_8_API_35 &
# or via Android Studio's emulator
$ANDROID_HOME/emulator/emulator -avd Pixel_8_API_35 &

# Wait for emulator to boot
adb wait-for-device
adb shell getprop sys.boot_completed  # returns "1" when ready

# Install APK
adb install app/build/outputs/apk/debug/app-debug.apk
adb install -r app/build/outputs/apk/debug/app-debug.apk  # reinstall

# Launch app
adb shell am start -n com.company.myapp/.MainActivity

# Stop app
adb shell am force-stop com.company.myapp

# Trigger JS reload (shake gesture)
adb shell input keyevent 82  # KEYCODE_MENU
# or send broadcast
adb shell am broadcast -a "com.company.myapp.RELOAD"

# Reverse port for Metro (connect physical device to local Metro)
adb reverse tcp:8081 tcp:8081

# Pull file from device
adb pull /sdcard/Download/screenshot.png e2e-evidence/j1-screenshot.png

# View logcat output filtered by app
adb logcat --pid=$(adb shell pidof com.company.myapp) 2>/dev/null | tee e2e-evidence/j1-logcat.txt

# Filter by React Native tag
adb logcat -s ReactNativeJS:V ReactNative:V 2>/dev/null | tee e2e-evidence/j1-rn-logs.txt

# Clear logcat buffer
adb logcat -c
```

## Evidence Capture

### Screenshots — iOS Simulator

```bash
# Capture screenshot
xcrun simctl io booted screenshot e2e-evidence/j1-home-screen.png

# Capture with explicit format
xcrun simctl io booted screenshot --type=png e2e-evidence/j1-home-screen.png
```

### Screenshots — Android (ADB)

```bash
# Capture screenshot on device and pull
adb shell screencap -p /sdcard/screenshot.png
adb pull /sdcard/screenshot.png e2e-evidence/j1-home-screen.png
adb shell rm /sdcard/screenshot.png

# One-liner
adb exec-out screencap -p > e2e-evidence/j1-home-screen.png
```

### Video Recording — iOS Simulator

```bash
# Start recording
xcrun simctl io booted recordVideo e2e-evidence/j2-onboarding-flow.mp4 &
RECORD_PID=$!

# ... perform actions ...

# Stop recording
kill -INT $RECORD_PID
wait $RECORD_PID 2>/dev/null
```

### Video Recording — Android (ADB)

```bash
# Start recording on device
adb shell screenrecord /sdcard/record.mp4 &
RECORD_PID=$!

# ... perform actions ...

# Stop recording and pull file
kill $RECORD_PID 2>/dev/null
sleep 1
adb pull /sdcard/record.mp4 e2e-evidence/j2-flow.mp4
adb shell rm /sdcard/record.mp4
```

### Logs — iOS

```bash
# Stream logs filtered by app
xcrun simctl spawn booted log stream \
  --predicate 'subsystem == "com.company.MyApp"' \
  --timeout 10 2>&1 | tee e2e-evidence/j3-logs.txt

# Include React Native JS logs
xcrun simctl spawn booted log stream \
  --predicate 'process == "MyApp"' \
  --timeout 10 2>&1 | tee e2e-evidence/j3-logs.txt
```

### Logs — Android

```bash
# Stream logcat for app process
adb logcat --pid=$(adb shell pidof com.company.myapp) \
  2>/dev/null | head -100 | tee e2e-evidence/j3-logcat.txt

# React Native JS and native logs
adb logcat -s ReactNativeJS:V ReactNative:V \
  2>/dev/null | timeout 10 cat | tee e2e-evidence/j3-rn-logs.txt
```

### App State and Storage

```bash
# iOS — read AsyncStorage (LevelDB files)
xcrun simctl get_app_container booted com.company.MyApp data
# Then read files in RCTAsyncLocalStorage_V1/ or RCTAsyncLocalStorage/

# Android — read SharedPreferences
adb shell run-as com.company.myapp \
  cat /data/data/com.company.myapp/shared_prefs/com.company.myapp.xml

# Android — read AsyncStorage (LevelDB)
adb shell run-as com.company.myapp ls /data/data/com.company.myapp/databases/

# Android — read SQLite DB
adb pull /data/data/com.company.myapp/databases/myapp.db /tmp/myapp.db
sqlite3 /tmp/myapp.db ".tables"
```

### Network Requests (React Native)

```bash
# Enable Flipper network plugin or use __DEV__ mode
# For dev builds: open React Native Debugger to inspect network

# Proxy device traffic through mitmproxy (physical device)
# On Mac: set proxy in device Wi-Fi settings to host machine's IP:8080
mitmproxy --listen-port 8080

# For emulator, set proxy
adb shell settings put global http_proxy $(ipconfig getifaddr en0):8080
# Reset after:
adb shell settings put global http_proxy :0
```

## Deep Links

```bash
# iOS — trigger deep link
xcrun simctl openurl booted "myapp://screen/home"
xcrun simctl openurl booted "https://myapp.com/deep/link"

# Android — trigger deep link
adb shell am start \
  -W -a android.intent.action.VIEW \
  -d "myapp://screen/home" \
  com.company.myapp

# Android — trigger universal link
adb shell am start \
  -W -a android.intent.action.VIEW \
  -d "https://myapp.com/screen/home" \
  com.company.myapp
```

## Evidence Quality Examples

**GOOD screenshot review:**
> "Screenshot j1-home-screen.png shows: status bar at top (9:41 AM, full signal),
> header with app logo and 'Dashboard' title, 3 summary cards (Sessions: 41,
> Success Rate: 94%, Avg Duration: 2.3m), horizontal scroll list of 5 recent items
> with timestamps, bottom tab bar with 4 tabs (Home selected, Search, Profile, Settings)"

**BAD screenshot review:**
> "Screenshot captured of home screen"

**GOOD log review:**
> "iOS logs show: `[Auth] Login succeeded for user@email.com at 14:32:01`,
> `[API] GET /sessions returned 200 with 41 items in 340ms`,
> `[Navigation] Navigated to HomeScreen`,
> no error-level messages in the stream"

**BAD log review:**
> "No errors in logs"

**GOOD ADB logcat review:**
> "Android logcat (ReactNativeJS): `I/ReactNativeJS: [Auth] Token stored successfully`,
> `I/ReactNativeJS: [API] Fetched 41 sessions (340ms)`,
> `I/ReactNativeJS: [Nav] HomeScreen mounted`,
> zero W/ or E/ level messages from app process"

**BAD ADB logcat review:**
> "App launched on Android emulator"

**GOOD Metro bundler check:**
> "Metro server returned HTTP 200 at http://localhost:8081/status,
> bundle compiled in 3.2s with 0 warnings, JS loaded on device confirmed
> by `[RCTBridge] Setting up bridge` in logs"

**BAD Metro bundler check:**
> "Metro is running"

## Common React Native Validation Journeys

| Journey | Entry | Key Evidence |
|---------|-------|-------------|
| App Launch (iOS) | `xcrun simctl launch` | Screenshot of first screen, launch time in logs |
| App Launch (Android) | `adb shell am start` | Screenshot of first screen, logcat confirms MainActivity |
| Login | Navigate to login screen | Post-login screenshot, auth token stored in AsyncStorage |
| Navigation | Tap through bottom tabs | Screenshot of each tab, navigation events in logs |
| Data Display | Navigate to list/detail screen | Screenshot showing real API data, network call in logs |
| Form Submission | Fill and submit form | Success state screenshot, POST request confirmed in logs |
| Deep Link | `simctl openurl` / `adb am start` | Screenshot of correct screen, deep link route in logs |
| Offline Mode | Toggle airplane mode | Screenshot showing offline indicator, no crash |
| Push Notification (iOS) | `xcrun simctl push` | Screenshot of notification banner |
| Hot Reload | Edit JS, save | Screenshot showing updated UI, Metro reload in logs |
