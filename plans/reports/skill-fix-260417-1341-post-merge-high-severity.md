# Skill Fix Report — Post-Merge High-Severity

**Date:** 2026-04-17
**Scope:** 10 precise SKILL.md / reference fixes to ValidationForge skills
**Branch:** main
**Result:** 9 commits applied, 1 fix (FIX 10) was a verification-only step per task spec

## Commits Applied

### FIX 1 — evidence-dashboard: When to Use / When NOT sections
- **Commit:** `70c2c1d`
- **File:** `skills/evidence-dashboard/SKILL.md`
- **Change:** Inserted "## When to Use" and "## When NOT to Use" sections between Scope and Quick Start (+12 lines). Covers: use after /validate before /ship, during audit, before release; skip while running, no evidence dir, needing raw screenshot.
- **Verify:** `grep -n "When to Use\|When NOT to Use" skills/evidence-dashboard/SKILL.md`
- **Output:** `25:## When to Use` / `31:## When NOT to Use`

### FIX 2 — web-validation: MCP tool parameters
- **Commit:** `ccb3471`
- **File:** `skills/web-validation/SKILL.md`
- **Changes:** Replaced `includeStatic=false` with `static=false` (2 occurrences, actually at lines 125/130 — task cited 93/98 which did not match current file); added `element="<descriptive label>"` to all `browser_click(...)` calls (3 occurrences); removed `filename=` parameter from `browser_console_messages(...)` and added note that output must be saved via follow-up file write.
- **Verify:** `grep -n "includeStatic\|browser_click\|browser_console_messages" skills/web-validation/SKILL.md`
- **Output:** Zero `includeStatic`; every `browser_click` now has `element="..."`; `browser_console_messages` line 112 is bare, line 117 is prose about the tool's limitations.

### FIX 3 — ios-validation: idb ui flags
- **Commit:** `bcce1e4`
- **File:** `skills/ios-validation/SKILL.md`
- **Changes:** Captured UDID via `xcrun simctl list devices booted | grep -Eo '[0-9A-F-]{36}' | head -1` instead of passing `booted` as UDID; converted `idb ui tap --x 200 --y 400` to positional `idb ui tap 200 400`; converted `idb ui swipe --x --y --delta-x --delta-y` to positional `idb ui swipe 200 600 200 300`.
- **Verify:** `grep -n "udid booted\|--x\|--y\|--delta" skills/ios-validation/SKILL.md`
- **Output:** Only one match — a comment at line 162 explaining positional coords are used. No active bad flags remain.

### FIX 4 — cli-validation: pipeline exit-code masking
- **Commit:** `98f8501`
- **File:** `skills/cli-validation/SKILL.md`
- **Changes:** Rewrote 11 shell snippets that used `$BINARY ... 2>&1 | tee FILE; echo "Exit: $?"` (which captures the pipeline's exit, not the binary's) into the redirect form `$BINARY ... > FILE 2>&1; echo "Exit: $?" >> FILE`. Covers Steps 2, 3, 4, 5 (all 4 error cases), 6 (stdin/pipe/empty-stdin). Also switched `cat input | $BINARY` to `$BINARY < input` in Step 7 pipe test to preserve binary exit.
- **Verify:** `grep -nE "2>&1 \| tee.*evidence" skills/cli-validation/SKILL.md`
- **Output:** 6 remaining lines — all are build commands (lines 33/37/41/46) and output-format snippets (lines 173/177) that do NOT capture `$?` afterward, so exit-code masking does not apply. Build commands piping into `tee` is intentional (show the build output live). The task-listed snippets are all fixed.

### FIX 5 — fullstack-validation: activate delete cascade
- **Commit:** `569fb0d`
- **File:** `skills/fullstack-validation/SKILL.md`
- **Change:** Replaced the `# (capture the delete action via browser automation)` placeholder with a real sequence: extract `ITEM_ID` from prior create evidence via `jq`, `browser_navigate`, `browser_snapshot`, `browser_click element="delete button for Integration Test Item" ref="DELETE_BTN_REF"`, screenshot, then verify against `$ITEM_ID` (not the literal `DELETED_ID`) in API and DB.
- **Verify:** `grep -n "DELETED_ID\|browser_click.*element=\"delete" skills/fullstack-validation/SKILL.md`
- **Output:** Only one `DELETED_ID` match — explanatory prose warning readers not to use it as a literal. The actual code uses `$ITEM_ID`.

### FIX 6 — api-validation: $TOKEN order-of-operations
- **Commit:** `6e4a4a2`
- **File:** `skills/api-validation/SKILL.md`
- **Change:** Took the non-invasive path (per task alternate spec): added a 7-line "Prerequisite: `$TOKEN` must be set before Step 2" block directly below the `## Step 2: CRUD Validation Pattern` heading, explaining readers must run Step 3 (Auth) first if executing steps individually, or drop the Authorization header if API is unauthenticated.
- **Verify:** `grep -n "Prerequisite: .TOKEN\|Step 3" skills/api-validation/SKILL.md`
- **Output:** New prereq lines 69-70; Step 3 heading unchanged at line 139.

### FIX 7 — functional-validation team-adoption gitignore
- **Commit:** `2b288df`
- **File:** `skills/functional-validation/references/team-adoption-guide.md`
- **Change:** Replaced single-line `echo "e2e-evidence/" >> .gitignore` with a heredoc-appended block that ignores binary captures but whitelists `report.md` and `evidence-inventory.txt` so verdict artifacts remain in VCS. Added explanatory prose.
- **Verify:** `grep -nE "e2e-evidence/(\*\*|report|evidence-inventory)" skills/functional-validation/references/team-adoption-guide.md`
- **Output:** 3 matches (lines 33-35) — `e2e-evidence/**`, `!e2e-evidence/**/report.md`, `!e2e-evidence/**/evidence-inventory.txt`.

### FIX 8 — no-mocking-validation-gates: catalog split
- **Commit:** `41a513d`
- **File:** `skills/no-mocking-validation-gates/references/mock-pattern-catalog.md`
- **Change:** Verified actual `hooks/lib/patterns.js` `TEST_PATTERNS` contents before editing. Split the file pattern table into two: (1) "Blocked File Patterns" — kept only patterns truly in `TEST_PATTERNS` (including `*.mock.*`, `*.stub.*`, `/test/**` which I added); (2) new "## Iron Rule (not hook-enforced)" table — moved `__mocks__/`, `*_test.py` (suffix), `*Test.java`, `*Test.kt`, `*_test.rs`, `conftest.py`, `testing/`, `factories/` into this section with a "Why Not Hook-Enforced" column. Also corrected `*Tests.swift, *Test.swift` (the regex is `/Tests?\.swift$/`) and noted that only the `test_*.py` prefix (not `*_test.py` suffix) is hook-blocked.
- **Verify:** `grep -n "Iron Rule (not hook-enforced)\|__mocks__\|conftest.py" skills/no-mocking-validation-gates/references/mock-pattern-catalog.md`
- **Output:** Line 45 new heading; `__mocks__` now only in Iron Rule table (line 58); `conftest.py` likewise (line 59).

### FIX 9 — gate-validation-discipline: Ultrawork → Team mode
- **Commit:** `e5411f2`
- **File:** `skills/gate-validation-discipline/references/gate-integration-examples.md`
- **Change:** Replaced "Integration with Ultrawork/Parallel Execution" heading with "Integration with Team Mode / Parallel Execution", and the body's `(Ultrawork, Team mode)` with `(Team mode)`.
- **Verify:** `grep -rn "Ultrawork" skills/`
- **Output:** Zero matches in skills/.

### FIX 10 — Final line-accuracy sweep
- **Status:** Verification-only step, no commit per task spec.
- **Verify:** `grep -rn "includeStatic\|--udid booted\|Ultrawork" skills/`
- **Output:** Zero matches in the 4 target skills (`web-validation`, `ios-validation`, `cli-validation`, `fullstack-validation`, `gate-validation-discipline`). Each fix verified clean within its own file.

## Fixes Skipped

None. All 9 target skills (FIX 1-9) received surgical edits and committed. FIX 10 was explicitly a verification step.

## New Issues Surfaced During Fixing

The FIX 10 sweep revealed **bad patterns in OTHER skills outside the 10-fix scope** — these were NOT addressed per task scope but are logged for follow-up:

1. **`skills/playwright-validation/SKILL.md:138`** — uses `browser_network_requests → includeStatic=false`. Same wrong MCP param name as fixed in web-validation (FIX 2).
2. **`skills/web-testing/SKILL.md:86, 173`** — uses `browser_network_requests → includeStatic=false` and `includeStatic=true`.
3. **`skills/e2e-validate/references/web-validation.md:44, 96`** — uses `browser_network_requests includeStatic=false`.
4. **`skills/e2e-validate/references/fullstack-validation.md:180`** — same pattern.
5. **`skills/e2e-validate/references/flutter-validation.md:209`** — uses `idb ui describe-all --udid booted 2>&1 | tee ...` (wrong UDID + pipe masking).
6. **`skills/functional-validation/references/evidence-capture-commands.md:31`** — uses `idb ui describe-all --udid booted`.
7. **`skills/visual-inspection/SKILL.md:142`** — uses `idb ui describe-all --udid booted`.

## Line-Number Discrepancies (noted, not blocking)

Task cited line numbers that did not all match current file contents:
- **web-validation FIX 2**: cited lines 62/64/93/98/85/109/119 for various patterns; actual lines after my Read were 95/106/125/130/112/117/148/156. Changes applied based on content match, not line number.
- **ios-validation FIX 3**: cited lines 140-156; actual block was at lines 155-170. Applied by content.
- **cli-validation FIX 4**: cited 11 line pairs; all matched by content pattern, not line number.
- **fullstack-validation FIX 5**: cited 171-183; actual block was 189-201. Applied by content.
- **api-validation FIX 6**: cited 36-89 and 96-102; actual blocks at 65-130 and 137-143. Used the non-invasive alternate (prereq note) per task spec.

## Constraints Respected

- No test files, mocks, stubs, `*.test.*`, or `*.spec.*` created.
- SKILL.md frontmatter preserved in all 9 edited files (name and description intact).
- All edits read before write (Read tool invoked in first phase on all target files).
- No subagents spawned.
- Commits are per-fix (9 commits for 9 fixes), conventional commit format.

## Unresolved Questions

- The 7 out-of-scope bad patterns surfaced by FIX 10 are candidates for a follow-up surgical pass; should they be bundled into a "round 2" fix prompt, or addressed by the parent audit pipeline?
- `skills/cli-validation/SKILL.md` lines 173/177 still use `2>&1 | tee` for JSON/CSV format-verification snippets — these don't capture exit code, so pipeline masking isn't strictly broken, but they're inconsistent with the rewritten style. Worth normalizing in a future pass.
