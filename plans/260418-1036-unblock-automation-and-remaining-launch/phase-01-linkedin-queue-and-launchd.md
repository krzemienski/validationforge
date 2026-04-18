# Phase 01 — LinkedIn Publisher Queue + launchd Mon/Thu 08:30 ET

## Context
- Parent plan: [plan.md](./plan.md)
- Depends on: nothing (soft-launch already shipped)
- Blocks: Phase 06 (content execution)

## Overview
OAuth works. First post shipped. Remaining 19 posts still need to flow through an automated
queue fired by launchd at 08:30 America/New_York every Mon + Thu. `schedule.js` and
`com.validationforge.linkedin-publisher.plist` exist but aren't wired together.

## Key Insights
- Public OAuth API has no native scheduling — must fire at publish-time via cron.
- launchd respects local-TZ wall-clock better than cron+TZ=America/New_York.
- Queue must be a plain JSON file (not DB) so it's diffable/commitable and user-editable.
- Skip weekends/holidays by leaving the queue slot empty — runner no-ops when head of queue is null.

## Requirements
1. `linkedin-queue.json` (already gitignored) holds ordered array of `{ slot_date, md_path, url }` entries aligned to master-calendar.
2. `lp queue next` CLI subcommand reads head, publishes via `publish.js`, pops on success, writes to `linkedin-queue.log`, exits 0; exits 1 on failure so launchd logs it.
3. launchd plist points to `/opt/homebrew/opt/node@22/bin/node bin/lp queue next`.
4. Retry: on 401 (token revoked) → auto-refresh via `getValidAccessToken()` then retry once.
5. Media support: if queue entry has `media_path`, call `upload-media.js` first, attach asset URN.

## Architecture
```
launchd (Mon/Thu 08:30 ET)
  → bin/lp queue next
    → read head(linkedin-queue.json)
    → upload media if present → asset URN
    → publishPost(md, media)
    → on 201: pop head, append to linkedin-queue.log with post URN
    → on error: append to error log, exit 1
```

## Related code files
- Modify: `integrations/linkedin-publisher/bin/lp` (add `queue` subcommand)
- Modify: `integrations/linkedin-publisher/src/schedule.js` (queue-file I/O)
- Modify: `integrations/linkedin-publisher/src/publish.js` (media-URN param already there)
- Seed: `integrations/linkedin-publisher/linkedin-queue.json` from master calendar
- Load: `launchctl load integrations/linkedin-publisher/com.validationforge.linkedin-publisher.plist`

## Implementation Steps
1. Populate `linkedin-queue.json` with 19 remaining posts from `assets/campaigns/.../execution/10-week-master-calendar.md` — slot_date, md_path per row.
2. Implement `lp queue next` + `lp queue list` + `lp queue add` + `lp queue peek` in `bin/lp`.
3. Wire `schedule.js` pop/log logic.
4. Dry-run: `lp queue next --dry` — confirms head parses + would-publish payload.
5. `launchctl load` the plist; verify `launchctl list | grep validationforge`.
6. First live cron fires Thu 2026-04-23 08:30 ET — Post 2 (announcement/Parts 1-2-3 build-up).

## Todo List
- [x] Seed `linkedin-queue.json` from master calendar — 16/20 rows (4 off-cadence deferred — Wed Apr 22, Sat Apr 25, Wed Apr 29, Thu Apr 30 conflict with Mon/Thu-only launchd schedule; require phase-06 content-calendar judgment)
- [x] Add `queue` subcommand to `bin/lp` (`list`, `peek`, `next [--dry]` + `run` legacy alias)
- [x] Wire schedule.js pop+log (time-based; `status: queued → published|failed|dry-run` + `post_urn` + ISO timestamps)
- [x] Retry-on-401 via `refreshAccessToken()` (detects `/publish failed: 401/`, refreshes, retries once)
- [x] Media attach path already wired in existing `publishOne` via `upload-media.js` (tested with `media_path: null` items; live image path validation deferred until first entry with media_path set)
- [x] Dry-run head of queue — back-dated test produced `processed=1, dry-run: (dry-run)`
- [x] `launchctl load` plist — `plutil -lint OK`, `launchctl list` shows job parked (PID `-`, last-exit `0`)
- [x] Document `lp queue` usage in `integrations/linkedin-publisher/README.md`
- [ ] Verify first REAL publish on Mon May 18 08:30 EDT (post-02) — deferred to post-cook
- Evidence: `plans/reports/cook-260418-1145-phase-01-linkedin-queue-launchd-evidence.md`

## Success Criteria (functional validation)
- `lp queue list` prints the 19 queued posts with dates.
- `lp queue next --dry` against Apr-23 slot returns payload with correct body + date.
- `launchctl list` shows plist loaded + StartCalendarInterval registered.
- At Thu 04-23 08:31 ET: `.lp.log` shows a successful HTTP 201 with `urn:li:share:` returned. Feed link renders.
- `linkedin-queue.json` has 18 remaining (head popped).

## Risk Assessment
- **Token refresh race:** If plist fires while token is <1 day from expiry, refresh must be synchronous — `getValidAccessToken()` already does this; verify with unit-time test.
- **Media upload failure mid-post:** If upload succeeds but publish 4xx, asset URN is orphaned. Acceptable — LinkedIn GCs after 24h.
- **Rate limits:** 125 posts/day/member on `w_member_social` — 2/week nowhere near ceiling.

## Security Considerations
- `.env` stays 600. Never log bearer token. Redactor already in place.
- launchd StandardOutPath writes to user-home log, not repo.

## Next Steps
- After Phase 1 ships, Phase 6 (content execution) becomes a pure queue-maintenance task.
- Consider: webhook on post-creation to auto-log `postUrn` + `feed_url` into campaign tracking sheet.
