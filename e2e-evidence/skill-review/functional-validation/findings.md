# Deep Review: `functional-validation` skill

**Reviewer:** coder (auto-claude), Task 004 phase-1-subtask-1
**Date:** 2026-04-17
**Files reviewed:**
- `./skills/functional-validation/SKILL.md` (97 lines)
- `./skills/functional-validation/references/common-failure-patterns.md` (120 lines)
- `./skills/functional-validation/references/evidence-capture-commands.md` (185 lines)
- `./skills/functional-validation/references/quick-reference-card.md` (53 lines)
- `./skills/functional-validation/references/team-adoption-guide.md` (92 lines)

**Cross-references checked:**
- `./skills/e2e-validate/workflows/execute.md`
- `./skills/ios-validation/SKILL.md`, `./skills/web-validation/SKILL.md`,
  `./skills/api-validation/SKILL.md`, `./skills/cli-validation/SKILL.md`,
  `./skills/fullstack-validation/SKILL.md`
- `./skills/gate-validation-discipline/SKILL.md`,
  `./skills/no-mocking-validation-gates/SKILL.md`,
  `./skills/e2e-validate/SKILL.md`,
  `./skills/create-validation-plan/SKILL.md`,
  `./skills/preflight/SKILL.md`
- `./hooks/block-test-files.js`, `./hooks/patterns.js`,
  `./.opencode/plugins/validationforge/patterns.ts`
- Project root `.gitignore`

**Tool-availability command transcript (to support preflight-style verification):**
```
$ node --version   → v25.9.0
$ curl --version   → curl 8.7.1 (x86_64-apple-darwin25.0) libcurl/8.7.1
$ jq --version     → jq-1.8.1
$ pnpm --version   → 10.33.0
$ which xcrun      → /usr/bin/xcrun (present; invocation blocked by sandbox)
$ which psql       → /opt/homebrew/bin/psql
$ which docker     → /opt/homebrew/bin/docker (present; invocation blocked by sandbox)
```
All tools mentioned in `references/evidence-capture-commands.md` are installed on this host,
though a few (xcrun, docker) are blocked by the worktree sandbox and so cannot be version-stamped
from inside this task. That is an environment constraint, not a SKILL.md defect.

---

## Summary

The `functional-validation` skill is the backbone protocol skill for ValidationForge.
Overall the instructions are coherent, cite correct tool syntax, and preserve the Iron
Rule. The cross-skill wiring resolves to real files. Commands were spot-checked and
produce non-empty, well-formed output on this machine where the sandbox allowed them.

Two issues rise to HIGH severity (both in the reference files rather than SKILL.md
itself) and a handful of MEDIUM/LOW inconsistencies are worth cleaning up. No CRITICAL
issues were found: following these instructions would not lead a validator to issue
a false PASS verdict.

---

## Accuracy Issues

### [HIGH] `team-adoption-guide.md` tells users to gitignore all evidence — but the repo policy keeps the report
**Location:** `skills/functional-validation/references/team-adoption-guide.md` lines 26–28
**Current text:**
```bash
mkdir -p e2e-evidence
echo "e2e-evidence/" >> .gitignore  # Evidence is ephemeral, not committed
```
**Contradicted by:** root `.gitignore` lines 8–12:
```
e2e-evidence/*.png
e2e-evidence/*.jpg
e2e-evidence/*.json
!e2e-evidence/evidence-inventory.txt
!e2e-evidence/report.md
```
**Why this matters:** the skill is the one teams adopt — if they copy the advice as
written, they will ALSO gitignore `evidence-inventory.txt` and `report.md`, which the
project's own rules treat as the canonical verdict artifacts and which CLAUDE.md's
evidence-directory diagram shows as retained files.
**Fix recommendation:** replace the one-liner with the two-line pattern:
```bash
echo -e 'e2e-evidence/*\n!e2e-evidence/**/evidence-inventory.txt\n!e2e-evidence/**/report.md\n!e2e-evidence/**/*.md' >> .gitignore
```
Or at minimum change the comment to "evidence binaries are ephemeral; keep
evidence-inventory.txt and report.md".

### [HIGH] `quick-reference-card.md` platform table lists Android — no `android-validation` skill exists
**Location:** `skills/functional-validation/references/quick-reference-card.md` line 32
**Current row:**
```
| `build.gradle` | Android | gradle + adb |
```
**Checked:** `ls ./skills/ | grep -i android` → no match. The README/CLAUDE.md does
not list Android among the platforms either (iOS, Web, API, CLI, Fullstack, Design).
**Why this matters:** a validator that detects `build.gradle` will find no
`android-validation` skill to delegate to and will stall (or worse, silently default
to the wrong skill).
**Fix recommendation:** remove the Android row from the table, or add an explicit note
that Android routing is not yet supported and should be escalated.

---

## Stale References

### [LOW] `SKILL.md` platform detection column order differs from CLAUDE.md
**Location:** `skills/functional-validation/SKILL.md` lines 37–43
**Order:** iOS → Web → CLI → API → Full-Stack
**CLAUDE.md order:** iOS → Web → API → CLI → Fullstack → Design (Platform Detection table,
CLAUDE.md).
**Impact:** cosmetic. "Priority" in SKILL.md is a list of detection checks, not a
routing priority, so the disagreement does not cause misrouting. Worth aligning for
consistency during Phase 4.

### [MEDIUM] `SKILL.md` platform table omits the Design platform
**Location:** `skills/functional-validation/SKILL.md` lines 37–43
CLAUDE.md lists Design as a supported platform with skills
`design-validation`, `stitch-integration`, `design-token-audit`. The functional-validation
table has 5 rows and stops at Full-Stack.
**Fix recommendation:** add a 6th row:
```
| 6 | Design | `DESIGN.md`, Stitch project | Token audit, component inspection | skill: `design-validation` |
```

### [MEDIUM] `references/evidence-capture-commands.md` Web section mixes MCP and manual HAR export
**Location:** `references/evidence-capture-commands.md` lines 41–60
- Lines 42–43 are a commented-out MCP pseudo-call (`# browser_navigate → browser_snapshot → browser_take_screenshot`) that looks like a shell comment but is actually a reference to Playwright MCP tool calls. It is not runnable as written.
- Lines 51–52 instruct the user to manually right-click in Chrome DevTools to save a HAR, which contradicts the automated-evidence-capture theme of the rest of the file.
**Fix recommendation:** replace the manual HAR export with a Chrome DevTools MCP call
(`list_network_requests`) or delete the HAR line entirely — `browser_network_requests`
is already covered below and produces comparable evidence.

### [LOW] `SKILL.md` "Multi-Platform Validation Order" inserts "Business Logic" layer
**Location:** `skills/functional-validation/SKILL.md` lines 65–68
**Current:** `Database/Infra (validate FIRST) -> Business Logic -> API Endpoints -> Frontend UI (validate LAST)`
**fullstack-validation/SKILL.md shows:** `Database -> Backend API -> Frontend` (no
distinct "Business Logic" tier; business logic is exercised through the API).
**Fix recommendation:** either remove "Business Logic" (to match
`fullstack-validation`) or add an explanatory note that business logic is exercised
indirectly through the API layer.

---

## Missing Content

### [MEDIUM] `SKILL.md` 4-step protocol under-specifies "READ the evidence"
**Location:** `skills/functional-validation/SKILL.md` Step 3 "Capture Evidence" (line 53–54)
**Current:** "Evidence must be READ and DESCRIBED, not just confirmed to exist."
**e2e-validate workflow expands this:** `./skills/e2e-validate/workflows/execute.md`
sub-step 3d ("READ the Evidence (MANDATORY)", lines 75–91) spells out four actions:
open, describe, note values, flag discrepancies, with GOOD/BAD examples.
**Why this matters:** the SKILL.md is what gets loaded first; the workflow is only
loaded when a validator reaches e2e-validate. Validators using the skill in isolation
get one sentence where they should get a short checklist.
**Fix recommendation:** promote the four actions (open, describe, note values, flag
discrepancies) into SKILL.md Step 3 — a single extra bullet list would close the gap
without exceeding the skill-length guidelines.

### [MEDIUM] `team-adoption-guide.md` is never linked from SKILL.md
**Location:** `skills/functional-validation/SKILL.md` lines 59–60 link only to
`references/evidence-capture-commands.md` and `references/common-failure-patterns.md`.
`references/quick-reference-card.md` is linked once (line 81). `references/team-adoption-guide.md`
is not mentioned anywhere in SKILL.md.
**Impact:** the team-adoption advice is silently orphaned. A reader following SKILL.md
never sees it.
**Fix recommendation:** add a one-line pointer under "Related Skills" or under a new
"Further Reading" section.

### [LOW] `SKILL.md` "Related Skills" omits `sequential-analysis`
**Location:** `skills/functional-validation/SKILL.md` lines 89–96
CLAUDE.md pipeline phase 4 (ANALYZE) explicitly uses "sequential thinking", which the
`sequential-analysis` skill provides. The validator using `functional-validation` is
exactly the reader who will need to reach for it on a FAIL verdict.
**Fix recommendation:** add `sequential-analysis` to the Related Skills bullet list.

---

## Broken Cross-Links

None. Every cross-skill reference in SKILL.md resolves to an existing
`./skills/<name>/SKILL.md`:

| Link target | Resolves? | Path verified |
|---|---|---|
| `ios-validation` | YES | `./skills/ios-validation/SKILL.md` |
| `web-validation` | YES | `./skills/web-validation/SKILL.md` |
| `api-validation` | YES | `./skills/api-validation/SKILL.md` |
| `cli-validation` | YES | `./skills/cli-validation/SKILL.md` |
| `fullstack-validation` | YES | `./skills/fullstack-validation/SKILL.md` |
| `gate-validation-discipline` | YES | `./skills/gate-validation-discipline/SKILL.md` |
| `no-mocking-validation-gates` | YES | `./skills/no-mocking-validation-gates/SKILL.md` |
| `e2e-validate` | YES | `./skills/e2e-validate/SKILL.md` |
| `create-validation-plan` | YES | `./skills/create-validation-plan/SKILL.md` |
| `preflight` | YES | `./skills/preflight/SKILL.md` |
| `references/evidence-capture-commands.md` | YES | present |
| `references/common-failure-patterns.md` | YES | present |
| `references/quick-reference-card.md` | YES | present |
| `references/team-adoption-guide.md` | YES | present (not linked) |

The `block-test-files` hook referenced obliquely by `team-adoption-guide.md` line 21–22
exists at `./hooks/block-test-files.js` and correctly uses the allowlist/denylist from
`./.opencode/plugins/validationforge/patterns.ts` (verified).

---

## Cross-skill consistency check: 4-step protocol vs. `e2e-validate/workflows/execute.md`

functional-validation's 4-step protocol (SKILL.md §"The 4-Step Protocol", lines 46–57):

| # | Name | One-line |
|---|---|---|
| 1 | Build & Launch | Build the real system with real deps; build failure is finding #1 |
| 2 | Exercise Through UI | Interact as a real user; no REPL / direct calls |
| 3 | Capture Evidence | Save to `e2e-evidence/`; READ and DESCRIBE, not just confirm |
| 4 | Write Verdict | Cite specific evidence with paths and quoted content |

e2e-validate/workflows/execute.md (lines 12–118):

| # | Name | Relation to functional-validation |
|---|---|---|
| 1 | Build the Real System | Matches first half of Step 1 |
| 2 | Start the Real System | Matches second half of Step 1 |
| 3 | Execute Each Journey (3a–3e) | Expands Steps 2 + 3 into navigate / perform / capture / read / match |
| 4 | Write Verdicts | Matches Step 4 |
| 5 | Handle Failures | Not in SKILL.md; newly surfaces failure routing |
| 6 | Error Recovery | Not in SKILL.md; newly surfaces retry budget |

**Conclusion:** no contradiction. The skill is a high-level overview; the workflow
is the detailed playbook. The only sharp edge (already noted above under "Missing
Content") is that Step 3's "READ the evidence" checklist in execute.md is not
mirrored into SKILL.md, so validators reading only SKILL.md may under-describe
captured evidence.

---

## Reference-file-level findings

### `common-failure-patterns.md`
- Ten recovery recipes, all syntactically valid bash. Verified tool presence:
  docker, psql, lsof, curl, jq, xcrun simctl — all installed on host.
- No stale references observed. Recipe #7 ("Auth Token Expired") uses a hard-coded
  `http://localhost:3000` which is consistent with the rest of the file; not a defect.
- No action required.

### `evidence-capture-commands.md`
- 185 lines, well organised by platform (iOS → Web → API → CLI → DB → Build → Logs).
- Issue already logged under "Stale References": Web section mixes manual HAR export
  with MCP automation.
- All `xcrun simctl`, `curl`, `docker logs`, `psql`, `sqlite3`, `xcodebuild`, `pnpm`,
  `cargo`, `go build` examples are syntactically valid and match current tool flag
  syntax. Line 152 `xcodebuild -scheme MyApp -destination 'platform=iOS Simulator,name=iPhone 16' build`
  matches the canonical form used in `e2e-validate/workflows/execute.md` line 19.
- No further action required beyond the Web-section fix above.

### `quick-reference-card.md`
- Succinct "card" format — fits the stated purpose.
- Issue already logged: Android row refers to a non-existent skill.
- The 5 pre-flight questions (lines 12–16) match SKILL.md "Before You Validate"
  (lines 27–32) — consistent.
- The Red Flags list (lines 47–52) is pithy and useful; no defects.

### `team-adoption-guide.md`
- Issue already logged: `.gitignore` advice is too aggressive.
- Line 17: `find . -name "*.test.*" -o -name "*.spec.*" -o -name "__tests__"` — valid
  find syntax. The trailing `| head -20` is fine as a sanity-check preview.
- Line 41 references "CI/CD integration pattern from `gate-validation-discipline`" —
  verified: `skills/gate-validation-discipline/references/gate-integration-examples.md`
  exists.
- No additional defects.

---

## Recommendations (ordered by severity)

1. **HIGH — `team-adoption-guide.md` .gitignore advice:** update the one-line `echo`
   to preserve `evidence-inventory.txt` and `report.md`, matching the project's
   actual `.gitignore` policy.
2. **HIGH — `quick-reference-card.md` Android row:** drop the row (or gate it behind
   an explicit "not supported — escalate" note). No `android-validation` skill exists.
3. **MEDIUM — Add Design platform row to SKILL.md platform table** (to match CLAUDE.md's 6 platforms).
4. **MEDIUM — Replace manual HAR export step** in `evidence-capture-commands.md` with
   a Chrome DevTools MCP call or delete it (the equivalent data is already captured via
   `browser_network_requests`).
5. **MEDIUM — Promote "READ the evidence" 4-bullet checklist** from
   `e2e-validate/workflows/execute.md` step 3d into SKILL.md Step 3.
6. **MEDIUM — Link `team-adoption-guide.md`** from SKILL.md so the file is discoverable.
7. **LOW — Align platform-table row order with CLAUDE.md** (iOS, Web, API, CLI, Fullstack, Design).
8. **LOW — Normalise fullstack ordering diagram** in SKILL.md: drop "Business Logic"
   (or add a footnote) so it matches `fullstack-validation/SKILL.md`.
9. **LOW — Add `sequential-analysis` to Related Skills list.**

All of the above should be applied in Phase 4; none require changes to
`commands/`, `agents/`, `rules/`, or `hooks/` source (only Markdown edits in
`./skills/functional-validation/`).

---

## Success criteria checklist

- [x] `findings.md` covers every claim in SKILL.md (platform table, 4-step protocol, Iron Rule, Related Skills)
- [x] Every reference file (4 total) was opened and inspected
- [x] All cross-skill links resolved to `./skills/<name>/SKILL.md`
