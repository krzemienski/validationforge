# Phase 6 — Post-Launch Retention

## 1. Context Links

- Parent plan: [plan.md](plan.md)
- Phase 5 10-week rollup (input): `reports/wave-3/10-week-kpi-rollup.md`
- Master calendar §Open Items #5 (Posts 12-18): `assets/campaigns/260418-validationforge-launch/execution/10-week-master-calendar.md`
- Blog-site integration: `assets/campaigns/260418-validationforge-launch/blog-site-mdx/SITE-INTEGRATION-STEPS.md`
- Consulting DM log (input): `reports/wave-2/consulting-dm-log.md`
- V1.5 CONSENSUS engine: `CLAUDE.md § /validate-consensus` + `skills/consensus-engine/`

## 2. Overview

- **Date range:** Days 71-100, 2026-06-28 (Sun) → 2026-07-25 (Fri); 4-week retention window
- **Priority:** P2 — launch done, now convert attention → revenue + SEO compounding
- **Status:** pending
- **Description:** Three workstreams in parallel — (A) Consulting DM triage with 2-business-day SLA, qualifying inbound into a one-paragraph format that turns engaged DMs into discovery calls; (B) Blog-site SEO push: canonical URLs, sitemap submission, Google Search Console setup, Dev.to canonical backlinks; (C) V1.5 CONSENSUS engine launch prep, running parallel to the extend-vs-conclude decision on Posts 12-18.
- **Estimated effort:** 6 hours total across 4 weeks (≈1.5h/wk — maintenance cadence)

## 3. Key Insights

- Consulting conversion is the campaign's true ROI metric. Phase 4 + 5 generated the pipeline; Phase 6 closes it.
- SEO compounds silently — canonical URLs + sitemap submission ship SEO value that accrues through Q3 without further posting.
- V1.5 CONSENSUS launch sits outside this plan's copy pipeline; Phase 6 is prep-only in baseline, but user decision (2026-04-18) adds a LAUNCH gate: if readiness-dashboard flags **≤3 gaps** on Sat Jul 12 (Day 85), V1.5 launches within Phase 6 window; else defer cleanly to Q3.
- Extend-vs-conclude decision on Posts 12-18 has long tail — extending adds 3-4 weeks, recommended only if 10-week KPIs exceed Target.
- Blog-site integration (`SITE-INTEGRATION-STEPS.md`) is already written; it's an 8-copy + flag-flip operation, ≈1 hour.

## 4. Requirements

### Functional
- Consulting DM triage SLA: respond to every qualifying DM within 2 business days. Response uses one-paragraph qualifying format that asks: (1) specific problem, (2) timeline, (3) budget tier. Template at `copy/consulting-response-template.md` (NEW).
- Blog-site integration executed: 8 VF/personal-brand posts copied to `~/Desktop/blog-series/site/posts/post-vf-*/post.md` per SITE-INTEGRATION-STEPS.md; `published` flag flipped after review.
- SEO foundation: (1) canonical URLs set in every LinkedIn article pointing to personal blog; (2) sitemap.xml submitted to Google Search Console; (3) GSC property verified; (4) 30-day impression baseline measured.
- V1.5 CONSENSUS launch prep: readiness-dashboard-style audit of consensus-engine skill + separate campaign brief (not full plan — just readiness audit).
- Posts 12-18 extend/conclude decision documented (already overdue from Phase 5 Sun May 31 gate, re-confirmed here).
- End-of-retention summary: revenue booked, pipeline state, V1.5 go-date.

### Non-Functional
- DM triage takes precedence — commercial work > content work in retention.
- Canonical URL must be the personal-blog URL, not LinkedIn (LI canonical = LI penalizes SEO attribution).
- GSC property must be Nick-owned (personal Google account, not shared).

## 5. Architecture — Order of Operations

```
Week A (Jun 28 - Jul 4) — Consulting triage activation
  - Sun: read all Phase 4+5 DMs, tier them (cold/warm/hot)
  - Set up Notion/Linear board for DM pipeline
  - Author consulting-response-template.md
  - Respond to all hot DMs first, warm DMs by end of week

Week B (Jul 5 - Jul 11) — SEO push
  - Set up Google Search Console for personal blog
  - Ensure canonical URLs in all 20 LinkedIn articles point to personal blog
  - Blog-site integration: copy 8 VF/brand posts per SITE-INTEGRATION-STEPS.md
  - Submit sitemap.xml

Week C (Jul 12 - Jul 18) — V1.5 CONSENSUS prep + LAUNCH DECISION
  - Sat Jul 12 AM: Audit consensus-engine skill state
  - Sat Jul 12 PM: Write V1.5 readiness dashboard; COUNT GAPS
  - **DECISION GATE Sat Jul 12 17:00 ET:** if gaps ≤3 → launch inside Phase 6;
    if gaps >3 → draft V1.5 campaign brief only, defer launch to Q3
  - Log decision to `reports/retention/v1-5-launch-decision-2026-07-12.md`

Week D (Jul 19 - Jul 25) — Close + decide
  - Measure: DMs → discovery calls → engagements booked
  - Finalize Posts 12-18 decision (extend vs conclude)
  - Write retention summary
```

## 6. Related Code/Artifact Files

- `copy/consulting-response-template.md` (NEW — one-paragraph qualifier template)
- `reports/retention/dm-pipeline-{YYYY-MM-DD}.md` (weekly DM state)
- `reports/retention/seo-baseline-2026-07-04.md` (GSC baseline)
- `reports/retention/v1-5-readiness-dashboard.md` (NEW)
- `reports/retention/v1-5-campaign-brief.md` (NEW)
- `reports/retention/posts-12-18-decision.md`
- `reports/retention/retention-summary.md` (final EOD Fri Jul 24)
- Blog-site integration: `~/Desktop/blog-series/site/posts/post-vf-*/` (8 dirs TO CREATE)

## 7. Implementation Steps

1. **[Sun Jun 28 10:00 ET]** Read `reports/wave-2/consulting-dm-log.md` + `reports/wave-3/…/dm-log` (cumulative). Tier each DM into cold (polite-but-no-need), warm (curious-exploring), hot (explicit-asking-about-engagement).
2. **[Sun Jun 28 12:00 ET]** Draft `copy/consulting-response-template.md`: 150 words max, asks (a) specific problem, (b) timeline, (c) budget tier. Tone matches personal-brand-launch-post.md §CTA.
3. **[Sun Jun 28 14:00 ET]** Set up simple DM pipeline tracker (Notion kanban OR flat file `reports/retention/dm-pipeline-2026-06-28.md` with columns: name-id | tier | last-touch | next-action | status).
4. **[Mon-Fri Jun 29 - Jul 3]** Respond to hot DMs first (≤2 business days), warm DMs by end of week. Log every response in pipeline tracker.
5. **[Fri Jul 3 17:00 ET]** Week-A summary: DM responses sent, discovery calls scheduled, engagements booked.
6. **[Sun Jul 5 10:00 ET]** Google Search Console: add personal blog property, verify ownership via DNS TXT record or HTML upload.
7. **[Sun Jul 5 12:00 ET]** Audit LinkedIn articles for canonical URLs. For each of 20 published posts: set canonical in LinkedIn article settings → point to personal-blog URL. Save canonical-set list to `reports/retention/canonical-urls.md`.
8. **[Mon Jul 6 10:00 ET]** Execute `SITE-INTEGRATION-STEPS.md`: 8 `cp` commands into `~/Desktop/blog-series/site/posts/post-vf-*/post.md`. Verify loader picks them up (`npm run dev`). All 8 ship `published: false`.
9. **[Tue Jul 7 10:00 ET]** Review 8 posts in dev preview; flip `published: true` for each after voice re-check.
10. **[Wed Jul 8 10:00 ET]** Generate + submit sitemap: `npm run build` produces `sitemap.xml`; submit URL to GSC.
11. **[Fri Jul 10 17:00 ET]** Week-B summary: GSC baseline impressions (14-day baseline), 8 posts live on blog-site, canonical URLs verified.
12. **[Mon Jul 13 10:00 ET]** V1.5 CONSENSUS audit: read `skills/consensus-engine/SKILL.md` + `CLAUDE.md § /validate-consensus` + `agents/consensus-validator.md` + `consensus-synthesizer.md`. Write readiness dashboard mirroring Phase 1 launch readiness style — what's ready, what's partial, what's missing.
13. **[Wed Jul 15 10:00 ET]** Draft 1-page V1.5 campaign brief: hook, 3-question leadership CTA, 3-channel distribution plan (LinkedIn + X + HN). Save to `reports/retention/v1-5-campaign-brief.md`.
14. **[Fri Jul 17 17:00 ET]** Week-C summary: V1.5 go/no-go recommendation.
15. **[Mon Jul 20 10:00 ET]** Posts 12-18 decision: read 10-week KPI rollup, evaluate vs Target/Stretch from master-calendar §Success Metrics. If ≥ Target on stars AND DMs: extend (3-4 more weeks). If < Target: conclude at 11.
16. **[Wed Jul 22 10:00 ET]** If extend: draft Posts 12-18 slotting table; sketch repo-prep deadlines; add to plan amendment. If conclude: write "campaign closeout" mini-post (LinkedIn, 400 words).
17. **[Fri Jul 24 17:00 ET]** Write `reports/retention/retention-summary.md`: DM pipeline final state, engagements booked, revenue (if any), SEO baseline, V1.5 go-date, Posts 12-18 decision.

## 8. Todo List

- [ ] Owner: Nick | Deadline: Sun Jun 28 15:00 | Effort: 1h | Deps: Phase 4/5 DM logs | Evidence: `dm-pipeline-2026-06-28.md` with ≥10 DMs tiered
- [ ] Owner: Nick | Deadline: Sun Jun 28 14:00 | Effort: 30min | Deps: none | Evidence: `copy/consulting-response-template.md` exists, <150 words
- [ ] Owner: Nick | Deadline: Fri Jul 3 17:00 | Effort: 2h spread across week | Deps: template | Evidence: DM pipeline file shows ≥90% of hot+warm DMs responded; 2-bizday SLA adherence count in Week-A summary
- [ ] Owner: Nick | Deadline: Sun Jul 5 14:00 | Effort: 30min | Deps: personal blog live | Evidence: GSC property verified; screenshot in `reports/retention/gsc-verification.png`
- [ ] Owner: Nick | Deadline: Sun Jul 5 17:00 | Effort: 1.5h | Deps: GSC live | Evidence: `canonical-urls.md` with 20 rows (LI post URL → blog canonical URL)
- [ ] Owner: Nick | Deadline: Mon Jul 6 12:00 | Effort: 1h | Deps: SITE-INTEGRATION-STEPS.md | Evidence: `ls ~/Desktop/blog-series/site/posts/post-vf-*/post.md \| wc -l` returns 8
- [ ] Owner: Nick | Deadline: Wed Jul 8 12:00 | Effort: 30min | Deps: site build | Evidence: GSC sitemap submission screenshot + status "Success"
- [ ] Owner: Nick | Deadline: Mon Jul 13 17:00 | Effort: 1.5h | Deps: consensus-engine state | Evidence: `v1-5-readiness-dashboard.md` with ready/partial/missing matrix
- [ ] Owner: Nick | Deadline: Wed Jul 15 17:00 | Effort: 1h | Deps: V1.5 audit | Evidence: `v1-5-campaign-brief.md` 1-page
- [ ] Owner: Nick | Deadline: Mon Jul 20 17:00 | Effort: 45min | Deps: 10-week KPI + DM pipeline state | Evidence: `posts-12-18-decision.md` with decision + rationale
- [ ] Owner: Nick | Deadline: Fri Jul 24 17:00 | Effort: 1h | Deps: all above | Evidence: `retention-summary.md` with: DM pipeline state, engagements booked, SEO baseline, V1.5 recommendation, Posts 12-18 decision

## 9. Success Criteria

- DM response SLA: ≥90% of qualifying DMs responded within 2 business days, measured over 4-week window.
- DM → discovery call conversion: ≥3 discovery calls scheduled by Fri Jul 24 (from ≥5 qualified DMs per Phase 4 target).
- Engagements booked (stretch): ≥1 paid consulting engagement signed by Fri Jul 24.
- SEO: GSC property verified, sitemap submitted, blog-site shows 8 VF/brand posts live with canonicals set.
- V1.5 readiness dashboard complete; campaign brief complete.
- Posts 12-18 decision documented with rationale + next action.
- Retention summary published.

## 10. Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| DM flood post-Week-10 exceeds triage capacity | M | M | Explicit SLA in response template ("responding in 2 business days"); auto-reply mode if >20 hot DMs/week |
| DMs cool off → 0 discovery calls | M | H | Qualification template asks budget tier up-front; cold responses get polite closeout; warm DMs get a low-friction "15-min chat" offer |
| V1.5 CONSENSUS not actually ready to launch | M | M | Readiness dashboard catches gaps; if missing >3 items, recommend V1.5 slip to Q3 |
| GSC verification fails (DNS access issue) | L | M | Fallback: HTML file upload verification to personal blog |
| Blog-site loader bug — 8 posts don't render | L | M | SITE-INTEGRATION-STEPS.md §2 names Option A correctly; `npm run dev` preview catches any issue pre-flip |
| Posts 12-18 extend decision gets deferred indefinitely | M | L | Hard gate Mon Jul 20; if decision not made, default = conclude |
| Canonical-URL audit discovers LI canonicals point to self (not blog) | M | M | Fixable via LI article edit → canonical field; batch through 20 posts in 90 min |
| Consulting DM from competitor fishing for positioning | L | L | Qualification template's "specific problem" question screens these out |
| Retention summary missed (burnout) | L | L | Hard deadline Fri Jul 24; if missed, 1 week slip OK but explicit note in `plan.md` |

## 11. Security Considerations

- Consulting DM content is commercially sensitive — pipeline tracker stores only: opaque ID, tier, last-touch date, next-action, status. NO names, company names, or project details in repo.
- If Notion used for DM tracker, access restricted to Nick's personal workspace; no team-shared.
- `consulting-response-template.md` is public (committed) — must not include real client names or specific numbers.
- GSC requires Google account access; 2FA must be active.
- Canonical URLs point to personal blog — blog hosting (Vercel) must be owned by Nick's personal account (not company account) to preserve control.
- V1.5 readiness dashboard + campaign brief are public-safe (no unreleased product details beyond what's already in CLAUDE.md).
- Blog-site `published: false` gate prevents accidental early-publish during integration.
- `reports/retention/*.md` may contain aggregate DM counts — gitignore body files but allow summary.
- Revenue figures in retention summary = aggregate only (e.g., "1 engagement signed"), not client names.

## 12. Next Steps

- V1.5 CONSENSUS campaign (separate plan, to be drafted Q3 if go decision).
- If Posts 12-18 extend: amendment to this plan adds Phase 7 (Jul 26 - Aug 15, 3 weeks, 6 more posts).
- DM pipeline continues beyond Jul 25 as ongoing ops — not a "phase" but a standing practice.
- SEO baseline measured again at Day 90 (late Sep 2026) to demonstrate compounding.

## 13. Functional Validation

- **DM triage evidence:** `reports/retention/dm-pipeline-2026-06-28.md` (and weekly updates); final state shows ≥90% response rate via SLA-adherence column. Discovery-call count in `retention-summary.md`.
- **Template evidence:** `wc -w copy/consulting-response-template.md` returns ≤150.
- **GSC evidence:** `reports/retention/gsc-verification.png` screenshot; `reports/retention/gsc-baseline-impressions.txt` with 14-day impression count.
- **Canonical URLs evidence:** `canonical-urls.md` with 20 rows; spot-check 3 random LI posts via browser → view canonical meta.
- **Blog-site integration evidence:** `ls ~/Desktop/blog-series/site/posts/post-vf-*/post.md | wc -l` = 8; browser test of each of 8 URLs returns HTTP 200.
- **Sitemap evidence:** GSC sitemap submission screenshot showing "Success" status; `curl -s <blog>/sitemap.xml | grep -c '<url>'` returns ≥26 (18 original + 8 VF/brand).
- **V1.5 readiness evidence:** `v1-5-readiness-dashboard.md` has ready/partial/missing rows with ≥15 items; `v1-5-campaign-brief.md` fits 1 page.
- **Posts 12-18 decision evidence:** `posts-12-18-decision.md` with decision line (EXTEND | CONCLUDE), ≥3 bullets of rationale, and next action.
- **Retention summary evidence:** `retention-summary.md` with 5 required sections: DM pipeline state, engagements booked, SEO baseline, V1.5 recommendation, Posts 12-18 decision.
- **Phase complete claim:** must cite retention-summary.md + DM pipeline file + GSC screenshot + posts-12-18 decision. Campaign is officially closed when all 4 artifacts exist and retention-summary sign-off is written.
