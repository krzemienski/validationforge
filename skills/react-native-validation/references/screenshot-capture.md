# Screenshot Capture

*Loaded by `react-native-validation` when executing Step 4 (Screenshot Capture) and you need the iOS simctl and Android adb screenshot commands with sequential naming conventions.*

Platform-specific commands for capturing simulator/emulator screenshots at each validation checkpoint.

## iOS Simulator Screenshots
```bash
xcrun simctl io booted screenshot e2e-evidence/rn-ios-01-launch-screen.png
sleep 2
xcrun simctl io booted screenshot e2e-evidence/rn-ios-02-main-view.png
```

## Android Emulator Screenshots
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
