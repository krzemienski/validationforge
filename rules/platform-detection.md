# Platform Detection

## Detection Priority

1. **iOS** — `.xcodeproj`, `.xcworkspace`, `*.swift`, `Package.swift`
2. **React Native** — `react-native` in package.json, `metro.config.js`, `ios/` + `android/` dirs
3. **Flutter** — `pubspec.yaml`, `flutter` SDK dependency, `lib/main.dart`
4. **CLI** — `bin/` entry in package.json, argument parsers, no UI framework
5. **Rust CLI** — `Cargo.toml`, `src/main.rs`, no web framework deps
6. **API** — Route handlers, OpenAPI spec, no frontend files
7. **Django/Flask** — `manage.py` / `app.py`, `requirements.txt` with django/flask, Python routes
8. **Web** — `package.json` + framework config (next.config, vite.config, etc.)
9. **Fullstack** — Multiple layers detected (frontend + backend + database)
10. **Generic** — Fallback when no platform detected

## Platform-Specific Validation

| Platform | Start Command | Validation Tool | Evidence Method |
|----------|--------------|-----------------|-----------------|
| iOS | `xcrun simctl boot` | idb + simctl | Screenshots + a11y tree |
| React Native | `npx react-native run-ios` / `run-android` | Detox / Appium | Device screenshots + interaction logs |
| Flutter | `flutter run` | Flutter Driver / integration_test | Screenshots + widget tree dumps |
| Web | `npm run dev` | Playwright MCP | Browser screenshots + snapshots |
| API | `npm start` / `python app.py` | curl / fetch | Response JSON + headers |
| Django/Flask | `python manage.py runserver` / `flask run` | curl / fetch | Response JSON + headers + logs |
| CLI | Direct invocation | Shell execution | stdout/stderr capture |
| Rust CLI | `cargo run` / direct binary | Shell execution | stdout/stderr capture + exit codes |
| Fullstack | Multiple services | All of the above | Combined evidence |

## Detection Confidence

- **HIGH** — Strong indicators (xcodeproj, next.config.ts)
- **MEDIUM** — Moderate indicators (package.json without framework)
- **LOW** — Weak indicators (generic file structure)

Always log detection confidence. If LOW, ask user to confirm platform.
