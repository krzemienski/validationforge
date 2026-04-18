---
post_number: 9
title_x: "Code Tales: Listen to a Codebase"
companion_repo: https://github.com/krzemienski/code-tales
linkedin_url: <to be filled at publish time>
total_tweets: 6
send_week: Week 8 — Mon Jun 8, 2026
rewrite_note: |
  REWRITE 2026-04-18 — calendar-framed thread, NOT source-faithful.
  Hook tweet uses the "What if I could listen to a codebase?" pull quote.
  All 6 tweets ≤280 chars (URLs count as 23).
---

### 1/6 — Hook

> What if I could listen to a codebase?
>
> Not read docs. Not scan source. Listen — like a podcast about FastAPI's architecture.
>
> So I built Code Tales. Repo URL in. Twenty minutes later, mp3 out.
>
> Here is the four-stage pipeline that makes it work.

*(247 chars)*

### 2/6 — The pipeline

> Four stages, clean handoffs:
>
> 1. Clone — walk the repo, build a file manifest
> 2. Analyze — Claude produces a structured doc of what's in there
> 3. Narrate — Claude rewrites the doc as a script in one of 9 styles
> 4. Synthesize — ElevenLabs renders the script to audio

*(255 chars)*

### 3/6 — Where it got hard

> The middle two stages decide whether you get something worth listening to or a robot reading a stack trace.
>
> First version skipped stage 2 entirely. Single prompt, repo to script. Output was occasionally brilliant, frequently incoherent.

*(243 chars)*

### 4/6 — The fix

> Adding the explicit analyze stage — model first produces a structured representation, THEN writes the script from it — fixed everything.
>
> The analysis becomes the model's anchor. The script is written about the analysis, not the repo. Finite. Consistent.

*(258 chars)*

### 5/6 — Same repo, different experiences

> Same Python framework, documentary style: 15-min calm narrative, architectural deep dive.
>
> Same repo, podcast style: two hosts, one skeptic, 20 min of disagreement.
>
> Same repo, executive briefing: 6 min of "should my team use this."
>
> Source data identical. Output is not.

*(279 chars)*

### 6/6 — Repo + lesson

> AI-generated content quality depends not on the model but on the constraints and structure you give it.
>
> The model is the engine. Constraints are the steering wheel.
>
> Repo: github.com/krzemienski/code-tales
> Long-form: <linkedin-url>

*(approx 240 chars w/ URLs at 23 each)*

---

## Posting Protocol

- **Send window:** Mon Jun 8, 2026, 8:30am ET (matches LinkedIn slot)
- **Pin:** pin to profile through Wed Jun 10
- **Reply:** within 2 hours of post for any substantive reply
- **Cross-post:** quote-tweet T1 at 5pm ET same day with one additional pull quote
- **Repo readiness:** confirm `code-tales` README has the "Featured in Agentic Dev Blog — Post #9" badge and the related-post link before publish (per audit-report quick-win checklist)
- **Asset:** attach the existing `code-tales-hero.png` to T1 (1200×627)
- **Engagement reply bank:** prep three replies for the predictable questions — "what model?" / "what voice provider?" / "can I run on private repos?" — so reply latency stays under 90 seconds
- **No hashtags.** None. Not even #ai.
