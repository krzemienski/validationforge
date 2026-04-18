# Phase 2 — LinkedIn Publisher Setup

## 1. Context Links

- Parent plan: [plan.md](plan.md)
- LinkedIn publisher scaffold: `integrations/linkedin-publisher/README.md`
- LinkedIn auth + CLI: `integrations/linkedin-publisher/bin/lp`, `src/auth.js`, `src/publish.js`, `src/schedule.js`
- Researcher Path-A/B analysis: `plans/reports/researcher-260418-0610-linkedin-publishing-options.md`
- Master calendar §LinkedIn Auto-Publishing: `assets/campaigns/260418-validationforge-launch/execution/10-week-master-calendar.md`

## 2. Overview

- **Date range:** Days 1-3, 2026-04-18 (Sat) → 2026-04-28 (Tue, Show HN day — must be live by then for Wave 1 late-sprint)
- **Priority:** P1 — enables Mon/Thu autopost cadence; degrades to manual-post if blocked
- **Status:** pending
- **Description:** Register LinkedIn Developer App, complete OAuth, queue the first 14 days of posts, commit to a cron host strategy, and prove one successful dry-run. Must be live before Show HN Day 11 (Tue Apr 28) so HN-day engagement isn't competing with copy-paste labor.
- **Estimated effort:** 4 hours

## 3. Key Insights

- Scaffold already exists — no code to write. All work is OAuth/config/scheduling operational.
- LinkedIn Developer App requires a **Company Page association**. If Nick lacks one, a placeholder Company Page can be created in ~5 minutes with no public commitment.
- Access token lifetime = 60 days, refresh = 365. Publisher auto-refreshes. One successful auth covers the entire 10-week launch window.
- Cron host decision: **Local Mac launchd** (user choice 2026-04-18). Plist template committed at `integrations/linkedin-publisher/com.validationforge.linkedin-publisher.plist` — NOT loaded yet (load only after VG-3 PASS). Awake dependency accepted; mitigation via `pmset repeat wakeorpoweron MTh 08:25:00` (wakes Mac 5min before fire). Manual fallback doc (MANUAL-FALLBACK.md) covers travel/sleep days.
- LinkedIn posting: post authorship uses personal URN (`urn:li:person:{sub}` via `/v2/userinfo`, auto-captured by `auth.js:128-135`). Developer App STILL requires Company Page association at creation — placeholder page acceptable. These are separate concerns.
- Publisher handles LinkedIn only — X/Reddit/HN/Discord remain manual.
- **Contingency matters:** OAuth can fail (company-page requirement, API quota review, scope drift). Manual-post fallback for Days 1-14 is viable because the first 5 posts are hand-crafted anyway.

## 4. Requirements

### Functional
- LinkedIn Developer App created, associated with a Company Page, **Sign In with LinkedIn (OIDC)** + **Share on LinkedIn** products enabled, scope `w_member_social` granted.
- `integrations/linkedin-publisher/.env` populated with `LINKEDIN_CLIENT_ID`, `LINKEDIN_CLIENT_SECRET`, `LINKEDIN_ACCESS_TOKEN`, `LINKEDIN_REFRESH_TOKEN`, `LINKEDIN_PERSON_URN`.
- `bin/lp test --md <path>` succeeds on at least 3 of the Week 1-2 post bodies (dry-run).
- `bin/lp queue add` populated for first 14 days of posts (Days 1-14 / 2026-04-20 → 2026-05-01) with correct UTC timestamps.
- One real publish via `bin/lp run` succeeds before Fri Apr 24 (Day 7 mid-sprint review), covering the soft-launch or Part 1 post automatically.
- Cron host committed: decision documented in `integrations/linkedin-publisher/.cron-host.md` with rationale.
- Manual-post fallback checklist exists at `integrations/linkedin-publisher/MANUAL-FALLBACK.md` — copy-paste ritual + screenshot evidence template.

### Non-Functional
- Credentials live in `.env` only; `.gitignore` already excludes `.env` (verify).
- No secrets logged to stdout during `bin/lp` runs.
- Cron host must survive 70-day campaign window without babysitting.

## 5. Architecture — Order of Operations

```
Day 1 (Sat 04-18):
  → Company Page check/create (if needed)
  → Developer App + Products + Auth tab
  → .env populated with Client ID/Secret
  → OAuth flow (./bin/lp auth) → tokens written
  → Dry-run test (./bin/lp test)

Day 2 (Sun 04-19):
  → Queue first 14 posts (./bin/lp queue add × N)
  → Cron host decision (local / VPS / GH Actions)
  → Cron installed OR GH Actions workflow committed
  → MANUAL-FALLBACK.md written

Day 3 (Mon 04-20 soft-launch):
  → Real publish via cron at 12:30 UTC (08:30 ET)
  → Verify post live on LinkedIn
  → Soft-launch serves as Phase 2 functional validation
```

Dependency: Phase 1 soft-launch gate (post-body + GIF) must exist before the real publish at Step 3.

## 6. Related Code/Artifact Files

- `integrations/linkedin-publisher/README.md`
- `integrations/linkedin-publisher/bin/lp`
- `integrations/linkedin-publisher/src/{auth,publish,upload-media,schedule}.js`
- `integrations/linkedin-publisher/.env.example`
- `integrations/linkedin-publisher/.env` (TO CREATE, gitignored)
- `integrations/linkedin-publisher/linkedin-queue.json` (TO POPULATE)
- `integrations/linkedin-publisher/.cron-host.md` (TO CREATE)
- `integrations/linkedin-publisher/MANUAL-FALLBACK.md` (TO CREATE)
- `.github/workflows/linkedin-publish.yml` (CONDITIONAL — if GH Actions cron path chosen)

## 7. Implementation Steps

1. **[Sat 04-18 19:00 ET]** Visit https://www.linkedin.com/company/setup/new/ if no Company Page exists; create "Nick Krzemienski Consulting" (or placeholder). 5 min.
2. **[Sat 04-18 19:15 ET]** Visit https://www.linkedin.com/developers/apps → Create app → name "ValidationForge Publisher", associate with Company Page, upload logo (reuse VF wordmark), paste terms-of-use URL.
3. **[Sat 04-18 19:30 ET]** Products tab: request "Sign In with LinkedIn using OpenID Connect" and "Share on LinkedIn" (both auto-approved).
4. **[Sat 04-18 19:45 ET]** Auth tab: copy Client ID + Client Secret. Add redirect URL `http://localhost:3000/callback`.
5. **[Sat 04-18 20:00 ET]** `cd integrations/linkedin-publisher && cp .env.example .env && vi .env` — fill `LINKEDIN_CLIENT_ID`, `LINKEDIN_CLIENT_SECRET`.
6. **[Sat 04-18 20:10 ET]** `npm install` (Node 22 LTS required). Log to `reports/phase-02-npm-install.log`.
7. **[Sat 04-18 20:15 ET]** `./bin/lp auth` — browser opens, consent, callback writes tokens. Confirm `.env` now contains `LINKEDIN_ACCESS_TOKEN`, `LINKEDIN_REFRESH_TOKEN`, `LINKEDIN_PERSON_URN`.
8. **[Sat 04-18 20:30 ET]** Dry-run test: `./bin/lp test --md ../../assets/campaigns/260418-validationforge-launch/copy/linkedin-soft-launch-mon-apr20.md > reports/phase-02-dryrun-soft-launch.log 2>&1`. Verify log shows what would be sent, no network call to publish endpoint.
9. **[Sun 04-19 10:00 ET]** Queue Days 1-14 posts. For each: `./bin/lp queue add <md-path> --at <ISO-UTC> --media <png-path>`. Posts: soft-launch (Mon 04-20), Part 1 (Wed 04-22), Part 2 (Sat 04-25), Personal-Brand Hero (Wed 04-29), Part 3 (Thu 04-30). Log each queue operation.
10. **[Sun 04-19 11:00 ET]** Verify queue: `cat linkedin-queue.json | jq '.[] | {slot: .scheduled_at, md: .markdown_path, status: .status}'`. Confirm 5 entries, all status=pending.
11. **[Sun 04-19 14:00 ET]** Cron host = **Local Mac launchd** (decided 2026-04-18). Plist already committed at `integrations/linkedin-publisher/com.validationforge.linkedin-publisher.plist` (Weekday 1+4 at 08:30 local). Load sequence:
    - `mkdir -p ~/Library/LaunchAgents`
    - `cp integrations/linkedin-publisher/com.validationforge.linkedin-publisher.plist ~/Library/LaunchAgents/`
    - `launchctl load -w ~/Library/LaunchAgents/com.validationforge.linkedin-publisher.plist`
    - Verify: `launchctl list | grep validationforge`
    - Schedule wake: `sudo pmset repeat wakeorpoweron MTh 08:25:00`
12. **[Sun 04-19 15:00 ET]** Document cron decision: `integrations/linkedin-publisher/.cron-host.md` with sections: chosen host = launchd, plist path, load command log, wake-schedule command, Mac-awake risk + fallback trigger, next token refresh date.
13. **[Sun 04-19 16:00 ET]** Write `MANUAL-FALLBACK.md`: paste-ready ritual for each post — (1) open LinkedIn create-post, (2) paste body from `copy/*.md`, (3) upload hero from `creatives/`, (4) schedule for 08:30 ET, (5) screenshot confirmation to `reports/live-posts/`.
14. **[Mon 04-20 08:30 ET]** First cron fire. Watch `bin/lp run` output (local) or GH Actions log. Confirm post live on LinkedIn within 5 min of scheduled time.
15. **[Mon 04-20 09:00 ET]** Phase 2 functional validation — soft-launch post visible in LinkedIn feed, GIF rendering, repo link preview correct. Screenshot to `reports/phase-02-first-autopost.png`.

## 8. Todo List

- [ ] Owner: Nick | Deadline: Sat 04-18 19:15 ET | Effort: 15min | Deps: none | Evidence: LinkedIn Company Page URL
- [ ] Owner: Nick | Deadline: Sat 04-18 19:45 ET | Effort: 30min | Deps: company page | Evidence: Client ID + Secret copied, screenshot of app dashboard
- [ ] Owner: Nick | Deadline: Sat 04-18 20:00 ET | Effort: 5min | Deps: app | Evidence: `.env` file with 2 filled vars (verified via `grep -c "=" .env`)
- [ ] Owner: Nick | Deadline: Sat 04-18 20:15 ET | Effort: 5min | Deps: env | Evidence: `reports/phase-02-npm-install.log` exit 0
- [ ] Owner: Nick | Deadline: Sat 04-18 20:30 ET | Effort: 15min | Deps: npm install | Evidence: `.env` contains `LINKEDIN_ACCESS_TOKEN` (`grep -c TOKEN .env >= 2`)
- [ ] Owner: Nick | Deadline: Sat 04-18 20:45 ET | Effort: 15min | Deps: tokens | Evidence: `reports/phase-02-dryrun-soft-launch.log` shows formatted preview
- [ ] Owner: Nick | Deadline: Sun 04-19 11:00 ET | Effort: 45min | Deps: dry-run pass | Evidence: `linkedin-queue.json` has ≥5 entries, jq dump in `reports/phase-02-queue-state.txt`
- [ ] Owner: Nick | Deadline: Sun 04-19 15:00 ET | Effort: 1h | Deps: none | Evidence: `.cron-host.md` + either `.github/workflows/linkedin-publish.yml` or `crontab -l` output in `reports/phase-02-cron-installed.txt`
- [ ] Owner: Nick | Deadline: Sun 04-19 17:00 ET | Effort: 30min | Deps: none | Evidence: `MANUAL-FALLBACK.md` exists with checklist
- [ ] Owner: Nick | Deadline: Mon 04-20 09:00 ET | Effort: 15min | Deps: all above + Phase 1 complete | Evidence: `reports/phase-02-first-autopost.png` screenshot of live LinkedIn post

## 9. Success Criteria

- `.env` contains 5 populated LinkedIn vars (Client ID, Secret, Access Token, Refresh Token, Person URN).
- `bin/lp test` completes without error on 3+ post files.
- Queue has ≥5 Days 1-14 entries scheduled with correct UTC offsets.
- Cron host decision documented in `.cron-host.md`; cron job OR GH Actions workflow live.
- First real autopost (Mon 04-20 08:30 ET) publishes successfully, verified by screenshot of live post.
- Manual-fallback doc exists and is runnable without the publisher (eyeball test: can Nick post Part 1 manually in 10 min using only the doc?).

## 10. Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| No Company Page exists → app creation blocked | M | M | Create placeholder Company Page (5 min, no branding commitment); unblocks immediately |
| LinkedIn API quota review flags app → approval delayed | L | H | "Share on LinkedIn" is auto-approved product; delay only if Share is rejected. Fallback: manual-post for Weeks 1-2, retry auth Week 3 |
| OAuth redirect fails on localhost (firewall, port conflict) | L | M | Use `PORT=3001 ./bin/lp auth`; update redirect URL in app settings to match |
| `w_member_social` scope not granted | L | H | Scope comes with "Share on LinkedIn" product; if missing, re-request product, re-run OAuth |
| Cron host goes offline during Mon/Thu window | M | M | GH Actions eliminates this; for local Mac, `pmset` keep-awake + `launchd` instead of cron |
| Token refresh fails silently mid-campaign | L | H | `bin/lp run` logs to `.lp.log`; cron job greps for "token expired"; weekly Sunday review checks log |
| LinkedIn API version 202504 deprecated mid-campaign | L | M | Version bumps announced 90 days ahead; quarterly bump check on Week 5 Sunday |
| Manual-fallback path untested, fails under pressure | M | M | Rehearse fallback once during Day 2 setup — publish one low-stakes post manually to prove path |

## 11. Security Considerations

- `.env` contains 5 secrets; `.gitignore` already excludes `.env` (verify before any commit: `git check-ignore integrations/linkedin-publisher/.env` → should return the path).
- `LINKEDIN_CLIENT_SECRET` = app-level secret; rotate if `.env` is ever committed accidentally (app Auth tab → regenerate).
- `LINKEDIN_ACCESS_TOKEN` = 60-day bearer; scope limited to `w_member_social` (publishing only, cannot read private data). Leak impact: attacker could publish on Nick's feed. Mitigation: weekly Sunday review inspects recent posts for anomaly.
- If GH Actions path: store all 5 vars in GitHub Secrets (Settings → Secrets → Actions), not in `.env`. Verify via `gh secret list` (names only, values never logged).
- Cron log (`.lp.log`) excluded from repo (`.gitignore`) — audit before commit.
- Revocation: `./bin/lp auth --revoke` (or LinkedIn Settings → Connected Apps → remove) invalidates tokens immediately.

## 12. Next Steps

Phase 3 (Wave 1 Execution) runs daily rituals that depend on Phase 2 being live by Day 1 OR manual-fallback being exercised. Phase 4 (Wave 2) and Phase 5 (Blog-Series) depend on the same publisher — one auth covers all 10 weeks. Phase 6 inherits but doesn't add setup work.

## 13. Functional Validation

- **Dry-run evidence:** `reports/phase-02-dryrun-soft-launch.log` contains the soft-launch post body + "DRY RUN — no publish" marker. Grep for "DRY RUN" returns ≥1 match.
- **Queue evidence:** `cat integrations/linkedin-publisher/linkedin-queue.json | jq 'length'` returns ≥5. `jq '.[] | .scheduled_at'` returns 5 ISO-8601 timestamps monotonically increasing.
- **Cron evidence:** either `crontab -l | grep -c "bin/lp run"` ≥ 1 OR `gh workflow list | grep -c linkedin-publish` ≥ 1. Saved to `reports/phase-02-cron-installed.txt`.
- **First autopost evidence:** `reports/phase-02-first-autopost.png` screenshot showing: LinkedIn feed, post timestamp = 08:30-08:35 ET Mon 04-20, body text matches `linkedin-soft-launch-mon-apr20.md`, GIF playing inline, repo link card present.
- **Token validity check (runnable weekly):** `curl -H "Authorization: Bearer $LINKEDIN_ACCESS_TOKEN" https://api.linkedin.com/v2/userinfo` returns HTTP 200 + JSON with `sub` field.
- **Manual-fallback smoke-test:** Nick hand-executes the fallback doc steps against a LinkedIn *draft* (NOT publish) — screenshot of compose window in `reports/phase-02-fallback-rehearsed.png`.
- **Phase complete claim:** must cite autopost screenshot + cron evidence. If first autopost fails, Phase 2 FAILS until next Mon/Thu; Phase 3 switches to manual-post mode (documented fallback) without blocking Wave 1.
