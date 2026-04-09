# Validation Discipline

## No-Mock Mandate

Never create test files, mocks, stubs, or test doubles. This includes:
- Files named `*.test.*`, `*.spec.*`, `*.mock.*`
- Any file importing `jest.mock`, `sinon`, or similar test frameworks
- In-memory fakes substituting for real services
- XCTest mocks or OCMock stubs instead of a real running simulator

## Evidence Standards

Every PASS/FAIL verdict must cite specific evidence:
- **Screenshots**: Describe what you SEE on the simulator screen, not that the file exists
- **Deeplink navigation**: Confirm the correct screen rendered with actual UI state
- **Build output**: Quote the actual success/failure line from xcodebuild
- **Simulator logs**: Include timestamps from the real device log
- **Empty files**: 0-byte or near-empty files are INVALID evidence

## Gate Protocol

Never claim completion without personally examining the evidence:
1. Launch the iOS simulator
2. Trigger the deeplink (`xcrun simctl openurl booted myapp://...`)
3. Capture a screenshot showing the resulting screen
4. Write verdict citing specific screen elements visible in the screenshot
5. Only then mark the journey complete

## iOS-Specific Rules

- Always validate against a **running simulator** — never against compiled code alone
- Capture the simulator state before AND after deeplink invocation
- Deeplink routing must be verified by observing the actual navigation outcome
- Background/foreground transitions must be explicitly tested if the app was already running

## Iron Rules

```
1. IF the real system doesn't work, FIX THE REAL SYSTEM.
2. NEVER mark a journey PASS without specific cited evidence.
3. NEVER skip preflight — if the simulator isn't running, START IT.
4. NEVER exceed 3 fix attempts per journey.
5. Compilation success is NOT functional validation.
6. A deeplink that compiles is NOT a deeplink that navigates correctly.
```
