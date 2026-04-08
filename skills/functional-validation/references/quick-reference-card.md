# Functional Validation — Quick Reference Card

## The Iron Rule (memorize this)

```
REAL SYSTEM broken? → FIX THE REAL SYSTEM.
Never mocks. Never stubs. Never test files. Never test frameworks.
```

## Pre-Flight (5 questions — all must be YES)

1. Real system running? (not dev server with mocks)
2. Accessible as user would access it? (browser/simulator/CLI, not REPL)
3. All dependencies real? (real DB, real API keys, real network)
4. PASS criteria written down? (specific, observable, measurable)
5. Capturing evidence to files? (not just eyeballing)

## The Protocol (4 steps)

| Step | Action | Output |
|------|--------|--------|
| 1. Build & Launch | Build real system, start all deps | Running app with real dependencies |
| 2. Exercise UI | Interact as a real user would | Observed behavior for each criterion |
| 3. Capture Evidence | Screenshots, responses, logs to files | `e2e-evidence/` directory populated |
| 4. Write Verdict | PASS/FAIL per criterion with citations | Verdict doc with evidence references |

## Platform Detection (check in order)

| Indicator | Platform | Tool |
|-----------|----------|------|
| `*.xcodeproj` | iOS/macOS | xcodebuild + simctl/idb |
| `build.gradle` | Android | gradle + adb |
| `package.json` + framework | Web | dev server + Playwright |
| `main.go` / `src/main.rs` | CLI | build binary + execute |
| `server.ts` / `app.py` | API | start server + curl |
| Frontend + Backend | Full-Stack | Bottom-up: DB → API → UI |

## Evidence Quality (one-line rules)

- Screenshots: DESCRIBE what you see, don't confirm existence
- API: QUOTE response body, not just status code
- Build: QUOTE success line with warning count
- CLI: QUOTE stdout content, not just exit code
- Logs: QUOTE specific lines with timestamps

## Red Flags (STOP if you think these)

- "Let me add a mock fallback" → Fix real dependency
- "Quick unit test" → Run real app
- "Stub the database" → Start real database
- "Too slow" → That's a real bug
- "Test mode flag" → One mode: production
