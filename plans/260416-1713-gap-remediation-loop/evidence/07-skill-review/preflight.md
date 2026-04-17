---
skill: preflight
reviewer: R3
date: 2026-04-16
verdict: PASS
---

# preflight review

## Frontmatter check
- name: `preflight`
- description: `Run before validation to detect missing dependencies, dead servers, unseeded databases. Auto-fixes common failures, produces CLEAR/BLOCKED/WARN verdict. Prevents mid-validation debugging cycles.`
- description_chars: 161
- yaml_parses: yes

## Trigger realism
- Trigger phrase: (none in YAML; skill is referenced by name as mandatory first step)
- Realism score (5/5): Skill is positioned as mandatory preflight step, not optional

## Body-description alignment
- Verdict: PASS
- Evidence: Description matches scope exactly. Purpose section explains value (saves 10-30 minutes of mid-validation debugging). How It Works has 5 steps (detect platform, run checklist, auto-fix failures, produce report, produce verdict). Preflight Report Format shows concrete example with PASS/FAIL/WARN states. Severity Levels table defines CRITICAL, HIGH, MEDIUM, LOW with actions.

## MCP tool existence
- Tools referenced: platform detection script, platform-specific checklists, auto-fix actions
- Confirmed: yes (documentation references point to `references/platform-checklists.md` and `references/auto-fix-actions.md`)

## Example invocation
"Run the preflight check before starting validation"

## Verdict
PASS
- Purpose is clear: prevent mid-validation failures (10-30 minute savings)
- Five-step process is systematic (detect → run → auto-fix → report → verdict)
- Severity Levels table provides clear guidance on when to PASS/BLOCK/WARN
- Rules section enforces mandatory preflight before any validation
- Rules section forbids auto-fixing major tools (Xcode, Docker) — pragmatic safety gate
- Rules section enforces re-check after auto-fix
- Security Policy clarifies non-invasive nature (diagnostics + service startup only)
- Integration section lists related skills (create-validation-plan, baseline-quality-assessment, e2e-validate, error-recovery, condition-based-waiting)
