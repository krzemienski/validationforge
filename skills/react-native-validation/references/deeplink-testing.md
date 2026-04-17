# Deep Link Testing

Exercise app routing via custom URL schemes and universal/app links on both iOS and Android.

## iOS Deep Links
```bash
xcrun simctl openurl booted "SCHEME://PATH?param=value"
sleep 2
xcrun simctl io booted screenshot e2e-evidence/rn-ios-deeplink-result.png
```

Test multiple deep link routes:
```bash
DEEP_LINKS=(
  "myapp://home"
  "myapp://profile/123"
  "myapp://settings"
  "myapp://invalid/route"
)
for i in "${!DEEP_LINKS[@]}"; do
  xcrun simctl openurl booted "${DEEP_LINKS[$i]}"
  sleep 2
  xcrun simctl io booted screenshot "e2e-evidence/rn-ios-deeplink-$i.png"
done
```

## Android Deep Links
```bash
adb shell am start \
  -W \
  -a android.intent.action.VIEW \
  -d "SCHEME://PATH?param=value" \
  PACKAGE_NAME
sleep 2
adb exec-out screencap -p > e2e-evidence/rn-android-deeplink-result.png
```

Test multiple Android deep link routes:
```bash
DEEP_LINKS=(
  "myapp://home"
  "myapp://profile/123"
  "myapp://settings"
)
for i in "${!DEEP_LINKS[@]}"; do
  adb shell am start -W -a android.intent.action.VIEW -d "${DEEP_LINKS[$i]}" PACKAGE_NAME
  sleep 2
  adb exec-out screencap -p > "e2e-evidence/rn-android-deeplink-$i.png"
done
```

## Universal Links / App Links Verification
```bash
# iOS Universal Links
xcrun simctl openurl booted "https://yourdomain.com/path"

# Android App Links
adb shell am start \
  -W \
  -a android.intent.action.VIEW \
  -d "https://yourdomain.com/path"
```
