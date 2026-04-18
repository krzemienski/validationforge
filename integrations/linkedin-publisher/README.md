# linkedin-publisher

> **Status: SCAFFOLD — requires LinkedIn app registration before use.**

Autonomous LinkedIn publishing for Nick Krzemienski's ValidationForge campaign.
File-based queue + cron + LinkedIn Posts API. No third-party services.

## Why this exists

The 10-week launch campaign generates ~20 LinkedIn posts. This tool publishes them
on schedule without manual copy-paste. Reuses markdown bodies in
`copy/blog-series-adapted/` and hero images in `creatives/screenshots/`.

## Setup (one-time, ~30 min)

### 1. Register a LinkedIn Developer App

1. Visit https://www.linkedin.com/developers/apps and click **Create app**.
2. Associate with a LinkedIn Company Page (any page Nick owns — placeholder OK).
3. Fill app name, logo, terms-of-use URL.
4. Open the **Products** tab and request:
   - **Sign In with LinkedIn using OpenID Connect** (auto-approved)
   - **Share on LinkedIn** (auto-approved, grants `w_member_social`)
5. Open the **Auth** tab and:
   - Copy `Client ID` and `Client Secret`
   - Add Authorized Redirect URL: `http://localhost:3000/callback`

### 2. Install dependencies

```bash
cd integrations/linkedin-publisher
npm install
```

Requires Node 22 LTS (matches dashboard convention).

### 3. Configure environment

```bash
cp .env.example .env
# edit .env, fill LINKEDIN_CLIENT_ID and LINKEDIN_CLIENT_SECRET
```

### 4. Run OAuth flow (captures access + refresh tokens)

```bash
./bin/lp auth
```

This:
- Opens a browser to LinkedIn's consent screen
- Listens on `localhost:3000` for the callback
- Writes `LINKEDIN_ACCESS_TOKEN`, `LINKEDIN_REFRESH_TOKEN`, `LINKEDIN_PERSON_URN` back into `.env`

**Token lifetime:** access = 60 days, refresh = 365 days. The publisher auto-refreshes on expiry.

### 5. Test (dry-run, no real post)

```bash
./bin/lp test --md ../../copy/blog-series-adapted/post-01.md
```

Prints what would be sent to LinkedIn. No network call to publish endpoint.

## Daily Use

### Queue subcommands

```bash
# Add one post
./bin/lp queue add ../../copy/blog-series-adapted/post-01-linkedin.md \
  --at 2026-04-21T12:30:00Z \
  --media ../../creatives/screenshots/hero-01.png

# Show everything in the queue, grouped by status
./bin/lp queue list

# Preview the next due item + countdown (no publish)
./bin/lp queue peek

# Process any items whose scheduled_at <= now
./bin/lp queue next              # live publish
./bin/lp queue next --dry        # dry-run (no HTTP POST to /rest/posts)
./bin/lp run                     # legacy alias for `queue next`
```

All queue ops are idempotent on `linkedin-queue.json`. Items transition
`queued → published | dry-run | failed` with ISO timestamps + post URN captured.

### 401 retry

If LinkedIn rejects a publish with `401 unauthorized` (token revoked or expired
between the start of `queue next` and the POST call), the publisher refreshes
via `getValidAccessToken()`'s refresh-token path and retries the publish ONCE.
Subsequent 401s leave the item as `failed` with the LinkedIn error body.

### Autonomous launchd schedule (Mon + Thu, 8:30am ET)

A launchd plist ships with the integration:
`com.validationforge.linkedin-publisher.plist`. It invokes `bin/lp run`
(which aliases to `queue next`) with Node 22 from Homebrew, at local-TZ
08:30 on Weekdays 1 (Mon) and 4 (Thu). launchd uses system timezone, so no
UTC math required.

```bash
# Install
cp com.validationforge.linkedin-publisher.plist ~/Library/LaunchAgents/
launchctl load -w ~/Library/LaunchAgents/com.validationforge.linkedin-publisher.plist

# Verify loaded
launchctl list | grep validationforge

# Check logs after first fire
tail -f .lp.log

# Wake-dependency note: macOS launchd only fires while the Mac is awake.
# For autonomy: `sudo pmset repeat wakeorpoweron MTh 08:25:00` (wake 5 min early).

# Unload when retiring
launchctl unload ~/Library/LaunchAgents/com.validationforge.linkedin-publisher.plist
```

## Files

```
integrations/linkedin-publisher/
├── README.md              ← this file
├── package.json           ← Node 22 dependencies
├── .env.example           ← credentials template
├── linkedin-queue.example.json
├── bin/lp                 ← CLI entry
└── src/
    ├── auth.js            ← OAuth flow + token refresh
    ├── publish.js         ← POST to /rest/posts
    ├── upload-media.js    ← image upload helper
    └── schedule.js        ← queue reader + cron-like runner
```

## Caveats

- **App registration required.** This scaffold cannot run without a real LinkedIn app + OAuth grant.
- **Cron requires online host.** If running locally, your Mac must be awake at the cron time. For full autonomy, deploy to a VPS or use GitHub Actions scheduled workflows.
- **Engagement still manual.** Replies to comments need human presence — this tool publishes only.
- **API versioning.** Pinned to `LinkedIn-Version: 202504`. Bump quarterly per LinkedIn deprecation calendar.
- **Rate limits.** ~100 posts/day per member. Nick's 2/week cadence is 0.3% of quota.

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `401 unauthorized` on publish | Token expired. Run `./bin/lp auth` again or check refresh logic in `src/auth.js`. |
| `403 forbidden, scope w_member_social missing` | App doesn't have "Share on LinkedIn" product. Re-add in Developer Portal. |
| `422 invalid author URN` | `LINKEDIN_PERSON_URN` in `.env` is wrong. Run `./bin/lp auth` to refresh it. |
| Image upload fails | Check the file path is absolute and the image is JPG/PNG under 10MB. |

## Sources

See companion research: `plans/reports/researcher-260418-0610-linkedin-publishing-options.md`
