# Site Integration Steps

Step-by-step guide for copying the 8 launch-campaign `.md` files into the production blog site at `/Users/nick/Desktop/blog-series/site/`.

**Target location:** `/Users/nick/Desktop/blog-series/site/posts/<slug>/post.md` (one directory per post).
**Loader:** `src/lib/posts.ts` auto-discovers any subdirectory matching `post-*` (see "Directory-naming convention" below for how this affects slug choice).
**Status on arrival:** all 8 posts ship with `published: false` — they will NOT appear on the public site until the site maintainer flips the flag.

---

## 1. Pre-flight: slug collision check

The existing site has posts `post-01-series-launch` through `post-18-sdk-vs-cli`. The 8 launch-campaign posts use content-based slugs (`vf-*`), not `post-NN-*` slugs, so there should be no direct collision. Before copying, confirm:

```bash
# From the site root
ls /Users/nick/Desktop/blog-series/site/posts/
```

Expected: directories named `post-01-*` through `post-18-*`, plus infrastructure files (`INDEX.md`, `findings.md`, etc.). None should start with `vf-`.

If any `vf-*` directory already exists, STOP and reconcile before proceeding.

---

## 2. Directory-naming convention (CRITICAL)

The site loader filters post directories with `entry.name.startsWith("post-")`:

```ts
// src/lib/posts.ts line 33
.filter((entry) => entry.isDirectory() && entry.name.startsWith("post-"))
```

**Implication:** a directory named `vf-launch-retrospective/` will be INVISIBLE to the site loader. You MUST either:

- **Option A (recommended for these 8 posts):** name each directory with a `post-` prefix, e.g. `post-vf-launch-retrospective/`. This is invisible-to-sort-order (sort is by `series_number`, which is undefined here → NaN, which sorts unpredictably). Since all 8 posts ship `published: false`, this is acceptable until the maintainer decides series placement.
- **Option B:** append these 8 to the existing series by giving them `series_number: 19..26` and `series_total: 26`, and name the directories `post-19-vf-launch-retrospective/` through `post-26-vf-week4-patterns/`. This also requires updating `series_total` in the existing 18 posts.

**For this integration, use Option A.** The directory names are:

| # | Directory name | Source `.md` file |
|---|---|---|
| 1 | `post-vf-personal-brand-launch` | `vf-personal-brand-launch.md` |
| 2 | `post-vf-validation-gap-essay` | `vf-validation-gap-essay.md` |
| 3 | `post-vf-mid-sprint-lessons` | `vf-mid-sprint-lessons.md` |
| 4 | `post-vf-launch-retrospective` | `vf-launch-retrospective.md` |
| 5 | `post-vf-week3-reflection-what-didnt-work` | `vf-week3-reflection-what-didnt-work.md` |
| 6 | `post-vf-week3-deepdive-no-mock-hook` | `vf-week3-deepdive-no-mock-hook.md` |
| 7 | `post-vf-week4-five-questions-engineering-leaders` | `vf-week4-five-questions-engineering-leaders.md` |
| 8 | `post-vf-week4-patterns-from-teams-doing-ebs` | `vf-week4-patterns-from-teams-doing-ebs.md` |

---

## 3. Copy commands

From any shell:

```bash
SRC=/Users/nick/Desktop/validationforge/assets/campaigns/260418-validationforge-launch/blog-site-mdx
DST=/Users/nick/Desktop/blog-series/site/posts

mkdir -p "$DST/post-vf-personal-brand-launch"
cp "$SRC/vf-personal-brand-launch.md" "$DST/post-vf-personal-brand-launch/post.md"

mkdir -p "$DST/post-vf-validation-gap-essay"
cp "$SRC/vf-validation-gap-essay.md" "$DST/post-vf-validation-gap-essay/post.md"

mkdir -p "$DST/post-vf-mid-sprint-lessons"
cp "$SRC/vf-mid-sprint-lessons.md" "$DST/post-vf-mid-sprint-lessons/post.md"

mkdir -p "$DST/post-vf-launch-retrospective"
cp "$SRC/vf-launch-retrospective.md" "$DST/post-vf-launch-retrospective/post.md"

mkdir -p "$DST/post-vf-week3-reflection-what-didnt-work"
cp "$SRC/vf-week3-reflection-what-didnt-work.md" "$DST/post-vf-week3-reflection-what-didnt-work/post.md"

mkdir -p "$DST/post-vf-week3-deepdive-no-mock-hook"
cp "$SRC/vf-week3-deepdive-no-mock-hook.md" "$DST/post-vf-week3-deepdive-no-mock-hook/post.md"

mkdir -p "$DST/post-vf-week4-five-questions-engineering-leaders"
cp "$SRC/vf-week4-five-questions-engineering-leaders.md" "$DST/post-vf-week4-five-questions-engineering-leaders/post.md"

mkdir -p "$DST/post-vf-week4-patterns-from-teams-doing-ebs"
cp "$SRC/vf-week4-patterns-from-teams-doing-ebs.md" "$DST/post-vf-week4-patterns-from-teams-doing-ebs/post.md"
```

Each post ends up at `$DST/<post-dir>/post.md`, which is what `getAllPosts()` expects.

---

## 4. Tag casing — important note

The existing 18 posts use **PascalCase** tags (`AgenticDevelopment`, `ClaudeCode`, `AIEngineering`, etc.). The 8 launch-campaign posts use **kebab-case** tags (`agentic-development`, `claude-code`, `validationforge`, etc.) per the user-resolved decision.

This mixed casing is tolerated by the site loader (tags are just strings), but it produces two cosmetic issues:

1. **Tag-list deduplication fails.** `AgenticDevelopment` and `agentic-development` render as two separate tags in any tag index / filter UI.
2. **Tag-based sorting / grouping** may split related posts across visually distinct tag buckets.

**Two paths forward:**

- **Keep mixed casing (acceptable today):** site maintainer migrates old posts later when they next edit them. Lowest effort now.
- **Migrate older posts to kebab-case:** 18-post sweep replacing tag strings. Moderate effort, one PR. Makes the tag taxonomy consistent going forward.

The user-resolved decision is **to defer the migration**: ship kebab-case for the 8 new posts and let the site maintainer migrate older posts at their own pace.

---

## 5. `series_number` / `series_total` — important note

The 8 launch-campaign posts omit `series_number` and `series_total` (user-resolved decision). The site loader sorts by `series_number`:

```ts
// src/lib/posts.ts line 53-55
return posts.sort(
  (a, b) => a.frontmatter.series_number - b.frontmatter.series_number
);
```

With `series_number` undefined, `a.frontmatter.series_number - b.frontmatter.series_number` evaluates to `NaN`, and `Array.prototype.sort` with a `NaN`-returning comparator is implementation-defined (in practice: unstable / unpredictable order, and these posts may appear at the top or bottom).

**This is mitigated by `published: false`** — these posts are filtered out of `getPublishedPosts()` entirely until the maintainer flips the flag. They're present in `getAllPosts()` for preview purposes only.

When the maintainer is ready to publish any of the 8:

1. Flip `published: true` in the post's frontmatter.
2. Decide on `series_number` assignment:
   - **Option A:** add these 8 to the existing series as `series_number: 19..26`, and update `series_total: 26` in all 26 posts.
   - **Option B:** treat them as a separate "VF Launch" mini-series with their own `series_total: 8` and numbers `1..8`, accepting that the sort logic will interleave them oddly with the main 18 unless the loader is updated to group by series name.
   - **Option C:** leave them un-numbered and update the loader to place un-numbered posts in a dedicated "Uncategorized" bucket.
3. Commit and push.

---

## 6. Pre-flight checklist

Before running the copy commands in §3, confirm:

- [ ] `/Users/nick/Desktop/blog-series/site/posts/` exists and contains existing `post-NN-*` directories.
- [ ] No existing directory starts with `post-vf-` (no collisions).
- [ ] The 8 source `.md` files in `/Users/nick/Desktop/validationforge/assets/campaigns/260418-validationforge-launch/blog-site-mdx/` all start with `---\n` (confirmed by the conversion validation run; see `CONVERSION-REPORT.md` §5).
- [ ] You have the resolved decisions memorized (no `description`, no `hero_image`, no `series_number`, no `series_total`, kebab-case tags, `published: false`).

---

## 7. Post-copy verification

After copying, from `/Users/nick/Desktop/blog-series/site/`:

```bash
# Confirm each post is discoverable
for slug in post-vf-personal-brand-launch post-vf-validation-gap-essay \
            post-vf-mid-sprint-lessons post-vf-launch-retrospective \
            post-vf-week3-reflection-what-didnt-work \
            post-vf-week3-deepdive-no-mock-hook \
            post-vf-week4-five-questions-engineering-leaders \
            post-vf-week4-patterns-from-teams-doing-ebs; do
  test -f "posts/$slug/post.md" && echo "OK $slug" || echo "MISSING $slug"
done
```

Expected: 8 `OK` lines.

Then run the site dev server (`npm run dev` or equivalent) and confirm:

- [ ] No build error referencing any of the 8 new posts.
- [ ] `getAllPosts()` returns the 8 new posts (they will NOT appear in `getPublishedPosts()` until `published: true`).
- [ ] Rendering a single post page (e.g. via `/posts/post-vf-launch-retrospective`) produces readable markdown with correct frontmatter parsing.
- [ ] The HTML comment `<!-- TODO hero image: ... -->` renders as invisible HTML (does not appear in the page body).

---

## 8. When each post is ready to publish

Per-post publish checklist (repeat for each of the 8):

1. Produce the hero image at `creatives/screenshots/<slug>-hero.png` per the TODO comment at the top of the body.
2. Decide where the hero image actually lives on the site (typically `posts/<slug>/assets/hero.png`) and wire it into the post body or the page template.
3. Remove (or leave) the `<!-- TODO hero image: ... -->` HTML comment. It's invisible when rendered but noisy in the source.
4. Flip `published: false` → `published: true` in the post's frontmatter.
5. Decide on `series_number` assignment (see §5 above).
6. Commit with a descriptive message (e.g. `feat(blog): publish vf-launch-retrospective`).
7. Push and verify the live site.

---

## 9. Rollback

To un-publish a post without deleting it:

```yaml
# In the post's frontmatter
published: false
```

To fully remove a post:

```bash
rm -rf /Users/nick/Desktop/blog-series/site/posts/<slug>
```

The loader will no longer see the directory on the next build.

---

## References

- Conversion source report: `./CONVERSION-REPORT.md`
- Site loader: `/Users/nick/Desktop/blog-series/site/src/lib/posts.ts`
- Existing post example: `/Users/nick/Desktop/blog-series/site/posts/post-01-series-launch/post.md`
