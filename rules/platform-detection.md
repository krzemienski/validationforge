# Platform Detection

## Detection Priority

1. **iOS** — `.xcodeproj`, `.xcworkspace`, `*.swift`, `Package.swift`
2. **CLI** — `bin/` entry in package.json, argument parsers, no UI framework
3. **API** — Route handlers, OpenAPI spec, no frontend files
4. **Web** — `package.json` + framework config (next.config, vite.config, etc.)
5. **Fullstack** — Multiple layers detected (frontend + backend + database)
6. **Generic** — Fallback when no platform detected

## Platform-Specific Validation

| Platform | Start Command | Validation Tool | Evidence Method |
|----------|--------------|-----------------|-----------------|
| iOS | `xcrun simctl boot` | idb + simctl | Screenshots + a11y tree |
| Web | `npm run dev` | Playwright MCP | Browser screenshots + snapshots |
| API | `npm start` / `python app.py` | curl / fetch | Response JSON + headers |
| CLI | Direct invocation | Shell execution | stdout/stderr capture |
| Fullstack | Multiple services | All of the above | Combined evidence |

## Detection Confidence

- **HIGH** — Strong indicators (xcodeproj, next.config.ts)
- **MEDIUM** — Moderate indicators (package.json without framework)
- **LOW** — Weak indicators (generic file structure)

Always log detection confidence. If LOW, ask user to confirm platform.
