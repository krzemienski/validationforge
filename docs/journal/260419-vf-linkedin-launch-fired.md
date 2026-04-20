# 2026-04-19 — VF launch on LinkedIn (v2 text-feed post)

## Final result

- **Live post**: `urn:li:share:7451771702121934848`
- **URL**: https://www.linkedin.com/feed/update/urn:li:share:7451771702121934848/
- **Format**: Text-only feed post, 2,345 chars / 389 words
- **Delivery**: OAuth `POST /rest/posts`, `w_member_social` scope
- **Fired at**: 2026-04-19 ~23:20 UTC
- **Superseded**: `urn:li:ugcPost:7451768403029245952` (PDF-document version, deleted 204)

## Two-pass launch story

**v1 (PDF document post) — DELETED.** First attempt packaged the 2,976-word
hero essay as an 8-page Chrome-rendered PDF and posted via the LinkedIn
Documents API. It worked mechanically — HTTP 201, doc rendered inline on
the feed. Nick rejected the format immediately: PDFs on LinkedIn look
amateur, regardless of how clean the typography is. Deleted via `DELETE
/rest/posts/{urn}` → HTTP 204.

**v2 (text feed post) — LIVE.** Rewrote for the 3,000-char limit. Kept the
hook (23,479 sessions, 5 bug bullets, Compilation Theater, 6/6 PASS
self-validation). Added the new positioning Nick asked for:

- "First of several things I've been building at withagents.dev"
- "Product #1. More coming — runbooks, memory/context, operator UX"
- "Taking a small number of engagements this quarter — architecture review,
  embedded sprint, monthly retainer"
- "If you just want to talk about agent development — DMs are open.
  I can't stop thinking about this and I like the company."

Body file: `plans/260419-1817-vf-linkedin-launch-today/commentary-v2-feed-post.txt`

## Coordination with parallel session

The parallel CC session is building out `withagents.dev` (path:
`~/Desktop/blog-series/withagents-site/`). The v2 LinkedIn post specifically
links to that domain as the work-and-writing home, not just to the
validationforge repo. Visible site structure at time of launch:

- **Home** (`index.astro`) — "WithAgents — Applied Agent Design. A home
  for products, systems-first writing, and field-tested open source work."
  Product pillars teased: Runbooks (SYS_01), Memory Layer (SYS_02),
  Operator UI (SYS_03).
- **Work** (`work.astro`) — "Quiet collaboration on hard agent problems.
  I work with a small number of teams at a time. No pitch decks."
  Areas: agent architecture, operator UX, validation infra, knowledge
  systems. Engagements: architecture review / embedded sprint / retainer.
  Existing `ConsultForm.astro` with UTM-capture.
- **Content** — `content/posts/day-36-functional-validation.mdx`,
  `content/posts/day-51-validation-across-6-products.mdx`,
  `content/insights/iron-rule.mdx` already exist.

**Handoff request for parallel session:** Add ValidationForge to the
withagents.dev home page products/repos section, and add a repo card under
the 'validation infra' area of the work page. The LinkedIn post sends
traffic to `withagents.dev` expecting to find VF positioned as a shipped
product. If the site lands before the LinkedIn post gains reach, no
action needed. If the LinkedIn post starts driving traffic first, the
home page should at minimum acknowledge VF exists.

## Oracle blockers closed

- A.1: repo topics extended with `no-mock`, `functional-testing`, `quality-assurance` (10 topics total)
- A.2: README.md lines 3-12 rewritten — launch-week badge + Related Post block with repo URL, self-validation evidence path, Apr 22 essay tease
- B.3: `site/public/CNAME` committed with `validationforge.dev`
- B.1 / B.2: verified already fixed by prior session (URL drift + getting-started Aside)

## What's next on the calendar

- **Apr 20 Mon 08:30 ET** — `w1-mon-soft-launch` (95-word teaser, pre-hero
  by design). **Consider deferring** — the hero already fired, and running
  the teaser after the hero is out of sequence. Options: (a) skip, (b) re-
  purpose as a "thanks for the first-day reactions, here's what's next"
  follow-up, (c) post as a comment under the v2 hero.
- **Apr 22 Wed 08:30 ET** — `w1-wed-blog-series-part-1-validation-gap`
  (1,055-word validation-gap long-form). Separate hero PNG already attached
  (`linkedin-part-1-hero.png`).
- **Apr 25 Sat / Apr 30 Thu** — blog series parts 2 & 3.

## Mechanical notes (for future launches)

- LinkedIn `w_member_social` scope caps `commentary` at 3,000 chars. No
  workaround via OAuth for longer feed posts.
- Documents API works (demonstrated in v1) but renders as an attached PDF
  document card, which was visually-reject on this launch. Not the right
  format for thought-leadership long-form.
- **Right pattern for VF-scale content**: write to 2,400-2,900 chars.
  Anything longer needs to live as a blog post on `withagents.dev` (or
  GitHub README) and be linked from a condensed feed post.
- Reusable fire script: `plans/260419-1817-vf-linkedin-launch-today/scripts/fire-pdf-post.mjs`
  (PDF variant) and the ad-hoc `/tmp/fire-v2.mjs` (text variant; should be
  promoted to `scripts/fire-text-post.mjs` next session).

## Evidence

- `plans/260419-1817-vf-linkedin-launch-today/evidence-post-v2-live.png`
  — Chrome screenshot of the live v2 post on Nick's feed, byline "Now"
- `plans/260419-1817-vf-linkedin-launch-today/fire-v2.log` — JSON log of
  the HTTP 201 response
- `plans/260419-1817-vf-linkedin-launch-today/evidence-post-live.png` —
  retained screenshot of the deleted v1 PDF post (for audit)
- **Public URL reachability check** (2026-04-19 20:36 ET, curl with stock
  Chrome UA, no auth): HTTP 200, 97,774 bytes, `pageKey=d_public_post`,
  HTML contains all 5 signature tokens (`ValidationForge`, `Compilation
  Theater`, `23,479`, `3.4M`, `Nick Krzemienski`). Post is publicly
  indexable and shareable without a LinkedIn account.

## Lessons (durable — grep for these on future launches)

### LESSON-01 — Never publish long-form to LinkedIn as a PDF carousel

LinkedIn's document post (`content.media.id = urn:li:document:...`)
renders as a swipeable PDF card. This format is culturally associated
with marketing carousels — listicle slides, infographic decks, sales
collateral. Using it for thought-leadership long-form positions the
brand as marketing-adjacent, not practitioner-credible.

**What happened:** Fired `urn:li:ugcPost:7451768403029245952` as a PDF
doc post. User rejected within minutes. Cost: ~15 min engineering + one
round-trip of frustration.

**What to do instead for long-form:**
1. If ≤3,000 chars → feed post via OAuth `/rest/posts` with `commentary`
2. If 3,000–20,000 chars → publish to `withagents.dev` or a GitHub page,
   then post a feed-post teaser linking to it
3. If truly long-form on-platform → LinkedIn Articles (Pulse editor).
   Requires browser automation or Pulse API (not in current scope).

### LESSON-02 — "Launch today" ≠ "fire whatever is soonest-queued"

When the user says "launch," examine which post is the HERO, not which
has the soonest `scheduled_at`. Queue order is a calendar artifact;
launch intent is editorial.

**What happened:** I grabbed `w1-mon-soft-launch` (95-word teaser) from
`lp queue peek` because it was the next due item. The actual hero was
`w2-wed-personal-brand-hero` (2,976 words). User corrected me.

**What to do instead:** Before firing, ask "which of these queued items
is the launch ANNOUNCEMENT vs a supporting piece?" Look for signal words
in the source files: "hero", "announcement", "launch-post", "canonical".

### LESSON-03 — Cookie-auth is the emergency fallback, not the default

The cookie publisher (`publish-via-cookie.js`) works but violates LinkedIn
ToS §8 and carries a ban ladder. OAuth (`w_member_social`) is the
official path and should always be tried first. The 3,000-char limit on
`commentary` applies to both paths equally — it's a LinkedIn platform
limit, not an OAuth scope limit.

## Ban-risk posture

OAuth only. No voyager cookie traffic. Both v1 create, v1 delete, and v2
create used the official `/rest/posts` endpoint with the saved OAuth bearer
token (`w_member_social` scope, expires Nov 2026).

## Open items

- Coordinate with parallel session on `withagents.dev` product listing
  for VF — see Handoff request above.
- Decide Apr 20 Mon teaser fate (defer/skip/repurpose).
- 5 campaign decisions still pending (publishing domain, newsletter
  platform, coupled brand, master/main, MDX/MD) — not blocking.
