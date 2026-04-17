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

Validates a React Native app end-to-end by running the real Metro bundler, real
simulator/emulator, and capturing real evidence. No mocks, no unit tests — only
functional validation against the live system.

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

## Validation Steps

Each step has bash commands in its reference file. Follow in order; do not skip.

### Step 1: Metro Startup
Start Metro with `--reset-cache`, pipe output to `e2e-evidence/rn-metro.txt`, and
confirm `packager-status:running`.
For the full background-Metro + Expo-alternative + `curl /status` probe sequence with flags and expected output, see `references/metro-bundler-setup.md` — load this before Step 1 if you need the exact commands; skip if you already know Metro startup by heart.
**Expected outcome:** Metro process running on port 8081, `curl
http://localhost:8081/status` returns `packager-status:running`.

### Step 2: Build and Launch (React Native CLI)
For bare RN projects: `npx react-native run-ios` or `run-android`, tee build
output, grep for `BUILD SUCCEEDED` / `BUILD SUCCESSFUL`.
For the full iOS + Android bash blocks with simulator flags and grep assertions, see `references/metro-bundler-setup.md` (same file as Step 1) — load it before Step 2 if you need the exact `run-ios`/`run-android` invocations.
**Expected outcome:** Build output contains the success string; app is installed
and launched on the target simulator/emulator.

### Step 3: Build and Launch (Expo CLI)
For Expo-managed projects: `npx expo run:ios` / `run:android` for native builds,
or `npx expo start --ios` for Expo Go without a native build.
For the full Expo native-build + Expo Go dev-client command sequence, see `references/metro-bundler-setup.md` — load it before Step 3 if you're on an Expo project and need the exact commands; skip if using bare RN CLI only.
**Expected outcome:** Build output contains `Installed` / `BUILD SUCCEEDED` /
`BUILD SUCCESSFUL`, or Expo Go loads the bundle successfully.

### Step 4: Screenshot Capture
Capture screenshots at every key validation state — launch, main view,
navigation, each feature screen — using `xcrun simctl io booted screenshot` on
iOS and `adb exec-out screencap -p` on Android, with sequential naming.
For the iOS simctl + Android adb screenshot commands with the sequential naming convention, see `references/screenshot-capture.md` — load this during Step 4 if you need the exact capture one-liners or a reminder of the `rn-{platform}-NN-*.png` filename pattern.
**Expected outcome:** PNG files written to `e2e-evidence/rn-{ios,android}-NN-*.png`,
each >0 bytes, each describable by what is visible on screen.

### Step 5: Log Streaming
Stream iOS device logs with `xcrun simctl spawn booted log stream`, Android
logs with `adb logcat`, and grep Metro output for errors/warnings.
For the iOS log-stream predicate filters, Android logcat tag filters, and Metro error-grep one-liner, see `references/log-streaming.md` — load it during Step 5 if you need the exact `--predicate` strings and tag arguments; skip if you're already comfortable with simctl/adb log syntax.
**Expected outcome:** Log files captured for iOS, Android, and Metro; no
error-level entries related to the app under test.

### Step 6: Deep Link Testing
Exercise custom-scheme deep links with `xcrun simctl openurl` (iOS) and `adb
shell am start -a android.intent.action.VIEW` (Android). Loop through every
app route. Also verify universal/app links over `https://`.
For the deep-link loop scripts, universal/app-link HTTPS variants, and post-openurl screenshot capture, see `references/deeplink-testing.md` — load it during Step 6 if the app has deep links to validate; skip if the app has no custom scheme.
**Expected outcome:** Each deep link navigates to the correct screen; a
post-openurl screenshot shows the expected destination.

### Step 7: Crash Detection
Scan `~/Library/Logs/DiagnosticReports/*.ips` for new iOS crashes, grep
`adb logcat -d` for `FATAL`/`AndroidRuntime`, and scan Metro output for
Red-Screen-of-Death JS errors (`Invariant Violation`, `TypeError`, etc.).
For the DiagnosticReports `find -newer` snippet, the Android FATAL/AndroidRuntime grep, and the full JS error pattern list, see `references/crash-detection.md` — load this at the end of the run when triaging for crashes.
**Expected outcome:** No new iOS crash logs, no Android FATAL entries, no
JS runtime errors in Metro output.

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
