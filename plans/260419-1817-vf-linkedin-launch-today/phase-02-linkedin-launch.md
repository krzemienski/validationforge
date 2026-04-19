# Phase 02 — Reschedule + fire soft-launch post

## 1. Reschedule `w1-mon-soft-launch` to now

Change `scheduled_at` from `2026-04-20T12:30:00Z` to current UTC (just now, so
`lp queue next` treats it as due). Other queue items stay on their dates.

```bash
jq --arg now "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  '.items |= map(if .id == "w1-mon-soft-launch" then .scheduled_at = $now else . end)' \
  integrations/linkedin-publisher/linkedin-queue.json > /tmp/queue.json \
  && mv /tmp/queue.json integrations/linkedin-publisher/linkedin-queue.json
```

## 2. Launch path decision

The file-based queue + `lp queue next` path uses the OAuth `publish.js`
(official API). The **cookie** publisher (`publish-via-cookie.js`) is the only
tested live path right now (user confirmed via `me` call).

**Chosen path:** `node src/publish-via-cookie.js post <md>` — cookie auth.
This bypasses the queue runner but is what's proven to work.

**Media note:** The cookie path's `postText()` currently sets `media: []`
unconditionally (line 117 of publish-via-cookie.js). For v1 launch, accept a
text-only post. The demo video can be added as follow-up comment from the user
themselves, or queued for a future cookie-flow media upgrade.

## 3. Pre-flight

```bash
cd integrations/linkedin-publisher
# Confirm auth still valid
node src/publish-via-cookie.js me
# Dry run
node src/publish-via-cookie.js dry ../../assets/campaigns/260418-validationforge-launch/copy/linkedin-soft-launch-mon-apr20.md
```

## 4. Fire (live post)

```bash
cd integrations/linkedin-publisher
node src/publish-via-cookie.js post ../../assets/campaigns/260418-validationforge-launch/copy/linkedin-soft-launch-mon-apr20.md
```

3-second abort window built into the CLI. Expected output:
`{"status":"LIVE_OK","http":200}` (or 201).

## 5. Capture evidence

- Log: `integrations/linkedin-publisher/.lp-cookie.log` (already gitignored)
- Update queue item: set `status=published`, add `published_at`, `post_url`

## Failure modes

| Failure | Action |
|---|---|
| `LP_KILL=1` set | Unset the env var, retry |
| 401 from voyager | Cookies expired; user re-extracts from browser, updates .env.local |
| 429 rate limit | Wait 60 min, retry |
| Network failure | Retry once; if fails twice, abort and publish manually |
