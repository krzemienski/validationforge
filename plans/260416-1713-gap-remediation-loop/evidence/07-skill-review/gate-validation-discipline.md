---
skill: gate-validation-discipline
reviewer: R3
date: 2026-04-16
verdict: PASS
---

# gate-validation-discipline review

## Frontmatter check
- name: `gate-validation-discipline`
- description: `Evidence before completion: examine actual evidence (not reports), cite specific proof, match evidence to criteria. Read files, view screenshots, quote output.`
- description_chars: 146
- yaml_parses: yes

## Trigger realism
- Trigger phrases: `evidence examination`, `before completion`, `verify gate`, `checkpoint validation`, `proof citation`
- Realism score (5/5): All triggers are domain-natural and realistic for completion workflows

## Body-description alignment
- Verdict: PASS
- Evidence: Description matches scope exactly. "The Rule" enforces evidence-before-completion mandate with 4 sub-rules. Mandatory Verification Checklist is concrete and actionable. Verification Loop (IDENTIFY, LOCATE, EXAMINE, MATCH, WRITE) is systematic.

## MCP tool existence
- Tools referenced: none (skill is process-based)
- Confirmed: yes

## Example invocation
"Verify the completion gate for the login feature"

## Verdict
PASS
- Iron rule is explicit (NEVER mark complete without examining evidence)
- Verification loop is prescriptive with 5 clear steps
- Evidence standards reference (good vs bad) points to `references/evidence-standards.md`
- Scope boundary is clear (does NOT handle validation generation, only examination)
- Related skills are well-linked (functional-validation, no-mocking-validation-gates, e2e-validate)
