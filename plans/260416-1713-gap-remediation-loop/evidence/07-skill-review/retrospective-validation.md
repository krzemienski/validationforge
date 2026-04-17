---
skill: retrospective-validation
reviewed_at: 2026-04-16T20:15:00Z
reviewer: R4
---

## Frontmatter Check
- **name:** retrospective-validation ✓
- **description:** "Assess if validation methodology worked: analyze past results, deployments, incidents. Calculates false PASS/FAIL rates, revert frequency, confidence score. Recommends process changes." (148 chars) ✓
- **yaml_parses:** Yes ✓

## Trigger Realism
4 triggers: all align with post-incident/sprint review workflows
**Realism:** 5/5

## Body-Description Alignment
**Verdict:** PASS — Phase 1 collects past results/deployments/incidents. Phase 2 calculates false PASS/FAIL rates and revert frequency. Phase 4 produces confidence score (Detection × Accuracy × Longevity formula). Report template includes Continue/Start/Stop.

## MCP Tool Existence
Bash (git log, find, grep) ✓

## Example Invocation Proof
**Prompt:** "retrospective validation for Q2 releases" (5 words, viable)

## Verdict
**Status:** PASS

4-phase protocol with quantitative metrics. Confidence formula prevents overconfidence (includes longevity factor). Evidence in e2e-evidence/retrospective/. Integration with create-validation-plan stated.

## Notes
- Process-level skill, not execution
- Pattern detection section valuable for incident analysis
