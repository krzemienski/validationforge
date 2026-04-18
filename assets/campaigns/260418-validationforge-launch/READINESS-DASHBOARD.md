# Pre-Launch Readiness Dashboard — ValidationForge 10-Week Launch

**Audit date:** 2026-04-18 (Day 0 — first scheduled post Mon Apr 20)
**Auditor:** general-purpose subagent
**Scope:** `/Users/nick/Desktop/validationforge/assets/campaigns/260418-validationforge-launch/`

---

## SUMMARY VERDICT: **READY-WITH-RISKS**

The campaign is ready to ship Day 1 (Mon Apr 20 soft-launch). Copy is drafted for **all 8 Weeks 1-4 slots** and adapted for **all 12 Weeks 5-10 slots** (10 blog posts + capstone scaffold + Week-10 wrap scaffold). Voice is consistent. Briefs, calendar, tracking plan, and companion-repo prep checklist are complete and coherent.

The risks are concentrated in three buckets: **(1) zero visual assets exist on disk** — every hero image, GIF, and image-quote in `visual-content-spec.md` is still TBD; only the `capture-terminal.sh` script ships. **(2) All 11 companion repos are unpolished** — zero topic tags, dormant commits, no homepage URLs, no badges. None blocks Day 1 (Mon Apr 20 only references the VF repo) but the first blog-series post (Mon May 18) needs `multi-agent-consensus` polished by Mon May 11. **(3) Five user-input decisions remain open** — publishing domain, newsletter platform, coupled-vs-decoupled brand, master/main branch standardization, blog-site MDX vs MD format.

Day 1 itself is unblocked: the soft-launch post is 95 words, references only the existing `vf-demo-hero.gif` filename (which still must be produced), and the only hard dependency is that GIF. Produce the GIF in the next 4 hours and Mon Apr 20 ships clean.

---

## 1. Content Readiness — 20 Calendar Slots

Status legend: **READY** = copy + repo named + asset spec defined; **PARTIAL** = copy drafted but adaptation/asset/data still required; **NOT-STARTED** = no draft.

| # | Date | Slot | LinkedIn copy | X thread | Companion repo | Hero image | Status |
|---|---|---|---|---|---|---|---|
| 1 | Mon Apr 20 | VF Soft-Launch | `linkedin-soft-launch-mon-apr20.md` ✅ | `x-threads.md → D3` ✅ | validationforge ✅ | `vf-demo-hero.gif` TBD | **PARTIAL** (asset) |
| 2 | Wed Apr 22 | VF Long-Form Part 1 (validation gap) | `linkedin-blog-series.md → Part 1` ✅ | `x-threads.md` (8-tweet) ✅ | validationforge ✅ | `linkedin-part-1-hero.png` TBD | **PARTIAL** (asset) |
| 3 | Sat Apr 25 | VF Long-Form Part 2 (mid-sprint) | `linkedin-blog-series.md → Part 2` ✅ | included in `x-threads.md` ✅ | validationforge ✅ | `linkedin-part-2-hero.png` TBD | **PARTIAL** (asset) |
| 4 | Wed Apr 29 | Personal-Brand Hero | `personal-brand-launch-post.md` ✅ (2,990w) | `x-thread-launch-hero.md` ✅ | validationforge ✅ | `personal-brand-launch-hero.png` TBD + 3 inline + headshot | **PARTIAL** (asset) |
| 5 | Thu Apr 30 | VF Long-Form Part 3 (retro) | `linkedin-blog-series.md → Part 3` ✅ | included in `x-threads.md` ✅ | validationforge ✅ | `linkedin-part-3-hero.png` TBD + optional 90s video | **PARTIAL** (asset + post-launch numbers) |
| 6 | Mon May 4 | Honest Retrospective | `linkedin-week3-reflection.md` ✅ (1,398w) | none specified | validationforge ✅ | TBD | **PARTIAL** (asset + real numbers) |
| 7 | Thu May 7 | 50-line Hook Deep-Dive | `linkedin-week3-deepdive-no-mock-hook.md` ✅ (1,614w) | excerpt thread (not drafted) | validationforge ✅ | TBD | **PARTIAL** (X thread + asset) |
| 8 | Mon May 12 | 5 Questions Magnet | `linkedin-week4-five-questions.md` ✅ (2,657w) | 5-tweet (not drafted) | validationforge ✅ | TBD | **PARTIAL** (X thread + asset) |
| 9 | Thu May 15 | EBS Patterns Spotlight | `linkedin-week4-spotlight.md` ✅ (1,179w) | none specified | validationforge ✅ | TBD | **PARTIAL** (asset) |
| 10 | Mon May 18 | Post 2: Three Agents P2 Bug | `blog-series-adapted/post-02-linkedin.md` ✅ | `post-02-x-thread.md` ✅ | multi-agent-consensus ✅ | inherit `~/Desktop/blog-series/posts/post-02*/assets/stitch-hero.png` | **READY** (pending repo polish by May 11) |
| 11 | Thu May 21 | Post 3: Banned Unit Tests | `post-03-linkedin.md` ✅ | `post-03-x-thread.md` ✅ | functional-validation-framework ✅ | inherit `post-03/assets/stitch-hero.png` | **READY** (pending repo polish by May 14) |
| 12 | Mon May 26 | Post 1: Series Overview | `post-01-linkedin.md` ✅ | `post-01-x-thread.md` ✅ | agentic-development-guide ✅ | inherit `post-01/assets/stitch-hero.png` | **READY** (pending repo polish by May 19) |
| 13 | Thu May 29 | Post 7: 7-Layer Prompt Stack | `post-07-linkedin.md` ✅ | `post-07-x-thread.md` ✅ | claude-prompt-stack ✅ | inherit `post-07/assets/stitch-hero.png` | **READY** (pending repo polish by May 22) |
| 14 | Mon Jun 1 | Post 5: 5 Layers to Call API | `post-05-linkedin.md` ✅ | `post-05-x-thread.md` ✅ | claude-sdk-bridge ✅ | inherit `post-05/assets/stitch-hero.png` | **READY** (pending repo polish + desc rewrite by May 25) |
| 15 | Thu Jun 4 | Post 6: 194 Worktrees | `post-06-linkedin.md` ✅ | `post-06-x-thread.md` ✅ | auto-claude-worktrees ✅ | inherit `post-06/assets/stitch-hero.png` | **READY** (pending repo polish + v0.1.0 by May 28) |
| 16 | Mon Jun 8 | Post 9: Code Tales | `post-09-linkedin.md` ✅ | `post-09-x-thread.md` ✅ | code-tales ✅ | inherit `post-09/assets/stitch-hero.png` | **READY** (pending repo polish + install verify by Jun 1) |
| 17 | Thu Jun 11 | Post 4: iOS SSE Bridge | `post-04-linkedin.md` ✅ | `post-04-x-thread.md` ✅ | claude-ios-streaming-bridge ✅ | inherit `post-04/assets/stitch-hero.png` | **READY** (pending repo polish + Swift build verify by Jun 4) |
| 18 | Mon Jun 15 | Post 10: 21 Screens Zero Figma | `post-10-linkedin.md` ✅ | `post-10-x-thread.md` ✅ | stitch-design-to-code ✅ | inherit `post-10/assets/stitch-hero.png` | **READY** (pending repo polish + screenshots by Jun 8) |
| 19 | Thu Jun 18 | Post 8: Ralph Orchestrator | `post-08-linkedin.md` ✅ | `post-08-x-thread.md` ✅ | ralph-orchestrator-guide ✅ | inherit `post-08/assets/stitch-hero.png` | **READY** (pending repo polish + desc rewrite by Jun 11) |
| 20a | Mon Jun 22 | Post 11: AI Dev OS Capstone | `post-11-linkedin.md` ✅ | `post-11-x-thread.md` ✅ | ai-dev-operating-system ✅ (calendar lists this; audit notes the repo *does* exist with 1 star) | inherit `post-11/assets/stitch-hero.png` | **READY** (pending repo polish + v1.0.0 by Jun 15) |
| 20b | Thu Jun 25 | 10-Week Wrap | `wrap-post-week-10-scaffold.md` ✅ (SCAFFOLD only) | none drafted | meta — references all 11 | screenshot of consolidated tracking dashboard | **PARTIAL** (24 placeholders to fill Week 9 + X thread + asset) |

**Summary:** 11 READY (Weeks 5-10 blog adaptations) + 9 PARTIAL (all Weeks 1-4 + Week 10 wrap) + 0 NOT-STARTED. Calendar lists 20 slots; 21 are tracked above because Mon Jun 22 + Thu Jun 25 are both Week 10 slots.

**Calendar drift note:** Master calendar (line 141) names companion repo `ai-dev-operating-system` for Post 11. Earlier in the same calendar (line 55) and the audit report use the same name — the audit confirms the repo exists at 1 star. Treating as resolved.

---

## 2. Visual Asset Readiness — Top 5 Critical

Per `visual-content-spec.md → Production Priority`, these three are the explicit "make first" priorities; #4 and #5 are the highest-leverage per-post heroes for Day 1-12 posts.

| # | Asset | Spec | Exists on disk? | Production path | Est. time |
|---|---|---|:--:|---|---|
| 1 | `vf-demo-hero.gif` | 800×450, 10-15s loop, real `/validate` run, no music/text | **NO** | `creatives/scripts/capture-terminal.sh` exists; need to record actual `/validate` session via asciinema → `agg` or QuickTime → ffmpeg | **2-3 hr** (record + iterate to <8MB) |
| 2 | `personal-brand-launch-hero.png` | 1200×627, terminal showing "Verdict: PASS — 6/6 journeys, 13/13 criteria, 0 fix attempts" in green | **NO** | Run VF self-validation in terminal at 14pt JetBrains Mono on `#0a0a0a` bg; Cmd+Shift+4 capture; save to `creatives/screenshots/` | **30 min** (assuming self-validation already runs cleanly) |
| 3 | `compilation-isnt-validation.png` | 1600×900 image-quote, JetBrains Mono Bold 96pt white on `#0a0a0a` | **NO** | Figma/Sketch — single text canvas; export PNG | **20 min** |
| 4 | `linkedin-part-1-hero.png` (Wed Apr 22) | 1200×627, bug-category header rendered as terminal output | **NO** | Same workflow as #2 — terminal screenshot | **30 min** |
| 5 | `linkedin-part-3-hero.png` (Thu Apr 30) | 1200×627, final scoreboard table as terminal output | **NO** | Same workflow as #2 — needs real launch numbers, so finalize Apr 29-30 | **30 min** (Day 12 only; can defer) |

**Per-asset table — ALL visual assets named in spec:**

| Asset path | Status | Blocks |
|---|:--:|---|
| `creatives/gifs/vf-demo-hero.gif` | **MISSING** | Day 1 (Mon Apr 20) — referenced by soft-launch + every Discord/Reddit/X T1 |
| `creatives/gifs/vf-validate-pass.gif` | MISSING | nice-to-have only |
| `creatives/screenshots/personal-brand-launch-hero.png` | MISSING | Day 12 (Wed Apr 29) |
| `creatives/screenshots/personal-brand-launch-evidence-curl.png` | MISSING | Day 12 inline #1 |
| `creatives/screenshots/personal-brand-launch-evidence-tree.png` | MISSING | Day 12 inline #2 |
| `creatives/screenshots/linkedin-part-1-hero.png` | MISSING | Day 5 (Wed Apr 22) |
| `creatives/screenshots/linkedin-part-2-hero.png` | MISSING | Day 8 (Sat Apr 25) |
| `creatives/screenshots/linkedin-part-3-hero.png` | MISSING | Day 13 (Thu Apr 30) |
| `creatives/screenshots/x-d3-pattern-{1-5}-*.png` | MISSING | D3 X big thread (Day 3) |
| `creatives/image-quotes/compilation-isnt-validation.png` | MISSING | X T4 Day 12 |
| `creatives/image-quotes/pass-without-citation.png` | MISSING | nice-to-have |
| `creatives/image-quotes/receipts-over-rhetoric.png` | MISSING | nice-to-have |
| Weeks 5-10 hero PNGs | INHERITABLE from `~/Desktop/blog-series/posts/post-NN/assets/stitch-hero.png` per master calendar §Step 4 — verify on disk before Week 5 | not blocking Day 1-30 |

**Total Day-1-blocking visual production: ~1 GIF, est. 2-3 hours.** Everything else can be produced rolling.

---

## 3. Voice + Framework Consistency Check — 3 Sampled Files

Sampled per task spec: one VF/personal-brand post, one early blog-series adaptation, one Week-10 capstone.

### File 1: `copy/personal-brand-launch-post.md` (Wed Apr 29 hero)

| Check | Result | Evidence |
|---|:--:|---|
| Voice matches creative-brief (no forbidden buzzwords, no emojis) | PASS | grep finds zero emojis; no "game-changer/revolutionary/next-gen/fast-paced/AI-powered" |
| Hook lands in first 210 chars | PASS | "Over the last six weeks I ran 23,479 coding sessions through Claude Code, distributed across 27 production-track projects." (167 chars before period) |
| Bridge sentence to ValidationForge | PASS | Title + body explicitly position the post as VF launch announcement |
| Soft consulting CTA at bottom matches `personal-brand-launch-post.md` pattern | PASS (this *is* the canonical pattern) — 3 engagement archetypes named, "LinkedIn DM with one-paragraph note", "respond within two business days" |
| Standard sign-off line | PASS | Line 120 — italicized, name + credibility numbers + repo URL |
| Companion repo referenced correctly | PASS | `github.com/krzemienski/validationforge` lines 65 + 120 |

**Verdict: PASS.** This file is the voice template against which others are measured.

### File 2: `copy/blog-series-adapted/post-02-linkedin.md` (Mon May 18 — first blog-series slot)

| Check | Result | Evidence |
|---|:--:|---|
| Voice matches creative-brief | PASS | "No emojis" called out in voice notes; grep clean |
| Hook lands in first 210 chars | PASS | "A single AI agent reviewed my iOS streaming code and said 'looks correct.' Three agents found a P2 bug on line 926..." (~180 chars) |
| Bridge sentence to ValidationForge | PASS | Line 145: "This consensus framework was built during the same 90-day stretch that produced ValidationForge — the no-mock validation platform that captures the evidence side of the same problem (github.com/krzemienski/validationforge for that one)." Exactly the calendar-prescribed bridge pattern |
| Soft consulting CTA matches pattern | PASS | Line 147: "I am taking on a small number of advisory engagements this quarter ... send me a LinkedIn DM with a one-paragraph note ... will respond within two business days" — mirrors hero post |
| Standard sign-off | PASS | Line 153 italicized |
| Companion repo referenced | PASS | `github.com/krzemienski/multi-agent-consensus` lines 7, 143, 153 + cross-link to validationforge line 145 |

**Verdict: PASS.** Cleanest voice match across the blog-series adaptations.

### File 3: `copy/wrap-post-week-10-scaffold.md` (Thu Jun 25 — capstone)

| Check | Result | Evidence |
|---|:--:|---|
| Voice matches creative-brief | PASS (in scaffold form) | Voice notes explicit: "Honest retrospective. Match `linkedin-week3-reflection.md`. NOT celebratory." |
| Hook lands in first 210 chars | WARN | First sentence depends on `{CREDIBILITY_METRIC_PLACEHOLDER}` — current scaffold reads OK in skeleton form but final hook needs a specific defensible number; risk that the placeholder gets filled with a vanity metric and bloats the hook past 210 chars |
| Bridge sentence to ValidationForge | PASS | Explicitly ties VF launch (Wks 1-2), personal-brand (Wks 3-4), blog series (Wks 5-10) as one 10-week arc |
| Soft consulting CTA | PASS | Q3 capacity callout near end with same DM/two-business-day pattern |
| Standard sign-off | WARN | Scaffold ends with engagement notes + placeholder appendix; **no italicized "Nick Krzemienski — ..." sign-off line is in the file**. Add at fill-in-Week-9 step |
| Companion repo referenced | PASS | References "all 11 companion repos" + names VF as the spine |
| 24 placeholders documented | PASS | Explicit data-source mapping table at bottom — Week 9 fill protocol is well-specified |

**Verdict: PASS-with-WARN.** Add sign-off line to scaffold checklist; verify `{CREDIBILITY_METRIC_PLACEHOLDER}` keeps T1-hook under 210 chars.

**Aggregate: 3/3 PASS-band (one with two warnings on the scaffold).** Voice is consistent across the campaign. The voice notes are repeated in every file's frontmatter, which is what makes the consistency hold.

---

## 4. Companion Repo Readiness Summary

**Source:** `companion-repo-audit-report.md` + `companion-repo-prep-checklist.md` (audit date 2026-04-18).

### TL;DR
- 11 of 11 repos exist, public, MIT-licensed, README present. Zero 404s, zero open issues, zero open PRs.
- 0 of 11 have topic tags. 0 of 11 have homepage URLs. 0 releases.
- All 11 will be ≥60 days dormant by their post send dates → all 11 need a refresh commit.
- 2 need description rewrites (`claude-sdk-bridge`, `ralph-orchestrator-guide`).
- Effort: ~6 hours total, batchable across 2-3 evenings, **must be staged in deadline order**.

### Per-Repo Quick Status

| # | Repo | Current state | Tasks remaining | Polish deadline |
|---|---|---|---|---|
| 1 | agentic-development-guide | 0★ · main · 43d dormant · description OK | topics + badge + Related Post + 11-repo list + commit refresh + homepage | **Tue May 19** |
| 2 | multi-agent-consensus | 0★ · master · 48d · description strong | topics + badge + Related Post + commit + homepage + install verify | **Mon May 11 (FIRST)** |
| 3 | functional-validation-framework | 0★ · master · 48d · description strong | topics + badge + Related Post + VF cross-link + commit + homepage + install verify | **Thu May 14** |
| 4 | claude-ios-streaming-bridge | 0★ · master · 48d | topics + badge + Related Post + commit + homepage + Swift build + Python bridge run + optional v0.1.0 | **Thu Jun 4** |
| 5 | claude-sdk-bridge | 0★ · master · 48d · **description WEAK** | description rewrite + topics + badge + Related Post + commit + homepage + build + verify 5 failure cases | **Mon May 25** |
| 6 | auto-claude-worktrees | 0★ · master · 48d | topics + badge + Related Post + commit + homepage + CLI install verify + **v0.1.0 release** + quick-start section | **Thu May 28** |
| 7 | claude-prompt-stack | 0★ · master · 48d · description strong | topics + badge + Related Post + commit + homepage + template-repo button + layer-by-layer copy section | **Thu May 22** |
| 8 | ralph-orchestrator-guide | 0★ · master · 48d · **description WEAK** | description rewrite + topics + badge + Related Post + commit + homepage + verify configs runnable + "What is Ralph?" preamble | **Thu Jun 11** |
| 9 | code-tales | 0★ · master · 48d · description strong | topics + badge + Related Post + commit + homepage + **end-to-end install + audio gen verify** + v0.1.0 + sample mp3 link | **Mon Jun 1** |
| 10 | stitch-design-to-code | 0★ · main · 48d · description strong | topics + badge + Related Post + commit + homepage + **embed 4-6 screenshots** + verify Stitch→Puppeteer flow | **Mon Jun 8** |
| 11 | ai-dev-operating-system | 1★ · master · 48d · description OK (sharpen) | topics + badge + Related Post + commit + homepage + **"Built On" section linking all 10 prior repos** + scaffold install verify + v1.0.0 | **Mon Jun 15** |

### Top 3 Highest-Risk Repos for Blocking Launch

1. **`multi-agent-consensus`** — first blog post (May 18, 10/10 importance) and the first companion repo touched by Weeks 5-10 content. Polish deadline Mon May 11. **Risk:** if this slips, the highest-leverage post of the entire 10-week arc lands on a dormant repo with no topics, no badge, and no homepage. Highest blast radius.
2. **`code-tales`** — Mon Jun 8 Show HN + Product Hunt double-launch. Install path is the heaviest of any repo (clone → install deps → generate one audio story → verify .mp3 plays). 25-min install verify alone, plus tag a v0.1.0. **Risk:** install breaks under HN/PH scrutiny, kills second-launch credibility (already a "second HN attempt — paid the price for not understanding HN's appetite for content products" risk per Week-10 wrap scaffold).
3. **`ai-dev-operating-system`** — capstone (Jun 22). Heaviest README investment (Built On section + 10 cross-links). 60 min effort but cannot be batched with any other repo because it depends on the polish state of all 10 prior repos. **Risk:** sequencing — must be polished AFTER repos 1-10. Realistic execution window is one focused 1-hour block on/around Jun 14.

---

## 5. Tracking + Measurement Plan Readiness

**File:** `tracking/measurement-plan.md` — **COMPLETE for Days 1-14.**

### Coverage check

| Section | Present | Notes |
|---|:--:|---|
| North-Star Metric | YES | 100+ stars by Day 14 |
| Tier 1-4 KPI tables | YES | Outcome / traffic / engagement-quality / per-post |
| UTM schema | YES | Channel-specific `utm_source` map; GitHub caveat called out |
| Daily log template | YES | 11-line block schema (stars, follower deltas, impressions, clones, visitors, issues, PRs, top/worst post, mood, note) |
| Logging cadence | YES | 5pm ET daily, 11pm Day 11 (HN day), Day 14 final rollup |
| Mid-sprint review (Day 7) | YES | Template ready to fill Apr 24 4pm |
| Final rollup template (Day 14) | YES | Verdict tier ladder + 5 learnings + what-to-keep/change |
| Daily Log section | YES (empty, ready to fill) | "*(empty; fill in at 5:00pm ET each day of the campaign)*" |

### Gaps (non-blocking)

- **No Weeks 3-10 daily-log fields specified.** The schema is built for the original 14-day sprint; the master calendar extends to 70 days. The `social-calendar-unified.md → Tracking` section adds Personal-Brand fields, but those have not been merged into `measurement-plan.md`. Risk: Week 5+ logs use ad-hoc fields and consistency erodes by Week 8.
- **No Weekly Log section** referenced by master calendar §"Weekly Measurement Ritual" (every Sunday 5pm ET). The hook is named in the calendar; the destination doesn't exist in `measurement-plan.md`. Add a `## Weekly Log` section before Sun Apr 26.
- **No Repo Attribution section** referenced by calendar §"Companion-Repo Strategy → Post-launch tracking". Same fix — add the section header now so weekly logs have a home.
- **Pivot Log** referenced by calendar §"Black — Full pause" — also missing as a section.

### Verdict

The Day 1-14 schema is **READY**. Pre-Day-15 add three new section headers (Weekly Log / Repo Attribution / Pivot Log) and merge Personal-Brand-track fields. ~15 min edit.

---

## 6. Master Calendar Consistency

Spot-check: every file referenced by `10-week-master-calendar.md` exists?

| Calendar reference | File on disk | Exists? |
|---|---|:--:|
| `copy/linkedin-soft-launch-mon-apr20.md` | yes | YES |
| `copy/linkedin-blog-series.md` (Parts 1/2/3) | yes (single file with 3 parts) | YES |
| `copy/personal-brand-launch-post.md` | yes | YES |
| `copy/x-thread-launch-hero.md` | yes | YES |
| `copy/x-threads.md` | yes | YES |
| `copy/show-hn-drafts.md` | yes | YES |
| `copy/reddit-posts.md` | yes | YES |
| `copy/reddit-r-experienceddevs.md` | yes | YES |
| `copy/discord-announcements.md` | yes | YES |
| `copy/linkedin-week3-reflection.md` | yes | YES |
| `copy/linkedin-week3-deepdive-no-mock-hook.md` | yes | YES |
| `copy/linkedin-week4-five-questions.md` | yes | YES |
| `copy/linkedin-week4-spotlight.md` | yes | YES |
| `copy/blog-series-adapted/post-{01..11}-linkedin.md` | yes | YES (11/11) |
| `copy/blog-series-adapted/post-{01..11}-x-thread.md` | yes | YES (11/11) |
| `copy/wrap-post-week-10-scaffold.md` | yes | YES |
| `creatives/visual-content-spec.md` | yes | YES |
| `creatives/scripts/capture-terminal.sh` | yes | YES |
| `tracking/measurement-plan.md` | yes | YES |
| `briefs/creative-brief.md` | yes | YES |
| `briefs/campaign-brief.md` | yes | YES |
| `execution/14-day-calendar.md` | yes | YES |
| `execution/social-calendar-unified.md` | yes | YES |
| `~/Desktop/blog-series/posts/post-{NN}-{slug}/...` | not verified in this audit | **UNVERIFIED** |

**Verdict:** PASS for everything inside the campaign directory. **One gap:** the calendar relies on inheriting `assets/stitch-hero.png` from `~/Desktop/blog-series/posts/post-NN/...` for Weeks 5-10 hero images. That tree was not audited here. Recommend a 5-minute spot-check before Mon May 11 (multi-agent-consensus polish deadline) to confirm `~/Desktop/blog-series/posts/post-02-multi-agent-consensus/assets/stitch-hero.png` exists at LinkedIn's 1200×627.

**Inconsistency flagged in calendar itself (line 56):** "Posts 12-18" listed as TBD but PUBLISHING-ROADMAP references 18 total posts — already called out in `Open Items #5`.

---

## 7. Open Decisions — Aggregated Decision Queue

Aggregated from `briefs/`, `execution/`, `creatives/`, `copy/`, `blog-site-mdx/CONVERSION-REPORT.md`. Priority: **BLOCK** (cannot ship without it) / **IMPORTANT** (lands within 2 weeks) / **NICE** (3+ weeks out).

| # | Decision | Source | Priority | Lands by |
|---|---|---|:--:|---|
| 1 | Produce `vf-demo-hero.gif` | visual-content-spec.md §Production Priority | **BLOCK** | Mon Apr 20 (Day 0) |
| 2 | Coupled vs decoupled brand strategy (VF + personal brand) | social-calendar-unified.md, master-calendar §Open Items #3 | **BLOCK** | Wed Apr 22 (affects Wks 3-4 framing) |
| 3 | Schedule-post.js automation OR hand-post each | social-calendar-unified.md §Open Items #3 | IMPORTANT | Mon Apr 20 |
| 4 | Founder headshot — current LinkedIn photo or new shoot | visual-content-spec.md §Open Items #2 | IMPORTANT | Wed Apr 29 (Day 12 hero) |
| 5 | 60s talking-head video for LinkedIn Part 3 — produce or skip | visual-content-spec.md §Open Items #4 | IMPORTANT | Thu Apr 30 |
| 6 | Standardize all repos onto `main` (vs accept master/main split) | companion-repo-audit-report §R4 + checklist Q1 | IMPORTANT | ≥10 days before May 18 = Fri May 8 |
| 7 | Publishing domain — `agentic.dev` vs other | master-calendar §Open Items #1 | IMPORTANT | Before Week 5 (Sat May 16) |
| 8 | Newsletter platform (ConvertKit / Buttondown / Substack / form / none) | master-calendar §Open Items #2 | IMPORTANT | Before Week 5 (Sat May 16) |
| 9 | Canonical blog post URLs (needed for "Related Post" sections in repo READMEs) | companion-repo-prep-checklist Q4 | IMPORTANT | Before Mon May 11 (first repo polish deadline) |
| 10 | Weekly Log / Repo Attribution / Pivot Log sections in measurement-plan.md | this audit §5 | IMPORTANT | Before Sun Apr 26 (first weekly review) |
| 11 | Blog-site MDX → MD conversion + posts/<slug>/post.md placement | blog-site-mdx/CONVERSION-REPORT.md Q1 | IMPORTANT | Before Week 5 (or skip blog-site integration entirely) |
| 12 | VF launch posts as separate "VF Launch" mini-series vs append to existing 18-post series | CONVERSION-REPORT.md Q2 | NICE | Before Wks 5 |
| 13 | Tag casing: `AgenticDevelopment` (PascalCase) vs `agentic-development` (kebab-case) | CONVERSION-REPORT.md Q3 | NICE | Before blog-site integration |
| 14 | Add `description` and `hero_image` fields to blog-site frontmatter? | CONVERSION-REPORT.md Q4 | NICE | Before Wk 5 |
| 15 | Shared org-level GitHub Pages site for series, OR per-repo homepageUrl | companion-repo-audit Q2 + checklist Q2 | NICE | Before Mon May 26 (series-overview post) |
| 16 | Cross-repo "See also" links inside each README | companion-repo-audit Q3 | NICE | Rolling per-repo polish |
| 17 | Add `SECURITY.md` / `CODE_OF_CONDUCT.md` to each repo | companion-repo-audit Q4 + checklist Q3 | NICE | YAGNI — defer until traffic justifies |
| 18 | Decoupling re-evaluation at Week 4 check-in | master-calendar §Open Items #3 | NICE | Sun May 10 |
| 19 | Posts 12-18 inclusion + extending campaign past Week 10 | master-calendar §Open Items #5 | NICE | Before Wk 7 (~Sun May 31) |
| 20 | Which LinkedIn adaptations to produce first (recommend Posts 2/3/1) | master-calendar §Open Items #4 | NICE | Already implicitly resolved — all 11 adaptations are now drafted |
| 21 | Auto-capture shell script for terminal screenshots | visual-content-spec §Open Items #1 | NICE | Already done — `creatives/scripts/capture-terminal.sh` exists |
| 22 | Show HN imageless confirmation | visual-content-spec §Open Items #3 | NICE | Confirm before Tue Apr 28 |
| 23 | Replace 🧵 in T1 of x-thread-launch-hero (no-emoji policy) | x-thread-launch-hero.md inline note | IMPORTANT | Before Wed Apr 29 |
| 24 | Wrap-post sign-off line missing from scaffold | this audit §3 | IMPORTANT | Week 9 fill-in pass |

**BLOCK count: 2.** Both must resolve before/on Mon Apr 20.
**IMPORTANT count: 11.** Cluster around Apr 26 → May 16.
**NICE count: 11.**

---

## NEXT 3 ACTIONS (priority-ordered, next 4 hours)

1. **Produce `vf-demo-hero.gif`** (800×450, 10-15s loop, real `/validate` run, no music/text). This is the only Day-1 blocker. Use `creatives/scripts/capture-terminal.sh` + asciinema → `agg`, OR QuickTime → ffmpeg per spec lines 211-218. Save to `creatives/gifs/vf-demo-hero.gif`. Also commit a copy to the VF repo at `demo/vf-demo.gif` (Show HN README dependency for Apr 28). **Est. 2-3 hours.**

2. **Make the coupled-vs-decoupled brand decision** (open item #2). The Wed Apr 22 Part 1 essay and the Wed Apr 29 personal-brand hero pivot on this. Recommendation per master calendar: **coupled** for Weeks 1-4, re-evaluate at Sun May 10 Week-4 check-in. A 5-minute "yes, coupled" confirmation unblocks Wk 3-4 production. **Est. 5 min.**

3. **Add the three missing sections to `tracking/measurement-plan.md`** — Weekly Log, Repo Attribution, Pivot Log — and merge the Personal-Brand fields from `social-calendar-unified.md`. Without this, the first Sunday review (Apr 26) writes into ad-hoc fields and the schema fragments by Week 5. **Est. 15 min.**

After those three, the next priority block is Sun Apr 26 — first weekly review + measurement-plan habit + decision on whether to pre-produce the Day 12 personal-brand hero asset bundle in advance vs. day-of.

---

## Appendix — Verification Checklist

- [x] `READINESS-DASHBOARD.md` exists at `/Users/nick/Desktop/validationforge/assets/campaigns/260418-validationforge-launch/READINESS-DASHBOARD.md`
- [x] All 7 audit sections present (Content / Visual / Voice / Companion-repo / Tracking / Calendar consistency / Open decisions)
- [x] SUMMARY VERDICT visible at top
- [x] NEXT 3 ACTIONS visible at bottom
