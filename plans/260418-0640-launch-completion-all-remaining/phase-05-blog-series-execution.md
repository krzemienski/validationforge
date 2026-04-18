# Phase 5 — Blog-Series Execution (Weeks 5-10)

## 1. Context Links

- Parent plan: [plan.md](plan.md)
- Master calendar §Weeks 5-10: `assets/campaigns/260418-validationforge-launch/execution/10-week-master-calendar.md`
- Companion-repo prep checklist: `assets/campaigns/260418-validationforge-launch/execution/companion-repo-prep-checklist.md`
- Blog-series adaptations: `assets/campaigns/260418-validationforge-launch/copy/blog-series-adapted/post-{01..11}-linkedin.md` + `-x-thread.md`
- Wrap-post scaffold: `assets/campaigns/260418-validationforge-launch/copy/wrap-post-week-10-scaffold.md`
- Source blog-series: `~/Desktop/blog-series/posts/post-{NN}-{slug}/`

## 2. Overview

- **Date range:** Days 29-70, 2026-05-16 (Sat) → 2026-06-27 (Sat); 12 slots over 6 weeks
- **Priority:** P1 — blog series is the authority-cementing phase; wraps with capstone + retrospective
- **Status:** pending
- **Description:** Execute 12 blog-series adaptations on Mon+Thu 8:30am ET. Each post requires: (1) companion repo polished 7 days prior (refresh commit + badge + Related Post URL), (2) LinkedIn + X adaptation live, (3) optional HN / Reddit / dev.to cross-post per calendar. Week 9 fill wrap-post scaffold with 24 real-metric placeholders. Week 10 capstone (Post 11) + wrap (Thu Jun 25).
- **Estimated effort:** 20 hours (≈3.3h/week average — repo prep + post publish + engagement)

## 3. Key Insights

- **Repo-prep is the hidden critical path.** Each companion repo must be polished ≥7 days before post send. multi-agent-consensus deadline Mon May 11 was already-set in Phase 4. All 11 deadlines are in prep-checklist master table.
- All 11 repos need a refresh commit before send (60-day dormancy threshold). Push the staged README patch from Phase 1 — that commit doubles as the refresh.
- Source blog-series drift: Posts 5, 6, 9 were rewritten 2026-04-18 to calendar framing. **Adaptations are calendar-faithful, not source-faithful.** Do not re-sync from source.
- Wrap-post scaffold has 24 placeholders documented in wrap-post's own data-source mapping table — Week 9 (Jun 13-19) fill window.
- Calendar drift: Post 3 companion was `functional-validation-framework`, corrected to `claude-code-skills-factory`. Post 11 was `ai-dev-operating-system`, corrected to `validationforge`. Stay aligned with prep-checklist v2.
- Weekly Sunday gate continues from Phase 4.

## 4. Requirements

### Functional
- 12/12 blog-series adaptations published on schedule (2 posts/week × 6 weeks).
- 10/10 companion repos polished by deadline per prep-checklist master table (validationforge already polished via Phase 1; agentic-development-guide + multi-agent-consensus + claude-code-skills-factory + claude-ios-streaming-bridge + claude-sdk-bridge + auto-claude-worktrees + claude-prompt-stack + ralph-orchestrator-guide + code-tales + stitch-design-to-code).
- Per-post ritual executed: refresh commit (7d before), topic tags verified, homepage URL set, install-verify where applicable.
- Wrap-post scaffold filled during Week 9 (24 placeholders → real metrics).
- Week 10 wrap (Thu Jun 25) published with retrospective tone matching week3-reflection voice.
- Weekly Sunday 17:00 ET performance gates continue.
- Cross-posts per calendar: HN submissions × 5 (Posts 2, 5, 6, 9 per calendar; Post 11 capstone optional), Dev.to cross-post × all 12 (48h after LI), Reddit × 3 (r/programming Post 2, r/ExperiencedDevs Post 3, r/iOSProgramming Post 4, r/rust Post 8).

### Non-Functional
- Max 1 HN submission per 2 weeks (spam-signal limit).
- Max 1 Reddit drop per sub per month.
- 48h gap between LI primary and dev.to cross-post.

## 5. Architecture — Order of Operations

```
Per-post ritual (T = publish date):
  T-7 days (EOD): Repo polish per prep-checklist (badge + homepage + topics + refresh commit + install-verify)
  T-3 days: Verify source asset exists (~/Desktop/blog-series/posts/post-NN/assets/stitch-hero.png)
  T-1 day: Final voice-edit pass on LI adaptation
  T-1 day 17:00 ET: Queue in LinkedIn publisher
  T (08:30 ET): LI primary live
  T (09:00 ET): X thread live + repo URL
  T (10:00-18:00 ET): engage all comments
  T+1: reply to overnight comments
  T+2 (08:30 ET): dev.to cross-post with canonical=personal blog
  T+3 to T+7: HN submission IF calendar flags HN (Tue/Wed 09:00-10:00 ET best window)

Weekly Sunday gate runs every week.
Week 9 (Jun 13-19) dedicated fill-window for wrap-post scaffold.
```

## 6. Related Code/Artifact Files

- `copy/blog-series-adapted/post-{01..11}-linkedin.md`
- `copy/blog-series-adapted/post-{01..11}-x-thread.md`
- `copy/wrap-post-week-10-scaffold.md` → becomes `copy/wrap-post-week-10-final.md` by Tue Jun 23
- `execution/companion-repo-prep-checklist.md` (per-repo per-deadline table)
- `tracking/measurement-plan.md → Repo Attribution` + `Weekly Log`
- `reports/wave-3/weekly-gate-{YYYY-MM-DD}.md`
- `reports/wave-3/repo-prep-{repo}.md` per companion (11 files)
- `reports/wave-3/post-{NN}-attribution.md` per post (star delta, referrers)

## 7. Implementation Steps

See Week-by-Week Table below. Each row is the full ritual for one post.

## 8. Todo List + Week-by-Week Table

**Column legend:** Repo-prep deadline = T-7 · LI post = T (Mon/Thu 08:30 ET) · X = T+1h · Cross-post = T+48h dev.to · HN = T+3d to +5d if flagged.

| # | Week | Send date | Post title (abbrev.) | Companion repo | Repo-prep deadline | HN/Reddit/Dev.to | Evidence-of-Done |
|---|---|---|---|---|---|---|---|
| 1 | W5 | **Mon May 18** | Post 2: Three Agents P2 Bug (10/10) | `multi-agent-consensus` | **Mon May 11** | HN Show HN Tue May 19 · r/programming · X 8t · Dev.to T+2 | Post URL + HN URL + attribution log |
| 2 | W5 | **Thu May 21** | Post 3: Banned Unit Tests | `claude-code-skills-factory` | **Thu May 14** | r/ExperiencedDevs · X 10t · Medium via Better Programming T+3 | Post URL + Reddit URL + attribution |
| 3 | W6 | **Mon May 26** | Post 1: 4,500 Sessions (series overview) | `agentic-development-guide` | **Tue May 19** | Pin as series hub · Dev.to T+2 · X recap | Post URL + pinned-status screenshot |
| 4 | W6 | **Thu May 29** | Post 7: 7-Layer Prompt Stack | `claude-prompt-stack` | **Thu May 22** | Dev.to T+2 · X one-tweet-per-layer | Post URL + template-repo button enabled |
| 5 | W7 | **Mon Jun 1** | Post 5: 5 Layers to Call API | `claude-sdk-bridge` | **Mon May 25** | HN Tue Jun 2 · X 6t | Post URL + HN URL |
| 6 | W7 | **Thu Jun 4** | Post 6: 194 Worktrees | `auto-claude-worktrees` | **Thu May 28** (requires v0.1.0 release) | HN Tue Jun 9 · X 6t | Post URL + release tag verified |
| 7 | W8 | **Mon Jun 8** | Post 9: Code Tales | `code-tales` | **Mon Jun 1** (full install-verify 25min) | Show HN Tue Jun 9 · Product Hunt | Post URL + Show HN URL + PH URL |
| 8 | W8 | **Thu Jun 11** | Post 4: iOS SSE Bridge | `claude-ios-streaming-bridge` | **Thu Jun 4** (Swift build + v0.1.0) | Dev.to primary · LI excerpt · r/iOSProgramming | Post URL + Swift-build log |
| 9 | W9 | **Mon Jun 15** | Post 10: 21 Screens Zero Figma | `stitch-design-to-code` | **Mon Jun 8** (embed 4-6 screenshots) | Dev.to T+2 · X visual carousel · Dribbble case study | Post URL + screenshots in README |
| 10 | W9 | **Thu Jun 18** | Post 8: Ralph Orchestrator | `ralph-orchestrator-guide` | **Thu Jun 11** (desc rewrite + configs runnable) | HN Tue Jun 16 · r/rust · X hat-system | Post URL + HN URL |
| 11 | W10 | **Mon Jun 22** | Post 11: AI Dev OS Capstone | `validationforge` (corrected from ai-dev-operating-system per prep-checklist) | **Mon Jun 15** (v1.0.0 tag + "Built On" section) | HN Tue Jun 23 · X long thread linking all prior posts | Post URL + v1.0.0 release URL |
| 12 | W10 | **Thu Jun 25** | 10-Week Wrap (scaffold → final) | meta (references all 11) | — | Blog canonical · X final thread | Post URL + wrap-post-week-10-final.md with 0 placeholders |

**Recurring per-week todos:**

- [ ] Owner: Nick | Deadline: Sunday 17:00 ET each week | Effort: 45min | Deps: weekly metrics | Evidence: `reports/wave-3/weekly-gate-{date}.md`
- [ ] Owner: Nick | Deadline: T-7 for each of 10 repos | Effort: 25-60min per repo | Deps: prep-checklist | Evidence: `reports/wave-3/repo-prep-{repo}.md` with checklist + commit SHA + `gh api` timestamp
- [ ] Owner: Nick | Deadline: T+7 per post | Effort: 15min | Deps: 72h post-publish | Evidence: `reports/wave-3/post-{NN}-attribution.md` — star delta, referrer mix, new issues

**Per-post todos (apply to all 12):**

- [ ] Owner: Nick | Deadline: T-1 day 17:00 | Effort: 30min | Deps: adaptation exists | Evidence: LinkedIn queue entry visible in `linkedin-queue.json`
- [ ] Owner: Nick | Deadline: T 09:00 ET | Effort: 15min | Deps: post live | Evidence: live-post screenshot + post URL
- [ ] Owner: Nick | Deadline: T 18:00 ET | Effort: 30-60min | Deps: engagement | Evidence: reply-count log
- [ ] Owner: Nick | Deadline: T+48h | Effort: 15min | Deps: post live | Evidence: dev.to URL with canonical tag

**One-time (Week 9):**

- [ ] Owner: Nick | Deadline: Fri Jun 19 17:00 | Effort: 2h | Deps: 7 weeks of metrics | Evidence: `wrap-post-week-10-final.md` with all 24 placeholders filled (grep `{` returns 0)
- [ ] Owner: Nick | Deadline: Tue Jun 23 12:00 | Effort: 30min | Deps: scaffold fill | Evidence: sign-off line present (`grep "Nick Krzemienski —" wrap-post-week-10-final.md`)

## 9. Success Criteria

- 12/12 blog-series posts published on schedule.
- 10/10 companion repos polished by deadline with verified commit + badge + homepage + topics.
- All 6 weekly gates logged with verdict.
- HN submissions: Posts 2, 5, 6, 9, 8, 11 — 6 attempts; ≥1 front page.
- Dev.to cross-posts: 12/12 with canonical URL pointing to personal blog.
- Wrap-post published Thu Jun 25 with real metrics, sign-off, 0 placeholders.
- Per-post star-attribution log for all 12 posts.
- 10-week cumulative KPIs tracked against master-calendar Success Metrics table (stars, followers, impressions, DMs, engagements-closed).

## 10. Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Repo-prep slips on heaviest repo (code-tales, 45min install-verify) | M | H | Start code-tales polish Wed May 27 instead of Mon Jun 1 deadline (1-week buffer); test install on a fresh mac |
| Source blog-series files further diverge from adaptations | L | M | Lock rule: Phase 5 does NOT re-sync from source; adaptations are authoritative |
| v0.1.0 release tag blocks auto-claude-worktrees polish | M | M | Tag Tue May 27 (day before Wed May 28 soft deadline) with copy-paste install in release notes |
| HN Show HN #2 (Code Tales Tue Jun 9) burns second-chance credibility | M | H | Per Week-10 wrap scaffold risk note: pre-launch HN appetite check via 2-person ask before submitting; if lukewarm, defer |
| Multiple Mondays in a row miss if publisher/cron fails | L | H | Manual-fallback doc from Phase 2 always available; weekly Sun check verifies cron fired last 2 Mondays |
| Week 9 wrap-post fill produces numbers that contradict Wave 1 rollup | L | M | Scaffold data-source table specifies source-of-truth per placeholder; reconcile Week 9 Monday |
| stitch-design-to-code repo can't embed screenshots due to size | L | L | Use GitHub Issues as image CDN or externalize to `screenshots/` dir |
| ralph-orchestrator-guide configs not runnable on fresh machine | M | M | Fresh-machine test Mon Jun 9 (3 days pre-deadline); fix configs if broken |
| Post 11 capstone "Built On" section missing cross-links | M | H | Build section during repo-prep on Sat Jun 13 (2 days before polish deadline Mon Jun 15) |
| Campaign fatigue — Nick burnout Week 8/9 | M | M | Weekly Sunday gate explicitly checks "author capacity"; can trigger red-gate pause if energy low |

## 11. Security Considerations

- All repo-prep commits are public README + config changes. No secrets.
- v0.1.0 / v1.0.0 release tags don't include binaries; source-only release notes.
- LinkedIn publisher tokens (Phase 2) auto-refresh; 60-day access token lifetime covers through end of campaign (expires ≈ mid-June if first auth was Sat Apr 18; refresh fires automatically via `src/auth.js`).
- Dev.to API key (if automated) stored in `.env.devto` (gitignore); otherwise manual cross-post.
- Product Hunt account credentials separate; 2FA required.
- Blog-series source at `~/Desktop/blog-series/` remains local; not exposed.
- Wrap-post placeholders fill from `tracking/measurement-plan.md` logs — no customer PII, only aggregate metrics.

## 12. Next Steps

- Phase 6 (Post-Launch Retention) begins Sat Jun 28 right after wrap. DM pipeline from Phases 4-5 feeds Phase 6 triage protocol.
- Sun May 31 (end W7) decision point: extend to Posts 12-18 (W11-W13) OR conclude at Post 11.
- V1.5 CONSENSUS engine prep begins in Phase 6 regardless of extension decision.

## 13. Functional Validation

- **Per-repo prep evidence:** for each of 10 repos, `reports/wave-3/repo-prep-{repo}.md` contains: (1) commit SHA for refresh, (2) `gh api repos/krzemienski/{repo} --jq '.pushed_at'` within 7 days of send date, (3) badge present (`grep -c "Featured in" README.md` ≥ 1), (4) homepageUrl set (`gh api repos/.../{repo} --jq '.homepage'` non-null), (5) topics list (`gh api repos/krzemienski/{repo}/topics`).
- **Per-post publish evidence:** `reports/wave-3/post-{NN}-live.png` screenshot of LinkedIn post; URL returns HTTP 200.
- **Cross-post evidence:** `reports/wave-3/cross-posts.md` table with 12 dev.to URLs, 6 HN submission URLs (Posts 2/5/6/9/8/11), 3 Reddit URLs.
- **Attribution evidence:** `reports/wave-3/post-{NN}-attribution.md` for each of 12 posts with 72h star delta + referrer mix (GitHub Insights → Traffic).
- **Wrap-post evidence:** `grep -cP '\{[A-Z_]+\}' copy/wrap-post-week-10-final.md` returns 0 before Thu Jun 25 08:00 ET. Sign-off line present. Tone matches week3-reflection (spot-check against file).
- **Weekly gate evidence:** 6 `weekly-gate-*.md` files (one per week) each with verdict + metrics table.
- **10-week KPI evidence:** `reports/wave-3/10-week-kpi-rollup.md` with each metric in master calendar §Success Metrics compared against Floor/Target/Stretch with verdict column.
- **Phase complete claim:** must cite wrap-post final file + 10-week KPI rollup + 10 repo-prep files + 12 attribution logs. A phase claim without the 10-week KPI rollup is rejected per `evidence-before-completion.md`.
