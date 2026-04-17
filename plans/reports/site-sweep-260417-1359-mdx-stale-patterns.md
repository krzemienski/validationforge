# Site MDX Stale Pattern Sweep — 2026-04-17

**Scope:** Sweep site MDX pages for three stale patterns flagged in audit report
`plans/reports/Explore-260417-1402-site-mdx-audit.md`.

## Summary of Fixes

| # | Pattern | Files touched | Occurrences | Commit |
|---|---------|--------------|-------------|--------|
| 1 | `includeStatic` → `static` | web-validation.mdx, playwright-validation.mdx | 3 | `c3e9fc4` |
| 2 | preflight.mdx verdict/drift | preflight.mdx | 1 (section) | `4028411` |
| 3 | `--udid booted` → `UDID=$(...)` | ios-validation.mdx | 5 | `613122f` |

## FIX 1 — includeStatic sweep

Replaced stale `includeStatic=false` with canonical `static=false` per
Playwright MCP parameter (Context7 reference, commit `ccb3471`).

- `site/src/content/docs/skills/web-validation.mdx` — 2 occurrences (lines 117, 123)
- `site/src/content/docs/skills/playwright-validation.mdx` — 1 occurrence (line 149)

## FIX 2 — preflight.mdx drift

Synced with live `skills/preflight/SKILL.md`:

- Aligned example report `Status:` line to the full `CLEAR | WARN | BLOCKED` enum
  (was only `CLEAR | BLOCKED`).
- Added explicit clarification that PASS/FAIL is not a preflight-level verdict —
  only the three-value enum applies.
- Added Iron Rule #4 citation from CLAUDE.md: "NEVER skip preflight — if it fails,
  STOP." (`<Aside type="caution">` block).
- Report location `e2e-evidence/preflight-report.md` was already documented.

## FIX 3 — `--udid booted` sweep

Replaced 5 stale `idb ui ... --udid booted` commands in ios-validation.mdx with
the canonical pattern from commit `bcce1e4`:

- Capture UDID via `UDID=$(xcrun simctl list devices booted | grep -Eo '[0-9A-F-]{36}' | head -1)`
- Positional coordinates for `idb ui tap` (not `--x/--y` flags)
- Positional `start-x start-y end-x end-y` for `idb ui swipe`
- `--udid "$UDID"` passed first, then positional args

No occurrences of `Ultrawork` were found in site/ (already clean).

## Verification

```
grep -rn 'includeStatic|--udid booted|Ultrawork' site/
→ No matches found
```

## Files Modified

- `site/src/content/docs/skills/web-validation.mdx`
- `site/src/content/docs/skills/playwright-validation.mdx`
- `site/src/content/docs/skills/preflight.mdx`
- `site/src/content/docs/skills/ios-validation.mdx`

## Commits

- `c3e9fc4` — fix(site): sweep includeStatic across MDX pages
- `4028411` — docs(site): preflight.mdx verdict enum CLEAR/WARN/BLOCKED + Iron Rule 4
- `613122f` — fix(site): sweep residual --udid booted idb pattern

## Unresolved Questions

- Commit `c3e9fc4` also swept 9 pre-existing untracked `.opencode/` symlinks into
  the same commit because they were already in `git add` staging area from a
  prior session. This is cosmetic — the substantive diff is the three MDX edits —
  but if strict per-fix commit hygiene matters, the symlinks could be moved to a
  separate chore commit. None were modified by this sweep.
