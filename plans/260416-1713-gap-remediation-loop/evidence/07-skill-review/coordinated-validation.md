---
skill: coordinated-validation
reviewer: R1
date: 2026-04-16
verdict: PASS
---

# coordinated-validation review

## Frontmatter check
- name: `coordinated-validation`
- description: `"Multi-platform validation respecting dependencies: DB→API→Web/iOS. Parallelizes independent layers, blocks downstream on failure, coordinates evidence. Use for fullstack, mobile+API, CI/CD."` (190 chars)
- description_well_formed: yes
- yaml_parses: yes

## Trigger realism
Would invoke on: `"coordinated validation"`, `"fullstack coordinated validation"`, `"cross-platform validation"`, `"validate with dependencies"`.
Realism score: 5/5. Natural phrasing for multi-platform teams. Triggers match skill scope.

## Body-description alignment
PASS. Body delivers all promised features:
- Dependency graph (DB→API→Web/iOS) ✓
- Wave execution (independent platforms in parallel) ✓
- Failure blocking (downstream waits for upstream PASS) ✓
- Evidence coordination (cross-platform consistency checks) ✓
- Multi-agent orchestration (Agent tool spawning) ✓

Orchestration protocol detailed in 5 phases. Failure blocking matrix is explicit. Report template includes cross-platform consistency section.

## MCP tool existence
- `Agent` tool — referenced for spawning validators with `run_in_background: true`
  - Confirmed available? Yes (part of standard tool set)

No other external MCP dependencies.

## Example invocation proof
User: `"Validate fullstack with dependencies: DB first, then API, then Web and iOS in parallel"`
Would execute wave-based protocol: Wave 0 (DB) → Wave 1 (API) → Wave 2 (Web+iOS).

## Verdict
**PASS**

Sophisticated orchestration skill. Dependency graph and wave execution are explicit. Failure blocking rules prevent meaningless downstream validation. Cross-platform consistency checks are thorough. Evidence directory isolation is enforced.
