# Creative Brief: ValidationForge Launch

## Voice

Direct. Technical. Slightly contrarian. Speaks to engineers who have been burned by "it compiled" being treated as success.

**Sounds like:** Patrick McKenzie writing about software bugs. DHH writing manifestos. Julia Evans drawing zines. None of those exactly — synthesize.

**Does NOT sound like:** Anthropic blog post. Y Combinator launch announcement. Medium "5 Lessons From..." post. Any LinkedIn influencer.

## Tone Spectrum

| Channel | Tone | Length |
|---|---|---|
| X / Twitter | Punchy, opinionated, demo-heavy | 280 char or 8-10 tweet thread |
| Hacker News | Calm, technical, defensible, modest | 200-400 word post body |
| Reddit r/ClaudeAI | Conversational, peer-to-peer, GIF-led | 300-500 words + media |
| Reddit r/LocalLLaMA | Technical, agent-compatibility framing | 400-600 words |
| Reddit r/programming | Manifesto-tinged, defensible under hostile skim | 500-800 words |
| LinkedIn | Long-form, story-led, polished but not corporate | 1500-2200 words |
| Discord | Casual, helpful, no-CTA | 50-150 words |

## Key Messages — exact phrasing approved

### Hero message (use everywhere as opener or close)
> "Compilation isn't validation. Build success ≠ feature working."

### The receipt message
> "ValidationForge ran its 7-phase pipeline against itself. Result: 6/6 journeys PASS, 13/13 criteria, 0 fix attempts. The evidence directory is in the repo."

### The credibility message
> "Born from 23,479 Claude Code sessions across 27 projects. 3.4 million lines of AI-generated code. At least 5 production bugs unit tests structurally cannot catch."

### The category message
> "Evidence-Based Shipping for AI-assisted development."

### The technical hook
> "The plugin blocks Claude from creating mock files in src/. Then makes it write a verdict that cites real evidence."

### The composability message
> "Use OMC or Superpowers to build. Use ValidationForge to verify."

## Anti-Messages — never publish

- "AI-powered validation" (redundant; the user knows)
- "The future of testing" (grandiose; under-delivers)
- "Replaces unit tests" (false; we are additive)
- "Game-changer" / "revolutionary" / "next-gen" (HN allergy)
- "We built this in a weekend" (under-sells the 23,479-session origin)
- Any sentence beginning with "In today's fast-paced world..."

## Visual Style

- **Real terminal output** — never mockup screenshots; use actual `cat` / `bat` output of real `e2e-evidence/` files
- **Evidence directory listings** as proof artifacts (`tree e2e-evidence/self-validation/`)
- **Demo GIFs**: 10-15 second loops, no music, no text overlay, 720p minimum
- **Code snippets**: monospace (JetBrains Mono or Menlo), syntax highlighted only where it adds info
- **Color palette**: terminal greens (PASS), reds (FAIL), with one Claude orange accent reserved for primary CTA only
- **Never use stock photos.** Never use AI-generated images.

## Hook Bank (rotate; do not exhaust on Day 1)

Tier-1 hooks — for X primary tweets, HN title candidates, LinkedIn opener:
1. "I shipped 3.4M lines of AI code. Here's the validation gap nobody is filling."
2. "Compilation isn't validation. I built the gate."
3. "Stop shipping AI code that compiles but doesn't work."
4. "Show HN: I made Claude prove its code works."
5. "Evidence-Based Shipping for AI-assisted development."
6. "The Claude Code plugin that blocks AI from creating mock files."
7. "VF validated itself: 6/6 PASS, 0 fix attempts, 13/13 criteria. Receipts in the repo."

Tier-2 hooks — for X secondary posts, Reddit titles, Discord drops:
8. "5 categories of bugs unit tests structurally cannot detect."
9. "What 23,479 Claude Code sessions taught me about validation."
10. "I made a hook that blocks AI from writing mocks. Here's why."
11. "Real terminal output > 'should work'."
12. "The opposite of test theater."

Tier-3 hooks — for engagement replies, comment threads:
13. "If your test passed but the feature didn't, you have a mock drift bug."
14. "PASS without citation isn't PASS."
15. "Type-checking is necessary. It is not sufficient."

## Negative Examples

❌ **Bad opener**: "Excited to announce ValidationForge, a revolutionary new tool that leverages AI to..."
✅ **Good opener**: "I shipped 3.4M lines of AI code in 42 days. Five things shipped broken. Here's what I built to fix that."

❌ **Bad demo**: "Here's a screenshot of the dashboard."
✅ **Good demo**: "Here's the actual `e2e-evidence/self-validation/journey-3/step-04-curl-response.json` from my last run."

❌ **Bad CTA**: "Try ValidationForge today and transform your workflow!"
✅ **Good CTA**: "Install: `/plugin marketplace add krzemienski/validationforge`. Repo: github.com/krzemienski/validationforge."

## Voice Calibration Test

Before posting, ask: **"Would Patrick McKenzie quote-tweet this without rolling his eyes?"** If no, rewrite.
