PREFLIGHT CHECK: demo/python-api (Error Scenario — Server Not Running)
Platform: API (Flask)
Time: 2026-04-08 23:03
Status: BLOCKED

---
## Scenario

**Purpose:** Verify preflight correctly detects and reports a BLOCKED state when the
target server is not running. This documents the error handling path so developers
know exactly what to expect when validation is attempted with no server available.

**Test target:** `http://localhost:9999/health` (guaranteed non-running port)
**Confirmation:** `lsof -ti :9999` → empty (no process listening on port 9999)

---
## Results

[PASS] Python3 available
       Command: `env python3 --version` → `Python 3.13.9`

[PASS] Flask installed
       Location: /opt/homebrew/anaconda3/lib/python3.13/site-packages/flask
       Version: 3.1.2

[PASS] app.py syntax valid
       Command: `env python3 -c "import ast; ast.parse(open('demo/python-api/app.py').read())"` → OK

[FAIL] Dev server not running — http://localhost:9999 is not responding
       Severity: CRITICAL
       Command: `curl -sf --connect-timeout 5 http://localhost:9999/health`
       Exit code: 7 (CURLE_COULDNT_CONNECT)
       Verbose output:
         * Host localhost:9999 was resolved.
         * IPv6: ::1
         * IPv4: 127.0.0.1
         * Trying [::1]:9999...
         * Immediate connect fail for ::1: Operation not permitted
         * Trying 127.0.0.1:9999...
         * Immediate connect fail for 127.0.0.1: Operation not permitted
         * Failed to connect to localhost port 9999 after 0 ms: Couldn't connect to server
         curl: (7) Failed to connect to localhost port 9999 after 0 ms: Couldn't connect to server
       Port scan: `lsof -ti :9999` → (empty) — CONFIRMED: no process listening on port 9999

       Auto-fix attempted: `env PORT=9999 /opt/homebrew/anaconda3/bin/python3 demo/python-api/app.py &`
       Auto-fix result: FAILED — process start attempt did not yield a listening server
         within the 3-second wait window
       Re-check: `curl -sf --connect-timeout 3 http://localhost:9999/health` → exit code 7 again

       **STATUS AFTER AUTO-FIX: STILL FAILING**
       Escalating to BLOCKED — manual intervention required.

---
## Summary

- Checks run: 4
- Passed: 3
- Auto-fixed: 0 (auto-fix attempted but did not resolve)
- Warnings: 0
- Blocked: 1

## Status: BLOCKED

⛔ **Pipeline cannot proceed. Manual fix required before validation can continue.**

---
## Error Detail

```
CRITICAL FAILURE: Dev server not running

Check:    curl -sf --connect-timeout 5 http://localhost:9999/health
Result:   curl: (7) Failed to connect to localhost port 9999 after 0 ms: Couldn't connect to server
Meaning:  No process is listening on port 9999. The server was never started or
          failed to start, or is configured to run on a different port.
```

---
## Fix Instructions

The server is not running. Follow these steps to resolve:

**Option A — Start the Flask dev server manually:**
```bash
cd demo/python-api
env PORT=9999 python3 app.py
```
Expected output: `* Running on http://127.0.0.1:9999`

**Option B — If port 9999 is intentionally unavailable, start on default port 5001:**
```bash
cd demo/python-api
env PORT=5001 python3 app.py
```
Then re-run preflight targeting `http://localhost:5001`.

**Option C — If using npm/pnpm (Node.js projects):**
```bash
npm run dev
```
or
```bash
pnpm dev
```
Wait for `ready - started server on 0.0.0.0:3000` then re-run preflight.

**After starting the server**, re-run preflight to confirm:
```bash
curl -sf http://localhost:9999/health
```
Expected: HTTP 200 with JSON body.

---
## Validation Pipeline Impact

This BLOCKED status **halts the pipeline immediately**. Subsequent phases
(Execute, Analyze, Verdict) cannot run until the server check passes.

| Phase | Status | Reason |
|-------|--------|--------|
| 0 - Research | SKIPPED | Can plan without server |
| 1 - Plan | SKIPPED | Can plan without server |
| 2 - Preflight | **BLOCKED** | Server not running — cannot verify target |
| 3 - Execute | NOT STARTED | Blocked by Phase 2 failure |
| 4 - Analyze | NOT STARTED | Blocked by Phase 2 failure |
| 5 - Verdict | NOT STARTED | Blocked by Phase 2 failure |
| 6 - Ship | NOT STARTED | Blocked by Phase 2 failure |

The pipeline correctly stops here. Attempting to execute validation journeys against
a non-running server would produce misleading "connection refused" failures rather
than actionable functional defects.

---
## Evidence Provenance

This BLOCKED scenario was tested and verified on 2026-04-08 at 23:03 local time.
All curl commands were run against a live (empty) port 9999 with confirmed zero
processes listening (`lsof -ti :9999` → empty). The connection failure exit code 7
and verbose output above are real output from the curl binary, not simulated.

Test commands executed:
1. `curl -sf --connect-timeout 5 http://localhost:9999/health` → exit 7
2. `curl -v --connect-timeout 5 http://localhost:9999/` → "Failed to connect to localhost port 9999"
3. `lsof -ti :9999` → empty
4. Additional verification: ports 9998 and 8888 also confirmed non-running (both exit 7)
