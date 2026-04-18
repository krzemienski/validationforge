# Campaign Plan: ValidationForge Launch

**Generated:** 2026-04-18
**Owner:** Nick Krzemienski
**Concept:** Receipts × Manifesto (Hybrid D)
**Window:** 2026-04-18 → 2026-05-01 (14 days)
**Budget:** $0 paid · ~30 hr creator time
**North-Star:** 100+ GitHub stars on github.com/krzemienski/validationforge

---

## TL;DR (the whole strategy in 5 lines)

1. **Spine:** Every public claim cites real evidence (no rhetoric, no mockups).
2. **Frame:** Coin and defend "Evidence-Based Shipping" — name "Compilation Theater" as the enemy.
3. **Channels:** X drumbeat (daily) → Reddit drops (3 subs) → LinkedIn 3-part series → Show HN spike Day 11.
4. **Proof:** VF self-validated 6/6 PASS, 0 fix attempts. Receipt directory is the campaign's secret weapon.
5. **Iron rule:** No mocked demos. Every demo runs `/validate` against a real OSS repo.

---

## File Index

```
assets/campaigns/260418-validationforge-launch/
├── briefs/
│   ├── campaign-brief.md          ← Strategy, audience, KPIs, risk
│   ├── creative-brief.md          ← Voice, tone, hook bank, anti-messages
│   └── channel-playbooks.md       ← Per-channel rules of engagement
├── copy/
│   ├── x-threads.md               ← 14 days of X content (drafts)
│   ├── show-hn-drafts.md          ← 3 HN title/body variants + author comment
│   ├── reddit-posts.md            ← r/ClaudeAI, r/LocalLLaMA, r/programming drafts
│   ├── linkedin-blog-series.md    ← 3-part long-form series
│   └── discord-announcements.md   ← 4 server-specific drops
├── execution/
│   └── 14-day-calendar.md         ← Day-by-day operations + checklists
├── tracking/
│   └── measurement-plan.md        ← KPIs, UTMs, daily metrics protocol
└── reports/
    └── 260418-campaign-plan.md    ← (this file)
```

---

## Wave Plan

| Wave | Days | Dates | Focus |
|---|---|---|---|
| 1 | 1-3 | Apr 18-20 | Repo polish · X tease · Discord soft-launch |
| 2 | 4-7 | Apr 21-24 | r/ClaudeAI drop · LinkedIn Part 1 · receipts cadence · r/LocalLLaMA drop |
| 3 | 8-10 | Apr 25-27 | LinkedIn Part 2 · r/programming drop · HN final prep |
| 4 | 11 | Apr 28 | **SHOW HN spike day (8am ET) + day-long engagement** |
| 5 | 12-14 | Apr 29 - May 1 | HN follow-up · LinkedIn Part 3 · retrospective |

---

## Success Tiers

| Tier | Stars | HN | Ecosystem | Verdict |
|---|---|---|---|---|
| **Stretch** | 250+ | top-10 | Anthropic devrel signal-boost | Category-defining win |
| **Win** | 100+ | front page (>50pts) | OMC or Superpowers maintainer mention | Goal achieved |
| **Floor** | 50+ | n/a | 3+ unsolicited "I'm using VF" posts | Acceptable; learnings logged |
| **Failure** | <30 | n/a | only existing followers engaged | Pause Day 7, reframe |

---

## Iron Rules (enforce throughout)

```
1. Every public claim cites evidence (file path, log line, screenshot).
2. No mocked demos — every demo runs against a real OSS project.
3. No AI-generated stock copy — all posts edited in voice by hand.
4. No paid amplification (constraint, not preference).
5. Reply to every reasonable HN/Reddit comment within 1 hour during launch day.
6. If a demo fails live, publish the failure with evidence. Do not hide.
7. Never post the same content to two subreddits within 24 hours.
8. Block-quote criticism in replies. Do not paraphrase to soften it.
```

---

## Daily Cadence (operational defaults)

- **Morning (8-10am ET):** Post primary asset of the day (X thread, Reddit drop, LinkedIn part, or HN if Day 11)
- **Midday (12-2pm ET):** Engage with comments on prior day's posts; quote-tweet ecosystem activity if natural
- **Afternoon (3-5pm ET):** Receipt drop — run `/validate` against an OSS repo, screenshot, post to X
- **Evening (5pm ET):** Log daily metrics in `tracking/measurement-plan.md` (1 line per metric)
- **Late evening:** Review and triage incoming GitHub issues / DMs / mentions

---

## Top Risks & Mitigations

| Risk | Mitigation |
|---|---|
| HN flop | Refined Variant A title, 5-min author comment, friend-network primer Day 10 |
| Reddit removal | Native long-form, no link spam, comply with each sub's self-promo rules |
| Demo fails on live OSS repo | Pre-validate every demo, keep 2 backup repos warm |
| "Sounds preachy" | Lead with receipts, defend with evidence, never with rhetoric |
| Anthropic policy concern | Explicit "complementary, not replacement" framing; no Anthropic logos |

---

## Mid-Sprint Review (Day 7 — Thu Apr 24)

Pause and assess:
- Star delta vs. plan?
- Which channel is over-performing?
- Which message is getting ignored?
- Adjust Wave 3-5 plan based on signal.

Document review in `tracking/measurement-plan.md` under "Mid-Sprint Review" section.

---

## Post-Mortem (Day 14 — Fri May 1)

Required deliverables:
1. Final numbers vs. targets (table)
2. Top-5 unexpected learnings
3. What we'd do differently for v2 (CONSENSUS engine launch)
4. Public retrospective LinkedIn Part 3 + X recap thread

Save to `reports/260501-launch-retrospective.md` (created Day 14, not now).

---

## Approval Gate

This plan is ready to execute. No further approval needed for in-scope tactics. Out-of-scope items (paid amplification, partnership announcements, Anthropic-tagged posts) require explicit user sign-off before publishing.
