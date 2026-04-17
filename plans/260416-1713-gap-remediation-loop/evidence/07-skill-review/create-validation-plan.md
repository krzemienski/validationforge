---
skill: create-validation-plan
reviewer: R1
date: 2026-04-16
verdict: PASS
---

# create-validation-plan review

## Frontmatter check
- name: `create-validation-plan`
- description: `"Create BEFORE evidence capture. Defines PASS criteria per journey (P0/P1/P2 priority). Maps routes/endpoints/screens, orders by dependency, checks prerequisites. Use when starting validation."` (199 chars)
- description_well_formed: yes
- yaml_parses: yes

## Trigger realism
Would invoke on: `"validation plan generation"`, `"journey discovery"`, `"pass criteria definition"`, `"validation strategy planning"`.
Realism score: 5/5. Phrases match validation workflow. Developer would request this upfront.

## Body-description alignment
PASS. Body delivers all promised elements:
- BEFORE evidence capture (critical timing rule) ✓
- Journey discovery (routes, endpoints, screens, commands) ✓
- PASS criteria definition (P0/P1/P2 priority) ✓
- Prerequisites documentation ✓
- Dependency mapping and execution ordering ✓

Plan quality checklist ensures completeness. PASS criteria rules (8 properties: specific, measurable, observable, complete, ordered, evidence-mapped, non-redundant, falsifiable) are explicit and well-explained.

## MCP tool existence
No external MCP servers required. Plan creation is markdown documentation and codebase scanning (grep, find, etc.).

## Example invocation proof
User: `"Create a validation plan for the new checkout flow"`
Would discover journeys, define P0/P1/P2 criteria, map dependencies, produce validation-plan.md.

## Verdict
**PASS**

Critical skill for validation discipline. PASS criteria rules are explicit with good/bad examples. Plan quality checklist prevents incomplete planning. References to journey-discovery-patterns and pass-criteria-examples indicate supporting documentation available.
