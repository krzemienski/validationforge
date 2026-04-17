---
name: ios-validation-runner
description: "Five-phase iOS protocol: SETUP → RECORD (video+logs) → ACT (interaction) → COLLECT (artifacts) → VERIFY (verdict). Complex flows & debug scenarios. Video catches temporal evidence screenshots miss."
triggers:
  - "ios validation runner"
  - "run ios validation"
  - "ios test run"
  - "validate ios feature"
context_priority: reference
---

# iOS Validation Runner

Five-phase protocol for capturing comprehensive iOS validation evidence: SETUP, RECORD, ACT, COLLECT, VERIFY.

## When to Use

- When you need deeper evidence than the iOS Validation Gate
- When validating complex multi-step iOS flows
- When you need video evidence of interactions
- When debugging iOS behavior that screenshots alone can't capture

## Five-Phase Protocol

```
SETUP ──> RECORD ──> ACT ──> COLLECT ──> VERIFY
  |          |         |         |           |
Boot sim   Start    Exercise   Gather     Analyze
& prepare  video +  feature    all        evidence
evidence   logs     via UI     artifacts  & verdict
dir
```

## Phase 1: SETUP

Prepare the simulator and evidence directory.

```bash
# Create evidence directory
JOURNEY="ios-validation-run-$(date +%Y%m%d-%H%M%S)"
mkdir -p "e2e-evidence/$JOURNEY"

# Identify simulator
UDID=$(xcrun simctl list devices booted -j | python3 -c "
import json, sys
data = json.load(sys.stdin)
for runtime, devices in data['devices'].items():
    for d in devices:
        if d['state'] == 'Booted':
            print(d['udid']); sys.exit()
")
echo "Using simulator: $UDID" | tee "e2e-evidence/$JOURNEY/step-01-setup.txt"

# Boot if needed
if [ -z "$UDID" ]; then
    xcrun simctl boot "iPhone 16 Pro"
    UDID=$(xcrun simctl list devices booted -j | python3 -c "
    import json, sys
    data = json.load(sys.stdin)
    for runtime, devices in data['devices'].items():
        for d in devices:
            if d['state'] == 'Booted':
                print(d['udid']); sys.exit()
    ")
fi

# Record simulator info
xcrun simctl list devices booted >> "e2e-evidence/$JOURNEY/step-01-setup.txt"
```

## Phase 2: RECORD

Start continuous capture BEFORE interacting with the app.

### Video Recording

```bash
# Start video recording in background
xcrun simctl io "$UDID" recordVideo "e2e-evidence/$JOURNEY/step-02-recording.mp4" &
VIDEO_PID=$!
echo "Video recording PID: $VIDEO_PID" > "e2e-evidence/$JOURNEY/step-02-video-pid.txt"
```

**CRITICAL:** Stop video with `kill -INT $VIDEO_PID` (SIGINT), NEVER `kill -9`. SIGKILL corrupts the video file.

### Log Streaming

```bash
# Start log streaming in background — MUST use --info --debug
xcrun simctl spawn "$UDID" log stream \
  --predicate "subsystem == \"$BUNDLE_ID\"" \
  --level debug \
  > "e2e-evidence/$JOURNEY/step-02-logs.txt" 2>&1 &
LOG_PID=$!
echo "Log stream PID: $LOG_PID" > "e2e-evidence/$JOURNEY/step-02-log-pid.txt"
```

**MANDATORY:** Always include `--level debug`. Without it, you miss most app-level logging.

## Phase 3: ACT

Exercise the feature through the real UI. Capture screenshots at each significant state.

### Using idb (preferred for automation)

```bash
# Tap element by accessibility label
idb ui tap --udid "$UDID" --label "Submit Button"

# Type text
idb ui type --udid "$UDID" "Hello World"

# Swipe
idb ui swipe --udid "$UDID" 200 400 200 100 --duration 0.5

# Screenshot after each action
xcrun simctl io "$UDID" screenshot "e2e-evidence/$JOURNEY/step-03-after-tap-submit.png"
```

### Using manual description (when idb is unavailable)

Describe each action taken and capture screenshot after:

```bash
# After each manual interaction:
xcrun simctl io "$UDID" screenshot "e2e-evidence/$JOURNEY/step-03-NN-description.png"
```

### Action Log

Maintain an action log documenting every interaction:

```bash
cat >> "e2e-evidence/$JOURNEY/step-03-actions.md" << 'EOF'
## Actions Performed

1. **Tapped "Login" button** — navigated to login screen
   - Screenshot: step-03-01-login-screen.png
2. **Entered email "test@example.com"** — email field populated
   - Screenshot: step-03-02-email-entered.png
3. **Tapped "Submit"** — loading spinner appeared, then dashboard loaded
   - Screenshot: step-03-03-dashboard.png
EOF
```

## Phase 4: COLLECT

Stop recording and gather all artifacts.

```bash
# Stop video recording (SIGINT only!)
kill -INT $VIDEO_PID 2>/dev/null
wait $VIDEO_PID 2>/dev/null

# Stop log streaming
kill $LOG_PID 2>/dev/null
wait $LOG_PID 2>/dev/null

# Capture final screenshot
xcrun simctl io "$UDID" screenshot "e2e-evidence/$JOURNEY/step-04-final-state.png"

# Capture crash logs if any
find ~/Library/Logs/DiagnosticReports -name "*.crash" -newer "e2e-evidence/$JOURNEY/step-01-setup.txt" \
  -exec cp {} "e2e-evidence/$JOURNEY/" \;

# Generate evidence inventory
find "e2e-evidence/$JOURNEY" -type f | sort | while read f; do
  echo "$(wc -c < "$f" | tr -d ' ') $f"
done | tee "e2e-evidence/$JOURNEY/evidence-inventory.txt"
```

## Phase 5: VERIFY

Analyze all collected evidence and produce a verdict.

### Verification Steps

1. **Read the logs** (`step-02-logs.txt`):
   - Are there errors or warnings?
   - Do log entries match expected execution flow?
   - Any crash or exception entries?

2. **Review screenshots** (all `step-03-*.png`):
   - Describe what is visible in each screenshot
   - Do state transitions match actions taken?
   - Any visual anomalies?

3. **Check video** (`step-02-recording.mp4`):
   - Does the recording show smooth transitions?
   - Any flickering, blank frames, or crashes visible?

4. **Check for crashes** (any `.crash` files):
   - If crash files exist, the validation FAILS
   - Include crash symbolication in report

5. **Produce verdict:**

```markdown
# iOS Validation Run Report

**Journey:** $JOURNEY
**Simulator:** $UDID
**Bundle ID:** $BUNDLE_ID
**Date:** YYYY-MM-DD HH:MM

## Evidence Inventory
[paste from evidence-inventory.txt]

## Log Analysis
- Errors found: N
- Warnings found: N
- Expected flow observed: YES/NO
- Key log entries: [quote relevant lines]

## Screenshot Analysis
- Screenshots captured: N
- State transitions correct: YES/NO
- Visual anomalies: [describe or NONE]

## Crash Analysis
- Crash files found: N
- [If any: paste crash summary]

## Verdict: PASS | FAIL
**Confidence:** HIGH | MEDIUM | LOW
**Evidence:** [cite specific files]
```

Save to `e2e-evidence/$JOURNEY/report.md`.

## NEVER Patterns

| Pattern | Why It's Wrong |
|---------|---------------|
| `kill -9 $VIDEO_PID` | Corrupts video file. Always use `kill -INT` |
| `--level info` without `--debug` | Misses app-level debug logging |
| Screenshot without describing content | "Screenshot captured" is NOT evidence |
| Skipping Phase 5 (VERIFY) | Collecting evidence without analyzing it is theater |
| Deleting evidence after PASS | Keep all evidence for audit trail |
| Running ACT phase without RECORD phase | No video/log evidence of what happened |

## Integration with ValidationForge

- All evidence goes to `e2e-evidence/{journey-name}/`
- The `verdict-writer` agent reads evidence-inventory.txt to find all files
- Video files provide temporal evidence that screenshots cannot
- Log correlation with UI actions proves end-to-end functionality
