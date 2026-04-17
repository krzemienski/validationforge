---
skill: ios-validation-runner
reviewer: R3
date: 2026-04-16
verdict: PASS
---

# ios-validation-runner review

## Frontmatter check
- name: `ios-validation-runner`
- description: `Five-phase iOS protocol: SETUP → RECORD (video+logs) → ACT (interaction) → COLLECT (artifacts) → VERIFY (verdict). Complex flows & debug scenarios. Video catches temporal evidence screenshots miss.`
- description_chars: 161
- yaml_parses: yes

## Trigger realism
- Trigger phrases: `ios validation runner`, `run ios validation`, `ios test run`, `validate ios feature`
- Realism score (5/5): Triggers match real iOS validation execution workflows

## Body-description alignment
- Verdict: PASS
- Evidence: Description matches body exactly. Five-phase protocol is clearly diagrammed and each phase is detailed: (1) SETUP (boot simulator, create evidence dir), (2) RECORD (video + logs in background), (3) ACT (exercise feature via idb or manual), (4) COLLECT (stop recording, gather artifacts), (5) VERIFY (analyze evidence, produce verdict). CRITICAL emphasis on `kill -INT` not `kill -9` for video integrity. Mandatory `--level debug` for logs.

## MCP tool existence
- Tools referenced: `xcrun simctl`, `idb`, `ps`, `kill`
- Confirmed: yes (standard Unix and Xcode tools)

## Example invocation
"Run the iOS validation runner for the checkout flow with video evidence"

## Verdict
PASS
- Five-phase protocol is complete and sequenced (SETUP → RECORD → ACT → COLLECT → VERIFY)
- CRITICAL rules are explicitly highlighted (kill -INT not -9, --level debug mandatory)
- NEVER patterns section documents 7 anti-patterns with explanations
- Action log pattern encourages documentation of every interaction
- Verification step is mandatory and rigorous (read logs, review screenshots, check video, check crashes)
- Report template is provided with specific required sections
- Integration section clearly states this is for complex multi-step flows (contrast with ios-validation-gate for simpler cases)
