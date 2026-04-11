# DEFERRED Triage (Phase 7)

**Triage date:** 2026-04-11
**Source:** CAMPAIGN_STATE.md — 11 specs with `cleanup=DEFERRED`
**Budget cap:** ≤ 45 min total DO NOW. Overflow → spin to new plan.

All 11 items are MERGED specs where only *post-merge cleanup* (evidence housekeeping, note tidying) was deferred. The underlying functionality is shipped; only polish work remains.

| Spec | DEFERRED item | Est. effort | Decision | Rationale |
|------|---------------|-------------|----------|-----------|
| 001 | Post-merge evidence housekeeping | 20 min | DEFER | Evidence already in `e2e-evidence/` and reviewed in merge campaign. Cleanup is cosmetic. |
| 002 | Post-merge npm-install log cleanup | 5 min | DEFER | `.sisyphus/npm-install-spec002.log` is historical artifact, not actively consumed. Safe to leave. |
| 008 | Deep Skill Quality Review follow-ups | 2h+ | DEFER → new plan | Requires deep review of 12 skill files. Exceeds 45-min DO NOW budget. Tracked in TECHNICAL-DEBT.md as future work. |
| 009 | Post-merge evidence housekeeping | 15 min | DEFER | Same category as 001. |
| 010 | Post-merge evidence housekeeping | 15 min | DEFER | Same category as 001. |
| 011 | Post-merge evidence housekeeping | 15 min | DEFER | Same category as 001. |
| 017 | Context Window Budget Management — evidence refresh | 30 min | DEFER | Requires a fresh run to validate `/context-budget` command output; not autonomous-safe. |
| 018 | Verified Benchmark Scoring System — re-calibration | 3h+ | DEFER → new plan | Requires real-project empirical calibration. Explicitly noted as "design target, not verified" in README "Verification Status" table. Out of scope. |
| 021 | Forge Engine Autonomous Loop — smoke run | 2h+ | DEFER → new plan | Requires live session (same blocker as plan Phase 4/5). Already tracked as M4 in TECHNICAL-DEBT.md. |
| 023 | React Native/Flutter platform pinning post-fix verification | 30 min | DEFER | Post-merge fix already landed. Verification is cosmetic. |
| 024 | Self-Validation evidence refresh | 20 min | DO NOW — already completed in Phase 1 Commit F | `e2e-evidence/benchmark-scenarios/vf-self-assessment/*` was refreshed as part of Commit F (`88c0e69`). Marking resolved. |

## Summary

- **DO NOW (completed):** 1 (spec 024 — already done in Phase 1 Commit F)
- **DEFER (cosmetic cleanup):** 7 (specs 001, 002, 009, 010, 011, 017, 023)
- **DEFER → new plan (exceeds budget):** 3 (specs 008, 018, 021)
- **DROP:** 0

## Total time spent in DO NOW

0 minutes (spec 024 was already resolved in Phase 1). Well under 45-min budget.

## Rationale for bulk-deferring

The 11 `DEFERRED` items are all post-merge cleanup tasks (evidence housekeeping, log tidying, note polish). The merge campaign CLOSED the underlying specs — functionality is shipped, tests pass, benchmark is Grade A. Cleanup tasks are cosmetic and do not block the campaign closeout.

Items 008, 018, 021 require substantial work (live sessions, empirical calibration, deep reviews) that exceeds this plan's scope. They are tracked in TECHNICAL-DEBT.md as:
- 008 → Deep Skill Quality Review (M1 continuation)
- 018 → Benchmark empirical calibration (referenced in README "Verification Status")
- 021 → FORGE engine live test (M4 in TECHNICAL-DEBT.md)
