# Phase 02 — OG + Twitter Card Metadata for ai.hack.ski

## Context
- Parent plan: [plan.md](./plan.md)
- Depends on: Phase 04 (DNS must resolve before scrapers can fetch tags)
- Blocks: Phase 06 (every shared post preview depends on correct cards)

## Overview
Every blog-series post links to `https://ai.hack.ski/blog/<slug>`. Today those links
unfurl as plain text in iMessage, LinkedIn, and X — no preview image, no title, no
description — because the rendered pages emit no `og:*` / `twitter:*` meta tags. With
19 remaining posts firing Mon/Thu through Jun 27, this kills CTR on every share. Fix:
add a reusable `<SEO>` component that emits full OG + Twitter Card + canonical link
tags per page, driven by post frontmatter.

## Key Insights
- Starlight auto-emits OG tags from the site URL + page frontmatter for `.md/.mdx`
  pages under `src/content/docs/`, but the custom hero in `site/src/pages/index.astro`
  is hand-coded and currently ships only `<title>` and `<meta name="description">`.
- `astro.config.mjs` already has `site: 'https://validationforge.dev'` set as a
  canonical root — but blog-series posts live on `ai.hack.ski`, a separate deploy
  (confirmed via grep in `staged-readme-patches/*` referencing `ai.hack.ski/blog/<slug>`).
- LinkedIn + iMessage unfurl bots are aggressive cachers — any tag change must be
  re-scraped via LinkedIn's Post Inspector and twitter.com/cards/validator.
- Hero image dimensions `1200×627` already match each blog-series post's
  `assets/stitch-hero.png` per `creatives/visual-content-spec.md` — no new art needed.

## Requirements
1. Every blog post page emits: `og:title`, `og:description`, `og:image` (absolute URL),
   `og:url` (canonical), `og:type=article`, `og:site_name`, `twitter:card=summary_large_image`,
   `twitter:title`, `twitter:description`, `twitter:image`, `twitter:creator=@nkrkn`.
2. Landing page (`site/src/pages/index.astro`) emits the same set with site-level defaults.
3. `<link rel="canonical" href="...">` present on every page.
4. Hero image absolute URL resolves (HTTP 200, correct content-type) from the deployed host.
5. LinkedIn Post Inspector refreshes cleanly for the first 3 canonical URLs.

## Architecture
```
Post frontmatter (title, description, hero_image, pub_date, slug)
      ↓
<SEO> Astro component (site/src/components/SEO.astro)
      ↓
emits <meta og:*>, <meta twitter:*>, <link canonical> into <head>
      ↓
deployed HTML → LinkedIn/X/iMessage scrapers → preview card renders
```

## Related code files
- Create: `site/src/components/SEO.astro` (single reusable head component)
- Modify: `site/src/pages/index.astro` (import + render `<SEO>` in `<head>`)
- Modify: `site/src/content.config.ts` (add `hero_image`, `description`, `pub_date` to frontmatter schema)
- Modify: any blog post layout used for `ai.hack.ski` (identify during step 1 — may be a separate Astro project outside this repo)
- Verify: `site/astro.config.mjs` → `site` field matches actual deploy URL for the blog host

## Implementation Steps
1. Confirm deploy topology: does `ai.hack.ski` point at THIS Astro site, or a separate
   blog-site repo? Grep → all evidence points to `ai.hack.ski` being a separate deploy.
   **Open question to resolve in Phase 04 work** — answer determines which repo gets
   the SEO component. If same repo, continue here; if separate, fork this phase to
   that repo's worktree.
2. Write `SEO.astro` with required props: `title`, `description`, `image`, `url`,
   `type='article'|'website'`. Default `image` → `/og-default.png` (ship a 1200×627
   default in `public/`).
3. Update content collection schema so MDX posts declare `hero_image` + `description`.
4. Render `<SEO>` in `index.astro` with site-level defaults.
5. Build + preview locally: `cd site && npm run build && npm run preview`.
6. curl the built HTML: `curl -s http://localhost:4321 | grep -E 'og:|twitter:|canonical'`
   — capture to `e2e-evidence/phase-02/step-01-landing-head-meta.txt`.
7. After Phase 04 DNS flips: run each canonical URL through
   https://www.linkedin.com/post-inspector/ and save the "Scraped" screenshot to
   `e2e-evidence/phase-02/step-02-linkedin-inspector-<slug>.png`.
8. Send one test iMessage link-share to Nick's own number, screenshot the preview to
   `e2e-evidence/phase-02/step-03-imessage-preview.png`.

## Todo List
- [ ] Confirm which repo hosts `ai.hack.ski` (same / separate from `site/`)
- [ ] Create `SEO.astro` component
- [ ] Ship `/og-default.png` (1200×627) to `public/`
- [ ] Wire into `index.astro`
- [ ] Extend frontmatter schema for blog posts
- [ ] Local build + curl head-tag check
- [ ] LinkedIn Post Inspector PASS on 3 URLs
- [ ] iMessage unfurl screenshot captured
- [ ] X card validator PASS on 3 URLs

## Success Criteria (functional validation)
- `curl -s https://ai.hack.ski/blog/<slug> | grep 'og:image'` returns a 1200×627
  absolute URL that HTTP 200s via a second curl against that URL.
- LinkedIn Post Inspector renders title + description + hero for all 3 test URLs
  (screenshot saved as evidence).
- iMessage unfurl shows image + title + description (screenshot saved).
- twitter.com card validator returns `summary_large_image` with no warnings.

## Risk Assessment
- **Scraper cache lag:** LinkedIn caches for ~7 days. Must force-refresh via Inspector
  for any URL that was shared before tags existed. Mitigation: run Inspector on all
  19 queue URLs before their slot dates.
- **Absolute URL drift:** If `site` in `astro.config.mjs` is wrong, OG images 404.
  Mitigation: assert absolute URLs resolve in step 6.
- **Starlight conflict:** Starlight already emits some `og:*` for docs pages; ensure
  `<SEO>` doesn't duplicate. Mitigation: only render `<SEO>` on non-Starlight routes
  (`index.astro`, blog post pages).

## Security Considerations
- OG image is public — no secrets embedded. Same image serves all referrers.
- No user-generated content in meta tags (no XSS surface). Frontmatter is trusted.

## Next Steps
- After Phase 02 ships, Phase 06 posts can cite canonical URLs with confidence that
  previews render — a prerequisite for measurable CTR benchmarking per Phase 03.
- Consider: generate per-post OG images from Mermaid diagrams via headless Chromium.
