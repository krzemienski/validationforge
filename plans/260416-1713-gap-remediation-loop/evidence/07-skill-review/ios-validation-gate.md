---
skill: ios-validation-gate
reviewer: R3
date: 2026-04-16
verdict: PASS
---

# ios-validation-gate review

## Frontmatter check
- name: `ios-validation-gate`
- description: `Three-gate iOS enforcement: Simulator (build/install/launch/screenshot/a11y) + Backend (health/endpoints/responses) + Analysis (logs/correlation). ALL gates must PASS. Use after each iOS feature.`
- description_chars: 166
- yaml_parses: yes

## Trigger realism
- Trigger phrases: `ios validation gate`, `ios gate`, `validate ios app`, `ios quality gate`
- Realism score (5/5): Triggers match standard iOS QA workflows

## Body-description alignment
- Verdict: PASS
- Evidence: Description matches scope exactly. Three-gate architecture (Simulator, Backend, Analysis) is clearly diagrammed and each gate has PASS/FAIL criteria. Gate 1 covers build/install/launch/screenshot/accessibility tree. Gate 2 covers health check and endpoint validation. Gate 3 covers logs and behavior correlation. Final Verdict section enforces "ALL THREE MUST PASS" rule.

## MCP tool existence
- Tools referenced: `xcodebuild`, `xcrun simctl`, `idb`, `curl`
- Confirmed: yes (standard Xcode and curl tools)

## Example invocation
"Run the iOS validation gate for the profile feature"

## Verdict
PASS
- Three-gate architecture is clear and properly enforced (all must PASS)
- Each gate has explicit PASS/FAIL criteria (not vague)
- Gate 1 (Simulator) is concrete: build + install + launch + screenshot + a11y tree
- Gate 2 (Backend) allows N/A condition if app is offline-only (pragmatic)
- Gate 3 (Analysis) enforces log correlation with visual changes (prevents false positives)
- Final Verdict template is provided with evidence requirements
- Rules section is explicit: "ALL three gates must PASS for overall PASS"
