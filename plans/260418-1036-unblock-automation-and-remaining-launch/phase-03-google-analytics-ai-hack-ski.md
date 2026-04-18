# Phase 03 — Google Analytics 4 on ai.hack.ski

## Context
- Parent plan: [plan.md](./plan.md)
- Depends on: nothing (runs parallel to 02/04)
- Blocks: nothing hard; unlocks KPI measurement for Phase 06 weekly gate reviews

## Overview
The `10-week-master-calendar.md` Performance Gates (green/yellow/red/black) key off
weekly traffic and conversion deltas. Today we have zero first-party traffic data on
`ai.hack.ski`. Install GA4 so every blog-post slot in Weeks 1-10 produces a measurable
pageview/session/referrer dataset. Without this, Sunday performance reviews are blind
and cadence decisions are guesses.

## Key Insights
- GA4 via `gtag.js` is the lowest-friction install — single `<script>` tag in `<head>`.
- Events worth instrumenting beyond default pageview: `outbound_click` (GitHub repo
  links — the conversion event), `scroll` (already default in GA4), `file_download`
  (PDF / hero images).
- Starlight's `head` config accepts arbitrary `<script>` entries — same mechanism as
  the existing `twitter:card` meta in `astro.config.mjs`.
- Cookie consent: Nick is a US-only audience today, but to keep EU doors open, ship
  a minimal consent banner that gates the `gtag('config', ...)` call.

## Requirements
1. GA4 property created, Measurement ID (`G-XXXXXXXXXX`) stored in `SITE_GA_ID` env
   var, not hardcoded.
2. `gtag.js` loads on every page of the `ai.hack.ski` host.
3. Outbound link clicks to `github.com/krzemienski/*` fire a `outbound_click` event
   with `link_url` as param.
4. Referrer tracking works: GA4 Real-time shows `linkedin.com`, `news.ycombinator.com`,
   `t.co`, `reddit.com` sources during a live test.
5. Consent: Regional consent mode default = `denied` for `ad_*`, `granted` for
   `analytics_storage` (first-party measurement, not ads).

## Architecture
```
Page request
  → <head> loads gtag.js with SITE_GA_ID
  → default_consent: analytics=granted, ads=denied
  → pageview auto-fires
  → click on outbound anchor [href^=github] → gtag('event', 'outbound_click', {...})
  → GA4 collects → Looker Studio dashboard reads weekly
```

## Related code files
- Create: `site/src/components/Analytics.astro` (gtag loader + consent init)
- Modify: `site/src/pages/index.astro` (inject `<Analytics />` near bottom of `<body>`)
- Modify: `site/astro.config.mjs` → Starlight `head` config (for docs pages)
- Modify: `.env.example` + local `.env` (add `SITE_GA_ID`)
- Verify: same install applied to the `ai.hack.ski` host repo if separate (see Phase 02)

## Implementation Steps
1. Create GA4 property at analytics.google.com — Property name: "ai.hack.ski",
   stream URL: `https://ai.hack.ski`. Capture Measurement ID.
2. Store ID in `.env` as `SITE_GA_ID=G-XXXXXXXXXX`. Add to `.env.example` with
   placeholder. Never commit the real value.
3. Write `Analytics.astro` reading `import.meta.env.PUBLIC_SITE_GA_ID` (PUBLIC_ prefix
   so Astro exposes it to client bundle).
4. Inject in `index.astro` and Starlight `head`.
5. Deploy preview. Open page → GA4 Real-time dashboard should show the session.
6. Click a GitHub outbound link → verify `outbound_click` event appears in Real-time.
7. Visit via `linkedin.com/...` tracked URL → verify referrer shows `linkedin.com`
   in Acquisition → Traffic Sources.
8. Capture screenshots of all three Real-time validations to
   `e2e-evidence/phase-03/step-{01,02,03}-ga4-*.png`.

## Todo List
- [ ] Create GA4 property for ai.hack.ski
- [ ] Write `Analytics.astro` component
- [ ] Wire into landing + docs pages
- [ ] Add `PUBLIC_SITE_GA_ID` to `.env.example`
- [ ] Deploy to staging / preview
- [ ] Real-time pageview screenshot
- [ ] Outbound click event screenshot
- [ ] Referrer attribution screenshot
- [ ] Add GA4 dashboard link to `tracking/measurement-plan.md`

## Success Criteria (functional validation)
- GA4 Real-time view shows active user within 10 seconds of a live page visit
  (screenshot with URL visible in evidence).
- `outbound_click` event visible in GA4 DebugView after clicking a GitHub link from
  a production page (screenshot).
- One full week of data accumulates (Apr 25 check-in) with non-zero sessions —
  proves tag is still live after a deploy cycle, not just at install time.
- Weekly Sunday performance gate review cites a GA4 number (impressions, sessions,
  or outbound clicks) in the logged decision.

## Risk Assessment
- **Ad-blocker skew:** uBlock / Brave block `gtag.js` — expect 20-40% undercount.
  Acceptable for directional trend data, not absolute counts. Mitigation: cross-check
  against GitHub repo star delta (harder to block) as a sanity signal.
- **Wrong property ID:** If `SITE_GA_ID` points at a stale property, data lands in
  the void. Mitigation: DebugView during step 6 shows the exact property receiving
  the hit — eyeball before declaring PASS.
- **Consent false-negative:** Consent default too strict = zero data. Mitigation: US
  visitors get `analytics_storage=granted` by default; EU path is a future phase.

## Security Considerations
- GA4 Measurement ID is public by design (shipped to client). No secret to protect.
- No PII collected. Do not set `user_id` or custom dimensions with email / name.
- Disable Google Signals in property settings (avoids ad-graph joining).

## Next Steps
- After Phase 03 ships + 1 week of data, wire a weekly Looker Studio report emailed
  Sunday 3pm ET as input to the performance-gate Sunday review ritual.
- Consider: add Plausible or PostHog as a self-hosted second source for cross-check.
