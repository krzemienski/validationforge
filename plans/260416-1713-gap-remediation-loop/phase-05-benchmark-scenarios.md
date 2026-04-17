---
phase: P05
name: Benchmark 5-scenario proof (B5)
date: 2026-04-16
status: pending
gap_ids: [B5]
executor: fullstack-developer
validator: code-reviewer
depends_on: [P01, P04]
---

# Phase 05 — Benchmark 5-Scenario Proof (B5)

## Why

The competitive claim that VF catches bugs that unit tests miss ("5/5 vs 0/5")
has never been empirically proven. `SPECIFICATION.md` names 5 canonical scenarios:
1. API field rename (JSON key drift)
2. JWT signature mismatch
3. iOS deep link broken
4. DB migration regression
5. CSS overflow clipping primary CTA

Each must be executed in a real project, VF must detect it, and unit-test oracle
must fail to detect it. Otherwise the public positioning is unsupported.

## Pass criteria

<validation_gate id="VG-05" blocking="true">
  <prerequisites>
    - P01 verdict = PASS
    - P04 verdict = PASS (platform detector ≥80% on external repos)
    - `evidence/00-preflight/demo-matrix.md` enumerates available demo dirs
    - For each in-scope scenario: target demo dir exists AND already contains a
      unit-test oracle (PRE-EXISTING test suite shipped with the demo). If no
      oracle exists in the demo repo, scenario becomes BLOCKED_WITH_USER.
      Executor does NOT create oracles.
  </prerequisites>
  <execute>
    For each in-scope scenario S:
    1. `git worktree add /tmp/vf-bench-<S> HEAD` — isolated, reversible
    2. Apply defect: `patch -p1 < evidence/05-benchmark/<S>-setup.patch` OR scripted
       mutation (e.g. `sed -i …`). Exact command recorded in scenarios.md.
    3. `cd /tmp/vf-bench-<S> && git add -A && git commit -m "defect: <S>"` — capture SHA
    4. Run VF: `/validate` from within the worktree; capture verdict + cited evidence
    5. Run the demo's PRE-EXISTING oracle (`pytest`, `go test`, `npm test`, etc.);
       capture raw stdout+stderr and exit code
    6. `git worktree remove /tmp/vf-bench-<S>`
  </execute>
  <capture>
    - `evidence/05-benchmark/scenarios.md` — scenario inventory table
    - `evidence/05-benchmark/<S>-setup.patch` — defect-introducing diff
    - `evidence/05-benchmark/<S>-defect-sha.txt` — committed defect SHA
    - `evidence/05-benchmark/<S>-vf-output.md` — `/validate` verdict + cited paths
    - `evidence/05-benchmark/<S>-oracle.txt` — oracle stdout+stderr
    - `evidence/05-benchmark/<S>-oracle-cmd.txt` — invoked command + oracle file path
    - `evidence/05-benchmark/scoreboard.md` — aggregate N×2 verdict table
  </capture>
  <pass_criteria>
    1. `scenarios.md` lists every IN-SCOPE scenario with columns:
       id | target_demo | bug_desc | mutation_cmd | defect_sha | oracle_cmd | oracle_file.
    2. Per in-scope scenario: VF verdict = FAIL AND the FAIL cites the mutated
       file path (grep-verifiable in `<S>-vf-output.md`).
    3. Per in-scope scenario: oracle PASSes (exit code 0 AND green in stdout).
       Oracle file MUST pre-exist at HEAD^ — validator confirms via
       `git show HEAD^:<oracle-file>` returning non-empty bytes.
    4. `scoreboard.md` reports VF `<N_vf>/<N_scope>` and Oracle `<N_oracle>/<N_scope>`
       where `N_scope` = count of IN-SCOPE scenarios only. A 5/5-vs-0/5 headline
       is claimed ONLY if all five scenarios were in-scope AND criteria 2+3 held.
    5. For each OUT-OF-SCOPE scenario: `scenarios.md` records BLOCKED_WITH_USER
       with the specific reason (missing demo OR missing oracle), and a follow-up
       plan stub is scaffolded in P13.
    6. If any VF run PASSes (VF miss), scoreboard records honestly; phase FAILs.
       Do NOT tune criteria after the fact to avoid the miss.
  </pass_criteria>
  <review>
    Validator opens scenarios.md, counts IN-SCOPE rows → scoreboard denominator.
    For each row: greps `<S>-vf-output.md` for the mutated file path; runs
    `git show HEAD^:<oracle-file> | wc -c` in the worktree (or pre-defect SHA) to
    confirm oracle pre-existence; reads oracle exit code from `<S>-oracle.txt`.
    No criterion may be satisfied by a validator- or executor-authored artifact.
  </review>
  <verdict>
    PASS → B5 gap CLOSED; competitive claim may cite scoreboard.md with exact ratio.
    FAIL → B5 stays OPEN; scoreboard published with honest ratio; README/competitive
    docs MUST NOT claim 5/5-vs-0/5 unless scoreboard shows it.
  </verdict>
  <mock_guard>
    The original draft's failure-mode clause "synthesize a minimal [oracle] inline"
    is REMOVED. Creating `*.test.*` / `*.spec.*` under `src/` or `lib/` would be
    blocked by `hooks/block-test-files.js`; creating them anywhere else still
    violates the Iron Rule. IF an oracle is missing → scenario is BLOCKED_WITH_USER,
    not fabricated.
  </mock_guard>
</validation_gate>

### Demo-reality notes (2026-04-16)

| # | Scenario | Target demo | Reality check | Status |
|---|----------|-------------|---------------|--------|
| 1 | API field rename (JSON key drift) | `demo/python-api/` | EXISTS; oracle TBD in P00 | tentative in-scope |
| 2 | JWT signature mismatch | any auth demo | no auth demo confirmed | likely out-of-scope |
| 3 | iOS deep link broken | iOS demo | no iOS demo on disk | OUT-OF-SCOPE until scaffolded |
| 4 | DB migration regression | DB-backed demo | depends on python-api features | tentative in-scope |
| 5 | CSS overflow clipping CTA | `demo/nextjs-web/` | `demo/nextjs-web/` ABSENT on disk | OUT-OF-SCOPE until scaffolded |

P00 must resolve each row into `demo-matrix.md` before this phase begins.
Scoreboard denominator tracks only IN-SCOPE scenarios.

## Inputs

- `SPECIFICATION.md` (scenario definitions)
- `commands/validate-benchmark.md`
- `demo/` subdirs (Nextjs, Flask, etc.)
- `.vf/benchmarks/`

## Steps

1. Dispatch executor.
2. For each scenario:
   a. Fork demo dir to `/tmp/vf-bench-<scenario>/` (or branch).
   b. Introduce defect (e.g., rename `email` to `emailAddr` in response JSON).
   c. Commit defect locally; capture SHA.
   d. Run `/validate` in demo; capture output.
   e. Run unit test oracle; capture output.
   f. Restore demo (reset branch).
3. Build scoreboard.
4. Write `evidence/05-benchmark/scenarios.md` and per-scenario files.
5. Dispatch validator.

## Evidence outputs

| File | Source |
|------|--------|
| `evidence/05-benchmark/scenarios.md` | Executor synthesis |
| `evidence/05-benchmark/<scenario>-setup.patch` | Defect diff |
| `evidence/05-benchmark/<scenario>-vf-output.md` | `/validate` output |
| `evidence/05-benchmark/<scenario>-unit-test.txt` | Oracle output |
| `evidence/05-benchmark/scoreboard.md` | 5×2 table with evidence refs |

## Failure modes

- **No demo dir for iOS scenario (#3):** substitute with a second API scenario
  OR document as blocked; phase may not claim 5/5 until fixed.
- **VF produces PASS on a defective demo:** root-cause; either a genuine
  gap in the skill (fix it) or the scenario setup was wrong (redo).
- **Unit-test oracle is non-existent:** synthesize a minimal one inline; must
  be a real test that the defect would not fail.

## Duration estimate

3–5 hours.
