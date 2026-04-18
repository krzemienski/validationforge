# Blog-Site MDX Conversion Report

**Date:** 2026-04-18
**Source:** `/Users/nick/Desktop/validationforge/assets/campaigns/260418-validationforge-launch/copy/`
**Output:** `/Users/nick/Desktop/validationforge/assets/campaigns/260418-validationforge-launch/blog-site-mdx/`
**Files produced:** 8 `.md` (post-resolution)
**Validation:** All 8 files pass YAML frontmatter parse; all required fields present; no forbidden fields; all tags kebab-case.

---

## Resolved Decisions (2026-04-18)

The four unresolved questions from the original report have been answered by the user. The 8 post files have been rewritten to reflect these decisions:

| # | Question | Decision | How it was applied |
|---|----------|----------|--------------------|
| 1 | `.mdx` vs `.md` extension? | **`.md`** — the existing site loads `.md` via gray-matter in `src/lib/posts.ts`. | All 8 files renamed to `.md`. The original `.mdx` versions have been deleted from the directory. |
| 2 | `series_number` / `series_total` — add or omit? | **Omit.** The 8 launch posts are not part of the original 18-series. Including series numbers would conflict with the site's `getAllPosts()` sort logic. | `series_number` and `series_total` are NOT present in any of the 8 frontmatter blocks. |
| 3 | Tag casing: PascalCase (existing) or kebab-case (spec)? | **kebab-case.** Modern convention; site maintainer can migrate older posts later. | All tags in all 8 files are kebab-case (e.g. `agentic-development`, `claude-code`, `validationforge`). |
| 4 | `description` and `hero_image` — keep or strip? | **Strip both.** Neither field exists in the site's `PostFrontmatter` interface. | `description` and `hero_image` removed from all 8 frontmatter blocks. Hero image path preserved as an HTML comment at the top of each body: `<!-- TODO hero image: creatives/screenshots/{slug}-hero.png -->`. |

---

## 1. Frontmatter schema (final, applied)

The blog-site at `/Users/nick/Desktop/blog-series/site/` loads `post.md` (markdown) files via `gray-matter` from `src/lib/posts.ts`. The canonical `PostFrontmatter` interface:

```ts
export interface PostFrontmatter {
  title: string;
  subtitle: string;
  author: string;
  date: string;          // ISO date "YYYY-MM-DD"
  series_number: number;
  series_total: number;
  github_repo: string;
  tags: string[];
  published?: boolean;
}
```

### Actual schema used in the 8 produced `.md` files

```yaml
---
title: string
subtitle: string
author: string
date: "2026-04-18"
github_repo: "https://github.com/krzemienski/validationforge"
tags:
  - <kebab-case string>
published: false
---

<!-- TODO hero image: creatives/screenshots/<slug>-hero.png -->
```

**Slug:** derived from the directory name when integrated (see `SITE-INTEGRATION-STEPS.md`). Not a frontmatter field.
**`series_number` / `series_total`:** intentionally omitted — see Resolved Decisions §2. If the site maintainer later decides to fold these 8 into the existing series, the fields must be added at integration time and `getAllPosts()` sort logic reviewed. Until then, these posts are filtered to `published: false` and will not surface via `getPublishedPosts()`.
**`published: false`:** applied to every post so they do not auto-publish when dropped into the site's `posts/` directory. The site owner flips this per-post when ready.
**Hero image:** delivered as an HTML comment at the top of the body so the site owner has a visible TODO when wiring up images. Comment format: `<!-- TODO hero image: creatives/screenshots/<slug>-hero.png -->`.

---

## 2. Files produced (8, all `.md`)

All paths absolute:

1. `/Users/nick/Desktop/validationforge/assets/campaigns/260418-validationforge-launch/blog-site-mdx/vf-personal-brand-launch.md`
2. `/Users/nick/Desktop/validationforge/assets/campaigns/260418-validationforge-launch/blog-site-mdx/vf-validation-gap-essay.md`
3. `/Users/nick/Desktop/validationforge/assets/campaigns/260418-validationforge-launch/blog-site-mdx/vf-mid-sprint-lessons.md`
4. `/Users/nick/Desktop/validationforge/assets/campaigns/260418-validationforge-launch/blog-site-mdx/vf-launch-retrospective.md`
5. `/Users/nick/Desktop/validationforge/assets/campaigns/260418-validationforge-launch/blog-site-mdx/vf-week3-reflection-what-didnt-work.md`
6. `/Users/nick/Desktop/validationforge/assets/campaigns/260418-validationforge-launch/blog-site-mdx/vf-week3-deepdive-no-mock-hook.md`
7. `/Users/nick/Desktop/validationforge/assets/campaigns/260418-validationforge-launch/blog-site-mdx/vf-week4-five-questions-engineering-leaders.md`
8. `/Users/nick/Desktop/validationforge/assets/campaigns/260418-validationforge-launch/blog-site-mdx/vf-week4-patterns-from-teams-doing-ebs.md`

Previous `.mdx` versions have been deleted.

---

## 3. Source → Output mapping

| # | Source file | Output `.md` |
|---|---|---|
| 1 | `copy/personal-brand-launch-post.md` | `vf-personal-brand-launch.md` |
| 2 | `copy/linkedin-blog-series.md` Part 1 | `vf-validation-gap-essay.md` |
| 3 | `copy/linkedin-blog-series.md` Part 2 | `vf-mid-sprint-lessons.md` |
| 4 | `copy/linkedin-blog-series.md` Part 3 | `vf-launch-retrospective.md` |
| 5 | `copy/linkedin-week3-reflection.md` | `vf-week3-reflection-what-didnt-work.md` |
| 6 | `copy/linkedin-week3-deepdive-no-mock-hook.md` | `vf-week3-deepdive-no-mock-hook.md` |
| 7 | `copy/linkedin-week4-five-questions.md` | `vf-week4-five-questions-engineering-leaders.md` |
| 8 | `copy/linkedin-week4-spotlight.md` | `vf-week4-patterns-from-teams-doing-ebs.md` |

---

## 4. Conversion issues encountered

### Stripped (campaign-internal, not for public blog)
Per user instruction, the following sections were removed from every output file:

- "Channels:" / "Send time:" / "Word count:" / "Visual:" / "Visual asset:" header blocks
- "Voice notes:" preamble
- "Purpose:" lines
- "Engagement notes" sections at the end of every LinkedIn post
- "Posting protocol" / pin/unpin instructions
- The `### Title` / `### Body` markup wrapping LinkedIn posts (kept the title, dropped the headers)
- Placeholder metric tables with literal `{N}`, `{M}`, etc. tokens were replaced with neutral wording ("tracked at publish") OR rewritten as flowing prose where the placeholders made the original sentence ungrammatical
- The final separator + "Sign-off line" header in `personal-brand-launch-post.md` (kept the actual sign-off line as italicized prose; dropped the section header)

### Schema alignment (post-resolution)

- Extension is `.md`, matching the site's loader. The previous MDX comment syntax `{/* ... */}` was replaced with HTML comments `<!-- ... -->` and moved INSIDE the body (after the closing `---`) so gray-matter does not see them as part of the frontmatter block.
- `series_number` / `series_total` omitted per Resolved Decisions §2.
- `description` / `hero_image` fields removed per Resolved Decisions §4. Hero image path preserved as an HTML comment at the top of each body.

### Markdown conversion notes

- No JSX components introduced. Body content remains pure markdown, consistent with existing site posts.
- All bare URLs (`github.com/krzemienski/validationforge`) were converted to proper markdown links `[github.com/krzemienski/validationforge](https://github.com/krzemienski/validationforge)`, matching the existing post-01 / post-02 link conventions.
- Fenced code blocks containing curly-brace tokens (e.g., regex examples like `/\.test\.[jt]sx?$/`) are inside code fences so they render literally.
- The 2x2 matrix in the five-questions post is a fenced text block (no components). Renders as `<pre>`.

### Missing assets

- All 8 hero images are TBD. Each `.md` file opens its body with a top-level HTML comment naming the expected path: `<!-- TODO hero image: creatives/screenshots/<slug>-hero.png -->`.
- Some source files referenced inline screenshots that are campaign-internal production notes; these references were dropped from the body. The actual code block(s) they documented are included inline instead. To render a screenshot alongside the code, add `![…](…)` markdown manually after the asset is produced.

---

## 5. Validation evidence

Ran `python3 yaml.safe_load` against all 8 frontmatter blocks (gray-matter compatible). Schema-level audit also performed: no forbidden fields (`description`, `hero_image`, `series_number`, `series_total`) present; all required fields (`title`, `author`, `date`, `tags`, `published`, `github_repo`) present; all tags lowercase + kebab-case; every body starts with the TODO hero-image HTML comment.

```
OK vf-launch-retrospective.md                        | tags=6 | published=False | hero_comment=True
OK vf-mid-sprint-lessons.md                          | tags=6 | published=False | hero_comment=True
OK vf-personal-brand-launch.md                       | tags=6 | published=False | hero_comment=True
OK vf-validation-gap-essay.md                        | tags=6 | published=False | hero_comment=True
OK vf-week3-deepdive-no-mock-hook.md                 | tags=7 | published=False | hero_comment=True
OK vf-week3-reflection-what-didnt-work.md            | tags=6 | published=False | hero_comment=True
OK vf-week4-five-questions-engineering-leaders.md    | tags=7 | published=False | hero_comment=True
OK vf-week4-patterns-from-teams-doing-ebs.md         | tags=7 | published=False | hero_comment=True
---
8 files, 0 errors
```

---

## 6. Integration guide

See the companion file `SITE-INTEGRATION-STEPS.md` in this directory for the step-by-step guide to copying these 8 `.md` files into `/Users/nick/Desktop/blog-series/site/posts/<slug>/post.md`, with slug-collision pre-flight, tag migration notes, and a publish checklist.

---

## Previously unresolved questions (now RESOLVED)

1. ~~`.md` vs MDX extension~~ → **RESOLVED:** `.md`, placed at `posts/<slug>/post.md`. No MDX upgrade needed.
2. ~~Mini-series vs append to 18~~ → **RESOLVED:** Neither — `series_number` / `series_total` omitted entirely. Posts ship with `published: false`; site maintainer decides series placement later if desired.
3. ~~PascalCase vs kebab-case tags~~ → **RESOLVED:** kebab-case. Site maintainer may migrate older PascalCase tags to match at their discretion.
4. ~~`description` and `hero_image` support~~ → **RESOLVED:** Stripped. Not part of the current interface. Hero image paths live as HTML comments in the body for manual wire-up later.
