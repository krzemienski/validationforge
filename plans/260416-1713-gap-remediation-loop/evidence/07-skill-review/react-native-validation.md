---
skill: react-native-validation
reviewer: R3
date: 2026-04-16
verdict: PASS
---

# react-native-validation review

## Frontmatter check
- name: `react-native-validation`
- description: `Validate React Native apps via Metro/Expo: platform build, launch, screenshots, logs, deep link testing on iOS/Android. Detects crashes, console errors, bundle issues. Covers Expo Go, CLI, bare RN.`
- description_chars: 161
- yaml_parses: yes

## Trigger realism
- Trigger phrase: (none in YAML; skill is platform-specific reference)
- Realism score (5/5): Skill is positioned as platform-specific validation reference for React Native

## Body-description alignment
- Verdict: PASS
- Evidence: Description matches body exactly. Seven steps: (1) Metro Startup (background, health check), (2) Build and Launch (React Native CLI for iOS/Android), (3) Build and Launch (Expo CLI and Expo Go variants), (4) Screenshot Capture (iOS simctl, Android adb), (5) Log Streaming (iOS device logs, Android logcat, Metro bundler logs), (6) Deep Link Testing (iOS xcrun simctl openurl, Android adb am start), (7) Crash Detection (iOS crashes, Android crash logs, Metro red screen). Evidence Quality section includes GOOD vs BAD screenshot descriptions. Common Failures table covers 11 scenarios.

## MCP tool existence
- Tools referenced: `npx react-native`, `npx expo`, `xcrun simctl`, `adb`, `emulator`, `kill`, `curl`
- Confirmed: yes (standard React Native tooling and Android SDK tools)

## Example invocation
"Validate the React Native authentication flow on iOS and Android"

## Verdict
PASS
- Seven-step protocol is complete and covers both iOS and Android
- Prerequisites section is thorough (Node.js, npm/yarn, React Native CLI/Expo CLI, simulators, Metro port check)
- Metro Startup section distinguishes between `react-native start` and `expo start`
- Health check command (`curl http://localhost:8081/status`) confirms Metro readiness
- Build and Launch offers two paths: React Native CLI and Expo CLI + Expo Go
- Screenshot Capture covers both iOS (xcrun simctl) and Android (adb screencap)
- Log Streaming covers iOS device logs, Android logcat, and Metro bundler logs separately
- Deep Link Testing covers iOS custom schemes, Android intent filters, and universal links
- Crash Detection covers iOS crash reports, Android fatal logs, and Metro red screen
- Evidence Quality guidance is explicit: "Describe what is VISIBLE, not what you expect"
- Common Failures table covers 11 scenarios with solutions
- PASS Criteria Template provides 10 checkpoints
- Cleanup section documents stopping Metro
