---
name: ios-validation-runner
description: "Use for deep iOS validation of multi-step user flows where screenshots alone miss the timing — animations, loading states, state transitions, anything where the journey matters more than the endpoints. Runs a five-phase protocol (SETUP → RECORD → ACT → COLLECT → VERIFY) that captures video + logs in the background while you interact with the app, then analyzes everything together for a PASS/FAIL verdict. Reach for it when you need richer evidence than ios-validation-gate provides, when debugging state transitions, or when someone asks 'what actually happens between tap and result'."
triggers:
  - "ios validation runner"
  - "run ios validation"
  - "ios test run"
  - "validate ios feature"
  - "ios video evidence"
  - "record ios flow"
  - "debug ios transition"
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
SETUP ──► RECORD ──► ACT ──► COLLECT ──► VERIFY
  │          │        │         │            │
Boot sim   Start     Exercise   Stop         Analyze
& prep     capture   feature    capture,     evidence,
evidence   (video+   (manual    gather       produce
dir        logs in   or idb)    artifacts    verdict
           bg)
```

**Key timing rule:** RECORD only *starts* the background capture — it does not exercise the app. The actual interaction happens in ACT. The capture runs the whole time from RECORD until COLLECT stops it. If you interact during RECORD, the phase boundaries get confused and the evidence narrative becomes hard to follow.

## Phase 1: SETUP

Prepare the simulator and evidence directory.

```bash
JOURNEY="ios-validation-run-$(date +%Y%m%d-%H%M%S)"
mkdir -p "e2e-evidence/$JOURNEY"

# Identify the booted simulator. jq is cleaner and more robust than inline Python.
UDID=$(xcrun simctl list devices booted -j | jq -r '.devices | .[] | .[] | select(.state=="Booted") | .udid' | head -1)

if [ -z "$UDID" ]; then
    xcrun simctl boot "iPhone 16 Pro"
    UDID=$(xcrun simctl list devices booted -j | jq -r '.devices | .[] | .[] | select(.state=="Booted") | .udid' | head -1)
fi

echo "Using simulator: $UDID" | tee "e2e-evidence/$JOURNEY/step-01-setup.txt"
xcrun simctl list devices booted >> "e2e-evidence/$JOURNEY/step-01-setup.txt"
```

## Phase 2: RECORD

Start continuous capture **before** interacting with the app. Both commands below run in the background and produce files that grow for the whole run — you stop them in Phase 4 COLLECT.

PIDs matter: save `$!` immediately after each backgrounding. You need the PIDs later to stop the captures cleanly. If you lose the PID, `pkill -INT -f recordVideo` is a fallback, but saving them explicitly is safer.

### Video Recording

```bash
xcrun simctl io "$UDID" recordVideo "e2e-evidence/$JOURNEY/step-02-recording.mp4" &
VIDEO_PID=$!
echo "Video recording PID: $VIDEO_PID" > "e2e-evidence/$JOURNEY/step-02-video-pid.txt"

# Sanity check: process should be alive
sleep 1
if ! kill -0 $VIDEO_PID 2>/dev/null; then
  echo "WARNING: video recorder exited immediately. Check permissions / simulator state." >&2
fi
```

**Why SIGINT, not SIGKILL?** `xcrun simctl io recordVideo` finalizes the MP4 container when it receives SIGINT — muxing headers, writing the index, closing cleanly. SIGKILL (`kill -9`) bypasses that, leaving a truncated file that many players refuse to open. Phase 4 uses `kill -INT`.

### Log Streaming

```bash
xcrun simctl spawn "$UDID" log stream \
  --predicate "subsystem == \"$BUNDLE_ID\"" \
  --level debug \
  > "e2e-evidence/$JOURNEY/step-02-logs.txt" 2>&1 &
LOG_PID=$!
echo "Log stream PID: $LOG_PID" > "e2e-evidence/$JOURNEY/step-02-log-pid.txt"

sleep 1
if ! kill -0 $LOG_PID 2>/dev/null; then
  echo "WARNING: log stream exited immediately. Check BUNDLE_ID is correct." >&2
fi
```

**Why `--level debug`?** Without it, the stream only surfaces `default` and `info`-priority logs, which misses most app-level `os_log`-style debug output — exactly the signals you need to correlate with UI state during a flow.

## Phase 3: ACT

Exercise the feature through the real UI. Capture screenshots at each significant state.

### Check idb availability first

```bash
if ! command -v idb >/dev/null 2>&1; then
  echo "idb not found. Install with: brew tap facebook/fb && brew install idb-companion"
  echo "Falling back to manual interaction + screenshots."
fi
```

If idb is available, use the CLI approach below for reproducible automation. If not, drive the simulator manually (UI clicks in the Simulator window) and follow the **manual description** section — still capture screenshots after each action.

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
| Deleting evidence after PASS | Keep all evidence for audit trail. After verdict, commit the evidence directory to version control so the artifact lives beyond the session: `git add e2e-evidence/$JOURNEY && git commit -m "ios-validation-run evidence"` |
| Running ACT phase without RECORD phase | No video/log evidence of what happened |

## Integration with ValidationForge

- All evidence goes to `e2e-evidence/{journey-name}/`
- The `verdict-writer` agent reads evidence-inventory.txt to find all files
- Video files provide temporal evidence that screenshots cannot
- Log correlation with UI actions proves end-to-end functionality
