# Unified Social Calendar — LinkedIn + X (4-Week Runway)

**Window:** 2026-04-18 → 2026-05-15 (28 days; project sprint Days 1-14, personal-brand runway Days 15-28).
**Channels:** LinkedIn (long-form + reactions) · X/Twitter (threads + drumbeat).
**Voice:** Direct, technical, slightly contrarian. No emojis except as already drafted (sparingly). Receipts > rhetoric.
**Owner:** Nick Krzemienski.

This calendar **does not duplicate** `14-day-calendar.md` (which is project-ops focused). It overlays personal-brand cadence on top, then extends 14 days past launch to keep the personal-brand engine running after the spike.

---

## Asset Inventory (everything you already have to work with)

| File | Type | Channel | Use Case |
|---|---|---|---|
| `copy/x-threads.md` | 14 days of X copy | X | Project launch drumbeat |
| `copy/linkedin-blog-series.md` | 3-part long-form | LinkedIn | Project tactical series |
| `copy/personal-brand-launch-post.md` | 1,500-word essay | LinkedIn + blog | **Hero personal-brand post** |
| `copy/x-thread-launch-hero.md` | 5-tweet thread | X | **Hero personal-brand thread** |
| `copy/show-hn-drafts.md` | 3 HN variants | HN | Show HN spike day |
| `copy/reddit-posts.md` | 3 sub-specific | Reddit | r/ClaudeAI, r/LocalLLaMA, r/programming |
| `copy/discord-announcements.md` | 4 server drops | Discord | Ecosystem priming |

---

## The Two-Track Strategy

**Track A: Project Launch (Days 1-14).**
Tactical, urgent, daily cadence. Goal: 100+ stars on the repo by Day 14. Uses everything in `14-day-calendar.md`.

**Track B: Personal Brand Runway (Days 5-28).**
Strategic, slower, 2-3 posts/week. Goal: position you as the "Evidence-Based Shipping" voice in agentic dev → consulting inbound. Starts mid-sprint (so the personal-brand essay rides on top of project momentum), continues 14 days past launch.

The two tracks reinforce each other: project receipts give the personal-brand essays credibility; personal-brand essays expand the audience that sees the project.

---

## Week 1 — Sat Apr 18 → Fri Apr 24 (Project Priming)

### LinkedIn cadence
- **Mon Apr 20:** Soft-launch (1-paragraph post): "Open-sourced something this weekend. Long writeup coming Wed." Link to repo. ~80 words.
- **Wed Apr 22 — Day 5:** **LinkedIn Part 1 of project series** (`copy/linkedin-blog-series.md → Part 1`). 1,500 words.

### X cadence (extracted from existing 14-day calendar)
- **Daily:** Follow `copy/x-threads.md` exactly — D1 through D7 posts.
- **Mon Apr 20 — Day 3:** Big project thread (8 tweets) + pin to profile.

### Engagement focus
- Reply to every substantive comment on the LinkedIn soft-launch within 24 hr
- Reply to every X thread comment within 1 hr during waking hours
- Read and respond to all r/ClaudeAI comments (Tue Apr 21 drop) for first 4 hr

### Asset gates (must be done by EOD Sun Apr 19)
- [ ] Repo final-polished + README updated
- [ ] Demo GIF embedded in README
- [ ] `e2e-evidence/self-validation/` viewable publicly
- [ ] Personal-brand essay edited in voice

---

## Week 2 — Sat Apr 25 → Fri May 1 (Launch Spike + Personal-Brand Hero)

### LinkedIn cadence
- **Sat Apr 26 — Day 8:** **LinkedIn Part 2** (project mid-sprint lessons). 1,500 words.
- **Wed Apr 29 — Day 12 (Day after Show HN):** **LinkedIn Personal-Brand Hero Post** (`copy/personal-brand-launch-post.md`). 1,438 words. **THIS IS THE BIG ONE.**
  - Why post the day AFTER HN: the HN spike (Day 11) gives you the receipt to cite in the essay ("Show HN landed, here's what 24h taught me about agentic-dev verification at scale"). The essay reframes the launch into authority territory.
  - Add a closing line referencing actual HN points before publishing.
- **Thu Apr 30 — Day 13:** **LinkedIn Part 3** of project series (results retrospective). 1,500 words.

### X cadence
- **Tue Apr 28 — Day 11:** Show HN spike day. Use `copy/x-threads.md → D11` posts for HN amplification.
- **Wed Apr 29:** **Personal-Brand 5-Tweet Thread** (`copy/x-thread-launch-hero.md`). Post immediately after the LinkedIn hero post is live (sequence: LinkedIn first → wait 30 min → X thread linking back to it).
- **Thu Apr 30 — Day 13:** Big retrospective thread.
- **Daily:** Follow `copy/x-threads.md` D8-D14.

### Reddit cadence (NEW — fills gap)
- **Tue Apr 28:** AFTER HN front-page (or 4 hours into HN engagement), drop on r/ExperiencedDevs with a different angle: "Engineering leadership perspective on Evidence-Based Shipping for AI-assisted dev." Less polemic than r/programming, more thoughtful audience. *(I haven't drafted this — see Gaps section below.)*

### Engagement focus
- **Day 11 (HN):** Cancel everything else. 4-6 hour HN engagement window minimum.
- **Day 12 (LinkedIn hero):** Personal-brand essay needs sustained engagement — every comment for 48 hours, not 24.
- **Day 13 retro:** Quote-tweet your own week's wins from project receipts.

---

## Week 3 — Sat May 2 → Fri May 8 (Personal-Brand Runway Begins)

The project sprint is over. Stars target either hit or missed. Now is when most launches die. **This is when personal brand work matters most** — the audience you earned during launch needs reasons to keep following.

### LinkedIn cadence
- **Mon May 4:** *Reflection post* — "What didn't work in the ValidationForge launch (real numbers, real misses)." 800 words. Honest retrospective. This earns more credibility than the win-laps usually do.
- **Thu May 7:** *Technical deep-dive #1* — "How the no-mock hook actually works (50 lines of JavaScript, with annotated source)." 1,200 words. Shows the work. Positions you as the implementation-detail person, not the abstract-principle person.

### X cadence
- **Tue May 5:** Quote-tweet a bug pattern someone DM'd you during launch with their permission. Format: "A reader sent me this last week. It's the [Nth] real-world example of mock drift we've now collected." Single tweet.
- **Wed May 6:** Mid-week receipt thread — run `/validate` against a public OSS repo, post the verdict. (Use `copy/x-threads.md` D6-pm format as template.)
- **Fri May 8:** Friday afternoon micro-post. "Three sentences I keep coming back to from this week's DMs about agentic-dev verification." Casual. Under 280 chars.

### Engagement focus
- DMs from launch should be triaged this week. Anyone substantive about consulting or implementation gets a real reply, not a template.

---

## Week 4 — Sat May 9 → Fri May 15 (Authority Cementing)

### LinkedIn cadence
- **Mon May 12:** *Strategic post* — "5 questions every engineering leader should ask before adopting agentic dev." 1,000 words. Frames you as advisor-level, not implementer-only. **This is the post that drives consulting DMs.**
- **Thu May 15:** *Community spotlight* — "Three projects I've seen do Evidence-Based Shipping right." 800 words. Names 2-3 OSS projects (with their permission ideally). Positions you as the connector and category-definer, not just the tool author.

### X cadence
- **Mon May 12:** Excerpt the LinkedIn post into a 5-tweet thread (don't link to LinkedIn until reply chain).
- **Wed May 14:** Single tweet — "Things I'm seeing across teams adopting agentic dev." Listicle format, 4-5 short lines. Designed for high reshare.
- **Fri May 15:** Soft consulting nudge. "Booked the second Q2 advisory engagement this week. One slot left for May. DM if you want to chat." Direct but not desperate.

### Engagement focus
- Consulting DMs should be triaged within 4 hours during business hours
- Every reasonable inquiry gets a 30-min discovery call offer

---

## Per-Platform Posting Discipline

### LinkedIn
| Rule | Detail |
|---|---|
| Best send time | Tue/Wed/Thu 8-10am ET (engineering leadership audience) |
| Max post length | LinkedIn truncates at ~210 chars before "see more" — first 2 sentences MUST hook |
| Hashtags | 3-5 max (`#AgenticDev #AICodingTools #SoftwareEngineering`). Stop using `#Innovation` `#TechLeadership` — they signal influencer-cringe |
| Tagging | Don't tag people unsolicited. Accept incoming tags from amplifiers |
| Carousel format | Skip for this campaign — text posts perform better in dev/eng leadership audience |
| Crosspost | Personal blog gets canonical rel=canonical pointing to itself, not to LinkedIn |
| Reply protocol | Every substantive comment within 24h on hero posts; within 4h on launch-day posts |

### X / Twitter
| Rule | Detail |
|---|---|
| Best send time | Mon-Fri 9am, 1pm, 7:30pm ET |
| Char limit | 280 (URLs count as 23 regardless of length) |
| Hashtags | 0-1 max. `#ClaudeCode` only when directly relevant. Stop after one |
| Threading | Reply-in-sequence to your own first tweet. Number tweets 1/N · 2/N if more than 3 |
| Pinning | Pin the highest-engagement thread of the week. Rotate weekly |
| Reply protocol | First 2 hours after posting are critical. Reply within 10 min during this window |
| Quote-tweet | Quote-tweet skeptics WITH evidence (file path, screenshot). Never with rhetoric |

---

## Content Gaps Worth Filling (not yet drafted)

These would round out the calendar above. Drafting any of them is a 10-15 min request.

1. **`copy/linkedin-soft-launch-mon-apr20.md`** — 80-word LinkedIn announcement post for Mon Apr 20 ("Open-sourced something this weekend, long writeup coming Wed").
2. **`copy/reddit-r-experienceddevs.md`** — leadership-angle Reddit post for r/ExperiencedDevs (Tue Apr 28).
3. **`copy/linkedin-week3-reflection.md`** — Week 3 honest retrospective post ("What didn't work in the launch").
4. **`copy/linkedin-week3-deepdive-no-mock-hook.md`** — Week 3 technical deep-dive on the 50-line PreToolUse hook with annotated source.
5. **`copy/linkedin-week4-five-questions.md`** — Week 4 strategic post ("5 questions every engineering leader should ask before adopting agentic dev"). **This is the highest-leverage one for consulting inbound.**
6. **`copy/linkedin-week4-spotlight.md`** — Week 4 community spotlight post.

Reply with the number(s) you want me to draft and I'll knock them out.

---

## Personal-Brand vs Project-Brand Voice Calibration

Both come from the same person, but the framing differs:

| Lever | Project posts (VF specifically) | Personal-brand posts (you, Nick) |
|---|---|---|
| Subject | "ValidationForge does X" | "I've learned that X. The tool I shipped to address it is Y" |
| Authority signal | "Self-validated 6/6 PASS" | "23,479 sessions, 3.4M lines, 27 projects" |
| CTA primary | Repo install command | Repo + DM (consulting) |
| Tone | Punchy, demo-driven | Reflective, opinionated, advisory |
| Word count | 280 (X) or 1,500 tactical (LinkedIn) | 1,500-2,000 (LinkedIn) or 5-tweet thread (X) |
| Risk | Sounds salesy | Sounds preachy |
| Mitigation | Receipts | Receipts (same lever) |

**Universal rule for both tracks:** every claim cites evidence. The receipts are what let you say strong things without being salesy or preachy.

---

## Tracking & Reporting

Daily metrics log lives in `tracking/measurement-plan.md`. Add these new fields specific to this calendar:

```
### Day {N} — Personal Brand Track Status
- LinkedIn personal-brand impressions (cumulative): {N}
- LinkedIn personal-brand follower delta: {Δ}
- Consulting DMs received (week-to-date): {N}
- Consulting discovery calls booked: {N}
- Top engaging personal-brand post this week: {url} ({metric})
```

Report rollup every Sunday evening. Adjust the next week's calendar based on what's working.

---

## Decision: Should the Project Brand and Personal Brand Be Coupled or Decoupled?

**Coupled (current default):** personal-brand essays explicitly mention VF; project posts are signed by you. Synergy: launch attention drives personal-brand growth; personal-brand audience drives later VF retention.
**Risk:** when VF gets criticism, it lands on you personally.

**Decoupled (alternative):** personal-brand essays talk about agentic-dev principles broadly; VF gets mentioned only as one implementation. Personal brand can outgrow VF.
**Cost:** lose ~30% of cross-pollination value during launch window.

This calendar is built for **coupled**. If you decide to decouple, the Week 4 posts are the natural transition point — at that stage, personal-brand authority is established enough to stand alone, and the calendar can pivot to "I write about agentic dev in general; here's one tool I built among many" framing.

---

## Open Items

1. **Pick which gaps to fill first** (numbered list above) — recommend #1 (Mon Apr 20 soft-launch, needed in 2 days) and #5 (Week 4 strategic post, highest consulting-inbound leverage).
2. **Confirm coupled vs decoupled brand strategy** — affects all Week 3-4 copy.
3. **Decide whether to invoke `scripts/schedule-post.js`** to actually queue these posts via API (requires platform API credentials in `~/.claude/.env`), or hand-post each.
4. **Review `tracking/measurement-plan.md`** for whether the new personal-brand metrics fields should be added to the existing template or kept separate.
