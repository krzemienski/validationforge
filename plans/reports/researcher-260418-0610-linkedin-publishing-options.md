# LinkedIn Auto-Publishing — Options Research (2026-04-18)

**Use case:** Nick Krzemienski, single-author, ~2 posts/week, 10-week launch campaign, may extend.

## Recommendation: PATH A (Official LinkedIn API) — with caveat

Single-author + low cadence + already programmatic content pipeline = LinkedIn API direct is the right fit. Cost: $0. Setup: ~30 min. Token refresh straightforward. The only blocker (Community Management API) does NOT apply because Nick is posting as a member, not as an organization page.

Fall back to Path B (Buffer) ONLY if: (a) Nick wants a managed UI/dashboard, (b) needs cross-posting to other networks, or (c) LinkedIn rejects his app's `w_member_social` access for his use case (rare for personal posting).

---

## Path A: Official LinkedIn API

### App Registration
1. Go to https://www.linkedin.com/developers/apps
2. Create app → associate with a LinkedIn Company Page (required even for personal posting; can be a placeholder page Nick owns)
3. Under **Products** tab, request **"Sign In with LinkedIn using OpenID Connect"** + **"Share on LinkedIn"** — both are self-service, auto-approved within minutes
4. Capture `Client ID` + `Client Secret` from Auth tab
5. Add OAuth redirect URL (e.g., `http://localhost:3000/callback` for local OAuth flow)

### Required Scopes
- `openid`, `profile`, `email` — get the member URN (needed as author of post)
- `w_member_social` — publish posts/comments/likes on member's behalf (auto-granted via Share on LinkedIn product)

### Endpoints (2026 current)
- **Posts API** (current): `POST https://api.linkedin.com/rest/posts` — replaces deprecated UGC Posts API. Use header `LinkedIn-Version: 202504` (or current monthly version).
- **UGC Posts API** (legacy, still works): `POST https://api.linkedin.com/v2/ugcPosts` — older but well-documented; many tutorials still reference it.
- **Media upload** (2-step): `POST /v2/assets?action=registerUpload` → returns upload URL → `PUT` binary to that URL → reference returned `asset` URN in post body.

### Rate Limits (2026)
- ~100–500 calls/day per member, scope-dependent. `w_member_social` posting: comfortably 100/day. Nick at 2 posts/week = 0.3% of quota. Non-issue.
- Throttling is per (app, member, scope) — Nick is the only member, so no contention.

### Token Lifecycle
- **Access token:** 60 days (5184000 seconds). Long enough that for a 10-week campaign Nick may not need refresh at all if he re-auths once mid-campaign.
- **Refresh token:** 365 days. Use `grant_type=refresh_token` against `/oauth/v2/accessToken`.
- Refresh tokens are NOT auto-rotated — same refresh token works for full year.

### Pros
- Free, no third-party dependency
- Direct control: queue logic + cron + publishing all in Nick's repo
- Tokens last 60 days → minimal maintenance
- Can be invoked from same content-pipeline scripts producing the markdown

### Cons
- Must register an app + complete OAuth dance once
- No built-in scheduling UI (we build minimal CLI)
- API versioning: LinkedIn ships monthly versions; pin one and revisit quarterly
- App must be associated with a Company Page (even placeholder is fine)

### Source credibility
- LinkedIn/Microsoft Learn (`learn.microsoft.com/linkedin/...`) = authoritative
- 2025/2026 third-party guides (apidog, zernio, outx) corroborate token TTL + scope details
- Cross-validation: 4+ sources agree on scopes, 60-day access TTL, Posts-API-replaces-UGC

---

## Path B: Third-Party Services

| Service | LinkedIn Programmatic API | Personal-Brand Pricing | Media Support | Verdict for Nick |
|---------|---------------------------|------------------------|---------------|------------------|
| **Buffer** | Public API exists (legacy v1, limited); newer features UI-only. Zapier integration mature. | $6/mo per channel (LinkedIn = 1 channel = $6). | Images, video. | Cheap, but API is dated; would still need OAuth + same setup work as direct LinkedIn. No win. |
| **Typefully** | Public API + native MCP integration (AI-friendly). | $12.50/mo Starter, $19 Creator. | Images + threads. LinkedIn support added 2024. | Best-in-class for AI/programmatic workflows BUT was X-first; LinkedIn parity still catching up. |
| **Hypefury** | No public API. Some Zapier triggers. | $19–$49/mo. | Images, threads. | Disqualified — no API. |
| **Mixpost / Postiz / Publer** | Self-hosted options with APIs exist | Varies / free tier | Yes | Heavyweight; overkill for 2 posts/week. |

### Trade-offs
- **Buffer**: cheapest but adds a layer (OAuth to Buffer + Buffer→LinkedIn) for no real benefit at single-author scale. Also: Buffer API publishing has historically lagged direct LinkedIn API (delayed posts, occasional silent failures).
- **Typefully**: strongest API/MCP story, but $12.50/mo × 12 = $150/yr for what direct API does free. Worth it only if Nick wants the polished web UI for non-programmatic edits.
- **Adoption risk**: third-party tools depend on LinkedIn's good graces. Buffer/Hypefury have all had LinkedIn API outages in 2024–2025. Direct API = one fewer point of failure.

---

## Trade-Off Matrix (ranked)

| Dimension | Path A (Direct) | Path B (Buffer) | Path B (Typefully) |
|-----------|-----------------|-----------------|---------------------|
| Setup complexity | Medium (OAuth once) | Medium (Buffer + LinkedIn auth) | Low (UI-driven) |
| Cost / 10-wk campaign | $0 | ~$15 | ~$31 |
| Programmatic control | Full | Partial | Good |
| Maintenance | Low (refresh ~yearly) | Low | Low |
| Vendor lock-in | None | Buffer-shaped | Typefully-shaped |
| Failure modes | LinkedIn-only | LinkedIn + Buffer | LinkedIn + Typefully |
| Fits content pipeline | Best (same repo) | OK | OK |

---

## Adoption Risk Assessment (Path A)

- **API stability:** LinkedIn versions monthly but maintains old versions ~12 months. Pin a version, monitor deprecation notices.
- **App rejection risk:** LOW for `w_member_social` self-service flow. Only Community Management API requires legal-entity registration + rejection-prone review.
- **Token revocation:** LinkedIn may revoke tokens on policy violations. Posting Nick's own original content presents no risk.
- **Rate-limit risk:** Negligible at 2 posts/week.

## Architectural Fit

Already-existing assets:
- `creatives/screenshots/` — hero PNGs to attach
- `copy/blog-series-adapted/` — markdown bodies to publish
- `assets/campaigns/.../execution/10-week-master-calendar.md` — schedule source-of-truth

Path A integration: file-based queue (JSON) → cron → Node CLI. Zero new infra. Reuses existing markdown directly.

---

## Unresolved Questions

1. Does Nick already own a LinkedIn Company Page to associate the app with? If not, ~5 min to create a placeholder.
2. Where will the cron job run? Local Mac (must be online + awake) vs. cheap VPS ($5/mo) vs. GitHub Actions scheduled workflow (free, but needs token storage in GH Secrets).
3. Does Nick want post images or text-only? Text-only ships faster (skip media-upload flow on first run).
4. LinkedIn API version pin: recommend `202504` initially; revisit at week 6.

---

## Sources

- [UGC Post API – Microsoft Learn](https://learn.microsoft.com/en-us/linkedin/compliance/integrations/shares/ugc-post-api)
- [Compliance API Request Limits and Patterns – Microsoft Learn](https://learn.microsoft.com/en-us/linkedin/compliance/request-limits-and-patterns)
- [Community Management API Overview – Microsoft Learn](https://learn.microsoft.com/en-us/linkedin/marketing/community-management/community-management-overview)
- [Increasing Access – Microsoft Learn](https://learn.microsoft.com/en-us/linkedin/marketing/increasing-access)
- [LinkedIn Posting API Guide 2026 – Zernio](https://zernio.com/blog/linkedin-posting-api)
- [LinkedIn API Complete Guide 2026 – apidog](https://apidog.com/blog/linkedin-api/)
- [LinkedIn API Guide 2026 – outx](https://www.outx.ai/blog/linkedin-api-guide)
- [Typefully Pricing](https://typefully.com/pricing)
- [Hypefury Pricing 2026 – wearefounders](https://www.wearefounders.uk/what-is-hypefury-and-how-can-it-help-me/)
- [Buffer Alternative Review – Typefully Blog](https://typefully.com/blog/buffer-review-alternative)
