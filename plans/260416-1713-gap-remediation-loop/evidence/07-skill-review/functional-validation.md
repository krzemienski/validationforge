---
skill: functional-validation
reviewer: R3
date: 2026-04-16
verdict: PASS
---

# functional-validation review

## Frontmatter check
- name: `functional-validation`
- description: `Build & validate real systems (iOS, Web, API, CLI, fullstack)—never mocks or test files. Capture evidence from browser, simulator, CLI, cURL. Platform detection, 4-step protocol.`
- description_chars: 155
- yaml_parses: yes

## Trigger realism
- Trigger phrase: (none in YAML triggers; skill is directly referenced)
- Realism score (5/5): Skill is referenced by name throughout ValidationForge pipeline, not by natural-language trigger

## Body-description alignment
- Verdict: PASS
- Evidence: Description matches scope exactly. "Iron Rule" section enforces no-mock mandate. "4-Step Protocol" (Build & Launch, Exercise Through UI, Capture Evidence, Write Verdict) aligns with description. Platform detection table covers iOS, Web, CLI, API, Full-Stack.

## MCP tool existence
- Tools referenced: none (skill is procedural, not tool-dependent)
- Confirmed: yes

## Example invocation
"Validate the iOS feature against a real simulator"

## Verdict
PASS
- Scope is clear (validation execution only, not planning)
- Iron Rule is explicit and load-bearing
- 4-step protocol is complete and testable
- Multi-platform validation order (bottom-up) is documented
- Verdict format is prescriptive with evidence citation requirement
