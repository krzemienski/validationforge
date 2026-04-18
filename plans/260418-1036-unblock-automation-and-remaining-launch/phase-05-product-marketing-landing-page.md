# Phase 05 — Product/Marketing Landing Page (Value Board Site)

## Context
- Parent plan: [plan.md](./plan.md)
- Depends on: nothing hard; benefits from Phase 04 (stable host) + Phase 02 (OG tags)
- Blocks: Show HN drop (2026-04-28) — landing should exist before HN traffic lands

## Overview
Today, inbound from LinkedIn/HN/Reddit hits the GitHub README. The README is a
technical artifact — dense, no narrative arc, no conversion funnel, no "what is VF
in 30 seconds." The `site/src/pages/index.astro` already has a strong scaffolded
marketing page (hero, iron rule, why-not-mocks table, 5-scenarios demo, features,
pipeline, CTA) but it's **not yet deployed to a public URL** and has several
placeholder sections (demo GIF, comparison page, `/quickstart`, `/installation`
routes linked but missing). Ship the consolidated value-board site before Show HN.

## Key Insights
- The heavy lift is done — `index.astro` is ~730 lines of hand-coded marketing copy
  with styling. Gaps are at the edges (missing sub-pages, missing demo GIF, nav
  links to 404s).
- Show HN on 2026-04-28 = 10 days from today (2026-04-18). Every hour before Apr 28
  is prep time.
- "Value board" per user language = the 5-scenarios section — already exists. Keep
  it as the centerpiece and polish around it.
- GitHub README can later add a "Featured on validationforge.dev" badge pointing at
  the new landing, creating a reciprocal link.

## Requirements
1. Landing page deploys to a public URL (`validationforge.dev` per astro.config.mjs,
   or subpath — decide in step 1).
2. Every nav link in the landing resolves to a real page, not a 404: `/docs`,
   `/installation`, `/commands`, `/comparison`, `/quickstart`.
3. The "Demo GIF — Coming Soon" placeholder is replaced with an actual 30-second
   screencast (or the section is temporarily removed).
4. Primary install snippet is `curl -fsSL .../install.sh | bash` — verify the URL
   returns HTTP 200 and the script actually installs VF.
5. Lighthouse score: Performance >85, Accessibility >90, SEO >95 on production URL.
6. Mobile viewport (375×667) renders without horizontal scroll.

## Architecture
```
User lands on validationforge.dev (from HN/LinkedIn/direct)
  → hero + iron rule (above fold)
  → why-not-mocks table (anchors the thesis)
  → 5-scenarios demo GIF + cards (emotional proof)
  → features grid (what you get)
  → 7-phase pipeline (how it works)
  → CTA + install snippet (conversion)
  → footer
  ↳ any nav click → /installation, /docs, /commands, /comparison
```

## Related code files
- Modify: `site/src/pages/index.astro` (polish: replace demo placeholder, verify all links)
- Create: `site/src/pages/installation.astro` (install steps, troubleshooting, requirements)
- Create: `site/src/pages/quickstart.astro` (5-min first-validation walkthrough)
- Create: `site/src/pages/comparison.astro` (VF vs unit tests vs Playwright alone)
- Modify: `site/src/content/docs/` (ensure `/docs` has at least a landing file)
- Add: `site/public/demo.mp4` or `site/public/demo.gif` (30s screencast)
- Add: `site/public/og-default.png` (1200×627 for Phase 02)
- Modify: `site/public/robots.txt` (allow all, add sitemap reference)

## Implementation Steps
1. **Decide canonical URL**: is the value-board at `validationforge.dev` or
   `ai.hack.ski/validationforge`? Recommend `validationforge.dev` (matches
   astro.config.mjs already).
2. Audit nav + footer links in `index.astro` — list every href, check it resolves
   after `npm run build`. Create stub pages for 404s.
3. Create `installation.astro` from scaffold: OS-specific install blocks (macOS,
   Linux, Windows WSL), verification step, common errors.
4. Create `quickstart.astro`: 5-minute walkthrough — `/vf-setup`, first `/validate`,
   read the generated report.
5. Create `comparison.astro`: port the existing why-not-mocks table into a full
   comparison page with a 3rd column for Playwright-alone.
6. Record 30-second demo: use `asciinema` or native macOS `ScreenCaptureKit` to
   record `/validate` against a seeded bug. Export to MP4 + GIF. Place in `public/`.
   Update `index.astro` placeholder to `<video>` element.
7. Build: `cd site && npm run build`. Verify `dist/` exists + all routes emit HTML.
8. Deploy to Vercel. Capture deploy URL.
9. Run Lighthouse (headless Chromium) against the deploy URL. Save full report HTML
   to `e2e-evidence/phase-05/step-01-lighthouse.html`.
10. Mobile screenshot at 375×667 via Playwright headless. Save to
    `e2e-evidence/phase-05/step-02-mobile-viewport.png`.
11. Curl-follow the install snippet URL — confirm HTTP 200 + valid bash script.
    Save first 50 lines of the script to `e2e-evidence/phase-05/step-03-install-head.txt`.

## Todo List
- [ ] Pick canonical domain
- [ ] Audit + fix all nav/footer hrefs
- [ ] Write `installation.astro`
- [ ] Write `quickstart.astro`
- [ ] Write `comparison.astro`
- [ ] Record + embed 30s demo
- [ ] Build clean (zero warnings)
- [ ] Deploy to production URL
- [ ] Lighthouse evidence
- [ ] Mobile viewport evidence
- [ ] Install script reachable
- [ ] Cross-link from GitHub README

## Success Criteria (functional validation)
- Production URL returns HTTP 200 + full HTML (not Vercel default).
- All 5 nav links resolve (no 404s) — each verified via curl -w "%{http_code}".
- Lighthouse report (saved HTML file in evidence) shows Performance ≥85, A11y ≥90,
  SEO ≥95.
- Mobile screenshot at 375×667 shows no horizontal scroll, hero text not truncated.
- Fresh-machine install: run the install snippet in a clean Docker container —
  confirm it completes with exit 0 and `/validate --help` works after.

## Risk Assessment
- **Apr 28 deadline pressure:** Show HN requires the site to exist before the post
  goes live. Mitigation: start TODAY, accept a v0.5 landing (no demo video) rather
  than missing the window.
- **Demo recording quality:** a bad demo GIF hurts more than no GIF. Mitigation:
  record 3 takes, pick the cleanest. Acceptable fallback: high-quality static
  screenshot of a real evidence report PDF.
- **Nav 404s:** first-time visitors clicking `/comparison` and hitting 404 destroys
  trust. Mitigation: step 2 is the hard gate — no deploy until every link resolves.
- **Install script regression:** if someone pushes a breaking change to `install.sh`,
  the hero snippet silently breaks. Mitigation: the step-3 evidence check should be
  repeated in CI / before every HN push.

## Security Considerations
- Install snippet executes piped bash — standard pattern for dev tools but user-facing
  risk. Add a "Want to see the script first?" link below the snippet pointing to the
  raw file on GitHub so paranoid users can audit before running.
- No forms, no auth, no cookies beyond GA (Phase 03) — minimal attack surface.
- `robots.txt`: allow all; don't accidentally block crawlers.

## Next Steps
- After Phase 05 ships: update GitHub repo description + topics to include
  `validationforge.dev` URL.
- Consider: A/B test two hero variants (current "Ship verified code" vs. a
  question-led hook) once GA has baseline traffic.
