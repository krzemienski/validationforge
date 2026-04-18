# Planner — ValidationForge Launch Completion Plan (Executive Summary)

**Plan dir:** `/Users/nick/Desktop/validationforge/plans/260418-0640-launch-completion-all-remaining/`
**Date:** 2026-04-18 (Sat, Day 0)
**Window:** 2026-04-18 → 2026-07-25 (14 weeks: 10 launch + 4 retention)
**Owner:** Nick Krzemienski

## Counts

- **Phases:** 6
- **Total todos across phases:** ~60 one-time + recurring daily/weekly rituals (14 daily log + 14 weekly gates)
- **Estimated total hours remaining:** **78h**
  - Phase 1: 8h (Sat-Sun 04-18/19)
  - Phase 2: 4h (Sat-Sun 04-18/19, parallel with P1)
  - Phase 3: 24h (14 days, ~2h/day + 8h HN day)
  - Phase 4: 16h (14 days, ~1h/day + deep-work)
  - Phase 5: 20h (42 days, ~3.3h/wk)
  - Phase 6: 6h (28 days, ~1.5h/wk)

## Critical Path Length

**~100 days** from Day 0 (Sat Apr 18) to retention close (Fri Jul 24).
**14 calendar weeks.** Hard-gated nodes: vf-demo-hero.gif (Sat-Sun) → soft-launch (Mon Apr 20) → Show HN (Tue Apr 28) → FIVE-QUESTIONS (Mon May 12) → multi-agent-consensus polish (Mon May 11) → Post 2 (Mon May 18) → capstone (Mon Jun 22) → wrap (Thu Jun 25) → retention summary (Fri Jul 24).

## Top 3 Risks

1. **vf-demo-hero.gif not produced Day 0** — blocks soft-launch + Show HN README + all Wave 1 T1 slots. Mitigation: Sat AM priority block; fallback to existing self-validation recording.
2. **multi-agent-consensus polish slips Mon May 11** — highest-importance post (Post 2, 10/10) lands on dormant repo. Mitigation: Phase 4 owner cross-checks Phase 5 prep weekly; Post 2 slidable to Thu May 21 if needed.
3. **LinkedIn publisher OAuth fails or Company Page blocked** — breaks cron autopost cadence across 10 weeks. Mitigation: Phase 2 includes MANUAL-FALLBACK.md rehearsed on Day 2; first 5 posts can be hand-posted in <30min each.

## Top 3 Decision Gates (User Must Resolve)

1. **(BLOCK Day 1, Sat 04-18)** ai-dev-operating-system conflict — Option A: archive the 1-star repo, use `validationforge` as Post 11 capstone companion (prep-checklist v2 alignment); Option B: revert to original audit pairing. **Recommend A** per calendar line 141 + prep-checklist correction. 15-minute decision.
2. **(BLOCK Day 1, Sat 04-18)** Orphaned-repo decision — archive vs keep-dormant for `ai-dev-operating-system` + `functional-validation-framework` (bypassed by Post 3 correction to `claude-code-skills-factory`). Affects Phase 1 push set.
3. **(IMPORTANT, Sun Apr 26)** Cron host — local Mac / VPS / GitHub Actions for LinkedIn publisher. **Recommend GitHub Actions** (free, always-on, tokens in Secrets). Affects Phase 2 Day 3 completion.

Secondary decisions already captured in plan.md Open Decisions section: coupled-vs-decoupled brand (Tue Apr 21), canonical URLs + publishing domain (Fri May 8), Posts 12-18 extend-vs-conclude (Sun May 31 or Mon Jul 20 fallback gate).

## Recommended Sequencing

**Start Phase 1 IMMEDIATELY (Sat Apr 18 AM).** Every downstream phase gates on the Mon Apr 20 08:30 ET soft-launch post.

**Parallelize Phase 2 alongside Phase 1** — LinkedIn publisher setup (4h) can run in the evening while GIF production (2-3h) owns the morning. Both finish by Sun Apr 19 18:00 ET.

**Phase 3 runs solo.** Days 1-14 are daily-ritual-heavy with Show HN Day 11 as the single critical event. Do not start Phase 4 copy work during Phase 3.

**Phase 4 begins Sat May 2 (Day 15).** First blocker = backfill week3-reflection real numbers from Phase 3 rollup. Phase 4 overlaps Phase 5 repo-prep (multi-agent-consensus due Mon May 11 during Phase 4 Week 3).

**Phase 5 starts Sat May 16 (Week 5 kick).** Repo-prep deadlines run rolling (7 days before each post send date). Phase 5 can absorb author fatigue with lighter weekly load than Phase 3.

**Phase 6 starts Sun Jun 28 (Day 71).** Runs 4 weeks at ≈1.5h/wk. Parallel workstreams (DM triage, SEO, V1.5 prep) have no hard dependencies on each other.

## Parallelization Opportunities

| Phase 1 | Phase 2 | Run simultaneously Sat-Sun Apr 18/19 (different workstreams: content/visual vs integration/OAuth) |
|---|---|---|
| Phase 4 Week 3 | Phase 5 pre-work | Phase 5 multi-agent-consensus polish deadline (Mon May 11) falls inside Phase 4 Week 3 |
| Phase 5 repo-prep (ongoing) | Phase 5 post-publish (T-slot) | 7-day offset; every Mon/Thu week, prep next-week's repo while this week's post ships |
| Phase 6 Week A | Phase 6 Week B | Consulting triage (commercial) + SEO push (technical) have no overlap; can run in same week if bandwidth permits |

## Blocking Relationships

```
Phase 1 (GIF + decisions + patches) ─────BLOCKS───→ Phase 3 Day 1 soft-launch
Phase 1 voice-edit pass ─────────────────BLOCKS───→ Phase 2 queueable copy
Phase 2 OAuth ──────────────────────────→ Phase 3 Day 1 autopost (fallback: manual)
Phase 3 final rollup (Fri May 1) ───BLOCKS───→ Phase 4 backfill week3-reflection
Phase 5 multi-agent-consensus polish (Mon May 11) ─BLOCKS─→ Post 2 send (Mon May 18)
Phase 5 Week 9 wrap-post fill ──────BLOCKS───→ Thu Jun 25 wrap publish
Phase 5 10-week KPI rollup ──────────BLOCKS───→ Phase 6 Posts 12-18 decision
Phase 4+5 DM logs ────────────────────FEED────→ Phase 6 DM pipeline
```

## Verification Before Declaring "Done"

Per `evidence-before-completion.md`, every phase closes with cited evidence — not prose. Canonical phase-close artifacts:

- Phase 1: `reports/phase-01-gate-checklist.md` with 8 [x] checkboxes + soft-launch live screenshot
- Phase 2: `reports/phase-02-first-autopost.png` + cron evidence file
- Phase 3: `reports/wave-1/north-star-final.txt` + final-rollup section of `measurement-plan.md`
- Phase 4: `reports/wave-2/phase-4-rollup.md` + consulting-dm-log.md with ≥5 tiered DMs
- Phase 5: `reports/wave-3/10-week-kpi-rollup.md` + `copy/wrap-post-week-10-final.md` with 0 placeholders
- Phase 6: `reports/retention/retention-summary.md` + posts-12-18 decision

## Plan Files Created

- `plans/260418-0640-launch-completion-all-remaining/plan.md` — overview + frontmatter
- `plans/260418-0640-launch-completion-all-remaining/phase-01-pre-launch-blockers.md`
- `plans/260418-0640-launch-completion-all-remaining/phase-02-linkedin-publisher-setup.md`
- `plans/260418-0640-launch-completion-all-remaining/phase-03-wave-1-execution.md` (includes day-by-day table)
- `plans/260418-0640-launch-completion-all-remaining/phase-04-wave-2-runway-consulting.md` (includes day-by-day table)
- `plans/260418-0640-launch-completion-all-remaining/phase-05-blog-series-execution.md` (includes week-by-week table)
- `plans/260418-0640-launch-completion-all-remaining/phase-06-post-launch-retention.md`

Each phase includes all 13 required sections (context, overview, insights, requirements, architecture, artifacts, steps, todos, success criteria, risks, security, next steps, functional validation).

## Unresolved Questions

1. Does Nick have a LinkedIn Company Page already, or will a placeholder be created in Phase 2? (affects Day 1 timing by 10 min)
2. Cron host recommendation (GH Actions) acceptable, or preference for local Mac launchd? (affects Phase 2 artifact shape)
3. Is `~/Desktop/blog-series/posts/post-02-multi-agent-consensus/assets/stitch-hero.png` confirmed at 1200×627 on disk? (Phase 5 spot-check flagged in readiness dashboard §6 — recommend 5-min verify before Mon May 11)
4. Personal blog live at `agentic.dev` or alternate domain? (blocks canonical URLs in Phase 5 repo-prep + Phase 6 SEO)
5. Does Nick want to extend Phase 6 if V1.5 CONSENSUS readiness dashboard flags >3 missing items, or defer V1.5 to Q3 cleanly?
