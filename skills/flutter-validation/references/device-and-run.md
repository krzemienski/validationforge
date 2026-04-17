# Flutter Device Targeting and Run

*Loaded by `flutter-validation` when executing Step 3 (Run on Device) and you need device-selection guidance (simulator vs emulator vs physical), `flutter devices`/`-d DEVICE_ID` invocations, and release-mode launch patterns.*

How to select a target device (simulator, emulator, physical) and launch the app.

## Launch on Default Device

```bash
flutter run 2>&1 | tee e2e-evidence/flutter-run.txt &
FLUTTER_PID=$!
sleep 10   # Wait for app to fully launch
```

## Target a Specific Device

```bash
# Get device ID
flutter devices

# Run on specific device
flutter run -d DEVICE_ID 2>&1 | tee e2e-evidence/flutter-run.txt &
FLUTTER_PID=$!
sleep 10
```

## Release Mode (Closer to Production)

```bash
flutter run --release -d DEVICE_ID 2>&1 | tee e2e-evidence/flutter-run.txt &
FLUTTER_PID=$!
sleep 10
```

## Verify the App Launched

```bash
if grep -q "Flutter run key commands" e2e-evidence/flutter-run.txt || \
   grep -q "Syncing files to device" e2e-evidence/flutter-run.txt; then
  echo "PASS: App launched on device"
else
  echo "FAIL: App did not launch — check flutter-run.txt for errors"
fi
```

## Device Selection Guidance

- **iOS Simulator** — default for iOS validation; use for 90% of journeys
- **Android Emulator** — default for Android; snapshots make it fast
- **Physical Device** — required for camera, biometrics, Bluetooth, real network conditions
