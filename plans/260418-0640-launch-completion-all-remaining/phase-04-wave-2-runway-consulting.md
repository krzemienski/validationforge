# Phase 4 — Wave 2 Runway + Consulting Magnet (Days 15-28)

## 1. Context Links

- Parent plan: [plan.md](plan.md)
- Master calendar §Weeks 3-4: `assets/campaigns/260418-validationforge-launch/execution/10-week-master-calendar.md`
- Week-3 reflection: `assets/campaigns/260418-validationforge-launch/copy/linkedin-week3-reflection.md`
- Week-3 deep-dive: `assets/campaigns/260418-validationforge-launch/copy/linkedin-week3-deepdive-no-mock-hook.md`
- Week-4 five-questions: `assets/campaigns/260418-validationforge-launch/copy/linkedin-week4-five-questions.md`
- Week-4 spotlight: `assets/campaigns/260418-validationforge-launch/copy/linkedin-week4-spotlight.md`
- Phase 3 final rollup (input): `reports/wave-1/…`

## 2. Overview

- **Date range:** Days 15-28, 2026-05-02 (Sat) → 2026-05-15 (Fri)
- **Priority:** P1 — Week 4 FIVE-QUESTIONS is highest consulting-inbound leverage of entire campaign
- **Status:** pending
- **Description:** Post-launch runway (Week 3) + authority cementing (Week 4). Requires real launch numbers from Phase 3 to be backfilled into `linkedin-week3-reflection.md` BEFORE Mon May 4 8:30am ET send. FIVE-QUESTIONS magnet on Mon May 12 is the campaign's commercial pivot. Weekly Sunday 5pm ET performance-gate evaluations green/yellow/red/black.
- **Estimated effort:** 16 hours

## 3. Key Insights

- `linkedin-week3-reflection.md` is DRAFTED (1,398 words) but contains placeholder numbers awaiting Wave 1 metrics. Backfill blocks Mon May 4 send.
- `linkedin-week3-deepdive-no-mock-hook.md` (1,614 words) requires a companion X excerpt thread — not drafted yet (readiness dashboard #7, row 8, X-thread not drafted).
- `linkedin-week4-five-questions.md` (2,657 words, consulting magnet) needs a 5-tweet X thread — not drafted yet (readiness #8, X-thread not drafted).
- Weekly Sunday gate formalizes the green/yellow/red/black decision framework from master calendar §Performance Gates.
- Consulting DMs from Wave 1 pile up; Phase 4 begins DM triage discipline (prelude to Phase 6 SLA).
- Sun May 10 = 4-week check-in = decoupling decision point (master calendar §Open Items #3).

## 4. Requirements

### Functional
- Real numbers filled into `linkedin-week3-reflection.md` by Sun May 3 evening (from Phase 3 rollup): star count, LI impressions, X impressions, HN points, Reddit upvotes, DM count.
- 4 Mon/Thu primary posts published on schedule: Mon May 4 reflection, Thu May 7 deep-dive, Mon May 12 five-questions, Thu May 15 spotlight.
- X threads drafted + published for deep-dive (8-tweet code excerpt) and five-questions (5-tweet).
- Weekly Sunday performance gate logged Sun May 3 + Sun May 10: green/yellow/red/black decision + rationale.
- FIVE-QUESTIONS DM excerpt sent to LinkedIn DMs (email-style broadcast to engaged Wave 1 commenters) on Mon May 12 afternoon.
- Sun May 10 decoupling decision: keep coupled vs decouple personal-brand/VF tracks for Weeks 5-10.
- Consulting DM count tracked in weekly log.

### Non-Functional
- Tone of Mon May 4 reflection matches `linkedin-week3-reflection.md` voice guidelines: honest, not celebratory, numbers-forward.
- No duplication of Wave 1 content — Week 3/4 posts must reference Wave 1 posts by link, not re-explain them.

## 5. Architecture — Order of Operations

```
Sat-Sun 05-02/03: Fill week3-reflection real numbers from Phase 3 rollup
Sun 05-03 17:00 ET: Weekly performance gate #1 (post-Wave-1)
Mon 05-04 08:30 ET: Reflection post
Wed 05-06: Draft deep-dive X thread (8 tweets)
Thu 05-07 08:30 ET: Deep-dive post + X thread + dev.to cross-post
Sun 05-10 17:00 ET: Weekly gate #2 + decoupling decision
Wed 05-11: Draft five-questions X thread (5 tweets) + LI-DM excerpt
Mon 05-12 08:30 ET: FIVE-QUESTIONS post + X thread
Mon 05-12 14:00 ET: LI-DM broadcast to 20-30 engaged Wave 1 commenters
Thu 05-15 08:30 ET: Spotlight post
Fri 05-15 17:00 ET: Week 4 closing check-in
```

## 6. Related Code/Artifact Files

- `copy/linkedin-week3-reflection.md` — backfill placeholders
- `copy/linkedin-week3-deepdive-no-mock-hook.md` — draft X thread (new file: `copy/x-thread-deepdive-hook.md`)
- `copy/linkedin-week4-five-questions.md` — draft X thread (new file: `copy/x-thread-five-questions.md`)
- `copy/linkedin-week4-spotlight.md`
- `copy/linkedin-week4-dm-excerpt.md` (NEW — send Mon May 12 to 20-30 Wave 1 engagers)
- `tracking/measurement-plan.md → Weekly Log` section (Phase 3 added this; append here)
- `reports/wave-2/weekly-gate-{YYYY-MM-DD}.md`
- `reports/wave-2/consulting-dm-log.md` — running DM count + qualification table

## 7. Implementation Steps

1. **[Sat 05-02 10:00 ET]** Read Phase 3 final rollup. Extract numbers: stars, LI impressions, X impressions, HN points, Reddit top upvotes, DM count.
2. **[Sat 05-02 12:00 ET]** Backfill `linkedin-week3-reflection.md` placeholders with real numbers. Grep for `{` to find all placeholders before saving.
3. **[Sun 05-03 15:00 ET]** Re-read the filled reflection post top-to-bottom. Voice check: honest, not triumphal. Hook-truncation check (first 210 chars).
4. **[Sun 05-03 17:00 ET]** Weekly gate #1: evaluate triggers per master calendar. Write verdict to `reports/wave-2/weekly-gate-2026-05-03.md` with: metrics snapshot, decision (green/yellow/red/black), Mon 05-04 send decision.
5. **[Mon 05-04 08:30 ET]** Publish reflection. If cron path, verify firing. Screenshot to `reports/wave-2/live-posts/`.
6. **[Wed 05-06 10:00 ET]** Draft `copy/x-thread-deepdive-hook.md` — 8 tweets, each quoting one code line from the 50-line hook. Voice-match hero-post pattern.
7. **[Thu 05-07 08:30 ET]** Publish deep-dive + X thread. Cross-post to dev.to with canonical URL pointing to personal blog (decision per Phase 5 prep).
8. **[Sun 05-10 17:00 ET]** Weekly gate #2. Includes decoupling decision: review master calendar §Open Items #3. Log decision to `reports/wave-2/decoupling-decision.md`.
9. **[Wed 05-11 10:00 ET]** Draft `copy/x-thread-five-questions.md` — 5 tweets, each one question. Also draft `copy/linkedin-week4-dm-excerpt.md` — short 150-word excerpt for DM broadcast.
10. **[Wed 05-11 15:00 ET]** Curate recipient list for DM excerpt: grep Phase 3 engagement logs for top 20-30 LinkedIn commenters; save list to `reports/wave-2/dm-broadcast-list.md` (names + profile URLs only — no DM body).
11. **[Mon 05-12 08:30 ET]** Publish FIVE-QUESTIONS + X thread. This is the commercial pivot — monitor DM inflow every 2h that day.
12. **[Mon 05-12 14:00 ET]** Send DM excerpt to curated list (one-by-one, personalized with a single-sentence reference to each person's prior comment — NOT a mail-merge blast).
13. **[Mon 05-12 17:00 ET]** Log DM broadcast completion + inbound DM count in `reports/wave-2/consulting-dm-log.md`.
14. **[Thu 05-15 08:30 ET]** Publish spotlight. Shorter post (1,179 words) — maintenance cadence.
15. **[Fri 05-15 17:00 ET]** Week 4 closing check-in. Update running DM log. Assess: is Phase 5 repo-prep on track? multi-agent-consensus deadline was Mon 05-11 — verify done.

## 8. Todo List + Day-by-Day Table

| # | Date | Day | Primary (08:30 ET) | X / Engage | Tracking | Evidence-of-Done |
|---|---|---|---|---|---|---|
| 1 | Sat 05-02 | D15 | (backfill prep) | engage prior-week comments | — | `linkedin-week3-reflection.md` placeholders filled; grep `{` returns 0 |
| 2 | Sun 05-03 | D16 | (prep complete) | — | **17:00 ET Weekly Gate #1** | `reports/wave-2/weekly-gate-2026-05-03.md` with verdict |
| 3 | Mon 05-04 | D17 | **Week-3 Reflection** post | X excerpt | daily log | live post screenshot + LI URL |
| 4 | Tue 05-05 | D18 | — | X receipt-of-week | daily log | X URL + engagement |
| 5 | Wed 05-06 | D19 | — | draft deep-dive X thread | daily log | `copy/x-thread-deepdive-hook.md` exists, 8 tweets |
| 6 | Thu 05-07 | D20 | **Deep-Dive 50-line Hook** + X 8-tweet + dev.to | — | daily log | LI + X + dev.to URLs |
| 7 | Fri 05-08 | D21 | — | Friday reflection 200w | daily log | X or LI short post URL |
| 8 | Sat 05-09 | D22 | (rest) | — | — | — |
| 9 | Sun 05-10 | D23 | (rest) | — | **17:00 ET Weekly Gate #2 + Decoupling Decision** | `reports/wave-2/weekly-gate-2026-05-10.md` + `decoupling-decision.md` |
| 10 | Mon 05-11 | D24 | (no primary) | — | Verify Phase 5 multi-agent-consensus polish deadline MET | `reports/wave-2/repo-prep-status.md` with multi-agent-consensus status |
| 11 | Tue 05-12 (Mon) | D25 | **FIVE-QUESTIONS** magnet + X 5-tweet + 08:30 ET LinkedIn | DM broadcast 14:00 ET | monitor DM inflow 2-hourly | LI URL + X URL + DM list sent + inbound-DM count |
| 12 | Tue 05-13 | D26 | — | engage FIVE-QUESTIONS comments heavily | daily log | reply-count ≥90% comments |
| 13 | Wed 05-14 | D27 | — | X mid-week | daily log | X URL |
| 14 | Thu 05-15 | D28 | **Patterns Spotlight** | X micro | daily log + Week-4 close | LI URL + Phase 4 summary in `reports/wave-2/phase-4-rollup.md` |

**Recurring todos (every day D15-D28):**

- [ ] Owner: Nick | Deadline: 17:00 ET daily | Effort: 15min | Deps: fresh metrics | Evidence: daily log entry in `tracking/measurement-plan.md`
- [ ] Owner: Nick | Deadline: daily rolling | Effort: 30min | Deps: inbound DMs | Evidence: DM log updated in `reports/wave-2/consulting-dm-log.md` (count + qualification tier only, no PII body)

**One-time todos:**

- [ ] Owner: Nick | Deadline: Sat May 2 18:00 | Effort: 1.5h | Deps: Phase 3 rollup | Evidence: week3-reflection.md with 0 placeholders (`grep -c '{[A-Z]' = 0`)
- [ ] Owner: Nick | Deadline: Sun May 3 17:30 | Effort: 45min | Deps: metrics snapshot | Evidence: `weekly-gate-2026-05-03.md` with verdict + rationale
- [ ] Owner: Nick | Deadline: Wed May 6 12:00 | Effort: 1.5h | Deps: none | Evidence: `copy/x-thread-deepdive-hook.md` with 8 numbered tweets
- [ ] Owner: Nick | Deadline: Sun May 10 17:30 | Effort: 45min | Deps: Wave-2 first week metrics | Evidence: `weekly-gate-2026-05-10.md` + `decoupling-decision.md`
- [ ] Owner: Nick | Deadline: Wed May 11 17:00 | Effort: 1.5h | Deps: none | Evidence: `copy/x-thread-five-questions.md` + `copy/linkedin-week4-dm-excerpt.md` + `dm-broadcast-list.md`
- [ ] Owner: Nick | Deadline: Mon May 11 EOD | Effort: (Phase 5) | Deps: Phase 5 owner | Evidence: multi-agent-consensus repo shows commit within 7d, badge present, homepage set
- [ ] Owner: Nick | Deadline: Mon May 12 14:00 | Effort: 1.5h | Deps: broadcast list | Evidence: 20-30 DMs sent, sent-count in `consulting-dm-log.md`
- [ ] Owner: Nick | Deadline: Fri May 15 17:00 | Effort: 1h | Deps: all above | Evidence: `reports/wave-2/phase-4-rollup.md` with 2-week metrics, DM count, gate-history

## 9. Success Criteria

- 4/4 primary posts published on schedule, each with live-post screenshot.
- 2/2 weekly gate decisions logged with verdict + rationale.
- Decoupling decision documented Sun May 10.
- FIVE-QUESTIONS DM broadcast sent to ≥20 recipients Mon May 12.
- Consulting DM inbound count tracked: **target ≥5 qualified DMs by end of Week 4** (feeds Phase 6 pipeline).
- multi-agent-consensus repo polish verified Mon May 11 (cross-phase check, Phase 5 owner).
- Phase 4 rollup written with: DM count, gate decisions, Mon May 12 inflow, open items for Phase 5/6.

## 10. Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Phase 3 numbers are weak (Floor verdict) → reflection post lands wrong | M | H | Pre-pub voice review — honest-retro tone is robust to weak numbers; the post is literally titled "What Didn't Work" |
| Reflection placeholders missed → live post shows `{NUMBER}` | L | CRITICAL | `grep '{[A-Z]'` gate before publish; CI-style check |
| FIVE-QUESTIONS underperforms → no consulting inbound | L | H | Red-gate flag; pivot Week 5 to direct 1:1 outreach instead of broadcast |
| DM broadcast reads as spam | M | M | Personalize each DM with 1-sentence reference to recipient's prior Wave-1 comment; ship <30 DMs not 300 |
| Decoupling decision leans "decouple" mid-campaign → brand confusion | L | M | Decision is for Weeks 5-10 only; Weeks 1-4 locked as coupled |
| multi-agent-consensus polish slips past Mon May 11 | M | H | Phase 4 owner monitors Phase 5 prep; if slip, delay Post 2 (Mon May 18) to Thu May 21 and re-shuffle |
| Consulting DM flood exceeds 2-bizday SLA | L | M | Triage queue; set "I respond in 2 business days" expectation in auto-reply if needed |
| Week 3 deep-dive X thread feels "too technical" for LI audience | L | L | LI deep-dive stays long-form; X thread is for the subset that wants code — this is correct segmentation |

## 11. Security Considerations

- DM broadcast list (`reports/wave-2/dm-broadcast-list.md`) contains LinkedIn profile URLs — not PII beyond public. Gitignore the file just in case (`reports/wave-2/*.md` wildcard).
- DM bodies NEVER committed to git — only summary count + qualification tier.
- Phase 2 `.env` tokens still active; no rotation needed.
- Consulting DM content may contain client hints — qualification log stores only: count, tier (cold/warm/hot), date, source channel. No names, no company names, no project details.
- dev.to cross-posts use personal dev.to account; no shared credentials.
- Review: `git check-ignore reports/wave-2/` should confirm exclusion before first commit.

## 12. Next Steps

- Phase 5 multi-agent-consensus polish deadline Mon May 11 runs in parallel with this phase — check-in Mon May 11 EOD.
- Phase 5 starts Sat May 16 (Week 5) with Post 2 adaptation and 12-post blog-series execution.
- Phase 6 DM triage protocol formally activates after Phase 4 — Wave 2 DMs feed the pipeline.
- Sun May 31 (end of Week 7) = Posts 12-18 extend/conclude decision (Phase 6 open decision #6).

## 13. Functional Validation

- **Placeholders-filled evidence:** `grep -cP '\{[A-Z_]+\}' copy/linkedin-week3-reflection.md` returns 0 before Mon May 4 08:00 ET. Log to `reports/wave-2/placeholder-check.txt`.
- **Weekly gate evidence:** `reports/wave-2/weekly-gate-2026-05-03.md` + `weekly-gate-2026-05-10.md` each contain: (1) metrics table with ≥6 rows, (2) verdict line (green|yellow|red|black), (3) rationale paragraph, (4) action decision for the next week.
- **Published-post evidence:** 4 LinkedIn post URLs + 4 live-post screenshots in `reports/wave-2/live-posts/`. Each URL returns HTTP 200.
- **X thread evidence:** `copy/x-thread-deepdive-hook.md` + `copy/x-thread-five-questions.md` exist; 8 + 5 numbered tweets respectively (`grep -cE '^T[0-9]+:' each-file` ≥ 8 / 5).
- **DM broadcast evidence:** `consulting-dm-log.md` shows ≥20 outbound DMs on 2026-05-12 with personalized 1-sentence references (stored as ID + timestamp only). Screenshot of LinkedIn "Sent" filter showing 20+ recent outbound.
- **Decoupling decision evidence:** `reports/wave-2/decoupling-decision.md` with: current state, decision (couple|decouple), rationale, 3-week re-evaluation date.
- **Consulting inbound evidence:** `consulting-dm-log.md` has ≥5 entries by Fri May 15 23:59 ET, each with tier (cold/warm/hot).
- **Phase rollup evidence:** `reports/wave-2/phase-4-rollup.md` present with 2-week metric delta vs Wave 1, consulting DM count, gate history, open items forwarded to Phases 5 and 6.
- **Phase complete claim:** must cite placeholder-check, 2 weekly gates, 4 post URLs, DM log, and phase rollup. Absence of any = FAIL per `evidence-before-completion.md`.
