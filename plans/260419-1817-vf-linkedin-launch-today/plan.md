---
title: VF LinkedIn Launch — Today (Apr 19, 2026)
created: 2026-04-19T22:17:00Z
mode: deep (execute-now)
blockedBy: []
blocks: []
status: in_progress
parallel_session: VF self-validation readiness (separate lane)
---

# VF LinkedIn Launch — Today

**Trigger:** User directive "launch today, right now. post on my LinkedIn."
**Scope:** LinkedIn-only (skip AI.hack.ski, skip blog series — both separate work)
**Executor:** This session (the higher-level launch coordinator). A parallel
session is validating VF readiness end-to-end.

## The decision

Original queue fires `w1-mon-soft-launch` on **Apr 20 08:30 ET (14h away)**.
User chose to pull that forward and fire NOW. All downstream posts stay
scheduled (Apr 22 blog part 1, etc.).

## Pre-launch state (verified 2026-04-19 22:17Z)

| Check | Status | Note |
|---|---|---|
| Repo public | ✓ | `isPrivate: false`, 7 topics present |
| Demo video produced | ✓ | `vf-demo-hero.mp4` 0.38 MB 800×450 |
| Hero PNGs (4) | ✓ | Week 1-2 posts all wired |
| LinkedIn cookie auth | ✓ | `me` returns `name=Nick` |
| Soft-launch copy | ✓ | `linkedin-soft-launch-mon-apr20.md`, 95 words, repo URL CTA |
| Queue seeded | ✓ | 21 items, `w1-mon-soft-launch` = next due |
| Oracle B.1 URL drift | ✓ | No `validationforge/validationforge` matches in site/ |
| Oracle B.2 getting-started Aside | ✓ | Already says "Fallback install path" |
| Oracle B.3 CNAME file | ✓ | Present, uncommitted, contains `validationforge.dev` |
| Oracle A.1 topics | ⚠ | Missing `no-mock`, `functional-testing`, `quality-assurance` |
| Oracle A.2 README purge | ✗ | Still references Post #11, "Mon Jun 22, 2026", "link added on send day" |

## Phases

1. **[phase-01](./phase-01-oracle-blockers.md)** — Close remaining Oracle gaps
   (topics, README rewrite). ETA 5 min.
2. **[phase-02](./phase-02-linkedin-launch.md)** — Reschedule + fire
   `w1-mon-soft-launch`. ETA 3 min.
3. **[phase-03](./phase-03-verify-and-commit.md)** — Confirm post live,
   commit all changes, journal. ETA 5 min.

Total critical path: ~13 min.

## Iron rules for this execution

- DO NOT post to any platform other than LinkedIn
- DO NOT edit blog-series material (separate active work)
- SHOW post body to user before firing (already in this thread)
- ABORT on first cookie-auth failure (kill switch: `LP_KILL=1`)
- Capture post URN/URL for traceability

## Coordination note (for parallel session)

The parallel session validating VF readiness owns `e2e-evidence/self-validation/*`
and is expected to land a PASS report the soft-launch post can cite. If that
session has not yet completed by the time we fire, the soft-launch post text
stands on its own — it cites the repo, not the live evidence report.
