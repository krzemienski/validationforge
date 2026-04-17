---
skill: ios-validation
reviewer: R3
date: 2026-04-16
verdict: PASS
---

# ios-validation review

## Frontmatter check
- name: `ios-validation`
- description: `iOS/macOS validation: Xcode build → simulator install/launch → screenshot/video/logs/deep links/accessibility tree. 9-step protocol from build through crash detection.`
- description_chars: 145
- yaml_parses: yes

## Trigger realism
- Trigger phrases: `ios feature validation`, `xcode build simulator`, `ios ui testing`, `deep link validation`, `ios accessibility testing`
- Realism score (5/5): Triggers match real iOS development workflows

## Body-description alignment
- Verdict: PASS
- Evidence: Description matches body exactly. 9-step protocol: (1) Build, (2) Install, (3) Launch, (4) Screenshot, (5) Video, (6) Logs, (7) Deep Links, (8) UI Automation (idb vs Xcode MCP), (9) Crash Detection. PASS Criteria Template is concrete and testable. Common Failures table covers 8 scenarios (xcodebuild, simulator, app crashes, deep links, simctl install, black screenshots, idb).

## MCP tool existence
- Tools referenced: `idb` (optional), `xcodebuild` (Xcode), `xcrun simctl` (Xcode), `Xcode MCP` (conditional)
- Confirmed: yes (Xcode tools are standard; Xcode MCP is conditional on Claude Code session config)

## Example invocation
"Validate the iOS login feature on the iPhone 16 simulator"

## Verdict
PASS
- 9-step protocol is complete and sequenced logically (build → install → launch → capture → verify)
- Evidence quality guidance is explicit: "Describe what you see" not "page loaded"
- Two UI automation paths offered: idb CLI and Xcode MCP (good flexibility)
- PASS Criteria Template is concrete and measurable
- Common Failures table covers real issues (scheme missing, simulator won't boot, crashes, black screenshots)
- Context priority correctly set to `reference` (use as companion to ios-validation-gate, ios-validation-runner)
