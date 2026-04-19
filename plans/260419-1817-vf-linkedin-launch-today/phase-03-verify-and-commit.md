# Phase 03 — Verify + commit + journal

## 1. Verify post is live

- Read `.lp-cookie.log` last entry: should show `STATUS 200` or `201`
- Visit https://www.linkedin.com/in/krzemienski/recent-activity/all/ (user does)
- Capture post URL into queue entry `published_url` field

## 2. Update queue state

Mark `w1-mon-soft-launch` as `published` with `published_at` and `published_url`.

## 3. Commit (single commit, conventional)

Staged files:
- `README.md` — Oracle A.2 launch-week copy
- `site/public/CNAME` — Oracle B.3 (already untracked)
- `integrations/linkedin-publisher/linkedin-queue.json` — reschedule + publish record
- `plans/260419-1817-vf-linkedin-launch-today/*` — this plan

Commit message:

```
feat(launch): fire VF LinkedIn soft-launch — launch week live

- README: replace Post #11 placeholder with launch-week copy (Oracle A.2)
- site: commit CNAME for validationforge.dev (Oracle B.3)
- linkedin-queue: w1-mon-soft-launch rescheduled + marked published
- plans: 260419-1817 launch-today execution plan

Launch post fired at <TIMESTAMP> via cookie-auth path. Post URL:
<POST_URL>. All other queue items remain on original schedule.
```

**DO NOT** commit `.env.local`, `.lp-cookie.log`, `.env` — all gitignored.

## 4. Journal entry

`docs/journal/260419-launch-day-soft-launch-fired.md` — 1-2 paragraphs:
- What fired, when
- What was decided vs. what was queued
- What's pinned for Apr 22 (blog part 1, separate session)
- Ban-risk reminder (cookie path trade-off)

## 5. Hand-off notes

- Next queued fire: `w1-wed-blog-series-part-1-validation-gap` on Apr 22 08:30 ET
- Parallel session status: unknown to this session — reconcile separately
- User action items still open: 5 campaign decisions + 11 companion repo polishes
