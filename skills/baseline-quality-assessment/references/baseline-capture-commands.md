# Baseline Capture Commands

Platform-specific commands for capturing baseline evidence.

## Capture Commands by Platform

| Platform | What to Capture | Command | Storage Path |
|----------|----------------|---------|-------------|
| Web | Screenshot of each route | Playwright MCP `browser_take_screenshot` | `baseline/page-[route].png` |
| Web | Console errors per page | Playwright MCP `browser_console_messages` | `baseline/console-[route].txt` |
| Web | Network requests per page | Playwright MCP `browser_network_requests` | `baseline/network-[route].txt` |
| API | Response for each endpoint | `curl -s -w "\n%{http_code}\n%{time_total}" [url]` | `baseline/api-[endpoint].json` |
| API | OpenAPI spec (if exists) | `curl -s [url]/docs/openapi.json` | `baseline/openapi-spec.json` |
| iOS | Screenshot of each screen | `xcrun simctl io booted screenshot [path]` | `baseline/screen-[name].png` |
| iOS | Build output | `xcodebuild build 2>&1` | `baseline/build-output.txt` |
| CLI | Output of each command | `./cli [command] 2>&1` | `baseline/cli-[command].txt` |
| CLI | Help text | `./cli --help 2>&1` | `baseline/cli-help.txt` |
| Any | Performance timing | `time [command] 2>&1` | `baseline/perf-[name].txt` |

## Baseline Assessment Document

Save to `e2e-evidence/baseline/assessment.md`:

```markdown
# Baseline Assessment

**Project:** [Name]
**Date:** [YYYY-MM-DD]
**Captured by:** Claude Code + ValidationForge
**Reason:** [What change is about to happen]

## Current State Summary

- Total features assessed: [N]
- Working: [N]
- Broken (pre-existing): [N]
- Partial: [N]

## Feature Assessments

### B1: [Feature Name]
**Status:** Working | Broken | Partial
**Evidence:** `e2e-evidence/baseline/b1-[name].[ext]`
**Behavior:** [Description of current behavior]
**Notes:** [Known issues or caveats]

## Known Issues (Pre-existing)

These issues exist BEFORE any changes. They are NOT regressions.

1. **B[N] — [Description]** — Evidence: `baseline/[file]`

## Performance Metrics (if applicable)

| Endpoint / Page | Response Time | Status Code | Body Size |
|----------------|---------------|-------------|-----------|
| GET / | 180ms | 200 | 12.4KB |
| POST /api/login | 340ms | 200 | 0.1KB |
```

## Baseline Targets Table

Use this to inventory features before capturing:

```markdown
| ID | Feature | Type | Status |
|----|---------|------|--------|
| B1 | Homepage | Page | To capture |
| B2 | Login flow | Form + API | To capture |
| B3 | GET /api/users | Endpoint | To capture |
| B4 | Dashboard metrics | Page | To capture |
```
