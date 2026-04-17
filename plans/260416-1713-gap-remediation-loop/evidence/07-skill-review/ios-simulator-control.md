---
skill: ios-simulator-control
reviewer: R3
date: 2026-04-16
verdict: PASS
---

# ios-simulator-control review

## Frontmatter check
- name: `ios-simulator-control`
- description: `iOS Simulator commands: boot, install, launch, screenshot, video, logs, deep links, permissions, location, crash detection. Reference for evidence capture. Used with all iOS validation skills.`
- description_chars: 161
- yaml_parses: yes

## Trigger realism
- Trigger phrases: `simulator control`, `boot simulator`, `simulator screenshot`, `manage simulator`, `simulator lifecycle`
- Realism score (5/5): All triggers match real user actions in iOS validation workflows

## Body-description alignment
- Verdict: PASS
- Evidence: Description is accurate. Skill documents complete simulator lifecycle: List → Boot → Shutdown, App Operations (Install, Launch, Terminate, Uninstall), Evidence Capture (Screenshots, Video, Logs, Crashes), Deep Links, Push Notifications, State Management, Status Board, App Container. Troubleshooting table is comprehensive (8 common problems). Integration section clearly states this is a companion to ios-validation, ios-validation-gate, ios-validation-runner.

## MCP tool existence
- Tools referenced: `xcrun simctl` (standard Xcode CLI tool, not MCP)
- Confirmed: yes (xcrun is part of Xcode; not an MCP integration)

## Example invocation
"Boot the iPhone 16 simulator and take a screenshot"

## Verdict
PASS
- Scope is clear: reference companion, not primary skill
- Commands are real and tested (xcrun simctl is standard Xcode)
- Evidence capture section is concrete (screenshots, video, logs, crashes)
- Troubleshooting table covers 8 common failure modes
- Integration note clearly positions this as support for three iOS validation skills
- Context priority is appropriately set to `reference`
