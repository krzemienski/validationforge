---
phase: P09
name: Evidence retention + .gitignore
date: 2026-04-16
status: pending
gap_ids: [M4]
executor: fullstack-developer
validator: code-reviewer
depends_on: [P00]
---

# Phase 09 — Evidence Retention + Cleanup

## Why

TECHNICAL-DEBT.md M4: evidence retention is policy-only; no enforcement, no
`.gitignore` entry, no `--clean` flag behaviour. Evidence dirs could balloon,
or worse, be accidentally committed. Rules are in `rules/evidence-management.md`
but no code respects them.

## Pass criteria

<validation_gate id="VG-09" blocking="true">
  <prerequisites>
    - P00 verdict = PASS
    - `.vf-config.json` OR documented fallback to `config/standard.json`
    - `.vf/state/validation-in-progress.lock` absent OR stale (>1h)
  </prerequisites>

  <already_satisfied note="Reality check 2026-04-16">
    Root `.gitignore:8-13` already excludes `e2e-evidence/**` with preserve-
    allowlist for `report.md`, `evidence-inventory.txt`, `dashboard.html`.
    A second file `e2e-evidence/.gitignore` adds file-type exclusions.
    Original criterion #1 is ALREADY MET — validator cites existing lines.
    Executor only updates the inline comment to reference
    `rules/evidence-management.md` if that pointer is missing.
  </already_satisfied>

  <pass_criteria>
    1. `evidence/09-retention/gitignore-snapshot.txt` = output of
       `grep -n -C2 'e2e-evidence' .gitignore`. Snapshot must show the
       exclusion block AND a comment referencing `rules/evidence-management.md`.
    2. `/validate --clean` reads `evidence_retention_days` from the resolved
       config (precedence: env `VF_CONFIG_FILE` > `~/.claude/.vf-config.json`
       > `config/standard.json`) AND removes only directories whose mtime is
       older than `now - retention_days`.
    3. Demonstration uses a date POST-DATING project history start (DO NOT use
       `202601010000` from the original draft — that pre-dates repo existence
       and causes filesystem ambiguity). Use a date ≥ `retention_days` ago:
       ```
       D=$((RETENTION_DAYS + 1))
       mkdir -p /tmp/vf-cleanup-demo/e2e-evidence/fake-old-journey
       echo "synthetic" > /tmp/vf-cleanup-demo/e2e-evidence/fake-old-journey/step-01.txt
       touch -d "$(date -u -v-${D}d +%Y-%m-%dT%H:%M:%SZ)" \
         /tmp/vf-cleanup-demo/e2e-evidence/fake-old-journey
       VF_EVIDENCE_ROOT=/tmp/vf-cleanup-demo/e2e-evidence /validate --clean
       test ! -d /tmp/vf-cleanup-demo/e2e-evidence/fake-old-journey
       ```
       Transcript → `evidence/09-retention/demo-transcript.md`.
    4. `--clean --dry-run` implemented: lists targets without deleting.
       Verified by: run dry-run, assert target still exists; then real clean,
       assert gone. Both transcripts captured.
    5. Lock-file protocol (reuses `run.sh:27-37` idiom —
       `echo $$ > LOCKFILE; trap 'rm -f LOCKFILE' EXIT`):
       - If `.vf/state/validation-in-progress.lock` exists AND its `pid=` line
         references a LIVE process (`kill -0 $pid` exits 0), `/validate --clean`
         exits non-zero, stderr contains literal "validation in progress",
         NO file removed. Evidence: `evidence/09-retention/lock-refusal.txt`.
       - If lock exists but PID is dead AND `started=` line is >1h in the past,
         `--clean` proceeds and logs a WARN line to cleanup.log. Evidence:
         `evidence/09-retention/stale-lock-proceed.txt`.
    6. `e2e-evidence/cleanup.log` appended for each action with exact format:
       `<ISO-8601 UTC> | <absolute-path> | <mtime ISO-8601> | deleted|skipped|dry-run`
       Validator tails the log, asserts demo's row present, format matches regex.
    7. Campaign evidence dirs (`evidence/01-active-plan/`, `evidence/02-*/`, …)
       are NOT removed — validator greps `ls -d evidence/*/` before and after
       and asserts identical output.
    8. `rules/evidence-management.md` unchanged:
       `git diff --exit-code rules/evidence-management.md` exits 0.
  </pass_criteria>

  <review>
    Validator: (a) greps `.gitignore` for preserved block + comment, (b) cats
    `demo-transcript.md` confirming pre/post dir state, (c) cats both lock
    scenarios, (d) tails `cleanup.log` matching format regex, (e) runs
    `git diff --exit-code rules/evidence-management.md`, (f) confirms every
    `evidence/NN-*/` dir from this campaign is still present.
  </review>
  <verdict>
    PASS → advance P10. FAIL → escalate.
    CRITICAL: if `--clean` removed a live-campaign evidence dir, HALT campaign
    immediately and restore from `git`.
  </verdict>
  <mock_guard>
    Cleanup is integrated into real `/validate` command, not a test harness.
    Demo uses synthetic `/tmp/` path; no mocks. Lock detection uses real
    `kill -0` process checks against live PIDs.
  </mock_guard>
</validation_gate>

### Concurrency note (reconciliation with P10)

P10 patches hooks to read active profile at invocation time. Config reads are
read-only at runtime, so concurrent P10-hook + P09-cleanup is safe — BUT a user
editing `.vf-config.json` mid-cleanup could swap `retention_days` partway
through. Mitigation: cleanup captures `retention_days` ONCE at start and uses
that snapshot for the full run. Evidence: the capture site is visible in
`evidence/09-retention/clean-implementation.patch`.

## Inputs

- `.gitignore`
- `rules/evidence-management.md`
- `config/standard.json`
- `.vf/state/` dir
- Whichever script implements `/validate`

## Steps

1. Dispatch executor.
2. Executor adds `.gitignore` rule + comment.
3. Executor wires `--clean` to respect retention days + lock file.
4. Executor adds lock-file write/delete wrappers around validation start/end.
5. Executor demonstrates with synthetic old dir.
6. Dispatch validator.

## Evidence outputs

| File | Source |
|------|--------|
| `evidence/09-retention/gitignore-diff.patch` | `git diff .gitignore` |
| `evidence/09-retention/clean-implementation.patch` | code diff |
| `evidence/09-retention/demo-transcript.md` | `touch` + `--clean` demo |
| `evidence/09-retention/cleanup.log` | sample log |
| `evidence/09-retention/lock-refusal.txt` | lock-file protocol proof |

## Failure modes

- **`--clean` removes active evidence:** CRITICAL FAIL. Roll back.
- **Lock file never removed:** CRITICAL FAIL. Add trap/cleanup.
- **`.gitignore` already present:** skip; record existing rule as evidence.

## Duration estimate

2–3 hours.
