# Flutter Build Variants

*Loaded by `flutter-validation` when executing Step 2 (Build) and you need the full command matrix for Android APK/AAB, iOS debug/release/simulator, and Web targets with success-marker grep patterns.*

Detailed build commands for each target platform and build mode. Use after `flutter pub get` succeeds.

## Install Dependencies

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

## Build by Target Platform

```bash
# Android APK (debug)
flutter build apk --debug 2>&1 | tee e2e-evidence/flutter-build.txt

# Android APK (release)
flutter build apk --release 2>&1 | tee e2e-evidence/flutter-build.txt

# Android App Bundle (release, for Play Store)
flutter build appbundle --release 2>&1 | tee e2e-evidence/flutter-build.txt

# iOS (debug, simulator)
flutter build ios --debug --simulator 2>&1 | tee e2e-evidence/flutter-build.txt

# iOS (release, device)
flutter build ios --release 2>&1 | tee e2e-evidence/flutter-build.txt

# Web
flutter build web 2>&1 | tee e2e-evidence/flutter-build.txt
```

## Verify Build Succeeded

```bash
if grep -q "Build complete" e2e-evidence/flutter-build.txt || \
   grep -q "Built build/" e2e-evidence/flutter-build.txt; then
  echo "PASS: Build succeeded"
else
  echo "FAIL: Build failed — read full output above"
  exit 1
fi
```

## When to Pick Which Variant

- **debug + simulator/emulator** — fastest iteration, hot-reload, most validation runs
- **debug + physical device** — catch device-specific issues (camera, sensors, permissions)
- **release** — only for pre-ship validation; disables assertions and DevTools
- **appbundle** — required for Play Store submission; validate via internal track
