# Workflow: Execute

**Objective:** Run the full validation pipeline — build the system, exercise every journey, capture evidence, review evidence, and write verdicts.

## Prerequisites

- Approved validation plan (`e2e-evidence/plan.md`)
- Detected platform type and platform reference loaded
- System source code accessible

## Process

### Step 1: Build the Real System

Build using the project's actual build system. Do NOT skip this step.

| Platform | Build Command | Success Indicator |
|----------|--------------|-------------------|
| iOS | `xcodebuild -scheme X -destination 'platform=iOS Simulator,name=iPhone 16' build` | `BUILD SUCCEEDED` in output |
| Web | `npm run build` / `pnpm build` / `yarn build` | Exit code 0, no errors |
| API | `cargo build` / `go build` / `pip install -e .` / `npm install` | Exit code 0, binary exists |
| CLI | `cargo build --release` / `go build -o ./bin/tool` | Binary exists at expected path |
| Fullstack | Backend build THEN frontend build | Both succeed |

**If build fails:** STOP. Fix the build error first. Do not proceed to validation with a broken build.

### Step 2: Start the Real System

| Platform | Start Command | Ready Indicator |
|----------|--------------|-----------------|
| iOS | `xcrun simctl boot 'iPhone 16'` then install and launch | App appears on simulator |
| Web | `npm run dev` / `pnpm dev` (background) | `ready on http://localhost:PORT` |
| API | `cargo run` / `go run .` / `python app.py` (background) | Health endpoint returns 200 |
| CLI | N/A (run per-journey) | Binary executes without crash |
| Fullstack | Start DB → start API → start frontend | All health checks pass |

**Background processes:** Use `run_in_background` for servers. Wait for ready indicator before proceeding.

### Step 3: Execute Each Journey

For each journey in the approved plan, in execution order:

#### 3a. Navigate to Entry Point

| Platform | Navigation Method |
|----------|------------------|
| iOS | `xcrun simctl openurl booted 'myapp://path'` or idb tap sequence |
| Web | `browser_navigate` to URL or `navigate_page` to URL |
| API | Construct curl command with method, URL, headers, body |
| CLI | Construct command with arguments |

#### 3b. Perform Journey Steps

Execute each step from the plan. Between steps:
- Wait for UI to settle (use condition-based-waiting, not sleep)
- Check for error states before proceeding
- If a step fails, record the failure and continue to next journey (don't abort all)

#### 3c. Capture Evidence

Capture evidence IMMEDIATELY after the journey reaches its end state.

| Platform | Capture Commands |
|----------|-----------------|
| iOS | `xcrun simctl io booted screenshot e2e-evidence/j{N}-{slug}.png` |
| iOS (logs) | `xcrun simctl spawn booted log stream --predicate '...' --timeout 5` |
| Web | `browser_take_screenshot` or `take_screenshot` to `e2e-evidence/j{N}-{slug}.png` |
| Web (console) | `browser_console_messages` or `list_console_messages` — save output |
| Web (network) | `browser_network_requests` or `list_network_requests` — save output |
| API | `curl -s URL \| tee e2e-evidence/j{N}-{slug}.json \| jq .` |
| CLI | `./tool args 2>&1 \| tee e2e-evidence/j{N}-{slug}.txt; echo "EXIT:$?"` |

**Naming convention:** `e2e-evidence/j{number}-{journey-slug}.{ext}`

#### 3d. READ the Evidence (MANDATORY)

This is the most critical step. For EVERY piece of evidence captured:

1. **Open the file** — Read the screenshot, response body, or output
2. **Describe what you see** — In your own words, not just "evidence captured"
3. **Note specific values** — Numbers, text, element counts, status codes
4. **Flag discrepancies** — Anything unexpected or concerning

```
GOOD: "Screenshot j3-dashboard.png shows: header with 'Welcome, Nick',
       3 metric cards (Sessions: 41, Agents: 12, Success Rate: 94.2%),
       chart with 7 data points spanning Jan-Mar"

BAD:  "Screenshot captured successfully"
```

#### 3e. Match Evidence to PASS Criteria

For each PASS criterion in the plan:
- Find the specific evidence that proves it
- Quote the relevant portion of the evidence
- Mark as PASS or FAIL

```
Criterion: "Dashboard shows user name in header"
Evidence:  j3-dashboard.png — header reads "Welcome, Nick"
Verdict:   PASS
```

### Step 4: Write Verdicts

For each journey, write a verdict block:

```markdown
### J{N}: {Journey Name} — {PASS|FAIL}

**Evidence:** `e2e-evidence/j{N}-{slug}.{ext}`
**Criteria Results:**
- [x] Criterion 1 — PASS (evidence: {quote})
- [ ] Criterion 2 — FAIL (expected: X, actual: Y)

**Notes:** {any observations}
```

### Step 5: Handle Failures

For each FAIL verdict:
1. Record the root cause (what went wrong)
2. Record the expected vs actual behavior
3. If `--fix` flag is set, hand off to `workflows/fix-and-revalidate.md`
4. If no `--fix` flag, include failure details in the report

### Step 6: Error Recovery During Execution

| Error Type | Recovery Action | Max Retries |
|-----------|----------------|-------------|
| Evidence capture fails (screenshot timeout) | Wait 2s, retry capture | 3 |
| Server crashes during journey | Restart server, retry journey from beginning | 2 |
| Simulator becomes unresponsive | `xcrun simctl shutdown` + reboot, retry | 1 |
| Browser tab crashes | Close and reopen, navigate back to entry point | 2 |
| Network timeout on API call | Retry with increased timeout | 3 |
| Build breaks after fix attempt | Revert fix, record as unresolvable | 0 |

After max retries, mark the journey as FAIL with error details and move to the next journey.

## Output

- `e2e-evidence/j{N}-{slug}.{ext}` — Evidence files for each journey
- Verdict blocks for each journey (PASS/FAIL with evidence references)
- Summary: total journeys, passed, failed, error count

## Next Step

Feed verdicts into `workflows/report.md` to generate the final report.
If `--fix` is active and failures exist, route to `workflows/fix-and-revalidate.md` first.
