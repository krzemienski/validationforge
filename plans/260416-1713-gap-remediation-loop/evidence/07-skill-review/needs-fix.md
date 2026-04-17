# P07 Needs-Fix Roster

4 skills need one-line frontmatter patches to add `triggers:` arrays. All are PASS functionally; the fix unlocks auto-discovery without touching behavior.

| # | Skill | Batch | Blocking issue | Proposed patch | Follow-up stub |
|---|-------|-------|----------------|----------------|----------------|
| 1 | flutter-validation | R2 | Missing `triggers:` in frontmatter — skill undiscoverable via trigger keywords | Add `triggers: [flutter, dart, "pubspec.yaml", "flutter run"]` under `description:` | `plans/260416-1934-skill-triggers-fix/` (bundle all 4) |
| 2 | full-functional-audit | R2 | Missing `triggers:` | Add `triggers: [audit, "functional audit", "full audit"]` | same bundle |
| 3 | fullstack-validation | R2 | Missing `triggers:` | Add `triggers: [fullstack, "fullstack validation", "web+api"]` | same bundle |
| 4 | rust-cli-validation | R4 | Missing `triggers:` | Add `triggers: [rust, "Cargo.toml", "rust CLI", cargo]` | same bundle |

## Disposition
- Option A: Apply the 4 patches inline in this phase (treat as in-scope).
- Option B: Scaffold `plans/260416-1934-skill-triggers-fix/` and defer (out of P07 scope; trigger work is mechanical frontmatter updates).

## Recommendation
Option B — defer. Rationale:
- P07 mandate was deep-review, not remediation. Remediation was P06's job (already CLOSED).
- Triggers work is uniform across the 4 skills; a small dedicated plan keeps the campaign's scope boundary clean.
- None of the 4 issues are blocking the campaign's remaining phases.

## Cross-cutting concerns flagged (for P13 follow-up)
- 4 skills reference `references/*.md` files the original R3 agent could not verify exist (gate-validation-discipline × 2, no-mocking-validation-gates × 2, verification-before-completion × 1). Recommend P13 close-out step: `ls skills/*/references/ | wc -l` to confirm.
- `.vf/` vs `.validationforge/` directory naming inconsistency noted across multiple skills. Non-blocking; track as docs cleanup.
- `max_fix_attempts` value parity across the 3 forge skills — verify identical values before P12 regression.

## Status
No FAIL-verdict skills across 48. Campaign can advance to P08 with these 4 NEEDS_FIX items queued for a post-campaign follow-up plan.
