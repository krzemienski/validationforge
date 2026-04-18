# Cookie-Based Auth — UNOFFICIAL PATH

User explicitly chose this path on 2026-04-18 after full ban-risk briefing.

## What This Is

Uses LinkedIn session cookies (`li_at`, `JSESSIONID`) to authenticate requests
against LinkedIn's internal voyager/api endpoints. No LinkedIn Developer App.
No OAuth. Zero official support from LinkedIn.

## What This Is NOT

- **ToS-compliant.** LinkedIn User Agreement §8 prohibits automated access
  via unofficial APIs.
- **Safe against detection.** LinkedIn runs automation-detection on voyager
  endpoints.
- **Long-lived.** Cookies rotate on logout, password change, or expire in
  2-4 weeks naturally.

## Detection Ladder

| Offense | Consequence |
|---------|-------------|
| 1st detection | Email challenge + 24-72h suspension |
| 2nd detection | 7-day restriction, profile hidden from search |
| 3rd detection | Permanent account termination. No appeal. |

## Why You Chose This Anyway

Trade-off you made: 0-min setup now vs 45-min OAuth setup tonight. Understood.

## Setup

```bash
cd integrations/linkedin-publisher

# 1. Copy template
cp .env.local.example .env.local

# 2. Extract cookies from browser
#    Chrome: DevTools → Application → Cookies → linkedin.com
#    Copy li_at and JSESSIONID. Paste into .env.local.

# 3. Test: identity check (no post)
node src/publish-via-cookie.js me

# 4. Test: dry-run (no network call to publish endpoint)
node src/publish-via-cookie.js dry ../../assets/campaigns/260418-validationforge-launch/copy/linkedin-soft-launch-mon-apr20.md

# 5. Live post (waits 3s, allows Ctrl-C abort)
node src/publish-via-cookie.js post ../../assets/campaigns/260418-validationforge-launch/copy/linkedin-soft-launch-mon-apr20.md
```

## Safety Features Built In

- **Kill switch:** Set `LP_KILL=1` in env to block all real posts.
- **Jitter:** Random 0-3min delay before each live post (reduces scheduled-time
  fingerprint).
- **Cookie redaction:** Logs automatically redact `li_at=` and `JSESSIONID=`
  values if they ever land in error messages.
- **.env.local gitignored:** Primary + defense-in-depth via root `.gitignore`.
- **No disk storage of raw cookies beyond .env.local.**

## Rotation Schedule

- **Every 2 weeks** OR immediately if you see:
  - Email from LinkedIn about "unusual sign-in"
  - CAPTCHA challenge on next browser login
  - Any `401` or `403` from the publisher
- Refresh process:
  1. Log out + log back in on linkedin.com
  2. Re-extract cookies from browser
  3. Update `.env.local`
  4. Test: `node src/publish-via-cookie.js me` should print your name

## Kill Switch Deployment

Put this in your shell:
```bash
# Kill all cookie-based posting immediately (if you see the first detection email)
export LP_KILL=1
```

Or unload launchd if cron-scheduled:
```bash
launchctl unload ~/Library/LaunchAgents/com.validationforge.linkedin-publisher.plist
```

## Migration Path to OAuth (recommended once campaign momentum exists)

When Wave 1 is done (May 1) and the ban risk compounds, switch to OAuth:
1. Register Developer App (still takes 45 min)
2. Run `./bin/lp auth`
3. Update launchd plist to call `bin/lp run` instead of `src/publish-via-cookie.js`
4. Keep cookie script as emergency fallback

## Files

```
integrations/linkedin-publisher/
├── .env.local.example                    # template (committed)
├── .env.local                            # YOUR COOKIES (gitignored, never commit)
├── .lp-cookie.log                        # runtime log, cookies redacted (gitignored)
├── src/publish-via-cookie.js             # the client
└── COOKIE-AUTH.md                        # this doc
```

## Final Reminder

Every `node publish-via-cookie.js post` is a roll of the dice on your personal
account. The campaign's consulting ROI depends on this account surviving 10
weeks. Be selective about when to use it vs manual-post.
