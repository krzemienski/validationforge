# Evidence Standards & Anti-Patterns

## Evidence Standards by Type

### Screenshots

Describe what you SEE in the screenshot, not that it exists.

- **GOOD**: "Viewed `e2e-evidence/dashboard.png` — shows 3 card widgets in a grid:
  'Total Users: 1,247', 'Active Sessions: 89', 'Error Rate: 0.3%'. Navigation
  sidebar on the left shows 5 items. User avatar 'NK' visible in top-right corner."
- **BAD**: "Screenshot exists at `e2e-evidence/dashboard.png`"
- **BAD**: "Dashboard screenshot captured successfully"
- **BAD**: "Screenshot shows the dashboard" (what specifically?)

### API Responses

Quote the actual response body, not just the HTTP status code.

- **GOOD**: "Response from `POST /api/auth/login`:
  ```json
  {"success": true, "token": "eyJhbG...", "user": {"id": 42, "email": "alice@example.com"}}
  ```
  HTTP 200, Content-Type: application/json, response time: 127ms."
- **BAD**: "Login endpoint returned 200 OK"
- **BAD**: "API call succeeded"
- **BAD**: "Authentication works" (prove it)

### Build Output

Quote the actual output line showing success, including warnings count.

- **GOOD**: "Build output final line: `Build Succeeded [2026-03-07 14:22:33.041]`
  with `0 errors, 0 warnings`. Archive produced at `build/Release/MyApp.app` (14.2 MB)."
- **BAD**: "Build succeeded"
- **BAD**: "xcodebuild exited with code 0"
- **BAD**: "No build errors" (how many warnings? was an artifact produced?)

### CLI Output

Quote the full stdout with actual content, not just the exit code.

- **GOOD**: "Command `./mytool process --input data.csv` produced:
  ```
  Reading data.csv... 1,847 rows loaded
  Processing: 100%
  Output written to /tmp/result.json (847 KB)
  Summary: 1,847 processed, 12 warnings, 0 errors
  ```"
- **BAD**: "Command completed successfully"
- **BAD**: "Exit code 0"

### Logs

Quote specific log lines with timestamps, not "logs look clean."

- **GOOD**: "Server log at 14:22:01: `[INFO] OAuth callback received for user 42,
  session abc123 created, redirecting to /dashboard`. No ERROR or WARN lines in
  the 50 most recent log entries."
- **BAD**: "Logs look clean"
- **BAD**: "No errors in the logs"

## Anti-Patterns Table

| # | Anti-Pattern | Why It Fails | Correct Approach |
|---|-------------|-------------|-----------------|
| 1 | **Report Trust** | Sub-agent says "all passed" but skipped edge cases | Personally examine the evidence the sub-agent produced |
| 2 | **Existence Checking** | File exists but may contain errors or empty content | READ the file and describe its content |
| 3 | **Exit Code Only** | Exit 0 but stdout contains warnings or partial failures | Read full stdout/stderr, quote relevant lines |
| 4 | **Premature Advance** | Moving to Phase 2 before Phase 1 is verified | Complete verification loop for current phase first |
| 5 | **Screenshot Blindness** | Confirming screenshot exists without viewing it | Open the screenshot, describe what you see in detail |
| 6 | **Status Code Trust** | HTTP 200 but body contains `{"error": "..."}` | Quote the response body, not just the status code |
| 7 | **Build = Works** | Build succeeded but app crashes on launch | Build is Step 1; launch and interact is Step 2 |
| 8 | **Log Silence** | "No errors in logs" without reading the logs | Quote specific log lines, confirm expected entries exist |
| 9 | **Delegation Handoff** | Marking complete because you delegated the work | You delegated the work; you still own the verification |
| 10 | **Partial Pass** | 7 of 10 criteria pass, marking "mostly done" | All criteria must pass. PARTIAL is not COMPLETE. |
