# Integration Guides Refresh — Audit + Light Edits

**Date:** 2026-04-17
**Scope:** 4 files under `/Users/nick/Desktop/validationforge/docs/integrations/`
**Driver:** New skills from worktrees 012 (evidence-dashboard) and 019 (consensus-engine) plus Iron-Rule-4 preflight needed mention in ecosystem guides.

## Audit findings

| File | Stale terms | Missing new skills | Stale counts | Dead links |
|------|-------------|--------------------|--------------|------------|
| README.md | none | consensus-engine, evidence-dashboard | n/a | none |
| vf-with-omc.md | none (grep clean) | consensus-engine, evidence-dashboard, preflight-as-gate | `... (7 more)` under VF commands | none |
| vf-with-ecc.md | none | consensus-engine, evidence-dashboard, preflight-as-gate | `... (8 more)` | none |
| vf-with-superpowers.md | none | consensus-engine, evidence-dashboard, preflight-as-gate | `... (7 more)` | none |

`grep -rn "Ultrawork\|includeStatic" docs/integrations/` → empty (both before and after edits).
All relative links (`../competitive-analysis.md`, `../ARCHITECTURE.md`, `../../README.md`, `.claude-plugin/marketplace.json`) resolve to existing files.

## Edits applied

All edits proportional — no rewrites.

1. **README.md** — Added two bullet lines to "Guiding principles" covering `/validate-consensus` (high-stakes features) and `evidence-dashboard` (post-run HTML summary).
2. **vf-with-omc.md** — (a) Intro paragraph now mentions `/validate-consensus` as a natural fit after OMC's multi-agent build. (b) Replaced stale `... (7 more)` VF command transcript with the current 13-command list (consensus, dashboard, team-dashboard, ci included). (c) Added a Phase-3 paragraph covering `/validate-dashboard` + preflight-as-CLEAR/WARN/BLOCKED gate.
3. **vf-with-ecc.md** — (a) Replaced `... (8 more)` stale transcript with the current VF command list. (b) Added a Phase-3 paragraph: consensus recommended after ECC security-reviewer flags, dashboard renders evidence for PR, preflight BLOCKED on boot failure.
4. **vf-with-superpowers.md** — (a) Replaced `... (7 more)` stale transcript. (b) Added a Phase-3 paragraph: consensus as the third layer after TDD + single-validator `/validate`, dashboard for PR reviewers, preflight BLOCKED when unit-tests-green but service won't boot.

## Commits

```
f1265e5  docs(integrations): README refresh for consensus-engine + evidence-dashboard
4c1d177  docs(integrations): vf-with-omc refresh for consensus-engine + evidence-dashboard
d83dd38  docs(integrations): vf-with-ecc refresh for consensus-engine + evidence-dashboard
a73ef20  docs(integrations): vf-with-superpowers refresh for consensus-engine + evidence-dashboard
```

One commit per file per the task's commit protocol.

## Verification

- `grep Ultrawork|includeStatic docs/integrations/` → empty
- `grep \(7 more\)|\(8 more\) docs/integrations/` → empty
- `grep validate-consensus|validate-dashboard|CONSENSUS docs/integrations/` → all 4 files match
- All relative links spot-checked; targets exist on disk.

## Unresolved questions

- The `... (1 more)` pseudo-transcript line I left in each guide is a placeholder suggesting there's one unlisted VF command; counting against the main README there are 13 validation commands plus 4 forge commands (vf-telemetry, forge-setup, forge-plan, forge-benchmark, forge-install-rules). If reviewers want the list to be comprehensive rather than illustrative, swap `... (1 more)` for an explicit `/vf-telemetry` + forge commands — this was kept light-touch per the "no rewrites" constraint.
- The OMC guide's opening paragraph still mentions "ultrawork" as an OMC mode (that is a real OMC command, not a VF term) — left as-is.
- None of the guides mention `/validate-sweep` interacting with CONSENSUS; that may be worth a future follow-up if the two features are expected to compose.
