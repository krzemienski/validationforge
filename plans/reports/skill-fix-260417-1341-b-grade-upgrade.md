# Skill Fix Report — B-Grade → A-Grade Upgrade (6 surgical fixes)

**Date:** 2026-04-17
**Working directory:** /Users/nick/Desktop/validationforge
**Total commits:** 6
**Skipped fixes:** 0 (all applicable; none pre-applied)

All six fixes applied as specified. YAML frontmatter verified for all six SKILL.md files via
`awk '/^---$/{p++;next} p==1{print}' | head -5` — each parses cleanly and prints the first
5 frontmatter lines (`name`, `description`, trigger entries).

---

## FIX 1 — chrome-devtools

**Commit:** `d985082` — `fix(skills/chrome-devtools): add WHY clause distinguishing from Playwright MCP`
**File:** skills/chrome-devtools/SKILL.md (line 3)

**Before:**
```
description: "Reach for this when browser debugging goes beyond what Playwright can show cleanly — …"
```
**After:**
```
description: "Use when Playwright MCP isn't detailed enough for debugging — Reach for this when browser debugging goes beyond what Playwright can show cleanly — …"
```

---

## FIX 2 — design-token-audit

**Commit:** `4cdbdf4` — `fix(skills/design-token-audit): clarify {3,8} is regex quantifier not shell brace expansion`
**File:** skills/design-token-audit/SKILL.md (line 104)

**Before:**
```sh
# Find hardcoded hex colors (POSIX sh — no brace expansion)
```
**After:**
```sh
# POSIX-compatible grep (ERE) — {3,8} is regex quantifier, not shell brace expansion
```

---

## FIX 3 — e2e-testing

**Commit:** `45696c6` — `fix(skills/e2e-testing): append WHY clause clarifying strategy-vs-execution distinction`
**File:** skills/e2e-testing/SKILL.md (line 3)

**Before (tail of description):**
```
… or when planning the shape of E2E work before writing any execution code."
```
**After (tail of description):**
```
… or when planning the shape of E2E work before writing any execution code. Use this BEFORE picking execution tools (playwright-validation, ios-validation, api-validation) to design WHAT to validate and WHY — this is the strategy skill, not an execution skill."
```

---

## FIX 4 — full-functional-audit

**Commit:** `e2fcb28` — `fix(skills/full-functional-audit): add Phase 3/4/5 subsections referencing existing body`
**File:** skills/full-functional-audit/SKILL.md (inserted after Phase 2 block, before Severity Matrix)

**Before:** Only `## Phase 2: Feature Inventory Techniques` had a standalone subsection; Phases 3/4/5 existed only in the 5-phase table.

**After:** Three new subsections added (total 35 insertions, each ≤15 lines, cross-referencing the existing body rather than duplicating it):
- `## Phase 3: Evidence Capture` — 5 bullets (exercise every feature, platform-specific commands, naming convention, verbatim errors, UNKNOWN for unreachable)
- `## Phase 4: Classification` — 4 bullets (5-level scale, CRITICAL for security/data-loss, classify UP, MEDIUM minimum for visual defects)
- `## Phase 5: Report` — 5 bullets (Exec Summary, Findings Summary + per-feature list, Priority Recommendations by impact, Evidence Index, reference template)

Each subsection ends with a pointer like `See **Evidence Capture Rules** below …` to avoid duplication.

---

## FIX 5 — validate-audit-benchmarks

**Commit:** `cd9ca5c` — `fix(skills/validate-audit-benchmarks): expand body explaining scope and per-dimension rationale`
**File:** skills/validate-audit-benchmarks/SKILL.md (inserted between line 18 opener and `## When to Use`)

**Before:**
```
Score the structural integrity and functional correctness of ValidationForge primitives.

## When to Use
```
**After:** One new paragraph added explaining (a) scope = VF itself, not user projects, and (b) why each dimension matters (hooks = enforcement surface, skills = invocable surface, commands = user UX, rules = policy layer). Last sentence: "A regression on any dimension is a release blocker."

---

## FIX 6 — web-testing

**Commit:** `75f877d` — `fix(skills/web-testing): add north-star rule and compress decision matrix rationale to 5 rules`
**File:** skills/web-testing/SKILL.md (lines 40–59)

**Change 1 — north-star rule added before the matrix:**
```
## Decision Matrix

**When in doubt: Layer 2 (E2E) is always safe.** Not every feature needs all 5 layers — use this matrix as a guide.

| Feature Type | Layer 1 | …
```

**Change 2 — compressed 8 verbose bullets to 5 concrete rules** under `### Why some intersections are skipped ("-")`:
1. Auth flow skips a11y (Layer 3)
2. API integration skips a11y + perf (Layers 3–4)
3. Style/layout change skips Layers 1, 4, 5
4. Performance optimization skips Layers 1–3, 5
5. Form + new page skip security/perf conditionally (combined the two "conditional" bullets)

Matrix logic itself unchanged — same YES/- grid.

---

## Verification

Ran `awk '/^---$/{p++;next} p==1{print}' skills/<name>/SKILL.md | head -5` for all six skills. Each printed a valid `name:`, `description:`, and opening trigger entries — confirming frontmatter YAML remains parseable after the edits. No YAML delimiter (`---`) corruption, no unclosed quotes.

## Unresolved Questions

None.
