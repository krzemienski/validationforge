# Campaign Brief: ValidationForge Launch

| Field | Value |
|---|---|
| Codename | Receipts × Manifesto (Hybrid D) |
| Window | 2026-04-18 → 2026-05-01 (14 days) |
| Owner | Nick Krzemienski |
| Budget | $0 paid · ~30 hr creator time |
| Repo | https://github.com/krzemienski/validationforge |
| North-Star Metric | 100+ GitHub stars by Day 14 |

## Objective

Earn **100+ GitHub stars** on `github.com/krzemienski/validationforge` through a credible, evidence-driven launch in the Claude Code ecosystem. Stars are a proxy — the real prize is **ecosystem endorsement**: being recommended by OMC, Superpowers, ECC creators and Anthropic devrel as the validation layer for AI-assisted development.

## Audience: Solo Claude Code power users

- Daily Claude Code users who have shipped AI-generated code that "passed tests" but broke
- Active in r/ClaudeAI, X dev twitter, Anthropic Discord, OMC/Superpowers communities
- Read HN front page, follow plugin ecosystem releases
- Pain: spent hours debugging features that compiled, type-checked, and "passed unit tests" — but didn't actually work

**Anti-audience:** enterprise QA leads, traditional test framework maintainers, AI skeptics. Not for them this round.

## Strategic Frame

### The spine: Receipts
Every public claim about VF is backed by cited evidence. We do not say "it works" — we link to `e2e-evidence/{journey}/step-NN-*.{ext}` files. We do not say "it's fast" — we publish wall-clock timings. We do not say "it caught a bug" — we publish the diff and the failing verdict.

This works because **VF self-validated 6/6 PASS, 13/13 criteria, 0 fix attempts** with the full evidence directory committed to the repo. Nobody else in this space can credibly publish receipts — they don't capture them.

### The frame: Manifesto
We name the enemy: **Compilation Theater** — the practice of treating "build passing" as evidence that AI-generated code works. We coin and defend a term we want to own: **Evidence-Based Shipping**.

Manifesto framing without receipts = preachy. Receipts without framing = forgettable demos. The hybrid is the play.

## Key Messages (priority order)

1. **Compilation isn't validation.** Build success ≠ feature working.
2. **Evidence-Based Shipping** is the new bar for AI-assisted development.
3. **VF self-validated 6/6 PASS, 0 fix attempts.** The evidence directory is in the repo.
4. **Born from 23,479 AI coding sessions** across 27 projects (3.4M lines). Earned wisdom, not theory.
5. **Free, open-source, complementary** to OMC, Superpowers, ECC. Additive, not competitive.

## Anti-Messages (forbidden)

- ❌ "Replace your test suite" — we don't, and saying so loses HN immediately.
- ❌ "AI is dangerous" — fearmongering loses the audience we want.
- ❌ "Claude Code is broken" — alienates users and Anthropic devrel.
- ❌ "Easy to use" — VF requires discipline; selling ease is a lie that backfires in comments.
- ❌ "AI-powered" / "synergy" / "leverage" / "platform" — buzzwords kill credibility on HN.

## Channel Mix (organic only)

| Channel | Role | Cadence |
|---|---|---|
| X / Twitter | Daily drumbeat, receipts, big thread | 1-2 posts/day, 1 thread every 3-4 days |
| Hacker News | Single high-stakes spike event | 1 Show HN, Day 11 (Tue Apr 28, 8am ET) |
| Reddit (r/ClaudeAI, r/LocalLLaMA, r/programming) | Subreddit-specific drops | 3 posts spread Days 4-10 |
| LinkedIn | Long-form 3-part series | Days 5, 8, 13 |
| Discord (Anthropic, OMC, Superpowers) | Soft community announcements | 1 per server, no spam |

## Wave Plan (high-level)

| Wave | Days | Focus |
|---|---|---|
| 1 | 1-3 | Tease + community priming + repo polish |
| 2 | 4-7 | First Reddit drop + LinkedIn Part 1 + receipts cadence |
| 3 | 8-10 | LinkedIn Part 2 + second Reddit drop + HN final prep |
| 4 | 11 | **Show HN spike day** + day-long engagement |
| 5 | 12-14 | HN follow-up + LinkedIn Part 3 + retrospective |

Day-by-day calendar lives in `execution/14-day-calendar.md`.

## Iron Rules (campaign-level)

```
1. Every public claim cites evidence (file path, log line, screenshot).
2. No mocked demos — every demo runs against a real OSS project.
3. No AI-generated stock copy — all posts written in voice, edited by hand.
4. No paid amplification (constraint, not preference; reinforces credibility).
5. Reply to every reasonable HN/Reddit comment within 1 hour during launch day.
6. If a demo fails live, publish the failure with evidence. Do not hide.
7. Never post the same content to two subreddits within 24 hours.
8. Block-quote criticism in replies. Do not paraphrase to soften it.
```

## Success Criteria (Day 14 review)

| Tier | Outcome |
|---|---|
| Win | 100+ stars, HN front page, ecosystem mention from OMC or Superpowers maintainer |
| Stretch | 250+ stars, HN top-10, Anthropic devrel signal-boost |
| Floor | 50+ stars, 3+ unsolicited "I'm using VF" posts from non-followers |
| Failure mode to avoid | Stars from existing followers only; zero ecosystem traction |

## Risk Register

| Risk | Likelihood | Mitigation |
|---|---|---|
| HN flop (Show HN dies on /new) | Medium | Refined title (Variant A), 5-min author comment, friend amplification network primed Day 10 |
| Reddit removal by mods | Medium | Native long-form posts, no link spam, comply with each sub's rules |
| Comment storm (Iron Rule sounds preachy) | Low-Medium | Lead with receipts, defend with code/evidence, never with rhetoric |
| Anthropic policy concern | Low | Explicit "complementary, not replacement" framing; no Anthropic logos |
| Demo fails on live OSS repo | Medium | Pre-validate every OSS repo demo before posting; have 2 backup repos ready |

## Budget & Resources

- **Spend:** $0 paid amplification.
- **Time:** ~30 hr of Nick's time across 14 days (~2 hr/day average; 6+ hr on Day 11 HN day).
- **Tools:** Claude Code (drafting), GitHub, X, Reddit, LinkedIn, Discord, terminal screen-recorder.

## Cross-References

- `briefs/creative-brief.md` — voice, tone, key messages, hook bank
- `briefs/channel-playbooks.md` — per-channel rules of engagement
- `execution/14-day-calendar.md` — day-by-day operations
- `tracking/measurement-plan.md` — KPIs, UTMs, reporting cadence
- `copy/` — exact ready-to-post content per channel
- `reports/260418-campaign-plan.md` — top-level executive summary
