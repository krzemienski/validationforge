---
name: ios-validation-gate
description: Three-gate iOS validation — Simulator, Backend, Analysis — all must PASS
triggers:
  - "ios validation gate"
  - "ios gate"
  - "validate ios app"
  - "ios quality gate"
---

# iOS Validation Gate

Three-gate enforcement for iOS applications. ALL gates must PASS before claiming completion. Each gate captures evidence to `e2e-evidence/`.

## When to Use

- After any iOS feature implementation
- Before claiming an iOS task is complete
- As the iOS platform validator in `e2e-validate` journeys

## Gate Architecture

```
Gate 1: SIMULATOR        Gate 2: BACKEND         Gate 3: ANALYSIS
Build + Install +        Health + Endpoints +     Logs + Screenshots +
Screenshot + a11y        Response validation      Behavior correlation
    |                        |                        |
    v                        v                        v
  PASS/FAIL              PASS/FAIL                PASS/FAIL
    \                        |                        /
     \                       |                       /
      --------> ALL THREE MUST PASS <---------
```

## Parameters

Detect these from the project or accept as arguments:

| Parameter | Source | Example |
|-----------|--------|---------|
| `SCHEME` | `*.xcodeproj` or `xcodebuild -list` | `MyApp` |
| `BUNDLE_ID` | `Info.plist` → `CFBundleIdentifier` | `com.example.myapp` |
| `UDID` | `xcrun simctl list devices booted` | `XXXXXXXX-XXXX-...` |
| `BACKEND_PORT` | Project config or README | `8080` |
| `BACKEND_URL` | Derived from port | `http://localhost:8080` |

## Gate 1: Simulator Gate

**Objective:** App builds, installs, launches, and renders correctly on a real simulator.

### Steps

```bash
mkdir -p e2e-evidence/ios-gate-1-simulator
```

1. **Build** the project:
```bash
xcodebuild -scheme "$SCHEME" -destination "platform=iOS Simulator,id=$UDID" \
  -derivedDataPath build/ build 2>&1 | tee e2e-evidence/ios-gate-1-simulator/step-01-build.log
```

2. **Install** the app:
```bash
xcrun simctl install "$UDID" "build/Build/Products/Debug-iphonesimulator/${SCHEME}.app" \
  2>&1 | tee e2e-evidence/ios-gate-1-simulator/step-02-install.log
```

3. **Launch** the app:
```bash
xcrun simctl launch "$UDID" "$BUNDLE_ID" \
  2>&1 | tee e2e-evidence/ios-gate-1-simulator/step-03-launch.log
```

4. **Wait** for UI to settle (3 seconds minimum)

5. **Screenshot** the initial state:
```bash
xcrun simctl io "$UDID" screenshot e2e-evidence/ios-gate-1-simulator/step-04-initial-screen.png
```

6. **Accessibility tree** (requires idb):
```bash
idb ui describe-all --udid "$UDID" > e2e-evidence/ios-gate-1-simulator/step-05-accessibility-tree.txt
```

### PASS Criteria
- Build exits 0 with no errors (warnings OK)
- App launches without crash
- Screenshot shows expected initial screen (describe what you see)
- Accessibility tree has interactive elements

### FAIL Triggers
- Build error (any)
- Launch crash (check `xcrun simctl spawn $UDID log stream --predicate 'eventMessage contains "crash"'`)
- Screenshot shows blank/black screen
- No accessibility elements found

## Gate 2: Backend Gate

**Objective:** If the app depends on a backend, verify it is running and responding correctly.

**Skip condition:** If the app is purely offline/local, mark this gate as `PASS (N/A — no backend dependency)` and document why.

### Steps

```bash
mkdir -p e2e-evidence/ios-gate-2-backend
```

1. **Health check:**
```bash
curl -s -o e2e-evidence/ios-gate-2-backend/step-01-health.json \
  -w "\nHTTP_STATUS:%{http_code}\n" "$BACKEND_URL/health" \
  | tee e2e-evidence/ios-gate-2-backend/step-01-health-status.txt
```

2. **Key endpoints** (identify from app code — network calls, API clients):
```bash
# For each critical endpoint:
curl -s -o "e2e-evidence/ios-gate-2-backend/step-02-endpoint-NAME.json" \
  -w "\nHTTP_STATUS:%{http_code}\n" "$BACKEND_URL/api/endpoint" \
  | tee "e2e-evidence/ios-gate-2-backend/step-02-endpoint-NAME-status.txt"
```

3. **Response validation:**
   - Read each saved response file
   - Verify JSON structure matches what the app expects
   - Check for error responses

### PASS Criteria
- Health endpoint returns 200
- All critical endpoints return expected status codes
- Response bodies have expected structure (not empty, not error objects)

### FAIL Triggers
- Health endpoint unreachable or non-200
- Any critical endpoint returns 4xx/5xx
- Response body is empty or contains error structure

## Gate 3: Analysis Gate

**Objective:** Correlate logs, screenshots, and behavior to confirm the feature actually works end-to-end.

### Steps

```bash
mkdir -p e2e-evidence/ios-gate-3-analysis
```

1. **Capture app logs** during feature exercise:
```bash
xcrun simctl spawn "$UDID" log stream \
  --predicate "subsystem == \"$BUNDLE_ID\"" \
  --level debug --timeout 15 \
  2>&1 | tee e2e-evidence/ios-gate-3-analysis/step-01-app-logs.txt
```

2. **Exercise the feature** (tap, navigate, interact via idb or manual description)

3. **Screenshot after interaction:**
```bash
xcrun simctl io "$UDID" screenshot e2e-evidence/ios-gate-3-analysis/step-02-after-interaction.png
```

4. **Correlate:**
   - Read the logs — do they show the expected flow? (network calls, state changes, navigation events)
   - Compare before/after screenshots — did the UI change as expected?
   - Check for error logs, crashes, or unexpected warnings

5. **Write correlation report:**
```bash
cat > e2e-evidence/ios-gate-3-analysis/step-03-correlation.md << 'EOF'
# Behavior Correlation

## Log Evidence
- [timestamp] Observed: {what the log shows}
- [timestamp] Observed: {what the log shows}

## Screenshot Evidence
- Before: {describe initial screen}
- After: {describe post-interaction screen}

## Correlation
{Do the logs match the visual changes? Is the feature working end-to-end?}

## Verdict: PASS | FAIL
EOF
```

### PASS Criteria
- Logs show expected execution flow without errors
- Screenshots show expected state transitions
- Log events correlate with visual changes
- No crash logs or unhandled exceptions

### FAIL Triggers
- Error logs during feature exercise
- Screenshots don't show expected changes
- Logs and screenshots don't correlate (UI changed but no backend call, or backend call but no UI update)
- Crash or unhandled exception in logs

## Final Verdict

```markdown
# iOS Validation Gate Report

| Gate | Verdict | Evidence Files |
|------|---------|----------------|
| 1. Simulator | PASS/FAIL | e2e-evidence/ios-gate-1-simulator/ |
| 2. Backend | PASS/FAIL/N/A | e2e-evidence/ios-gate-2-backend/ |
| 3. Analysis | PASS/FAIL | e2e-evidence/ios-gate-3-analysis/ |

**Overall: PASS | FAIL**
```

Save to `e2e-evidence/ios-gate-report.md`.

## Rules

- ALL three gates must PASS for overall PASS
- A single FAIL in any gate = overall FAIL
- Never skip Gate 3 (Analysis) — build + launch alone proves nothing
- Every PASS must cite the specific evidence file
- Every FAIL must include root cause and remediation
