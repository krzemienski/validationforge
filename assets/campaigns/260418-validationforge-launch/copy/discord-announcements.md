# Discord Announcements

All Discord drops on **Day 3 (Mon Apr 20)**, late afternoon ET. ONE post per server. After the drop: engage as a peer in conversations, never repost.

**Universal rules:**
- Never `@everyone` or `@here`. Instant ban-worthy.
- Never bump your own message later in the day.
- Never crosspost the same message in two channels of one server.
- Lead with utility, close with the link.

---

## Anthropic Discord — `#showcase` channel

> Just shipped **ValidationForge** — a Claude Code plugin that enforces evidence-based validation for AI-generated code.
>
> What it does:
> – PreToolUse hook blocks test/mock/stub file creation in `src/`
> – `/validate` runs a 7-phase pipeline against the real system (curl, simctl, Playwright, shell)
> – Every verdict cites specific evidence files (no "I think it works")
>
> Self-validated 6/6 PASS, 13/13 criteria, 0 fix attempts. Evidence directory committed in the repo.
>
> Free, MIT, no telemetry by default.
>
> Install: `/plugin marketplace add krzemienski/validationforge`
> Repo: https://github.com/krzemienski/validationforge
>
> Happy to answer questions in-thread.

---

## OMC (oh-my-claudecode) server — `#show-and-tell` or equivalent

> For folks running OMC orchestration: **ValidationForge** integrates as a validation handoff layer.
>
> Pattern: use `ralph` / `autopilot` to build → use `/validate` to verify with cited evidence.
>
> Why this composes well:
> – OMC's parallel agents produce a lot of code fast — VF gives you a uniform verdict layer with auditable artifacts
> – `e2e-evidence/{journey}/step-NN-*` becomes the handoff doc between agent waves
> – The PreToolUse no-mocks hook plays nicely with OMC's existing hook stack
>
> Integration guide in repo: `docs/integrations/vf-with-omc.md`
> Repo: https://github.com/krzemienski/validationforge
>
> Would love OMC users to try it and tell me where it grates.

---

## Superpowers community

> **ValidationForge** complements Superpowers cleanly:
>
> – Superpowers TDD discipline → great for pure logic with no I/O
> – ValidationForge real-system validation → great for the assembled feature touching real interfaces
>
> They sit at different layers and don't compete. Integration guide is in the repo at `docs/integrations/vf-with-superpowers.md`.
>
> Self-validated 6/6 PASS. Free, MIT.
> Repo: https://github.com/krzemienski/validationforge

---

## Plugin-dev community (general Claude Code plugin ecosystem)

> For plugin developers: **ValidationForge** might be useful as a working reference.
>
> Specifically:
> – `hooks/block-test-files.js` — small (~50 LOC) PreToolUse hook with the canonical `decision: "deny"` pattern
> – `hooks/evidence-gate-reminder.js` — TaskUpdate-triggered checklist injection
> – `hooks/completion-claim-validator.js` — PostToolUse Bash hook catching unsupported claims
>
> All hooks are JS, deterministic, zero LLM cost. Source is small enough to read in a sitting.
>
> Repo: https://github.com/krzemienski/validationforge
>
> If you want to lift one of these patterns for your own plugin, please do — the hook layer is the contribution, not the brand name.

---

## Engagement Protocol After Posting

For each server, set a 24-hour engagement window:

| Time after post | Action |
|---|---|
| 0-30 min | Stay in channel, reply to first reactions |
| 30 min - 2 hrs | Respond to every substantive question |
| 2 - 24 hrs | Check 2-3x; reply within 1 hr to anything substantive |
| After 24 hrs | Move on. Do not bump the post. |

**Do NOT:**
- Cross-post to other Claude Code-related Discord servers ("ecosystem broadcasting" reads as spam)
- Reply with "thanks!" to every reaction (noise; only reply when you have something useful)
- Tag specific maintainers / influencers (let them find it organically)

**Do:**
- Answer "how does X work" with a specific file path or line number
- Acknowledge "I tried it and got Y error" by moving the conversation to a GitHub issue
- Quote-tweet substantive Discord praise to X (with screenshot, name redacted unless they're public)
