# Phase 06 — Content Execution Waves 1-5 (Apr 21 → Jun 27)

## Context
- Parent plan: [plan.md](./plan.md)
- Depends on: Phase 01 (queue + launchd), Phase 02 (OG previews), Phase 04 (DNS)
- Blocks: nothing downstream; this IS the campaign output

## Overview
`10-week-master-calendar.md` defines 20 LinkedIn slots across Apr 18 → Jun 27.
Slot 1 (Apr 18 / 20 soft-launch) already shipped. Remaining 19 posts must flow
through the `lp queue` pipeline built in Phase 01 with no manual per-post work
beyond authoring. This phase is the weekly maintenance contract: seed the queue,
author each LinkedIn adaptation by its deadline, capture evidence of publication,
feed the Sunday performance gate ritual.

## Key Insights
- Most content is already drafted — `copy/*.md` files exist for Weeks 1-4; blog-series
  posts in `~/Desktop/blog-series/posts/post-{NN}-*` feed Weeks 5-10.
- Only ONE genuinely new post needs authoring from scratch: the Week 10 wrap post
  (Jun 25). Everything else is adaptation of existing source.
- LinkedIn auto-publisher can ONLY publish LinkedIn — X threads, HN submissions,
  Reddit drops, Dev.to cross-posts remain manual.
- Canonical URLs point at `ai.hack.ski/blog/<slug>` — Phases 02/04 must ship first
  or every LinkedIn article buries its backlink in an unprevievable URL.
- Per-post evidence = a LinkedIn post URN from the publish response. That's the
  PASS criterion. No screenshots of "I saw it in my feed."

## Requirements
1. `linkedin-queue.json` seeded with all 19 remaining slots, each with `slot_date`,
   `md_path`, and optional `media_path`.
2. Each LinkedIn adaptation file exists in `copy/blog-series-adapted/` or `copy/`
   by its deadline (see production task table below).
3. Every Mon/Thu 08:30 ET fire produces a `urn:li:share:*` logged in
   `.lp.log`. Missing fires are surfaced same-day.
4. Sunday 5pm ET performance review runs weekly — log in `tracking/measurement-plan.md`.
5. Week 2 gate check (end of Apr) decides green/yellow/red/black for Weeks 3-4.
   Week 5 gate check decides same for Weeks 6-10.

## Architecture
```
Sunday 5pm ET:
  review GA4 + GitHub stars + LinkedIn analytics
  → decision: green (accelerate) | yellow (hold) | red (pause Thu) | black (reframe)
  → log to tracking/measurement-plan.md
  → edit linkedin-queue.json for upcoming week if needed

Mon/Thu 08:30 ET:
  launchd → lp queue next → LinkedIn API → urn:li:share:* logged

Manual mid-week:
  Tue: X excerpt · Wed: receipt-of-the-week · Fri: reflection post
```

## Related code files
- Seed: `integrations/linkedin-publisher/linkedin-queue.json` (copy the JSON below)
- Author (still to draft per deadline): see Open Production Tasks §1-14 in master calendar
- Modify weekly: `assets/campaigns/260418-validationforge-launch/tracking/measurement-plan.md`
- Reference (already drafted): `copy/linkedin-*.md`, `copy/personal-brand-launch-post.md`

## Seed Data for linkedin-queue.json (19 slots)

Derived from `10-week-master-calendar.md`. `slot_date` in ET; launchd converts via
`America/New_York` TZ. `md_path` relative to
`integrations/linkedin-publisher/` (so `../../copy/...`). `status: queued` at seed time;
`lp queue next` pops on success.

```json
{
  "items": [
    { "id": "w1-part1-validation-gap",        "slot_date": "2026-04-22T08:30:00-04:00", "md_path": "../../assets/campaigns/260418-validationforge-launch/copy/linkedin-blog-series.md#part-1", "media_path": null, "status": "queued" },
    { "id": "w2-part2-mid-sprint-lessons",    "slot_date": "2026-04-25T08:30:00-04:00", "md_path": "../../assets/campaigns/260418-validationforge-launch/copy/linkedin-blog-series.md#part-2", "media_path": null, "status": "queued" },
    { "id": "w2-personal-brand-hero",         "slot_date": "2026-04-29T08:30:00-04:00", "md_path": "../../assets/campaigns/260418-validationforge-launch/copy/personal-brand-launch-post.md", "media_path": null, "status": "queued" },
    { "id": "w2-part3-retrospective",         "slot_date": "2026-04-30T08:30:00-04:00", "md_path": "../../assets/campaigns/260418-validationforge-launch/copy/linkedin-blog-series.md#part-3", "media_path": null, "status": "queued" },
    { "id": "w3-reflection-what-didnt-work",  "slot_date": "2026-05-04T08:30:00-04:00", "md_path": "../../assets/campaigns/260418-validationforge-launch/copy/linkedin-week3-reflection.md", "media_path": null, "status": "queued" },
    { "id": "w3-deepdive-no-mock-hook",       "slot_date": "2026-05-07T08:30:00-04:00", "md_path": "../../assets/campaigns/260418-validationforge-launch/copy/linkedin-week3-deepdive-no-mock-hook.md", "media_path": null, "status": "queued" },
    { "id": "w4-five-questions",              "slot_date": "2026-05-12T08:30:00-04:00", "md_path": "../../assets/campaigns/260418-validationforge-launch/copy/linkedin-week4-five-questions.md", "media_path": null, "status": "queued" },
    { "id": "w4-spotlight-patterns",          "slot_date": "2026-05-15T08:30:00-04:00", "md_path": "../../assets/campaigns/260418-validationforge-launch/copy/linkedin-week4-spotlight.md", "media_path": null, "status": "queued" },
    { "id": "w5-post-02-three-agents-bug",    "slot_date": "2026-05-18T08:30:00-04:00", "md_path": "../../assets/campaigns/260418-validationforge-launch/copy/blog-series-adapted/post-02-three-agents-bug.md", "media_path": null, "status": "queued" },
    { "id": "w5-post-03-banned-unit-tests",   "slot_date": "2026-05-21T08:30:00-04:00", "md_path": "../../assets/campaigns/260418-validationforge-launch/copy/blog-series-adapted/post-03-banned-unit-tests.md", "media_path": null, "status": "queued" },
    { "id": "w6-post-01-series-overview",     "slot_date": "2026-05-26T08:30:00-04:00", "md_path": "../../assets/campaigns/260418-validationforge-launch/copy/blog-series-adapted/post-01-series-overview.md", "media_path": null, "status": "queued" },
    { "id": "w6-post-07-7-layer-prompt-stack","slot_date": "2026-05-29T08:30:00-04:00", "md_path": "../../assets/campaigns/260418-validationforge-launch/copy/blog-series-adapted/post-07-prompt-stack.md", "media_path": null, "status": "queued" },
    { "id": "w7-post-05-5-layers-api",        "slot_date": "2026-06-01T08:30:00-04:00", "md_path": "../../assets/campaigns/260418-validationforge-launch/copy/blog-series-adapted/post-05-5-layers-api.md", "media_path": null, "status": "queued" },
    { "id": "w7-post-06-194-worktrees",       "slot_date": "2026-06-04T08:30:00-04:00", "md_path": "../../assets/campaigns/260418-validationforge-launch/copy/blog-series-adapted/post-06-194-worktrees.md", "media_path": null, "status": "queued" },
    { "id": "w8-post-09-code-tales",          "slot_date": "2026-06-08T08:30:00-04:00", "md_path": "../../assets/campaigns/260418-validationforge-launch/copy/blog-series-adapted/post-09-code-tales.md", "media_path": null, "status": "queued" },
    { "id": "w8-post-04-ios-sse-bridge",      "slot_date": "2026-06-11T08:30:00-04:00", "md_path": "../../assets/campaigns/260418-validationforge-launch/copy/blog-series-adapted/post-04-ios-sse-bridge.md", "media_path": null, "status": "queued" },
    { "id": "w9-post-10-21-screens",          "slot_date": "2026-06-15T08:30:00-04:00", "md_path": "../../assets/campaigns/260418-validationforge-launch/copy/blog-series-adapted/post-10-21-screens.md", "media_path": null, "status": "queued" },
    { "id": "w9-post-08-ralph-orchestrator",  "slot_date": "2026-06-18T08:30:00-04:00", "md_path": "../../assets/campaigns/260418-validationforge-launch/copy/blog-series-adapted/post-08-ralph.md", "media_path": null, "status": "queued" },
    { "id": "w10-post-11-capstone-ai-dev-os", "slot_date": "2026-06-22T08:30:00-04:00", "md_path": "../../assets/campaigns/260418-validationforge-launch/copy/blog-series-adapted/post-11-capstone.md", "media_path": null, "status": "queued" },
    { "id": "w10-wrap-10-week-retrospective", "slot_date": "2026-06-25T08:30:00-04:00", "md_path": "../../assets/campaigns/260418-validationforge-launch/copy/wrap-post-week-10-scaffold.md", "media_path": null, "status": "queued" }
  ]
}
```

Note: this is **20 items** to cover the full Apr 22 → Jun 25 window. The Apr 18/20
soft-launch already fired — omit if already popped; per user "19 remaining" count,
delete the `w1-part1` entry if Apr 22 was treated as the soft-launch slot. Reconcile
before `launchctl load`.

## Implementation Steps
1. Copy the JSON above into `integrations/linkedin-publisher/linkedin-queue.json`.
2. Verify each `md_path` resolves: `for p in $(jq -r '.items[].md_path' ...); do
   test -f "integrations/linkedin-publisher/$p" || echo "MISSING: $p"; done`.
3. For any MISSING path, either (a) draft by its deadline per master calendar
   Open Production Tasks §1-14, or (b) swap in a placeholder and mark `status: draft`
   (launchd runner should skip `status != queued`).
4. Weekly Sunday 5pm ET: run metrics-gather script, write decision to
   `tracking/measurement-plan.md → Weekly Log`.
5. Day-of each slot: within 2 hours of publish, reply to LinkedIn comments + DMs;
   post Tue X excerpt next morning.
6. At Week 2 end (May 2): re-forecast based on Floor/Target/Stretch metrics.
7. At Week 5 start (May 16): verify all blog-series adaptations exist in
   `copy/blog-series-adapted/` with hero images referenced.
8. At Week 9 (Jun 13): begin drafting wrap post using real numbers.

## Todo List
- [ ] Seed queue JSON (once soft-launch reconciliation done)
- [ ] Verify all md_paths exist OR create drafts by deadline
- [ ] Author Post 2 LinkedIn adaptation (deadline May 15)
- [ ] Author Post 3 LinkedIn adaptation (deadline May 18)
- [ ] Author Post 1 LinkedIn adaptation (deadline May 22)
- [ ] Author Post 7 LinkedIn adaptation (deadline May 27)
- [ ] Author Post 5 LinkedIn adaptation (deadline May 29)
- [ ] Author Post 6 LinkedIn adaptation (deadline Jun 2)
- [ ] Author Post 9 LinkedIn adaptation (deadline Jun 5)
- [ ] Author Post 4 LinkedIn adaptation (deadline Jun 8)
- [ ] Author Post 10 LinkedIn adaptation (deadline Jun 12)
- [ ] Author Post 8 LinkedIn adaptation (deadline Jun 15)
- [ ] Author Post 11 LinkedIn adaptation (deadline Jun 19)
- [ ] Draft Week 10 wrap post (deadline Jun 22)
- [ ] X threads for Posts 4-11 (batch)
- [ ] Weekly Sunday gate review × 10

## Success Criteria (functional validation)
- Every Mon/Thu 08:30 ET slot produces a `urn:li:share:*` line in `.lp.log` within
  60 seconds of scheduled time. Missing fires trigger a same-day investigation.
- Feed URLs for all 19 fires are captured to `tracking/published-posts.md` with
  impressions + engagement captured 48h post-publish.
- Sunday weekly logs in `tracking/measurement-plan.md → Weekly Log` have entries
  for all 10 weeks, each citing GA4 + GitHub stars + LinkedIn impressions numbers.
- Endpoint metrics on Jun 28 meet at least the Floor column per
  master calendar §"Success Metrics — 10-Week Endpoint".

## Risk Assessment
- **Adaptation backlog:** 13 LinkedIn adaptations × 2h each = 26h of writing across
  10 weeks. If Nick skips 2 weeks, the queue will starve. Mitigation: front-load —
  draft 4 adaptations in first 2 weeks to build a buffer.
- **Red-gate trigger:** if Week 1-2 metrics come in below floor, cadence slows and
  queue needs re-shuffling. Mitigation: queue JSON is editable — remove Thu slots,
  insert reframe content without touching launchd.
- **Stale canonical URLs:** if ai.hack.ski DNS (Phase 04) is not live before a slot
  fires, the post's backlink is dead. Mitigation: Phase 04 is critical path;
  verify DNS health before Week 1 Thu (Apr 23).
- **LinkedIn API version deprecation:** pinned to `202604`; deprecates after ~12
  months. 10-week window safely inside.
- **Token revocation mid-campaign:** if Nick accidentally revokes app access,
  queue silently fails every fire. Mitigation: Phase 01's retry-on-401 auto-refreshes;
  hard-fail still needs manual `lp auth` re-run.

## Security Considerations
- Every queue entry's markdown is committed — never embed secrets (test tokens,
  draft confidential URLs) in slot copy.
- `.lp.log` may contain share URNs (not sensitive) but also token-refresh traces.
  Ensure redactor from Phase 01 is active.
- Comment-reply DMs are manual — no auth surface here.

## Next Steps
- After Phase 06 completes (Jun 27): archive campaign artifacts, extract learnings
  into a V1.5 campaign template for the CONSENSUS engine launch in Q3.
- Consider: wire post-publish webhook that auto-inserts the `feed_url` back into a
  campaign tracking Google Sheet for real-time dashboards.
