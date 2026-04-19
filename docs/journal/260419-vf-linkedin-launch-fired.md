# 2026-04-19 — VF launch fired on LinkedIn (PDF-document path)

## What fired

- **Post**: `urn:li:ugcPost:7451768403029245952`
- **URL**: https://www.linkedin.com/feed/update/urn:li:ugcPost:7451768403029245952/
- **Content**: 8-page PDF (`hero-vf-launch.pdf`, 160 KB) rendered from `copy/personal-brand-launch-post.md` (2,976 words) + 2,835-char commentary hook
- **Delivery path**: OAuth `/rest/posts` + Documents API (`w_member_social` scope)
- **Fired at**: 2026-04-19 ~23:07 UTC (Apr 19 PM ET)

## The pivot

Started the session pulling forward the 95-word Mon teaser (`w1-mon-soft-launch`)
from Apr 20 → now. Nick corrected: "there should have been a meticulously
fucking written blog post that has over like 5,000 words." The meticulously
written post already existed in the campaign as `personal-brand-launch-post.md`,
originally scheduled for Apr 29 as `w2-wed-personal-brand-hero`.

That post is 2,976 words / ~18,000 chars — six times LinkedIn's feed-post
commentary limit (LinkedIn confirmed with a literal 400 response:
`"ShareCommentary text length (17422 characters) exceeded the maximum allowed
(3000 characters)"` — code `FIELD_ARRAY_SIZE_TOO_HIGH`, `maxLength: 3000`).

Pivoted to LinkedIn Documents API: render essay → PDF → upload as document →
post with doc attachment + a 2,835-char commentary teaser. OAuth `w_member_social`
scope supports this path natively. Zero ban risk (official API only, no voyager
cookie path touched).

## What got done along the way

- Oracle A.1: added 3 missing repo topics (`no-mock`, `functional-testing`,
  `quality-assurance`). Repo now has 10 topics.
- Oracle A.2: README.md lines 3-12 rewritten — launch-week badge + Related Post
  block pointing to repo + self-validation evidence + Apr 22 essay tease.
- Oracle B.1/B.2/B.3: verified as already done (URL drift fixed, getting-started
  Aside matches target, `site/public/CNAME` present with `validationforge.dev`).
- Queue: `w1-mon-soft-launch` reverted to Apr 20 12:30Z; `w2-wed-personal-brand-hero`
  marked published with post_urn + doc_urn + published_url.

## What's next on the calendar

- Apr 22 Wed 08:30 ET: `w1-wed-blog-series-part-1-validation-gap` — the
  validation-gap long-form Part 1, 1,055-word LinkedIn post with
  `linkedin-part-1-hero.png`. Separate queue item, separate send.
- Apr 25 Sat: blog part 2 (mid-sprint lessons)
- Apr 30 Thu: blog part 3 (retrospective)
- Apr 20 Mon: the 95-word soft-launch teaser still scheduled, but is probably
  now redundant since the hero already fired. Consider deferring or repurposing
  as a comment reply under the hero post.

## Mechanical notes (for future launches)

- LinkedIn `w_member_social` scope caps `commentary` at 3,000 chars. Period.
- Documents API (`/rest/documents?action=initializeUpload`) is the escape
  hatch for long-form via OAuth. Flow:
  1. `POST /rest/documents?action=initializeUpload` with `{initializeUploadRequest:{owner:personUrn}}`
     → returns `{uploadUrl, document:"urn:li:document:..."}`
  2. `PUT uploadUrl` with Bearer token + `Content-Type: application/pdf` and
     binary body → HTTP 201.
  3. Poll `GET /rest/documents/{urn}` until `status != "WAITING_UPLOAD"`
     (typically 2-4s).
  4. `POST /rest/posts` with `content.media: { id: docUrn, title: ... }` +
     ≤3000-char commentary + standard author/visibility/distribution fields.
- Working script committed at
  `plans/260419-1817-vf-linkedin-launch-today/scripts/fire-pdf-post.mjs`.
  Reusable for future long-form launches.

## Open items (not for tonight)

- Coordinate with the parallel VF self-validation readiness session. The hero
  post cites `e2e-evidence/self-validation/report.md` — need to confirm that
  report is live and matches the "6/6 PASS, 13/13 criteria, 0 fix attempts"
  claim in the post.
- Decide what to do with the Apr 20 Mon teaser. Options: (a) let it fire as
  originally planned, (b) repurpose as a comment under the hero, (c) skip.
- 5 open campaign decisions (publishing domain, newsletter platform, coupled
  brand, master/main, MDX/MD) still pending — not blocking today's launch.

## Ban-risk posture

OAuth-only this session. No voyager cookie calls. Cookie auth confirmed working
earlier (`publish-via-cookie.js me` returned `name=Nick`) but was not used for
the fire. The cookie path remains the emergency fallback for future fires.
