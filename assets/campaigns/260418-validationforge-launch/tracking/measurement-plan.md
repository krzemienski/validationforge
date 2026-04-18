# Measurement Plan: ValidationForge Launch

## North-Star Metric

**100+ GitHub stars on `github.com/krzemienski/validationforge` by end of Day 14 (2026-05-01 23:59 ET).**

Everything else is a supporting or diagnostic metric.

---

## KPI Framework

### Tier 1 — Outcome metrics (what we're judged on)

| Metric | Target | Floor | Stretch | Source |
|---|---|---|---|---|
| GitHub stars | 100 | 50 | 250 | github.com/krzemienski/validationforge (star count in header) |
| HN points (Show HN) | 50 (front page) | 20 | 200+ | news.ycombinator.com item page |
| Plugin marketplace installs | 25 | 10 | 75 | Claude Code marketplace telemetry (if visible) |
| Ecosystem endorsement | 1 mention from OMC/Superpowers/Anthropic devrel | 0 | 3+ | manual search, X mentions |

### Tier 2 — Traffic metrics (leading indicators)

| Metric | Target | Source |
|---|---|---|
| GitHub unique cloners (14-day) | 30+ | GitHub → Insights → Traffic → Clones |
| GitHub unique visitors (14-day) | 500+ | GitHub → Insights → Traffic → Visitors |
| X cumulative impressions (14-day) | 250,000 | X Analytics (export CSV) |
| X follower delta | +200 | X Analytics |
| LinkedIn cumulative impressions | 5,000 across all 3 parts | LinkedIn native analytics |
| Reddit top-post upvotes | 100+ on at least one post | Reddit post page |
| Discord mentions (ecosystem servers) | 50+ | manual scan; search "validationforge" in each server |

### Tier 3 — Engagement quality metrics (the signal behind the noise)

| Metric | Target | Source |
|---|---|---|
| X thread reply ratio on D3 big thread | ≥1 reply per 5 likes | X Analytics |
| HN comments (substantive) | 20+ | HN thread |
| GitHub issues opened by non-Nick | 3+ | github.com/krzemienski/validationforge/issues |
| GitHub external PRs | 1+ | github.com/krzemienski/validationforge/pulls |
| Unsolicited "I'm using VF" posts from strangers | 3+ | X search, Reddit search, GitHub backlinks |

### Tier 4 — Content-specific metrics (per-post diagnostics)

| Post | Metric | Target |
|---|---|---|
| D3 big X thread | impressions | 50,000+ |
| D3 big X thread | quote-tweets | 15+ |
| r/ClaudeAI post | upvotes | 100+ |
| r/ClaudeAI post | comments | 30+ |
| r/LocalLLaMA post | upvotes | 50+ |
| r/programming post | upvotes | 30+ (hostile sub; floor) |
| LinkedIn Part 1 | impressions | 2,000+ |
| LinkedIn Part 2 | impressions | 1,500+ |
| LinkedIn Part 3 | impressions | 2,500+ |
| Show HN | time on front page | ≥4 hrs |

---

## UTM Schema

### Convention

All external links that go to a non-GitHub destination (blog posts, landing page if created, documentation site) use:

```
?utm_source={channel}&utm_medium=organic&utm_campaign=launch-260418
```

### Channel values

| Channel | `utm_source` |
|---|---|
| X / Twitter | `x` |
| Hacker News | `hn` |
| Reddit — r/ClaudeAI | `reddit-claudeai` |
| Reddit — r/LocalLLaMA | `reddit-localllama` |
| Reddit — r/programming | `reddit-programming` |
| LinkedIn | `linkedin` |
| Discord — Anthropic | `discord-anthropic` |
| Discord — OMC | `discord-omc` |
| Discord — Superpowers | `discord-superpowers` |
| Discord — plugin-dev | `discord-plugindev` |

### Notes on GitHub

GitHub does **not** preserve UTM parameters on star/clone events. UTMs still matter for:
- Any landing page linked from X/Reddit/LinkedIn
- Docs site links (if created)
- Blog post destinations (cross-hosted)

For GitHub traffic specifically, attribution is inferred from the **Referrers** panel in GitHub Insights → Traffic.

---

## Daily Metrics Log Protocol

### Log format (one block per day, appended to bottom of this file)

```
### Day {N} — {YYYY-MM-DD} — {DAY-OF-WEEK}

Stars: {count} (Δ +{delta})
X followers: {count} (Δ +{delta})
X impressions today: {count}
LinkedIn impressions today: {count}
GitHub clones today: {count}
GitHub visitors today: {count}
New issues: {count}
New PRs: {count}
Top post of the day: {channel} — {one-line summary} — {top metric}
Worst post of the day: {channel} — {one-line summary} — {why}
Mood: {one word: great / steady / soft / concerning}
Note: {one sentence worth remembering}
```

### When to log

- Daily at 5:00pm ET, before dinner
- Extended log on Day 11 (HN day) at 11:00pm with full numbers
- Final rollup on Day 14 afternoon → export to `tracking/final-numbers.csv`

---

## Mid-Sprint Review — Day 7 (Thu Apr 24)

**Required output:** fill in the section below at Day 7 4:00pm.

### Day 7 Status
- Stars so far: ___ / target-by-Day-14 = 100
- Projected Day 14 stars (current × 2): ___
- On track? (Y/N): ___

### Signal analysis
- Highest-engagement channel: ___
- Lowest-engagement channel: ___
- Highest-engagement content format: ___
- Lowest-engagement content format: ___

### Decisions for Wave 3-5
- [ ] Continue as planned
- [ ] Double down on: ___
- [ ] De-prioritize: ___
- [ ] Swap HN title variant to: (A/B/C) ___ because ___
- [ ] Shift OSS demo emphasis: ___

---

## Final Rollup Template — Day 14 (Fri May 1)

**Required output:** fill in at Day 14 afternoon → save to `reports/260501-launch-retrospective.md`.

### Final numbers

| Metric | Target | Actual | Δ |
|---|---|---|---|
| GitHub stars | 100 | ___ | ___ |
| HN points | 50+ | ___ | ___ |
| Marketplace installs | 25 | ___ | ___ |
| X impressions cumulative | 250K | ___ | ___ |
| X follower delta | +200 | ___ | ___ |
| LinkedIn impressions cumulative | 5K | ___ | ___ |
| Reddit top-post upvotes | 100+ | ___ | ___ |
| Ecosystem mentions | 1+ | ___ | ___ |

### Verdict tier
- [ ] Stretch (250+ stars + HN top-10 + ecosystem signal-boost)
- [ ] Win (100+ stars + HN front page + OMC/Superpowers mention)
- [ ] Floor (50+ stars + 3+ unsolicited mentions)
- [ ] Below floor (pause-and-reframe triggered? what we learned)

### Top-5 learnings (non-negotiable; write honestly)
1.
2.
3.
4.
5.

### What to do differently next launch
1.
2.
3.

### What to keep
1.
2.
3.

---

## Daily Log (append below — one block per day)

*(empty; fill in at 5:00pm ET each day of the campaign)*

---

## Appendix — What we are NOT measuring (and why)

- **Revenue / conversions** — VF is free and open source; no revenue funnel this sprint
- **CSAT / NPS** — launch sprint is too short for reliable satisfaction data
- **SEO rank** — organic-search is a 3-6 month game, not a 14-day one
- **Email list growth** — we are not running an email capture this sprint (by design)
- **"Brand sentiment"** — no way to measure rigorously in 14 days; watch for red flags in comments instead
