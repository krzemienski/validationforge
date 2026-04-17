# Merge 2 — 015 documentation-site — Conflict Resolution

## Conflict summary

5 add/add conflicts: main had its own smaller site/ scaffold (from commit `6ff749f`
"subtask-1-2 Verify Astro + Starlight builds successfully"), while the 015 branch
built a full documentation site on top of a different scaffold.

- site/astro.config.mjs
- site/package.json
- site/package-lock.json
- site/src/content/docs/index.mdx
- site/tsconfig.json

## Resolution

Taken 015's version for ALL 5 files (`git checkout --theirs`).

## Rationale

The 015 branch's site/ is the complete superset:
- Pre-merge analysis confirmed `npm ci` succeeded (426 dependencies pinned) and
  `npm run build` produced 33 static pages.
- Main's scaffold was a minimal exploratory placeholder from an earlier session;
  its docs/ directory was empty beyond placeholders.
- Keeping main's version would preserve stale stub content without the content
  authored in 015 (getting-started, 15 command pages, 10 skill deep-dives, 2
  integration guides).

## Verification

Post-resolution `grep -l '<<<<<<< HEAD'` returns nothing — all conflict markers
clean. Post-merge HEAD: 38e98d4.
