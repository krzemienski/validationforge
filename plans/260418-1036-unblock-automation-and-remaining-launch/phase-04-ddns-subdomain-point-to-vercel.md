# Phase 04 — Point ai.hack.ski Subdomain at Vercel Deployment

## Context
- Parent plan: [plan.md](./plan.md)
- Depends on: nothing — pure infra
- Blocks: Phase 02 (OG tags need stable URL), Phase 03 (GA4 stream URL needs
  production host), Phase 06 (every blog-post slot cites `https://ai.hack.ski/blog/...`)

## Overview
Blog-series posts are cited as `https://ai.hack.ski/blog/<slug>` across the campaign
(confirmed in `staged-readme-patches/validationforge-README.md`). Currently only a
path-rewrite works — the apex subdomain is not pointed at the Vercel project hosting
the blog. Result: LinkedIn previews fail, analytics misattribute, and the Week 1-10
calendar's canonical URLs are unreliable. This phase produces a functioning
`ai.hack.ski → Vercel` DNS path with a valid TLS cert.

## Key Insights
- `hack.ski` is a DDNS-managed apex (per phase title) — DNS provider is **unknown**
  and not in the repo. User input required (see Open Questions).
- Vercel requires either (a) `CNAME ai.hack.ski → cname.vercel-dns.com` or (b) for
  apex, an A record to `76.76.21.21`. For a subdomain, CNAME is correct.
- The Vercel project hosting the blog is also **unknown** — master calendar references
  `site-rho-pied.vercel.app` as the current blog deployment. That's a Vercel
  default URL, not a named project.
- TLS is auto-provisioned by Vercel once the DNS record validates.
- Propagation: CNAME for subdomain typically resolves in 5-60 minutes.

## Requirements
1. `dig ai.hack.ski CNAME` returns `cname.vercel-dns.com.` (or equivalent Vercel host).
2. `curl -Iv https://ai.hack.ski` returns HTTP 200 with a valid LetsEncrypt/Vercel cert.
3. `curl -s https://ai.hack.ski/blog/<any-slug>` returns the expected post HTML
   (not a 404 or Vercel default).
4. `https://site-rho-pied.vercel.app/blog/<slug>` and `https://ai.hack.ski/blog/<slug>`
   serve the same content (confirms project is correctly aliased).
5. Old path-rewrite URLs 301 to the new canonical host (or are retired cleanly).

## Architecture
```
User → DNS resolver
  → ai.hack.ski CNAME → cname.vercel-dns.com
  → Vercel edge picks project by domain alias
  → serves site-rho-pied (or newly-named project) content
  → TLS cert auto-provisioned on first request
```

## Related code files
- No repo-level code changes in THIS repo — DNS + Vercel dashboard work.
- If same Vercel project also serves `validationforge.dev`, verify project domain
  alias list does not conflict. Check: `vercel domains ls` + `vercel project ls`.
- Document the final mapping in `docs/integrations/ai-hack-ski-dns.md` (create it)
  so future operators know the source of truth.

## Implementation Steps
1. **User input gate:** confirm DNS provider for `hack.ski` (likely Cloudflare,
   Namecheap, or Google Domains — user must tell us) and Vercel project name.
2. Login to Vercel → find project serving `site-rho-pied.vercel.app`. Note project
   ID + team. Settings → Domains → Add `ai.hack.ski`. Copy the CNAME target Vercel
   displays (e.g. `cname.vercel-dns.com`).
3. Login to DNS provider. Add record: `Type=CNAME Name=ai Value=cname.vercel-dns.com TTL=3600`.
4. Wait for Vercel dashboard to flip `ai.hack.ski` from "Invalid Configuration" to
   "Valid" (green checkmark + cert icon). Screenshot to
   `e2e-evidence/phase-04/step-01-vercel-domain-valid.png`.
5. `dig ai.hack.ski +short` — expect CNAME or resolved A.
   Capture to `e2e-evidence/phase-04/step-02-dig-output.txt`.
6. `curl -IL https://ai.hack.ski` — expect final HTTP 200 and a cert chain from Let's
   Encrypt. Capture headers to `e2e-evidence/phase-04/step-03-curl-headers.txt`.
7. `curl -s https://ai.hack.ski/blog/post-01-launch-day | head -40` — expect MDX
   rendered output, not a 404. Capture to `e2e-evidence/phase-04/step-04-content.html`.
8. Update `docs/integrations/ai-hack-ski-dns.md` with the final DNS record and
   Vercel project ID for future-Nick.

## Todo List
- [ ] Confirm DNS provider for hack.ski (user input)
- [ ] Confirm Vercel project name + team (user input, or `vercel project ls`)
- [ ] Add ai.hack.ski alias in Vercel dashboard
- [ ] Add CNAME record at DNS provider
- [ ] Wait for Vercel green-check (TLS provisioned)
- [ ] dig + curl evidence captured
- [ ] Blog content renders at final URL
- [ ] Document source-of-truth in docs/integrations/

## Success Criteria (functional validation)
- `dig ai.hack.ski` resolves to a Vercel CNAME target (evidence file).
- `curl -IL https://ai.hack.ski` → HTTP 200 with valid TLS (evidence file shows cert
  subject / issuer from the `-v` output).
- Browser visit shows actual blog homepage, not a Vercel default landing (screenshot
  in evidence).
- LinkedIn Post Inspector can fetch `https://ai.hack.ski/blog/<slug>` without error
  (feeds Phase 02 validation).

## Risk Assessment
- **DNS propagation delay:** up to 48h worst case. Most CNAMEs land in minutes.
  Mitigation: start this phase first — it is the critical path bottleneck.
- **Wrong Vercel project:** aliasing `ai.hack.ski` to a non-blog project serves the
  wrong content. Mitigation: step 7 verifies correct content before moving on.
- **`hack.ski` apex ownership ambiguity:** if the apex is shared infra (family /
  other projects), adding a subdomain must not break sibling records. Mitigation:
  inspect all existing records at the DNS provider before adding.
- **DDNS conflict:** phase title says "DDNS" — if `hack.ski` is updated dynamically
  by a Dyn client, manual CNAMEs may get stomped. Mitigation: add the CNAME in the
  DDNS management interface, not the raw DNS provider.

## Security Considerations
- DNS provider access = full apex control. Verify MFA is enabled on the provider
  account before making changes.
- Do not log the DNS provider API key into chat or commits.
- Vercel deployment is public; no secrets leak via DNS flip itself.

## Next Steps
- After Phase 04 ships, Phase 02 (OG tags) and Phase 03 (GA4) unblock immediately.
- Consider: add an AAAA record for IPv6 readiness once CNAME is stable.

## Open Questions (blocking — need user input)
1. **DNS provider for hack.ski** — Cloudflare? Namecheap? Google Domains? Dynv6 or
   other DDNS host?
2. **Vercel project name** currently serving `site-rho-pied.vercel.app` — is this
   already on Nick's Vercel account, or someone else's team?
3. **Does `www.hack.ski` or apex `hack.ski` also need aliasing**, or only the
   `ai.` subdomain?
