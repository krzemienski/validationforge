# Phase 3 — Wave 1 Execution (Days 1-14)

## 1. Context Links

- Parent plan: [plan.md](plan.md)
- 14-day calendar: `assets/campaigns/260418-validationforge-launch/execution/14-day-calendar.md`
- 10-week master calendar: `assets/campaigns/260418-validationforge-launch/execution/10-week-master-calendar.md` §Week 1-2
- Measurement plan: `assets/campaigns/260418-validationforge-launch/tracking/measurement-plan.md`
- Show HN drafts: `assets/campaigns/260418-validationforge-launch/copy/show-hn-drafts.md`
- Reddit drops: `assets/campaigns/260418-validationforge-launch/copy/{reddit-posts.md, reddit-r-experienceddevs.md}`
- Discord drops: `assets/campaigns/260418-validationforge-launch/copy/discord-announcements.md`

## 2. Overview

- **Date range:** Days 1-14, 2026-04-20 (Mon) → 2026-05-01 (Fri)
- **Priority:** P0 — the highest-stakes two weeks of the entire 10-week campaign. North Star (100+ stars) is judged here.
- **Status:** pending
- **Description:** Execute the 14-day tactical sprint: 5 LinkedIn long-form slots, daily X drumbeat, 3 Reddit drops, 4 Discord drops, Show HN spike Tue Apr 28. Daily-log ritual at 5pm ET. Mid-sprint review Fri Apr 24 4pm. Show HN day (Tue Apr 28) is highest-stakes single event — everything else that day is cancelled.
- **Estimated effort:** 24 hours (≈2h/day average; Show HN day = 8h block)

## 3. Key Insights

- Soft-launch (Mon Apr 20) is the ignition. Part 1 (Wed Apr 22) is the manifesto. Show HN (Tue Apr 28) is the spike. Personal-brand hero (Wed Apr 29) converts spike → authority. Part 3 (Thu Apr 30) consolidates.
- Day 11 (Tue Apr 28) Show HN rules: post at 8:00am ET (Tue is best HN window), reply within 1 hour to every substantive comment, no simultaneous other drops that day.
- Mid-week engagement (Tue/Wed/Fri short posts) is NOT optional — it keeps the feed warm between Mon/Thu heavy posts.
- North Star is lagging. Tier-2 traffic metrics are leading — watch X cumulative impressions (250K target by Day 14) and GitHub unique visitors (500+).
- Day 7 mid-sprint review (Fri Apr 24 4pm ET) triggers Red-gate if impressions <30% of pace — reframe by Day 10.

## 4. Requirements

### Functional
- All 20 Days-1-14 content slots published on schedule (5 LinkedIn + 14 X threads + 3 Reddit + 4 Discord + 1 Show HN).
- Daily metrics log populated at 5pm ET, 14 entries in `tracking/measurement-plan.md → Daily Log`.
- Day 7 mid-sprint review filled in `measurement-plan.md → Mid-Sprint Review` template with green/yellow/red verdict.
- Show HN Day (Day 11) executed per HN day playbook: 8am post, author comment at T+5min, hourly engagement log, all comments replied within 1h during 8am-midnight ET.
- Day 14 final rollup (Fri May 1) written to `measurement-plan.md → Final Rollup`: 5 learnings + North Star verdict + what-to-keep/change.
- Companion repo ops: check `validationforge` star delta + issue/PR inflow at 5pm daily.

### Non-Functional
- No cross-posting the same content to 2 subs within 24h (iron rule #7).
- Every HN/Reddit comment gets a reply within 1 hour during launch day.
- If demo fails live, publish the failure with evidence (iron rule #6).

## 5. Architecture — Order of Operations

```
Daily ritual (every day Apr 20 → May 1):
  07:30 ET — confirm today's scheduled post fired (or manual-post)
  08:30 ET — publish or verify
  09:00 ET — X micro-post excerpting today's LinkedIn
  10:00 ET — engage: reply to all LI/X comments from prior day
  17:00 ET — daily log entry (11-line block)
  17:30 ET — queue tomorrow's asset if not done
  22:00 ET — final engagement sweep

Sprint gates:
  Day 7  Fri 04-24 16:00 ET — mid-sprint review, green/yellow/red
  Day 11 Tue 04-28 08:00 ET — SHOW HN, cancel all else today
  Day 14 Fri 05-01 17:00 ET — final rollup
```

## 6. Related Code/Artifact Files

- All copy files in `assets/campaigns/260418-validationforge-launch/copy/` (see Phase 1 list)
- `assets/campaigns/260418-validationforge-launch/tracking/measurement-plan.md` (append daily logs here)
- `assets/campaigns/260418-validationforge-launch/execution/14-day-calendar.md` (operational source of truth)
- `integrations/linkedin-publisher/linkedin-queue.json` (Phase 2 artifact driving Mon/Thu sends)
- `reports/wave-1/daily-log-{YYYY-MM-DD}.md` (per-day evidence log — TO CREATE)

## 7. Implementation Steps

See Day-by-Day Table in §Todo List below. Each row is the ordered list of ops for that day.

## 8. Todo List + Day-by-Day Table

**Column legend:** Primary = the scheduled long-form post · X = X thread/micro-post · Drops = Reddit/HN/Discord activity · Evidence = what is captured.

| # | Date | Day-of-Week | Primary (08:30 ET) | X / Micro | Drops | Evidence-of-Done |
|---|---|---|---|---|---|---|
| 1 | Mon 04-20 | D1 | LinkedIn soft-launch (`linkedin-soft-launch-mon-apr20.md`) + `vf-demo-hero.gif` | X drumbeat D1 (`x-threads.md`) | Discord ecosystem drops × 4 (Anthropic, OMC, Superpowers, plugin-dev) | `reports/wave-1/daily-log-2026-04-20.md` with star count + LI impressions + screenshots |
| 2 | Tue 04-21 | D2 | (mid-week, no primary) | X D2 drumbeat | r/ClaudeAI drop (`reddit-posts.md → r/ClaudeAI`) | reddit-post URL logged + upvotes at 17:00 |
| 3 | Wed 04-22 | D3 | LinkedIn Part 1 (`linkedin-blog-series.md → Part 1`) + `linkedin-part-1-hero.png` | X D3 BIG 8-tweet thread (`x-threads.md`) | — | Part 1 URL + X thread URL + first-hour impressions |
| 4 | Thu 04-23 | D4 | (no primary this week — Part 2 slides to Sat) | X D4 receipt-of-the-week | — | X thread URL + engagement |
| 5 | Fri 04-24 | D5 | (no primary) | X D5 micro-post | **16:00 ET MID-SPRINT REVIEW** → Part 2 + tracking `measurement-plan.md` | Mid-sprint section filled, verdict green/yellow/red, decision on Sat Part 2 |
| 6 | Sat 04-25 | D6 | LinkedIn Part 2 (`linkedin-blog-series.md → Part 2`) + `linkedin-part-2-hero.png` | X D6 mid-sprint excerpt | r/LocalLLaMA drop (`reddit-posts.md → r/LocalLLaMA`) | Part 2 URL + LocalLLaMA upvotes |
| 7 | Sun 04-26 | D7 | (rest) | — | Sunday 17:00 ET weekly review → log to `Weekly Log` | Weekly log entry |
| 8 | Mon 04-27 | D8 | (no primary — save oxygen for Show HN D11) | X D8 final tease for HN | — | Tease impressions |
| 9 | Tue 04-28 | D9 | **SHOW HN 08:00 ET** (`show-hn-drafts.md` variant chosen) + author comment T+5min | X D9 HN live thread update | r/ExperiencedDevs drop afternoon (`reddit-r-experienceddevs.md`) | HN URL + hourly log (08:00, 09:00, …, 23:00) + comment-reply count ≥90% |
| 10 | Wed 04-29 | D10 | **Personal-Brand Hero** (`personal-brand-launch-post.md`, 2,842 words) + `personal-brand-launch-hero.png` + 3 inline + headshot | X 5-tweet thread (`x-thread-launch-hero.md`) | — | Hero post URL + LI impressions + DM count |
| 11 | Thu 04-30 | D11 | LinkedIn Part 3 retrospective (`linkedin-blog-series.md → Part 3`) + `linkedin-part-3-hero.png` + optional 90s video | X D11 recap thread | — | Part 3 URL + referrer chart from GH Insights |
| 12 | Fri 05-01 | D12 | (no primary) | X D14 victory-lap thread referencing North Star result | **17:00 ET FINAL ROLLUP** → `measurement-plan.md → Final Rollup` | Rollup section filled: 5 learnings, North Star verdict tier, what-to-keep/change |

**Recurring daily todos (apply every day D1-D14):**

- [ ] Owner: Nick | Deadline: 08:30 ET daily | Effort: 15min | Deps: Phase 2 live OR manual fallback | Evidence: screenshot of live post in `reports/wave-1/live-posts/` per day
- [ ] Owner: Nick | Deadline: 10:00 ET daily | Effort: 30min | Deps: prior-day posts | Evidence: engagement log entry (comment-reply count)
- [ ] Owner: Nick | Deadline: 17:00 ET daily | Effort: 15min | Deps: fresh metrics | Evidence: 11-line daily log block appended to `measurement-plan.md → Daily Log` + per-day `reports/wave-1/daily-log-YYYY-MM-DD.md`
- [ ] Owner: Nick | Deadline: 22:00 ET daily | Effort: 15min | Deps: evening activity | Evidence: "last engagement at {ISO}" note in daily log

**Show HN (Tue Apr 28) special block:**

- [ ] Owner: Nick | Deadline: 08:00 ET | Effort: 15min | Deps: Phase 1 GIF + Show HN variant chosen by Sun Apr 26 | Evidence: HN submission URL in `reports/wave-1/hn-submission.txt`
- [ ] Owner: Nick | Deadline: 08:05 ET | Effort: 10min | Deps: HN post live | Evidence: author comment permalink
- [ ] Owner: Nick | Deadline: Every hour 08:00-23:00 ET | Effort: 15min/hr | Deps: HN activity | Evidence: hourly rank + points + comment count log in `reports/wave-1/hn-hourly-log.md`
- [ ] Owner: Nick | Deadline: 23:00 ET | Effort: 30min | Deps: full day | Evidence: final HN state + "time on front page ≥4hrs" verified

**Mid-sprint + final rollup:**

- [ ] Owner: Nick | Deadline: Fri Apr 24 16:00 ET | Effort: 1h | Deps: 6 days of metrics | Evidence: mid-sprint review section filled with green/yellow/red + pivot decision if needed
- [ ] Owner: Nick | Deadline: Fri May 1 17:00 ET | Effort: 2h | Deps: all 14 daily logs | Evidence: final rollup section with verdict tier (Stretch/Win/Floor/Failure), 5 learnings, keep/change list

## 9. Success Criteria

- **North Star:** ≥100 stars on `github.com/krzemienski/validationforge` by Fri May 1 23:59 ET (floor 50, stretch 250).
- Tier-2 traffic: X cumulative impressions ≥250K, GitHub unique visitors ≥500, LinkedIn cumulative impressions ≥5K across 3 Parts.
- Show HN: reaches front page (≥50 pts) AND stays ≥4h.
- 14/14 daily logs filled on time.
- Mid-sprint review completed Fri Apr 24.
- Final rollup completed Fri May 1.
- Verdict tier determined: Stretch / Win / Floor / Failure.

## 10. Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Show HN flames out (<20 pts in first hour) | M | H | Red-gate triggers pivot; switch to r/ExperiencedDevs drop afternoon to salvage the day; reframe message based on HN feedback |
| LinkedIn Part 1 flat (<1K impressions first 24h) | M | H | Trigger Red gate; skip Part 2 Sat send; use Sun for root-cause + message reframe; publish Part 2 revised Mon 04-27 |
| Demo fails live during HN / X amplification | L | H | Iron rule #6 — publish failure with evidence, fix forward; past-incident doc in `e2e-evidence/` shows this converts skepticism to trust |
| Personal-brand hero post (2,842 words) gets truncated badly | L | M | Pre-publish: verify first 210 chars pass LinkedIn hook-truncation test (Phase 1 voice-edit pass already covers this) |
| Consulting DM flood exceeds Nick's 2-business-day SLA | L | M | Queue in Notes app, triage next-week; if >20, trigger Phase 6 DM triage protocol early |
| Factual error surfaces in comments → requires VF code fix | L | H | Black-gate full pause 1 week; log pivot in `measurement-plan.md → Pivot Log`; resume Week 3 with revised plan |
| ai-dev-operating-system conflict re-surfaces in Part 1 comments | M | M | Phase 1 decision forces calendar alignment; if question raised, answer with Phase 1 dashboard link |
| X thread gets quote-tweeted by a critic with large following | L | M | Iron rule #8 — block-quote the criticism, reply with receipts, do not paraphrase |
| LinkedIn publisher (Phase 2) fails mid-week | L | M | Manual-fallback doc covers 5 remaining primary sends in <30min each |

## 11. Security Considerations

- All published content is already written and voice-reviewed; no fresh copy drafted in this phase → no risk of accidental secret paste.
- Show HN submission uses Nick's personal HN account; no shared credentials.
- Reddit drops use Nick's account; rate-limited by subreddit rules (new-account throttle does not apply).
- LinkedIn auto-publish uses Phase 2 `w_member_social` scope only — cannot read DMs.
- Daily logs contain star counts, follower counts, and DM counts — no PII. Consulting DMs summarized by count only, no names.
- Screenshots saved to `reports/wave-1/live-posts/` must NOT include terminal screenshots with env vars, API keys, or $HOME user paths.
- HN account 2FA should be active throughout Day 11.

## 12. Next Steps

- **If Verdict = Win or Stretch:** Phase 4 launches Mon May 4 with `linkedin-week3-reflection.md` (real numbers filled from Wave 1 metrics).
- **If Verdict = Floor:** Phase 4 launches as planned but with adjusted tone (less triumphant); Phase 5 repo-prep deadlines examined for feasibility.
- **If Verdict = Failure:** Black-gate activated — 1-week pause, root-cause write-up, revised plan for Week 3 onwards. Phase 4 shifts right by 1 week.
- Phase 5 first repo polish (multi-agent-consensus) deadline Mon May 11 — starts regardless of Wave 1 verdict.

## 13. Functional Validation

- **Per-day evidence:** each `reports/wave-1/daily-log-YYYY-MM-DD.md` contains: (1) screenshot of live post at 08:30 ET, (2) 11-line metrics block, (3) engagement count (reply-count ≥ expected floor), (4) any anomalies. 14/14 files exist by Fri May 1 23:59 ET.
- **Published-post evidence:** LinkedIn API (`GET /rest/posts/{urn}`) OR direct LinkedIn URL returns HTTP 200 for each of the 5 primary posts. Saved to `reports/wave-1/linkedin-post-urns.txt`.
- **HN evidence:** `reports/wave-1/hn-hourly-log.md` contains ≥16 hourly snapshots (08:00-23:00). Front-page verified via `https://news.ycombinator.com/front?day=2026-04-28` screenshot.
- **Reddit evidence:** 3 post URLs + final upvote count per sub, in `reports/wave-1/reddit-drops.md`.
- **North Star evidence:** Fri May 1 23:59 ET, `gh api repos/krzemienski/validationforge --jq '.stargazers_count'` → value ≥ 100 (target) or ≥ 50 (floor). Saved to `reports/wave-1/north-star-final.txt`.
- **Mid-sprint review evidence:** `measurement-plan.md` contains filled Mid-Sprint Review section with 6-day metrics table + green/yellow/red verdict + decision line.
- **Final rollup evidence:** `measurement-plan.md` contains filled Final Rollup section with: verdict tier, 5 learnings (numbered), keep-list (3+ items), change-list (3+ items), consulting DM count.
- **Phase complete claim:** must cite all 7 evidence artifacts above. A completion claim like "Wave 1 shipped" without the `north-star-final.txt` file is rejected per `evidence-before-completion.md`.
