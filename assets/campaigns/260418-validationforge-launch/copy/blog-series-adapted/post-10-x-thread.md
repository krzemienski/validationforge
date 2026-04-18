---
title: "21 Screens. Zero Figma. One Afternoon."
channel: X / Twitter
companion_blog_post: 10 of 18
companion_repo: github.com/krzemienski/stitch-design-to-code
total_tweets: 7
voice_notes: Visual carousel-style. Each tweet attaches an image. Punchy, opinionated. No emojis.
---

### 1/7 — Hook

> 21 screens. Zero Figma. One afternoon.
>
> I shipped a full design system to production code without opening a design tool. Not once.
>
> Here's the pipeline, the bug that almost killed it, and the workflow rule that saved it.

(214 chars)

### 2/7 — The numbers

> The receipts across 42 days:
>
> 269 generate_screen_from_text calls
> 87 list_screens calls
> 47 design tokens (one source of truth)
> 21 production screens shipped
> 0 Figma files opened
> 0 lines of CSS hand-written
>
> Three products. One token file. Plain English in, rendered React out.

(279 chars)

### 3/7 — The branding bug

> Screen 22 is where I noticed it.
>
> Header said "Awesome Video Dashboard." My prompt said "Awesome Lists." Eight screens were already wrong.
>
> Each Stitch call is stateless. By call 15, the model's training data had quietly overwritten my product name. I never told it to.

(276 chars)

### 4/7 — The fix is the lesson

> The fix wasn't a patch. It was a rule:
>
> The full design system, including the exact product name, goes into every prompt. Verbatim. Every time.
>
> Not "see previous specs." Not "continue the design from screen 14."
>
> Treat the brand name as a token, not as memory.

(266 chars)

### 5/7 — Border radius = 0

> Every border radius in the token file is 0px.
>
> Not for taste. For testing.
>
> If any component renders with rounded corners, the token pipeline is broken. You can spot the failure from across the room.
>
> The design system is its own validation suite.

(254 chars)

### 6/7 — Prompts as build artifacts

> The mindset shift that made this work:
>
> Prompts are not instructions. They are build artifacts.
>
> Version-controlled. Reviewed in PRs. Tested for propagation. Generated from the token file, not from my memory.
>
> Same discipline as a Tailwind config. Same enforcement.

(272 chars)

### 7/7 — Repo + full post

> Full pipeline, 47-token file, 107-action validation suite, branding-bug case study — all in the companion repo.
>
> Repo: github.com/krzemienski/stitch-design-to-code
>
> Full post (one of 18 on agentic dev at scale): [LINKEDIN_URL]

(238 chars, with two URLs at 23 each)

---

## Posting Protocol

**Cadence:** post all 7 tweets as a single thread. Reply-chain, not standalone posts.

**Visual attachments — every tweet attaches an image.** Use the existing assets from `~/Desktop/blog-series/posts/post-10-stitch-design-to-code/assets/`:

| Tweet | Attached visual |
|---|---|
| 1/7 | `stitch-hero.png` (primary hero image) |
| 2/7 | Screenshot of one of the 21 production screens (any high-contrast example — Admin Dashboard or Home recommended) |
| 3/7 | Side-by-side: screen with "Awesome Video Dashboard" wrong header vs. correct "Awesome Lists" header |
| 4/7 | `post10-token-hierarchy.svg` rendered as PNG |
| 5/7 | Close-up of any UI card showing the sharp 0px corners |
| 6/7 | `post10-generation-pipeline.svg` rendered as PNG |
| 7/7 | `linkedin-card.html` rendered, OR `twitter-card.html` rendered |

**SVG → PNG:** X does not render SVG inline. Pre-render any SVG to PNG at 1600x900 minimum before attaching.

**URL placeholder:** replace `[LINKEDIN_URL]` in tweet 7 with the live LinkedIn post URL after the LinkedIn version goes up. Post the LinkedIn version 30-60 minutes before the X thread.

**Best posting window:** Mon Jun 15, 9:30am ET (cross-references the LinkedIn post that goes up Mon morning).

**Engagement:** quote-tweet 1/7 from your own account 24 hours later with one observation about a reply or a real-world example from someone who tried the workflow. Do not boost your own thread without adding a new datapoint.
