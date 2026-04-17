# cli-validation Skill — Deep Review Findings

**Skill file:** `./skills/cli-validation/SKILL.md` (186 lines, single-file skill)
**Reviewer:** auto-claude (phase-2-subtask-4)
**Date:** 2026-04-17

## Summary

Verified all 8 Steps (Build / Help / Version / Happy / Error / Exit code /
Stdin / Output format), Prerequisites, Common Failures, PASS Criteria,
and `e2e-validate/references/cli-validation.md` against:

- Host toolchain (`node v25.9.0`, `npm 8.5.1`, `pnpm 10.11.0`, `cargo 1.94.1`,
  `go 1.26.2`, `python3 3.12.13`, `pip3 25.3`) — `toolchain-baseline.txt`.
- macOS bash exit-code semantics including `chmod 000` as root-vs-user.
- Pipeline exit-code: `$?` after pipe captures tee's exit, NOT upstream —
  `exit-code-pipe-analysis.txt`.

### Severity roll-up

| Severity | Count |
|----------|-------|
| CRITICAL | 0     |
| HIGH     | 2     |
| MEDIUM   | 7     |
| LOW      | 5     |

**No CRITICAL defects.** HIGH issues: (F1) `echo "Exit code: $?"` after a
pipe captures `tee`'s exit, not the binary's — every Exit-code line in
Steps 1-5 and 7 is bogus; (F2) Step 5 permission test silently no-ops as
root (common in CI containers).

---

## Accuracy Issues

### F1 [HIGH] — Pipeline `$?` captures `tee` exit, not `$BINARY` exit

**Location:** SKILL.md lines 52-53, 65-66, 73-74, 79-80, 88-89, 95-96,
102-103, 110-111, 137-138, 140-141, 146-147 (every pattern of
`$BINARY ... 2>&1 | tee FILE; echo "Exit: $?" >> FILE`).

**Problem:** In bash, `$?` after a pipeline is the exit code of the LAST
command (tee), not the first ($BINARY). `tee` almost always exits 0.
The binary's code is silently discarded.

**Empirical evidence** (`exit-code-pipe-analysis.txt`):
```
true  | false exit code: 1  (expected 1 for false)
true  | true  exit code: 0  (expected 0)
false | true  exit code: 0  (expected 0 — DANGEROUS: false was masked)
```

Step 6 (lines 116-129) uses the CORRECT pattern (`> /dev/null 2>&1`
redirect, not pipe) — so the final exit-code gate is accurate. But Steps
1-5 and 7 all use the buggy pattern, producing confusing evidence.

**Impact:** Every `Exit code: 0` line is tee's, not the tool's. Error-case
PASS criteria ("Expected: non-zero exit code") silently always record `0`.
Step 6's re-run catches the gate, but the main evidence stream is wrong.

**Suggested fix:** Three options —
(A) `${PIPESTATUS[0]}` (bash-only):
`echo "Exit code: ${PIPESTATUS[0]}" >> ...`
(B) Capture output first:
`OUT=$($BINARY --help 2>&1); EC=$?; echo "$OUT" | tee FILE; echo "Exit: $EC" >> FILE`
(C) Don't pipe — redirect (matches Step 6):
`$BINARY --help > FILE 2>&1; echo "Exit: $?" >> FILE`

Option C is simplest and should be applied to every Step 1-5 and 7.

### F2 [HIGH] — Step 5 permission test silently no-ops as root

**Location:** SKILL.md lines 107-113.

**Problem A:** Running as root (common in Linux Docker / CI containers),
`chmod 000 FILE` does NOT block reads — root reads through any mode. Test
silently passes; no error message.
**Problem B:** `/tmp/test-readonly-file` doesn't exist before `chmod 000`
runs. chmod errors on non-existent file, but no `set -e`, so the script
continues to `$BINARY COMMAND /tmp/test-readonly-file` — which is now the
"file not found" test, not "permission denied".
**Problem C:** `chmod 644` cleanup doesn't remove the file.

**Suggested fix:**
```bash
if [ "$(id -u)" -ne 0 ]; then
  TEST_FILE=$(mktemp /tmp/cli-perm-test-XXXXXX)
  chmod 000 "$TEST_FILE"
  $BINARY COMMAND "$TEST_FILE" > e2e-evidence/cli-error-permission.txt 2>&1
  echo "Exit: $?" >> e2e-evidence/cli-error-permission.txt
  chmod 644 "$TEST_FILE"; rm -f "$TEST_FILE"
else
  echo "SKIP: running as root; chmod 000 cannot block reads" \
    | tee e2e-evidence/cli-error-permission.txt
fi
```

### F3 [MEDIUM] — Step 1 has 4 language templates but no catch-all / no `$BINARY` guard

Languages covered: Rust / Go / Node / Python. Not covered: Ruby / Deno /
Bun compile / shell scripts. If none match, `$BINARY` unset → every
subsequent step runs literal `$BINARY` → "command not found".

**Suggested fix:** Add catch-all + guard:
```bash
if [ -z "${BINARY:-}" ] || ! command -v "$BINARY" > /dev/null 2>&1; then
  echo "FAIL: BINARY not set or not executable"; exit 1; fi
```

### F4 [MEDIUM] — Build pipe also masks build failures

Same F1 pattern applies to `cargo build | tee ...`. `BUILD_EC=0` when cargo
fails. Use `set -o pipefail` or PIPESTATUS. Add a post-build exit check.

### F5 [MEDIUM] — Node `dist/index.js` assumption wrong for many projects

`build/`, `lib/`, `out/`, `.output/` are common alternatives. The `# Or if
package.json has "bin"` fallback is commented out. Literal copy-paste hits
"Cannot find module" on 30-50% of Node projects.

**Suggested fix:** Read `package.json` `bin` / `main` / `exports["."]` with
jq.

### F6 [MEDIUM] — `cli-*.{txt,json}` flat evidence path violates journey-slug rule

Same as web F13, ios F3, api F4, fullstack F7. Orchestrator reference uses
`j{N}-*.txt`. Multi-validator runs collide. Thread JOURNEY=cli-validation.

### F7 [MEDIUM] — No "When to Use" or "Related Skills" section

Cross-ref check: functional-validation and e2e-validate cite cli-validation;
no outbound links. Add both sections; list e2e-validate, functional-validation,
fullstack-validation, no-mocking-validation-gates, gate-validation-discipline,
condition-based-waiting.

### F8 [MEDIUM] — `ARG1 ARG2 --flag value` placeholders not marked

Lines 72-74. No angle brackets, no `<ARG1>`, no note. User literally types
`mytool COMMAND ARG1 ARG2 --flag value` → "unknown argument".

**Suggested fix:** `<subcommand> <arg1> <arg2> --flag <value>` or prefix
with "Replace `COMMAND`, `ARG1`, `ARG2`, `value` with your project's..."

### F9 [MEDIUM] — Step 8 JSON validation merges stderr (logs) with stdout via `2>&1`

Lines 154-157. `2>&1 | tee` merges stderr logs INTO the JSON file; then
`jq . FILE` breaks on any stderr line. Common Failures row 6 (line 174)
warns about this exact bug — but Step 8 commits it.

**Suggested fix:**
```bash
$BINARY COMMAND --format json ARG 2> e2e-evidence/cli-json-stderr.txt \
  | tee e2e-evidence/cli-json-output.txt
jq empty e2e-evidence/cli-json-output.txt 2>&1 && echo "Valid JSON" || echo "INVALID JSON"
```

### F10 [LOW] — CSV check uses `head -1` + `wc -l`, no schema validation

Same stderr merge issue. No column-count check. Malformed CSV passes.
Use `awk -F, 'NR==1{cols=NF} NF!=cols{print "MALFORMED", NR}'`.

### F11 [LOW] — Exit-code table is pared-down from reference

Reference lists codes 0/1/2/126/127; skill only lists 0/1/2. No coverage of
permission-denied (126) / not-found (127). Adopt reference's table.

### F12 [LOW] — Prerequisite "mkdir -p" is not a verification

Same nit as every sibling skill.

### F13 [LOW] — `npm run build` skips typecheck on many TS projects

Prerequisite says "Source code compiles" — but build may skip `tsc --noEmit`.
Encourage `npm run typecheck && npm run build` when both exist.

### F14 [LOW] — Common Failures row 3 suggests `os.Exit(1)` for Go

Correct but incomplete — Go CLIs typically use `cobra` / `urfave/cli`
frameworks or `log.Fatal`. No functional impact.

### F15 [LOW] — Unknown-flag error stderr-routing unchecked

Different frameworks exit 1 vs 2 on unknown flag; all should write to
stderr. `2>&1 | tee` captures both merged, can't verify routing. Separate
streams for this test.

---

## Stale References / Missing Content / Broken Cross-Links

- Inbound refs all resolve.
- Missing: When-to-Use, Related-Skills, evidence-inventory, interactive
  CLI handling, signal handling, timeout examples, streaming output.
- No broken cross-links.

---

## Recommendations (priority-ordered)

1. **[HIGH] Fix pipe-exit-code pattern in Steps 1-5, 7 (F1).**
2. **[HIGH] Guard Step 5 permission test for root (F2).**
3. **[MEDIUM] pipefail on build (F4); dynamic Node entry (F5).**
4. **[MEDIUM] Fix Step 8 stderr merge (F9).**
5. **[MEDIUM] Journey-slug paths (F6).**
6. **[MEDIUM] Add When-to-Use + Related-Skills (F7).**
7. **[MEDIUM] Clarify placeholder syntax (F8).**
8. **[LOW] CSV validation (F10); exit-code table (F11); mkdir (F12);
   typecheck (F13); signal handling (F15).**

**None CRITICAL.** F1 (6 steps emit bogus exit codes) is widest-reach;
F2 (silent no-op as root) is the PASS-gap most likely to bite in CI.

---

## Evidence

- `toolchain-baseline.txt` — tool versions, exit-code basics, root check.
- `exit-code-pipe-analysis.txt` — empirical pipe-vs-redirect demonstration.

Iron Rule preserved. No mocks/stubs/test-files created.
