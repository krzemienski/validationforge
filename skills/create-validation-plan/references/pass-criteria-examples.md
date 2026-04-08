# PASS Criteria Examples

20 examples showing bad criteria, why they fail, and the corrected version.

## Web / UI Criteria

| # | Bad Criteria | Why Bad | Good Criteria |
|---|---|---|---|
| 1 | "Page loads" | No specifics about what loads | "GET / returns 200; screenshot shows header, hero section, and footer rendered" |
| 2 | "Login works" | Doesn't define success | "POST /api/login with valid creds returns 200 with JSON containing `token` string > 20 chars" |
| 3 | "Form submits" | Doesn't verify the result | "After form submit, redirect to /dashboard occurs AND GET /api/me returns the submitted name" |
| 4 | "Looks correct" | Subjective, no evidence mapping | "Screenshot shows 3 metric cards: Users (number), Revenue (currency), Growth (percentage)" |
| 5 | "No console errors" | Can't prove absence without capturing | "Playwright console output contains zero entries with level `error`" |

## API Criteria

| # | Bad Criteria | Why Bad | Good Criteria |
|---|---|---|---|
| 6 | "API responds" | Doesn't specify status or body | "GET /api/users returns 200 with JSON array of length >= 1, each item has `id`, `name`, `email`" |
| 7 | "Auth is secure" | Untestable in one step | "GET /api/admin without token returns 401; with valid token returns 200" |
| 8 | "Data persists" | Doesn't specify verification method | "POST /api/items creates item; GET /api/items returns array containing item with matching `title`" |
| 9 | "Handles errors" | Too vague | "POST /api/users with missing `email` field returns 400 with body containing `error` field" |
| 10 | "Fast response" | No threshold | "GET /api/health responds in < 200ms (measured via `curl -w '%{time_total}'`)" |

## iOS Criteria

| # | Bad Criteria | Why Bad | Good Criteria |
|---|---|---|---|
| 11 | "App launches" | Minimum bar, not useful | "App launches to home screen within 3 seconds; screenshot shows tab bar with 4 tabs" |
| 12 | "Navigation works" | Doesn't specify which paths | "Tapping 'Settings' tab shows Settings screen; tapping 'Back' returns to previous screen" |
| 13 | "Data loads" | Doesn't define what data | "List screen shows 5+ items; each item displays title text and thumbnail image (not placeholder)" |
| 14 | "Dark mode supported" | No specific verification | "In dark mode, background is #000000 or #1C1C1E; text is #FFFFFF or #F2F2F7 (screenshot proof)" |
| 15 | "No crashes" | Can't prove a negative | "Navigate all 5 main screens sequentially without Xcode console showing crash log or EXC_" |

## CLI Criteria

| # | Bad Criteria | Why Bad | Good Criteria |
|---|---|---|---|
| 16 | "Command runs" | Doesn't define success output | "`./cli generate --input test.txt` exits with code 0 and stdout contains 'Generated 3 files'" |
| 17 | "Help shows" | Doesn't specify content | "`./cli --help` prints usage line starting with 'Usage:' and lists all 4 subcommands" |
| 18 | "Handles bad input" | Doesn't specify the handling | "`./cli parse --file missing.txt` exits with code 1 and stderr contains 'File not found'" |
| 19 | "Output is correct" | Doesn't define correct | "`./cli convert data.csv` produces `data.json` with valid JSON containing 10 objects" |
| 20 | "Works offline" | Untestable without setup | "With network disabled, `./cli cache --list` returns cached items; `./cli fetch` exits 1 with 'No network'" |

## Principles Summary

1. **Specify the HTTP method, path, status code, and body shape** for API criteria
2. **Reference the screenshot filename and describe what's visible** for UI criteria
3. **Include exit code AND stdout/stderr content** for CLI criteria
4. **Separate happy path and error path** into distinct criteria
5. **Include numbers** (counts, sizes, timings) whenever possible
