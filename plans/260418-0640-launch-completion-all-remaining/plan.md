---
title: "ValidationForge Launch Completion — All Remaining Work"
description: "6-phase operational plan from pre-launch blockers through post-launch retention (2026-04-18 → 2026-07-25)"
status: pending
priority: P1
effort: 78h
branch: main
tags: [launch, marketing, validationforge, operations]
created: 2026-04-18
---

# ValidationForge Launch Completion — All Remaining Work

## Overview

Campaign is 80% assembled: 60K+ words of copy drafted, 10-week calendar authored, 11 companion repos tagged with READMEs staged, tracking schema built. This plan operationalizes the remaining 20% — unblock Day-1, ship 20 calendar slots, convert consulting DMs, extend into V1.5 — from 2026-04-18 through 2026-07-25 (14-week window: 10 launch + 4 retention).

## Phase Summaries

1. **[Phase 1 — Pre-Launch Blockers](phase-01-pre-launch-blockers.md)** (2026-04-18 → 2026-04-20 08:30 ET, 8h) — GIF production, ai-dev-operating-system conflict, orphaned-repo decision, push 11 README patches, voice-edit pass, soft-launch gate.
2. **[Phase 2 — LinkedIn Publisher Setup](phase-02-linkedin-publisher-setup.md)** (Days 1-3, 2026-04-18 → 2026-04-28, 4h) — Developer App, OAuth, queue 14 days, cron host decision, manual-post contingency.
3. **[Phase 3 — Wave 1 Execution](phase-03-wave-1-execution.md)** (Days 1-14, 2026-04-18 → 2026-05-01, 24h) — 14-day tactical sprint: soft-launch, Parts 1/2/3, Show HN Day 11, personal-brand hero Day 12, retrospective Day 14.
4. **[Phase 4 — Wave 2 Runway + Consulting Magnet](phase-04-wave-2-runway-consulting.md)** (Days 15-28, 2026-05-02 → 2026-05-15, 16h) — Week 3 reflection with real numbers, 50-line hook deep-dive, FIVE-QUESTIONS consulting magnet, patterns spotlight, weekly performance gates.
5. **[Phase 5 — Blog-Series Execution](phase-05-blog-series-execution.md)** (Days 29-70, 2026-05-16 → 2026-06-27, 20h) — 12 blog-series adaptations on Mon+Thu 8:30am ET, per-post 7-day repo-prep ritual, Week 9 wrap-post fill, Week 10 capstone + wrap.
6. **[Phase 6 — Post-Launch Retention](phase-06-post-launch-retention.md)** (Days 71-100, 2026-06-28 → 2026-07-25, 6h) — Consulting DM triage SLA, SEO (canonicals + GSC), V1.5 CONSENSUS prep, extend-vs-conclude decision on Posts 12-18.

## Critical Path

`vf-demo-hero.gif (Phase 1)` → `soft-launch Mon Apr 20 (Phase 3 Day 1)` → `Show HN Tue Apr 28 (Phase 3 Day 11)` → `FIVE-QUESTIONS Mon May 12 (Phase 4)` → `multi-agent-consensus repo polish Mon May 11 (Phase 5 prep)` → `Post 2 Mon May 18 (Phase 5)` → `Post 11 capstone Mon Jun 22 (Phase 5)` → `wrap Thu Jun 25 (Phase 5)` → `retention Phase 6`.

Any slip in the GIF blocks the entire calendar. Any slip in multi-agent-consensus polish (highest-importance post 10/10) blocks Wave 3 credibility.

## Top 5 Dependencies

1. **vf-demo-hero.gif** — blocks Day 1 soft-launch, Show HN README, every Discord/Reddit/X T1 for 14 days.
2. **LinkedIn Developer App approval** — blocks automated publishing; manual-post fallback covers Week 1-2 only.
3. **Canonical blog-post URLs** — blocks "Related Post" sections in all 11 repo READMEs (currently placeholders).
4. **Real launch numbers (Wave 1 metrics)** — must fill week3-reflection Mon May 4 post; 24 placeholders in wrap-post scaffold fill Week 9.
5. **Blog-series source drift** — `~/Desktop/blog-series/` posts 5, 6, 9 rewritten to calendar framing (not source-faithful); adaptations exist but source-file final state may diverge.

## Open Decisions (priority-ordered)

1. **(BLOCK Day 1)** ai-dev-operating-system conflict — A: keep agentic-development-guide as Post 1 companion and validationforge as Post 11 capstone (prep-checklist v2); B: revert to original audit pairing. Recommend A. Lands before Phase 1 complete.
2. **(BLOCK Day 1)** Orphaned repos — archive or repurpose `ai-dev-operating-system` (1 star, untouched) and `functional-validation-framework` (bypassed by Post 3 correction). Lands before Phase 1 complete.
3. **(IMPORTANT)** Coupled vs decoupled brand for Wks 3-4 — calendar assumes coupled. 5-minute confirmation needed. Lands Tue Apr 21.
4. **(IMPORTANT)** Cron host: local Mac / VPS / GitHub Actions — affects Phase 2 Day 3 shipping. Lands Sun Apr 26.
5. **(IMPORTANT)** Publishing domain (agentic.dev vs other) + canonical URLs — blocks Phase 5 repo-prep "Related Post" sections. Lands Fri May 8.
6. **(NICE)** Posts 12-18 extension vs conclude at 11 — affects Phase 6 scope. Lands Sun May 31 (Week 7).

## Measurement Checkpoints Per Phase

- **Phase 1:** Day 0 gate — GIF + 11 pushed patches + soft-launch post verified rendering in LinkedIn preview.
- **Phase 2:** `bin/lp test` dry-run log + one successful real publish on Day 3.
- **Phase 3:** Daily 5pm ET log entry; mid-sprint review Day 7 (Fri Apr 24 4pm); Day 11 hourly HN log; Day 14 final rollup (Fri May 1) — North Star: 100+ stars.
- **Phase 4:** Sunday 5pm ET performance gate (green/yellow/red/black) Weeks 3+4; consulting DM count post-May-12.
- **Phase 5:** Weekly Sunday gate + per-post 72h star delta + repo attribution log; Week 5 mid-forecast re-run.
- **Phase 6:** DM-to-call conversion rate; SEO impressions in Google Search Console; V1.5 launch-ready checklist.

## Non-Goals

- Re-plan content strategy (captured in `briefs/campaign-brief.md`).
- Re-plan voice (captured in `briefs/creative-brief.md`).
- Re-plan 10-week calendar (captured in `execution/10-week-master-calendar.md` — only operationalize).
- Write new copy — 60K words already drafted.
- Build new code — this is marketing ops, not feature work.

## Validation Summary

**Validated:** 2026-04-18
**Questions asked:** 8
**Mode:** auto

### Confirmed Decisions

1. **Post 11 repo framing** → **Option A**: use `validationforge` as Post 11 capstone (archive `ai-dev-operating-system`). Aligns with prep-checklist v2 + master calendar annotation.
2. **Orphaned repos** → **Archive both immediately**: `ai-dev-operating-system` + `functional-validation-framework`. Preserves history, removes visitor confusion.
3. **LinkedIn posting target** → **Personal LinkedIn profile** for post authorship (`urn:li:person:{sub}` via `w_member_social`). Developer Portal STILL requires a Company Page for app association at creation time — placeholder page acceptable (2-min setup). Post authorship (personal URN) and app ownership (Company Page) are separate concerns. `auth.js:128-135` auto-captures the personal URN via `/v2/userinfo`.
4. **Cron host** → **Local Mac launchd**. User choice. Accepts the awake-dependency risk; manual fallback doc (Phase 2) covers travel/sleep days.
5. **Brand strategy Wks 3-4** → **Coupled through Week 4**. Max momentum into FIVE-QUESTIONS consulting magnet Mon May 12. Revisit Sun May 10 per Phase 4 weekly gate.
6. **Canonical blog domain** → **ai.hack.ski**. All "Related Post" links in Phase 5 repo READMEs + dev.to cross-post canonicals point here.
7. **V1.5 CONSENSUS launch** → **Launch inside Phase 6 if readiness ≤3 gaps**. Decision gate Sat Jul 12 (Day 85) per Phase 6.

### Action Items — Plan Revisions Required

- [ ] **Phase 2**: KEEP Company Page creation step (mandatory at app creation, placeholder OK). Change post-authorship docs from `urn:li:organization` to personal `urn:li:person:{sub}` — `auth.js` already handles this via `/v2/userinfo`. Scopes confirmed: `openid profile email w_member_social`.
- [ ] **Phase 2**: change cron section from "GH Actions recommended" to "launchd plist at `~/Library/LaunchAgents/com.validationforge.linkedin-publisher.plist`". Document Mac-awake risk + manual fallback activation.
- [ ] **Phase 1**: add "Archive 2 orphaned repos" todo with command `gh repo archive krzemienski/ai-dev-operating-system && gh repo archive krzemienski/functional-validation-framework`.
- [ ] **Phase 5**: all repo README "Related Post" placeholder URLs → `https://ai.hack.ski/blog/{post-slug}` canonical pattern.
- [ ] **Phase 5 + 6**: update any `agentic.dev` references to `ai.hack.ski`.
- [ ] **Phase 6**: add explicit V1.5 readiness checkpoint Sat Jul 12 (Day 85) — count gaps, compare to threshold (≤3), decide launch-vs-defer.
- [ ] **Phase 3 Day 11 (Show HN)**: confirm canonical URL in HN submission points to `https://ai.hack.ski` (or GitHub README if blog not live yet).

### Remaining Unresolved (non-blocking)

- `ai.hack.ski` deployment status — is it live, or does it need a first deploy before Phase 5 (Sat May 16) needs canonical URLs?
- `stitch-hero.png` 1200×627 verification — flagged in readiness dashboard §6, deferred until Phase 5 repo-prep for Post 2 (Mon May 11 polish).
- Posts 12-18 extend-vs-conclude — defer to Sun May 31 (Week 7) gate per master calendar.

### Recommendation

**Proceed to Phase 1 implementation.** All blocking decisions resolved. The 6 Phase-file revisions above are small edits that can be batched in the first 30 minutes of Sat Apr 18 work block. No structural replanning required.
