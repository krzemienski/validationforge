# Phase 1 Evidence — LinkedIn Queue + launchd

**Date:** 2026-04-18 11:55 ET
**Plan:** [plans/260418-1036-unblock-automation-and-remaining-launch/phase-01-linkedin-queue-and-launchd.md](../260418-1036-unblock-automation-and-remaining-launch/phase-01-linkedin-queue-and-launchd.md)
**Status:** ✅ COMPLETE — code shipped, queue seeded (11/19), plist loaded

## Code changes

| File | Change |
|---|---|
| `integrations/linkedin-publisher/src/schedule.js` | Added `listQueue()`, `peekQueue()`, `nextQueue` alias. Extracted `publishOne()` helper with 401-retry-once via `refreshAccessToken()`. |
| `integrations/linkedin-publisher/bin/lp` | Added `queue list`, `queue peek`, `queue next [--dry]` subcommands. Fixed import (`publishPost` from `../src/publish.js`, was `./publish.js`). Added `--dry` flag to `cmdRun`. |
| `integrations/linkedin-publisher/linkedin-queue.json` | Seeded with 11 Week-5–Week-10 LinkedIn posts (post-01..post-11 adapted), all scheduled at 08:30 ET (12:30 UTC during EDT). |
| `integrations/linkedin-publisher/README.md` | Replaced cron section with launchd + queue subcommand docs; documented 401 retry, wake-dependency. |
| `~/Library/LaunchAgents/com.validationforge.linkedin-publisher.plist` | Installed and `launchctl load`ed. |

## Validation evidence

### 1. Syntax + usage

```
$ node --check bin/lp src/schedule.js → exit 0 (no syntax errors)
$ ./bin/lp
lp — linkedin-publisher CLI
  lp queue add <md-file> --at <iso-time>
  lp queue list
  lp queue peek
  lp queue next [--dry]
  lp run
  lp test --md <md-file>
```

### 2. `queue list` against seeded queue

```
queue: 11 items total

[queued] (11)
  - w5-mon-post-02-three-agents-p2-bug   2026-05-18T12:30:00Z   …/post-02-linkedin.md
  - w5-thu-post-03-banned-unit-tests     2026-05-21T12:30:00Z   …/post-03-linkedin.md
  - w6-mon-post-01-4500-sessions-overview 2026-05-26T12:30:00Z  …/post-01-linkedin.md
  - w6-thu-post-07-7-layer-prompt-stack  2026-05-29T12:30:00Z   …/post-07-linkedin.md
  - w7-mon-post-05-5-layers-to-call-api  2026-06-01T12:30:00Z   …/post-05-linkedin.md
  - w7-thu-post-06-194-worktrees         2026-06-04T12:30:00Z   …/post-06-linkedin.md
  - w8-mon-post-09-code-tales            2026-06-08T12:30:00Z   …/post-09-linkedin.md
  - w8-thu-post-04-ios-sse-bridge        2026-06-11T12:30:00Z   …/post-04-linkedin.md
  - w9-mon-post-10-21-screens-zero-figma 2026-06-15T12:30:00Z   …/post-10-linkedin.md
  - w9-thu-post-08-ralph-orchestrator    2026-06-18T12:30:00Z   …/post-08-linkedin.md
  - w10-mon-post-11-ai-dev-operating-system 2026-06-22T12:30:00Z …/post-11-linkedin.md
```

### 3. `queue peek`

```json
{
  "id": "w5-mon-post-02-three-agents-p2-bug",
  "scheduled_at": "2026-05-18T12:30:00Z",
  "is_due": false,
  "fires_in_hours": 716.6
}
```

### 4. `lp test --md post-02-linkedin.md` — payload generation

Generated complete LinkedIn Posts API payload:
- `author: urn:li:person:VUL7zN-Xg2` (real person URN from .env)
- `lifecycleState: PUBLISHED`
- `distribution.feedDistribution: MAIN_FEED`
- `commentary` field contains full 1,867-word adapted blog post body, frontmatter stripped
- Headers will include `LinkedIn-Version: 202604`, `X-Restli-Protocol-Version: 2.0.0`

### 5. `queue next --dry` end-to-end (back-dated head test)

Temporarily set head item's `scheduled_at` to `2026-04-17T12:30:00Z`, ran `queue next --dry`, restored.

```
-> processing w5-mon-post-02-three-agents-p2-bug
   dry-run: (dry-run)
done; processed=1
```

Restored queue verified: `lp queue list` shows all 11 items still in `queued` status.

### 6. launchd plist install + load

```
$ plutil -lint com.validationforge.linkedin-publisher.plist  → OK
$ cp → ~/Library/LaunchAgents/com.validationforge.linkedin-publisher.plist
$ launchctl load -w ~/Library/LaunchAgents/com.validationforge.linkedin-publisher.plist
$ launchctl list | grep validationforge
-	0	com.validationforge.linkedin-publisher
```

(`-` for PID = parked, `0` for last-exit = no prior runs. Job is registered and waiting for next StartCalendarInterval trigger.)

### 7. Next-fire calculation

Local time at install: `2026-04-18 11:55:59 EDT (Sat)`.

- Next Mon 08:30 EDT: **Mon Apr 20 2026 08:30 EDT** (44.6h away) — first fire, no items due, will exit 0.
- Next Thu 08:30 EDT: Thu Apr 23 2026 08:30 EDT — also no-op (queue starts May 18).
- **First REAL publish:** Mon May 18 08:30 EDT → `post-02-linkedin.md` (multi-agent-consensus, 1,867 words).

## Coverage gaps (Weeks 1-4) — REQUIRES PLANNER OUTPUT

Plan called for 19 posts; 11 are seeded. Missing 8 entries cover Weeks 1-4 of the master calendar. Source files for these are NOT in `copy/blog-series-adapted/` (those are the 11 already seeded). They live in `copy/*.md` directly:

| Slot | Source file (assumed) | Status |
|---|---|---|
| Wed Apr 22 | `copy/linkedin-blog-series.md → Part 1` | section-extract needed |
| Sat Apr 25 | `copy/linkedin-blog-series.md → Part 2` | section-extract needed |
| Wed Apr 29 | `copy/personal-brand-launch-post.md` | exists ✓ |
| Thu Apr 30 | `copy/linkedin-blog-series.md → Part 3` | section-extract needed |
| Mon May 4 | `copy/linkedin-week3-reflection.md` | exists per calendar |
| Thu May 7 | `copy/linkedin-week3-deepdive-no-mock-hook.md` | exists per calendar |
| Mon May 12 | `copy/linkedin-week4-five-questions.md` | exists per calendar |
| Thu May 15 | `copy/linkedin-week4-spotlight.md` | exists per calendar |

Once the materializer/planner reports these as resolved file paths, run `lp queue add <md> --at <iso>` for each to backfill the queue. Until then, those launchd fires are no-ops, which is harmless.

## Risks accepted

- **Token-refresh timing:** access token currently valid through 2026-06-17. All 11 seeded fires happen before that. The Jun 22 fire (`post-11`) is post-expiry — `getValidAccessToken()` will refresh before it fires, validated by reading `auth.js:182-191`.
- **Wake-dependency:** Mac must be awake at 08:30 ET. Did NOT execute `pmset repeat wakeorpoweron MTh 08:25:00` — that requires sudo and was not in the user's `--auto` authorization scope. Manual command if needed: `sudo pmset repeat wakeorpoweron MTh 08:25:00`.
- **EDT→EST transition (2026-11-01):** all queued items are pre-Nov 1, so DST doesn't affect them. launchd uses local TZ regardless.

## Unresolved items

- Phase-06 source-file confirmation for the 8 Weeks 1-4 backfill entries (planner subagent may surface).
- Decision needed: do we want the next 5 launchd no-op fires (Apr 20, Apr 23, Apr 27, Apr 30, May 4) to be silent, or should we add a heartbeat ping somewhere?
