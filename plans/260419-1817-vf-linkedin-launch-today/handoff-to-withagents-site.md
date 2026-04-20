# Handoff → withagents-site parallel session

**From:** validationforge session (launch-coordinator lane)
**To:** blog-series / withagents-site session (domain-buildout lane)
**Created:** 2026-04-19 20:36 ET
**Priority:** soft — doesn't block you, but closes a positioning loop

## The ask in one sentence

Add ValidationForge to `withagents.dev` as a shipped product + repo chip, before the Apr 22 Wed 08:30 ET LinkedIn fire of `w1-wed-blog-series-part-1-validation-gap`.

## Why this matters now

The Apr 19 PM LinkedIn post that just went live
(https://www.linkedin.com/feed/update/urn:li:share:7451771702121934848/)
contains this positioning copy:

> "This is product #1 of several at withagents.dev — runbooks, memory,
> operator UX in the oven."

Traffic lands on withagents.dev expecting to see VF listed. Currently the
home page product grid lists 3 pillars (Runbooks / Memory Layer / Operator
UI) but NOT ValidationForge. This is a short-term incoherence for anyone
who clicks through this week.

## Concretely — what I'd propose you add

### 1. Home page (`src/pages/index.astro`) — add a "Shipped" section above or below the Core Infrastructure pillars

Example product card:

```ts
const shipped = [
  {
    name: 'ValidationForge',
    slug: 'validationforge',
    tagline: 'View on GitHub',
    description: 'No-mock functional validation for Claude Code + OpenCode. Hooks that block mock creation; a /validate pipeline that captures evidence from real systems.',
    sysNum: 'SHIP_01',
    icon: 'verified',
    href: 'https://github.com/krzemienski/validationforge',
  },
];
```

### 2. Repo chip array (same file, near `agent-contracts` / `trace-timeline` / `eval-suite`)

```ts
const repos = [
  { name: 'validationforge', version: 'v1.0.0', status: 'active' as const },
  { name: 'agent-contracts', version: 'v1.2.4', status: 'active' as const },
  ...
];
```

### 3. Work page (`src/pages/work.astro`) — under the "Validation infra" area, add a callout

```astro
<p class="mt-4 text-sm text-muted">
  The shipped reference implementation of this approach is
  <a href="https://github.com/krzemienski/validationforge" class="text-accent">ValidationForge</a>
  — open-sourced Apr 2026, MIT licensed.
</p>
```

### 4. (Optional) Content post

If you're producing a `content/posts/day-XX-validationforge-launch.mdx`
companion to the LinkedIn announcement, that's great — but not blocking.

## What I'm NOT asking you to do

- Don't rewrite the Core Infrastructure (Runbooks/Memory/Operator) copy.
  That's still the forward-looking product line.
- Don't rebrand away from "WithAgents — Applied Agent Design." The VF
  LinkedIn post defers to that positioning.
- Don't touch `content/insights/iron-rule.mdx` — I didn't read it in full
  and don't want to create a merge conflict with your in-progress work.

## Files I touched in validationforge repo (for awareness)

- `README.md` — lines 3-12 rewrite (launch-week badge + Related Post)
- `site/public/CNAME` — added with `validationforge.dev`
- `docs/journal/260419-vf-linkedin-launch-fired.md` — retrospective
- `plans/260419-1817-vf-linkedin-launch-today/` — plan + scripts + evidence

I did NOT touch:
- `assets/campaigns/260418-validationforge-launch/**` (your lane)
- `site/src/**` (your lane if this site shares a repo)
- Anything under `~/Desktop/blog-series/withagents-site/`

## Launch calendar impact on you

| Date (ET) | LinkedIn fires | withagents.dev should have |
|---|---|---|
| Apr 19 (today, DONE) | v2 hero (2,345-char text + withagents.dev CTA) | — (today was the launch) |
| Apr 20 Mon 08:30 | `w1-mon-soft-launch` (95 words) — may defer/skip | no change needed |
| **Apr 22 Wed 08:30** | `w1-wed-blog-series-part-1-validation-gap` (1,055 words, links back to VF repo) | **VF product card + repo chip should be live by now** |
| Apr 25 Sat 08:30 | `w2-sat-blog-series-part-2-mid-sprint` | — |
| Apr 29 Wed 08:30 | `w2-wed-personal-brand-hero` — ALREADY FIRED (superseded today) | — |
| Apr 30 Thu 08:30 | `w2-thu-blog-series-part-3-retrospective` | — |

## Questions for you (if any)

1. Are the 3 Core Infrastructure pillars (Runbooks / Memory / Operator UI)
   actually shipped or still scaffolding? If scaffolding, VF is genuinely
   the first SHIPPED product and the framing is correct. If they're also
   shipped, framing should shift to "latest product, with X prior."
2. Does the Apr 22 blog-series-part-1 LinkedIn post (scheduled in the VF
   campaign queue) reference withagents.dev? I didn't check yet — if yes,
   that's another traffic spike where VF should be listed.
3. Do you want me to coordinate future LinkedIn sends through a shared
   state file, or is ad-hoc commit-message signaling sufficient?

## No response required

Closing this as a soft handoff. If you need clarification, leave a
comment in this file or open a PR touching it — I'll see it on next
session start.
