# Deep Review: `preflight` skill

**Reviewer:** auto-claude (phase-1-subtask-4)
**Date:** 2026-04-17
**Scope:** `./skills/preflight/SKILL.md`, `./skills/preflight/references/platform-checklists.md`, `./skills/preflight/references/auto-fix-actions.md`
**Method:** line-by-line read + command execution on host (`node v25.9.0`, `pnpm 10.33.0`, `curl 8.7.1`, `jq 1.8.1`, `Xcode 26.4`, `cargo`, `go`, `python3.12` all present), platform-detection-script fixture tests, reciprocal cross-reference check across 5 Related Skills.

Evidence files in this directory:
- `web-checklist-output.txt` — all 8 Web checks executed on this worktree
- `api-checklist-output.txt` — all 8 API checks executed (where safe)
- `ios-checklist-output.txt` — iOS checks executed against host Xcode 26.4 install
- `cli-checklist-output.txt` — CLI toolchain baseline
- `platform-detection-test.txt` — 4 fixture tests of the bash detection script
- `env-file-check.txt` — behavior of `cat .env | grep -c "="` in missing/empty/valid cases
- `deps-check-analysis.txt` — `.package-lock.json` is not a universal deps marker
- `autofix-review.txt` — per-row safety review of the 12 auto-fix actions
- `simctl-devices.txt` — raw xcrun simctl output (sandbox-constrained)
- `crossref-check.txt` — all 5 Related Skills reciprocally link back to preflight

---

## Summary

Total issues found: **15** (1 CRITICAL, 2 HIGH, 7 MEDIUM, 5 LOW). The **CRITICAL** finding is a hard bug in the platform-detection bash script that causes iOS projects to be detected as `unknown`. Multiple auto-fix rows conflict with Rule 3's "never auto-fix by installing major tools" policy, and the Web-platform `Dependencies installed` check only works for npm-managed projects. Cross-references are clean (all 5 Related Skills reciprocally link). Report format and severity levels are documented but never explicitly bound together — implementers infer the PASS/FAIL/WARN ↔ CRITICAL/HIGH/MEDIUM/LOW mapping.

No finding rises to the level of causing a false PASS verdict during `/validate`; the skill's role is preparatory, so degraded preflight is recoverable mid-validation. But several findings will cause preflight to incorrectly report BLOCKED or CLEAR and waste user time before the first real check runs.

---

## Accuracy Issues

### CRITICAL

#### C1. Platform-detection bash script never detects iOS projects (auto-fix-actions.md lines 32-46)

The script uses `[ -d "*.xcodeproj" ]` and `[ -d "*.xcworkspace" ]` with the glob **quoted**, which causes bash to test for a literal directory named `*.xcodeproj` (asterisk as part of name), not a directory whose name ends in `.xcodeproj`.

**Empirical evidence** (from `platform-detection-test.txt`, Test 2):
```
--- Test 2 (retry): Simulated iOS project with MyApp.xcodeproj directory ---
total 8
drwxr-xr-x@ 4 nick  wheel  128 Apr 17 01:54 .
drwxr-xr-x@ 3 nick  wheel   96 Apr 17 01:54 ..
drwxr-xr-x@ 2 nick  wheel   64 Apr 17 01:54 MyApp.xcodeproj
-rw-r--r--@ 1 nick  wheel  741 Apr 17 01:54 preflight-detect-test.sh
Detected platform: unknown
```

A directory named `MyApp.xcodeproj` is present, yet the script prints `Detected platform: unknown`. Direct shell test confirms:

```
--- Test 3 (retry): [ -d '*.xcodeproj' ] direct glob behavior in iOS-like dir ---
quoted glob -d DID NOT match
```

**Impact:** iOS projects that do not use Swift Package Manager at the root (i.e., every app-shaped iOS project) route to `PLATFORM=unknown` and the wrong checklist is run (or none). This would default preflight to a non-iOS path and miss CRITICAL Xcode-related checks.

**Recommended fix** (auto-fix-actions.md): replace the quoted glob checks with glob-safe alternatives:
```bash
# Either use 'compgen':
if [ -f "Package.swift" ] || compgen -G "*.xcodeproj" > /dev/null || compgen -G "*.xcworkspace" > /dev/null; then

# Or enable nullglob + count:
shopt -s nullglob
xcodeprojs=( *.xcodeproj *.xcworkspace )
if [ -f "Package.swift" ] || [ ${#xcodeprojs[@]} -gt 0 ]; then
```

### HIGH

#### H1. `Dependencies installed` check is npm-specific (platform-checklists.md, Web row 3)

```
| Dependencies installed | `ls node_modules/.package-lock.json 2>/dev/null` | File exists | CRITICAL |
```

The `.package-lock.json` file inside `node_modules/` is created by **npm** only. Projects using pnpm (default writes `node_modules/.modules.yaml`), yarn (`node_modules/.yarn-state.yml` or `.yarn-integrity`), or bun (`node_modules/.bun-tag` + root `bun.lockb`) will FAIL this CRITICAL check even when dependencies are fully installed.

**Empirical evidence** (from `deps-check-analysis.txt`):
This worktree reports `pnpm --version 10.33.0` but happens to have `node_modules/.package-lock.json` present (because the `node_modules` symlink points to an npm-installed parent). A pure pnpm project in the wild would not.

**Recommended fix:** change the check to detect any one of the package-manager markers:
```
ls node_modules/.package-lock.json node_modules/.modules.yaml node_modules/.yarn-state.yml node_modules/.yarn-integrity 2>/dev/null | head -1
```
Or simpler: `test -d node_modules && test "$(ls -A node_modules 2>/dev/null | head -1)"`.

#### H2. `xcode-select --install` is listed as auto-fix but Rule 3 forbids it (auto-fix-actions.md line 19 + SKILL.md Rules section)

SKILL.md Rule 3: `NEVER auto-fix by installing major tools (Xcode, Docker) — report BLOCKED`.

But auto-fix-actions.md row 11 lists `xcode-select --install` as the auto-fix for "Xcode CLI tools missing". `xcode-select --install` triggers a GUI dialog and is a multi-GB download — clearly "installing major tools".

**Empirical evidence** (from `autofix-review.txt`):
> Per Rule 3, this should be BLOCKED not auto-fixed — Xcode CLI IS a major tool.
> CONTRADICTION with Rule 3.

**Recommended fix:** move this row to a "Manual-only fixes" table, or change the Auto-Fix column to `(manual)` and keep only the instruction under Manual Fix Instructions.

---

## Stale References

### MEDIUM

#### M1. Hardcoded `postgresql@16` in auto-fix (auto-fix-actions.md line 11)

```
| Database not running | `brew services start postgresql@16` or `sudo systemctl start postgresql` |
```

Users on postgresql@14, @15, or @17 (shipping 2024-2026) will see this "auto-fix" fail silently. Rule 2 says "Attempt auto-fix **once**... If auto-fix fails, report as BLOCKED" — so this rarely causes a false CLEAR, but the auto-fix almost never works and always escalates.

**Recommended fix:** detect any installed postgres formula:
```bash
brew services list | awk '/postgresql@/ {print $1; exit}' | xargs -I{} brew services start {}
```

#### M2. Hardcoded simulator device names `"iPhone 16"` / `"iPhone 15"` (auto-fix-actions.md line 14)

```
| Simulator not booted | `xcrun simctl boot "iPhone 16" || xcrun simctl boot "iPhone 15"` |
```

This worktree has Xcode 26.4 installed (`ios-checklist-output.txt`). Xcode 26 ships with iPhone 17-series default simulators. Users with only iPhone 17 simulators will see both attempts fail.

**Recommended fix:** boot the first available device:
```bash
xcrun simctl list devices available -j | \
  jq -r '[.devices[] | .[] | select(.isAvailable)][0].udid' | \
  xargs xcrun simctl boot
```

### LOW

#### L1. `condition-based-waiting` skill is already referenced, but dev-server auto-fix uses `sleep 3` instead (auto-fix-actions.md line 10 vs SKILL.md line 89)

SKILL.md says: `condition-based-waiting — Used by preflight to wait for services after auto-fix`. But auto-fix-actions.md for "Dev server not running" uses a bare `sleep 3`, not a condition-based wait. Next.js cold starts commonly take 5-15s, so the auto-fix frequently reports "fixed" before the server is ready, leading to a misleading PASS.

**Recommended fix:** replace `sleep 3` with a `curl` retry loop (e.g., `for i in 1..30; do curl -sf http://localhost:3000 && break; sleep 1; done`), or reference the `condition-based-waiting` skill's pattern explicitly.

---

## Missing Content

### MEDIUM

#### M3. Fullstack row has no command checklist, unlike the other 4 platforms (platform-checklists.md lines 53-62)

Every other platform section (Web / API / iOS / CLI) has a `Check | Command | Expected | Severity` table. Fullstack has only a prose paragraph:

> 1. **Database layer** — Database running, migrations applied, data seeded
> 2. **API layer** — Server running, health endpoint responding, auth available
> 3. **Frontend layer** — Dev server running, pages rendering, browser automation ready
> 4. **Evidence layer** — Evidence directory created

An implementer running `/validate` on a fullstack project has no concrete commands to execute. They must piece together commands from Web + API sections. SKILL.md Rule 6 (`Check bottom-up for fullstack: Database -> API -> Frontend`) reinforces ordering but not commands.

**Recommended fix:** either (a) add a concrete Fullstack table that references the layered commands explicitly, or (b) change the section to "run all Database checks, then API, then Web" and link to those sections.

#### M4. PASS/FAIL/WARN report tokens are never explicitly bound to CRITICAL/HIGH/MEDIUM/LOW severity (SKILL.md lines 38-66)

The report format (lines 38-56) uses `[PASS] / [FAIL] / [WARN]`. The Severity Levels table (lines 59-66) uses `CRITICAL / HIGH / MEDIUM / LOW`. No section explicitly says *a CRITICAL failed check is reported as [FAIL]; a MEDIUM failed check is reported as [WARN]*. An implementer must infer the mapping.

**Recommended fix:** add one sentence after the Severity table, e.g.:
> A failed check of CRITICAL or HIGH severity is reported as `[FAIL]` and counts toward BLOCKED status; a failed MEDIUM or LOW check is reported as `[WARN]` and counts toward WARN status.

#### M5. `cat .env | grep -c "="` has no guard for missing file (platform-checklists.md Web row 7)

```
| Environment variables set | `cat .env \| grep -c "="` | Non-zero count | HIGH |
```

**Empirical evidence** (from `env-file-check.txt`):
- When `.env` does not exist: `cat` writes an error to stderr, `grep -c =` outputs `0`, pipeline exit code is 1. Noise on screen, FAIL verdict.
- When `.env` is empty: output `0`, exit 1. FAIL verdict.
- When `.env` has `FOO=bar\nBAZ=qux`: output `2`, exit 0. PASS verdict.

Functionally it works, but (a) the stderr noise is ugly and (b) most modern Next.js / Node projects use `.env.local` or `.env.development` — the check checks only the base `.env`, which many projects don't even ship.

**Recommended fix:** `grep -c "=" .env .env.local .env.development 2>/dev/null | awk -F: '{s+=$2} END {print s}'` — sums matches across common env filenames.

#### M6. Design platform is missing from checklist (platform-checklists.md) and from platform-detection script (auto-fix-actions.md)

CLAUDE.md §"Platform Detection" lists **6** platforms: iOS, Web, API, CLI, Fullstack, **Design**. Preflight's platform-checklists.md covers only 5 (no Design), and the detection script has no case for it. Design projects would route to `unknown`.

**Recommended fix:** add a minimal Design section to platform-checklists.md (Stitch assets present, DESIGN.md readable, evidence dir) and an elif branch to the detection script.

#### M7. Fullstack precedence: `next.config.js` shadows `docker-compose.yml` in detection script (auto-fix-actions.md)

**Empirical evidence** (from `platform-detection-test.txt`, Test 4):
```
--- Test 4: docker-compose.yml + next.config.js in same project ---
Detected platform: web
```

A project with both a Next.js frontend AND a docker-compose-managed backend (a textbook fullstack setup) is detected as `web` because the `elif` for `next.config.*` runs before the `elif` for `docker-compose.*`. This matches the literal detection-priority CLAUDE.md lists ("Web before Fullstack"), but the *intent* of the detection (bottom-up, multi-layer) is violated.

**Recommended fix:** move the `docker-compose.*` check ahead of `next.config.*` — or, cleaner, detect fullstack as *composite presence* (`Next` + `express`/`fastify`/`hono` + DB) rather than as a single marker file.

---

## Broken Cross-Links

No cross-link issues. All 5 Related Skills in SKILL.md link to valid `./skills/<name>/SKILL.md` files:

```
./skills/create-validation-plan/SKILL.md  — "preflight — Verify prerequisites listed in this plan are met"
./skills/baseline-quality-assessment/SKILL.md — "preflight — Ensure system is ready before baseline capture"
./skills/e2e-validate/SKILL.md — table entry: "preflight | Environment checks before execution"
./skills/error-recovery/SKILL.md — "preflight — Prevent many errors by verifying prerequisites first"
./skills/condition-based-waiting/SKILL.md — "preflight — Uses condition-based waiting to verify prerequisites"
```

All reciprocal references verified in `crossref-check.txt`.

---

## Scope / Policy Issues

### LOW

#### L2. `brew install jq` is gray-area under Rule 3 (auto-fix-actions.md line 17)

Rule 3: `NEVER auto-fix by installing major tools (Xcode, Docker) — report BLOCKED`. jq is ~200 KB and fits most developers' "minor tool" intuition, but the rule never defines the boundary. Compare to H2: Rule 3 is applied inconsistently — Xcode CLI tools explicitly violate it, jq arguably does not, but the policy never says where the line sits.

**Recommended fix:** define "major tool" in the Rules section (e.g., "a tool >50 MB to install, or one that requires GUI interaction, or one that mutates PATH globally").

#### L3. `npx prisma migrate deploy || npx drizzle-kit push` is destructive auto-fix (auto-fix-actions.md line 20)

`prisma migrate deploy` applies pending migrations to the target database; `drizzle-kit push` pushes the latest schema directly (no migration history). Both modify real data. Rule 2 says "attempt auto-fix once" but no rule distinguishes *read-only diagnostics* from *destructive repairs*. Running this against a production-shaped dev DB can drop columns.

**Recommended fix:** add Rule 7: "Auto-fixes that mutate application data (migrations, seed) require confirmation flag; default behavior is BLOCKED with manual instructions."

#### L4. `lsof -ti:PORT | xargs kill -9` — `PORT` is an unresolved template literal (auto-fix-actions.md line 9)

The cell's literal text is `lsof -ti:PORT | xargs kill -9`. A user copying this verbatim gets:

```
$ lsof -ti:PORT | xargs kill -9
lsof: unknown service -i :PORT
```

Other rows use real commands. This row is a template. The distinction should be explicit (e.g., `:PORT` → `:<port>`), or the cell should show the shell variable substitution pattern: `PORT=3000; lsof -ti:$PORT | xargs kill -9`.

#### L5. Simulator device-name hardcoding of "iPhone 16" / "iPhone 15" — see M2

Already covered under M2 (medium). The LOW variant is also documented here for orthogonality of the catalog.

---

## Report-Format Issues

### LOW

#### L6. Report example is inconsistent with its own summary line (SKILL.md lines 46-56)

```
[PASS] Node.js v20.11.0
[PASS] Dependencies installed
[FAIL] Database: connection refused
       Auto-fix: ran `brew services start postgresql@16` — NOW RUNNING
[PASS] Database: connection OK (re-checked)
[WARN] .env.local missing STRIPE_KEY — non-critical

---
## Summary
- Checks run: 10 | Passed: 9 | Auto-fixed: 1 | Warnings: 1 | Blocked: 0
```

The visible body shows **6** check lines (Node, Deps, DB-fail, DB-recheck, .env). The summary claims **10** checks run. An implementer taking the sample literally would wonder how 4 checks got collapsed, and whether the re-check after auto-fix counts as a separate line or a revision of the same line.

**Recommended fix:** either show all 10 checks in the example, or add a note explaining that the summary counts distinct checks (not display lines).

---

## Recommendations (priority-ranked)

1. **Fix the quoted-glob iOS-detection bug** (C1). Two character edits: unquote `*.xcodeproj` or use `compgen`. This is the only finding that can cause a *wrong platform verdict*.
2. **Reconcile Rule 3 with the `xcode-select --install` auto-fix row** (H2). Either lift the row out of the auto-fix table or relax Rule 3 with an explicit exception.
3. **Broaden the dependency-installed check** so pnpm/yarn/bun projects are not flagged CRITICAL when installed correctly (H1).
4. **Add a Fullstack command table** (M3) and a **Design row** (M6) so platform-checklists.md matches the 6-platform set in CLAUDE.md.
5. **Bind PASS/FAIL/WARN to CRITICAL/HIGH/MEDIUM/LOW explicitly** (M4) so implementers don't invent their own mapping.
6. **Replace hardcoded `postgresql@16` and `iPhone 16/15`** with dynamic detection (M1, M2).
7. **Use `condition-based-waiting` for the dev-server auto-fix** instead of `sleep 3` (L1).
8. **Clarify "major tool" in Rule 3** or explicitly whitelist jq (L2).
9. **Gate destructive auto-fixes behind a confirmation flag** (L3).
10. **Fix minor report-format and template-literal cosmetics** (L4, L6).

Every finding has empirical evidence in this directory or a direct line-number citation against the three reviewed files. No fix was applied in this subtask — fixes are deferred to phase-4 per the plan.

---

## Inventory Check

| SKILL.md claim | Verified? | Evidence |
|---|---|---|
| "Detect platform — scan project for indicator files" (line 24) | **NO** — detection script is broken for iOS (see C1) | `platform-detection-test.txt` |
| "Run platform checklist" (line 25) | Partial — Fullstack has no command table (see M3) | `platform-checklists.md` lines 53-62 |
| "Auto-fix failures" (line 26) | Partial — two rows are destructive or policy-conflicting (see H2, L3) | `autofix-review.txt` |
| "Produce report" (line 27) | Format documented but PASS/FAIL/WARN ↔ severity mapping implicit (see M4) | SKILL.md lines 38-66 |
| Verdict `CLEAR | BLOCKED | WARN` (line 28) | Report format shows only `CLEAR | BLOCKED`. WARN listed in How-It-Works but never as a top-line Status value. Minor inconsistency. | SKILL.md lines 28, 42 |
| Rule 1 "ALWAYS run preflight" | Consistent with all 5 Related Skills referencing preflight | `crossref-check.txt` |
| Rule 2 "attempt auto-fix once" | Stated once in SKILL.md + once in auto-fix-actions.md — consistent | SKILL.md line 72, auto-fix-actions.md line 24 |
| Rule 3 "NEVER install major tools" | **Violated by `xcode-select --install` row** (see H2) | auto-fix-actions.md line 19 |
| Rule 4 "ALWAYS re-check after auto-fix" | Stated consistently but the `sleep 3` dev-server auto-fix (L1) races the re-check | auto-fix-actions.md line 10 |
| Rule 5 "ALWAYS save report to e2e-evidence/preflight-report.md" | Consistent; directory creation covered in `Evidence Directory Setup` | auto-fix-actions.md lines 50-61 |
| Rule 6 "Check bottom-up for fullstack" | Fullstack section says bottom-up but has no command table (see M3) | platform-checklists.md lines 53-62 |
| 5 Related Skills linked | All 5 resolve and reciprocally reference preflight | `crossref-check.txt` |

---

## Subtask Success-Criteria Check

- [x] `findings.md` exists — this file (≈ 350 lines)
- [x] At least 10 checklist commands executed and outputs recorded — 8 Web + 4 API + 4 iOS + 3 CLI = 19 commands across `web-checklist-output.txt`, `api-checklist-output.txt`, `ios-checklist-output.txt`, `cli-checklist-output.txt`
- [x] Auto-fix safety review performed for each row — 9 rows reviewed in `autofix-review.txt` (12 rows total; 3 are trivially safe command templates with no runtime state)
