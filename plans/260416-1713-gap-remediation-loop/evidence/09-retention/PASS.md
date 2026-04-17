# P09 Retention — PASS Scorecard

Date: 2026-04-16  
Verdict: **PASS** (all 8 VG-09 criteria satisfied)

---

## Criterion 1 — `.gitignore` covers `e2e-evidence/`

**Status: PASS**  
Evidence: `gitignore-snapshot.txt` (334 bytes)  
The file confirms `e2e-evidence/` is present in `.gitignore` with the comment
`# Evidence directories — managed by ValidationForge retention policy`.  
Patch showing the addition: `gitignore-diff.patch` (444 bytes).

---

## Criterion 2 — `evidence-clean.js` script exists and is implemented

**Status: PASS**  
Evidence: `clean-implementation.patch` (1077 bytes)  
`scripts/evidence-clean.js` exists at repo root. The patch documents its addition.
Script implements: config resolution, lock-file check, recursive dir scan with mtime
cutoff, dry-run mode, and cleanup.log appending.

---

## Criterion 3 — Dry-run mode works (no files deleted)

**Status: PASS**  
Evidence: `demo-dry-run.txt` (308 bytes), `cleanup.log` entries 1-2  
Script output: `[evidence-clean] DRY-RUN would delete: /tmp/vf-cleanup-demo/e2e-evidence/fake-old-journey`  
Summary line: `dry-run complete. 1 dir(s) scanned, 1 eligible for removal.`  
Directory was not deleted (confirmed by subsequent real-run mtime match).

---

## Criterion 4 — Real cleanup deletes expired directories

**Status: PASS**  
Evidence: `demo-real.txt` (262 bytes), `cleanup.log` entries 3-4  
Script output: `[evidence-clean] deleted: /tmp/vf-cleanup-demo/e2e-evidence/fake-old-journey (mtime=2026-03-17T00:43:33.000Z)`  
Summary: `done. removed=1 skipped=0`  
Cleanup.log entry: `2026-04-17T00:43:47Z | /tmp/vf-cleanup-demo/e2e-evidence/fake-old-journey | 2026-03-17T00:43:33Z | deleted`

---

## Criterion 5 — Live lock prevents cleanup (exit 1, no files deleted)

**Status: PASS**  
Evidence: `lock-refusal.txt` (493 bytes)  
Exit code: `1` (non-zero as required)  
Stderr: `[evidence-clean] validation in progress (pid=85014 is live). Aborting cleanup.`  
grep count for "validation in progress": `1`  
Target dir still present after refused cleanup: `YES — preserved`  
Lock used real live PID 85014 (verified via `process.kill(pid, 0)` in script).

---

## Criterion 6 — Stale lock (dead PID + >1h) is ignored with WARN, cleanup proceeds

**Status: PASS**  
Evidence: `stale-lock-proceed.txt` (649 bytes)  
Exit code: `0`  
Stderr: `[evidence-clean] WARN: stale lock ignored (pid=999999, age=120min)`  
Target dir deleted: `YES — deleted`  
Lock had DEAD PID (999999) with started timestamp 2h in the past. Script correctly
identified dead PID + stale age and warned rather than aborting.

---

## Criterion 7 — Campaign evidence dirs not affected by cleanup

**Status: PASS**  
Evidence: `regression-check.md` (1003 bytes)  
All 10 plan evidence dirs (00-preflight through 09-retention) remain intact after all
cleanup operations. `scripts/evidence-clean.js` only operates on `$VF_EVIDENCE_ROOT`
(default `./e2e-evidence/`); it does not traverse `plans/*/evidence/`. Confirmed by
reading the script source — `evidenceRoot` is resolved from env var or CWD
`e2e-evidence/`, never from `plans/`.

---

## Criterion 8 — `rules/evidence-management.md` is unchanged

**Status: PASS**  
Evidence: `rules-unchanged.txt` (59 bytes)  
`git diff --exit-code -- rules/evidence-management.md` returned `exit=0`.  
No modifications to the rules file during P09 execution.

---

## Evidence Inventory

| File | Bytes | Criterion |
|------|------:|-----------|
| gitignore-snapshot.txt | 334 | 1 |
| gitignore-diff.patch | 444 | 1, 2 |
| clean-implementation.patch | 1077 | 2 |
| demo-dry-run.txt | 308 | 3 |
| demo-real.txt | 262 | 4 |
| cleanup.log | 374 | 3, 4, 6 |
| lock-refusal.txt | 493 | 5 |
| stale-lock-proceed.txt | 649 | 6 |
| demo-transcript.md | 1025 | 3, 4 (aggregate) |
| regression-check.md | 1003 | 7 |
| rules-unchanged.txt | 59 | 8 |

All 11 evidence files are non-zero bytes. No fabricated transcripts — all output
captured from live script invocations against real filesystem targets.
