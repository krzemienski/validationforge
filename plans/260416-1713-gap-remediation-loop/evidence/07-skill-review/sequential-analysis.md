---
skill: sequential-analysis
reviewed_at: 2026-04-16T20:15:00Z
reviewer: R4
---

## Frontmatter Check
- **name:** sequential-analysis ✓
- **description:** "Root cause analysis for FAIL verdicts: structured hypothesis testing, evidence investigation, sequential thinking. Use when validation fails unexpectedly or errors are ambiguous." (151 chars) ✓
- **yaml_parses:** Yes ✓

## Trigger Realism
5 triggers: "sequential analysis", "root cause analysis", "why did validation fail", "trace the failure", "debug validation"
**Realism:** 5/5 — All align with failure investigation

## Body-Description Alignment
**Verdict:** PASS — Phase 4 produces root cause. Phase 2 generates structured hypotheses. Phase 3 investigates with sequential-thinking MCP. All claims verified.

## MCP Tool Existence
sequential-thinking MCP (Phase 3, explicit), Bash ✓

## Example Invocation Proof
**Prompt:** "debug why the login flow validation failed" (8 words, viable)

## Verdict
**Status:** PASS

4-phase protocol with hypothesis-driven methodology. Phase 2 categories well-organized (Data, Timing, Environment, Code, Integration, Infrastructure, Validation setup). Phase 3 uses sequential-thinking for structured reasoning. Evidence collection concrete (bash commands, git history).

## Notes
- Very strong for ambiguous failures
- Hypothesis generation is critical thinking step
- Sequential thinking integration elevates rigor
- Evidence-driven conclusion prevents bias
