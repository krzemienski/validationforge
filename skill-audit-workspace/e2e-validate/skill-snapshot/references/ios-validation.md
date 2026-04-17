# iOS Validation Reference

Platform-specific commands, tools, and patterns for validating iOS applications through the simulator.

## Build

```bash
# Find scheme name
xcodebuild -list -project MyApp.xcodeproj

# Build for simulator
xcodebuild -scheme MyApp \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -configuration Debug \
  build 2>&1 | tail -5

# Success indicator: look for "BUILD SUCCEEDED"
# If using workspace:
xcodebuild -workspace MyApp.xcworkspace -scheme MyApp \
  -destination 'platform=iOS Simulator,name=iPhone 16' build

# Swift Package Manager project
swift build
```

## Simulator Management

```bash
# List available simulators
xcrun simctl list devices available

# Boot a simulator
xcrun simctl boot 'iPhone 16'

# Check boot status
xcrun simctl list devices | grep Booted

# Shutdown
xcrun simctl shutdown booted

# Erase (factory reset)
xcrun simctl erase booted

# Create a specific device
xcrun simctl create 'Test iPhone' 'iPhone 16' 'iOS-18-0'
```

## App Installation and Launch

```bash
# Find the built .app bundle
find ~/Library/Developer/Xcode/DerivedData -name "MyApp.app" -path "*/Debug-iphonesimulator/*" | head -1

# Install on booted simulator
xcrun simctl install booted /path/to/MyApp.app

# Launch app
xcrun simctl launch booted com.company.MyApp

# Launch and stream stdout
xcrun simctl launch --console booted com.company.MyApp

# Terminate app
xcrun simctl terminate booted com.company.MyApp

# Uninstall
xcrun simctl uninstall booted com.company.MyApp
```

## Evidence Capture

### Screenshots

```bash
# Capture screenshot
xcrun simctl io booted screenshot e2e-evidence/j1-home-screen.png

# Capture with specific format
xcrun simctl io booted screenshot --type=png e2e-evidence/j1-home-screen.png
```

### Video Recording

```bash
# Start recording (runs until Ctrl+C or kill)
xcrun simctl io booted recordVideo e2e-evidence/j2-onboarding-flow.mp4 &
RECORD_PID=$!

# ... perform actions ...

# Stop recording
kill -INT $RECORD_PID
wait $RECORD_PID 2>/dev/null
```

### Logs

```bash
# Stream logs filtered by app subsystem
xcrun simctl spawn booted log stream \
  --predicate 'subsystem == "com.company.MyApp"' \
  --timeout 10 2>&1 | tee e2e-evidence/j3-logs.txt

# Stream with specific level
xcrun simctl spawn booted log stream \
  --predicate 'subsystem == "com.company.MyApp" AND messageType == error' \
  --timeout 5

# Collect recent logs (last 5 minutes)
xcrun simctl spawn booted log collect --last 5m --output e2e-evidence/j3-logarchive.logarchive
```

## Deep Links and URL Schemes

```bash
# Open a URL in the simulator
xcrun simctl openurl booted "myapp://dashboard"
xcrun simctl openurl booted "https://example.com/deep/link"

# Open Settings
xcrun simctl openurl booted "App-Prefs:"
```

## UI Automation (idb)

If `idb_companion` is available:

```bash
# Tap at coordinates
idb_companion --tap X Y

# Swipe
idb_companion --swipe X1 Y1 X2 Y2

# Type text (requires focused text field)
idb_companion --type "hello@example.com"

# Press hardware button
idb_companion --button HOME
idb_companion --button LOCK
```

Using Xcode MCP tools (if configured):

```
idb_tap x={X} y={Y}
idb_input text="hello@example.com"
idb_gesture gesture_type=swipe start_x={X1} start_y={Y1} end_x={X2} end_y={Y2}
idb_find_element query="Submit Button"
idb_describe operation=all  # Get accessibility tree
```

## App Data Access

```bash
# Get app data container path
xcrun simctl get_app_container booted com.company.MyApp data

# Get app bundle container
xcrun simctl get_app_container booted com.company.MyApp bundle

# Read UserDefaults
plutil -p "$(xcrun simctl get_app_container booted com.company.MyApp data)/Library/Preferences/com.company.MyApp.plist"

# Check Core Data / SQLite
sqlite3 "$(xcrun simctl get_app_container booted com.company.MyApp data)/Library/Application Support/MyApp.sqlite" ".tables"
```

## Push Notifications

```bash
# Send a push notification
xcrun simctl push booted com.company.MyApp payload.json

# payload.json:
# {
#   "aps": {
#     "alert": { "title": "Test", "body": "Notification body" },
#     "badge": 1
#   }
# }
```

## Evidence Quality Examples

**GOOD screenshot review:**
> "Screenshot j1-home-screen.png shows: Navigation bar with title 'Dashboard',
> 3 card widgets (Sessions: 41, Success Rate: 94%, Avg Duration: 2.3m),
> tab bar at bottom with 4 tabs (Home selected, Search, Profile, Settings)"

**BAD screenshot review:**
> "Screenshot captured of home screen"

**GOOD log review:**
> "Logs show: `[Auth] Login succeeded for user@email.com at 14:32:01`,
> `[API] GET /sessions returned 200 with 41 items in 340ms`,
> no error-level messages in the stream"

**BAD log review:**
> "No errors in logs"

## Common iOS Validation Journeys

| Journey | Entry | Key Evidence |
|---------|-------|-------------|
| App Launch | `xcrun simctl launch` | Screenshot of first screen, launch time in logs |
| Login | Deep link to login screen | Screenshot showing logged-in state, auth token in logs |
| Navigation | Tap through tabs | Screenshot of each tab's content |
| Data Display | Navigate to list/detail | Screenshot showing real data, API call in logs |
| Form Submission | Fill and submit form | Success state screenshot, POST request in logs |
| Offline Mode | Toggle airplane mode | Screenshot showing offline indicator |
| Push Notification | Send via `simctl push` | Screenshot of notification banner |
