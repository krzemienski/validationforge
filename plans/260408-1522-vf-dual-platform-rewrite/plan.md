---
title: VF Dual-Platform Audit Rewrite
status: planned
created: 2026-04-08
branch: audit/plugin-improvements
mode: hard
blockedBy: [260409-0432-merge-campaign-continuation, 260411-2242-vf-gap-closure]
blocks: []
triage_pending: true
triage_plan: plans/260411-2242-vf-gap-closure/plan.md
triage_phase: Phase 8
note: 15 red-team findings pending triage in gap closure plan. On completion, status will become `retired` or findings will be split into new plans.
---

# VF Dual-Platform Audit Plan — Rewrite

**Trigger**: Red-team review found 15 issues (5C/7H/3M) in original `vf.md`. Core problem: plan targeted wrong platform (pure OC framing for a CC-primary product).

**Decision**: Full rewrite (Option A) preserving 8-phase structure. See `vf.md` for complete plan.

## Phases

| # | Phase | Status | Key Deliverable |
|---|-------|--------|-----------------|
| 0 | Inventory and Scoping | pending | `audit-artifacts/phase-0-inventory.md` |
| 1 | Deep Analysis | pending | `audit-artifacts/phase-1-analysis.md` |
| 2 | Git Hygiene and Baseline | pending | `v0-pre-audit` tag, rollback doc |
| 3A | Documentation Overhaul | pending | README, ARCHITECTURE, SKILLS, COMMANDS |
| 3B | CC Hook Protocol Fix + Shell Audit | pending | Fixed PostToolUse hooks, shell script hardening |
| 4 | Full CC Audit + Pattern Consolidation | pending | Consolidated patterns.js, sanitized hooks |
| 5 | Benchmark Skill Creation | pending | Three-part benchmark system + baseline scores |
| 6 | Improvement Pass | pending | Improved files + benchmark deltas |
| 7 | Final Validation and Release | pending | `v1-post-audit` tag, final report |

## Critical Path

```
Phase 0 → Phase 1 → Phase 2 → Phase 3A ──┐
                                           ├→ Phase 4 → Phase 5 → Phase 6 → Phase 7
                     Phase 2 → Phase 3B ──┘
```

Phase 3A and 3B can run in parallel after Phase 2. All other phases are sequential.

## Key Risks

| Risk | Mitigation |
|------|-----------|
| Context compaction during Phase 4 (67+ files) | Checkpoint to `audit-progress.json` after each file |
| Pattern consolidation breaks hooks | Test each hook after require() change |
| Benchmark skill scope creep | MVP: hooks only automated, top 10 skills LLM-evaluated |
| OC plugin findings leak into CC audit | Constraint: document only, separate OC track |

## References

- Main plan: [vf.md](./vf.md)
- Red-team report: [red-team-260408-1417-vf-plan-review.md](../reports/red-team-260408-1417-vf-plan-review.md)
- CC Hook Audit: [researcher-260408-1523-cc-hook-protocol.md](../reports/researcher-260408-1523-cc-hook-protocol.md)
- Benchmark Feasibility: [researcher-260408-1523-benchmark-feasibility.md](../reports/researcher-260408-1523-benchmark-feasibility.md)
- Superseded plan: [vf.md (old)](../260307-unified-validationforge-product/vf.md)

## Cook Command

```
/cook plans/260408-1522-vf-dual-platform-rewrite/vf.md
```
