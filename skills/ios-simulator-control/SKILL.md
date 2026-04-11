---
name: ios-simulator-control
description: "iOS Simulator commands: boot, install, launch, screenshot, video, logs, deep links, permissions, location, crash detection. Reference for evidence capture. Used with all iOS validation skills."
triggers:
  - "simulator control"
  - "boot simulator"
  - "simulator screenshot"
  - "manage simulator"
  - "simulator lifecycle"
context_priority: reference
---

# iOS Simulator Control

Reference for all iOS Simulator lifecycle operations. Use these commands within ValidationForge validation flows to interact with real simulators.

## When to Use

- When iOS validation skills need to boot/manage simulators
- When capturing screenshots or logs from simulators
- When resetting simulator state between validation runs
- As a reference for `evidence-capturer` agent iOS commands

## Simulator Lifecycle

### List Available Simulators

```bash
# All available simulators
xcrun simctl list devices available

# Booted simulators only
xcrun simctl list devices booted

# JSON output for parsing
xcrun simctl list devices available -j
```

### Boot a Simulator

```bash
# Boot by name (picks first match)
xcrun simctl boot "iPhone 16 Pro"

# Boot by UDID (precise)
xcrun simctl boot XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX

# Verify boot
xcrun simctl list devices booted
```

### Shutdown

```bash
# Shutdown specific device
xcrun simctl shutdown "$UDID"

# Shutdown all
xcrun simctl shutdown all
```

## App Operations

### Install

```bash
# Install .app bundle
xcrun simctl install "$UDID" "/path/to/MyApp.app"

# Install from derived data (common after xcodebuild)
xcrun simctl install "$UDID" "build/Build/Products/Debug-iphonesimulator/MyApp.app"
```

### Launch

```bash
# Launch app
xcrun simctl launch "$UDID" "$BUNDLE_ID"

# Launch and wait for exit (useful for CLI-style apps)
xcrun simctl launch --console "$UDID" "$BUNDLE_ID"

# Launch with arguments
xcrun simctl launch "$UDID" "$BUNDLE_ID" --reset-state
```

### Terminate

```bash
xcrun simctl terminate "$UDID" "$BUNDLE_ID"
```

### Uninstall

```bash
xcrun simctl uninstall "$UDID" "$BUNDLE_ID"
```

## Evidence Capture

### Screenshots

```bash
# PNG screenshot
xcrun simctl io "$UDID" screenshot output.png

# With evidence directory
xcrun simctl io "$UDID" screenshot "e2e-evidence/journey-name/step-NN-description.png"
```

### Video Recording

```bash
# Start recording (runs until interrupted)
xcrun simctl io "$UDID" recordVideo output.mp4 &
VIDEO_PID=$!

# ... exercise the app ...

# Stop recording (MUST use SIGINT, never SIGKILL)
kill -INT $VIDEO_PID
wait $VIDEO_PID
```

### App Logs

```bash
# Stream logs for specific app (with debug level — mandatory)
xcrun simctl spawn "$UDID" log stream \
  --predicate "subsystem == \"$BUNDLE_ID\"" \
  --level debug

# Stream with timeout
xcrun simctl spawn "$UDID" log stream \
  --predicate "subsystem == \"$BUNDLE_ID\"" \
  --level debug \
  --timeout 15

# Save to file
xcrun simctl spawn "$UDID" log stream \
  --predicate "subsystem == \"$BUNDLE_ID\"" \
  --level debug \
  --timeout 15 > "e2e-evidence/journey/logs.txt" 2>&1

# All system logs (verbose — use sparingly)
xcrun simctl spawn "$UDID" log stream --level debug
```

### Crash Logs

```bash
# Find recent crash logs
find ~/Library/Logs/DiagnosticReports -name "*.crash" -mmin -10

# Copy crashes to evidence
find ~/Library/Logs/DiagnosticReports -name "*.crash" -mmin -10 \
  -exec cp {} "e2e-evidence/journey-name/" \;
```

## Deep Link Testing

```bash
# Open URL in simulator
xcrun simctl openurl "$UDID" "myapp://path/to/content"

# Open web URL (opens in Safari)
xcrun simctl openurl "$UDID" "https://example.com"

# Test universal links
xcrun simctl openurl "$UDID" "https://myapp.com/deeplink/path"
```

## Push Notifications

```bash
# Send push notification
xcrun simctl push "$UDID" "$BUNDLE_ID" notification.apns

# notification.apns format:
cat > /tmp/test-notification.apns << 'EOF'
{
  "Simulator Target Bundle": "com.example.myapp",
  "aps": {
    "alert": {
      "title": "Test",
      "body": "Notification body"
    }
  }
}
EOF
xcrun simctl push "$UDID" "$BUNDLE_ID" /tmp/test-notification.apns
```

## State Management

### Reset Content and Settings

```bash
# Full reset (like factory reset)
xcrun simctl erase "$UDID"
```

### Privacy Permissions

```bash
# Grant permission
xcrun simctl privacy "$UDID" grant photos "$BUNDLE_ID"
xcrun simctl privacy "$UDID" grant camera "$BUNDLE_ID"
xcrun simctl privacy "$UDID" grant location "$BUNDLE_ID"

# Revoke permission
xcrun simctl privacy "$UDID" revoke photos "$BUNDLE_ID"

# Reset all permissions
xcrun simctl privacy "$UDID" reset all "$BUNDLE_ID"
```

### Location Simulation

```bash
# Set location (latitude, longitude)
xcrun simctl location "$UDID" set 37.7749,-122.4194

# Clear location
xcrun simctl location "$UDID" clear
```

## Status Board

```bash
# Override status bar (for clean screenshots)
xcrun simctl status_bar "$UDID" override \
  --time "9:41" \
  --batteryState charged \
  --batteryLevel 100 \
  --cellularBars 4 \
  --wifiBars 3

# Clear overrides
xcrun simctl status_bar "$UDID" clear
```

## App Container Access

```bash
# Get app data container path
xcrun simctl get_app_container "$UDID" "$BUNDLE_ID" data

# Get app bundle container
xcrun simctl get_app_container "$UDID" "$BUNDLE_ID"

# List files in app container
ls -la "$(xcrun simctl get_app_container "$UDID" "$BUNDLE_ID" data)"
```

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `simctl: error: Unable to boot device` | Shutdown all first: `xcrun simctl shutdown all` |
| `simctl: error: Device not found` | List available: `xcrun simctl list devices available` |
| Video file corrupted | Used `kill -9` instead of `kill -INT` — re-record |
| No logs appearing | Check `--predicate` subsystem matches bundle ID exactly |
| App won't install | Check build destination matches simulator OS version |
| Screenshot is black | App may not have launched yet — add `sleep 3` after launch |

## Integration with ValidationForge

This skill is a reference companion for:
- `ios-validation` — the primary iOS validation skill
- `ios-validation-gate` — three-gate enforcement
- `ios-validation-runner` — five-phase protocol
- `evidence-capturer` agent — iOS capture commands

All commands should save output to `e2e-evidence/` for the `verdict-writer` agent to review.
