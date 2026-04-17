# P12 Regression — P05 Benchmark 5-Scenario Proof (B5)

**Date:** 2026-04-16
**Source verdict:** plans/260416-1713-gap-remediation-loop/validators/P05-verdict.md (FAIL, B5 BLOCKED_WITH_USER)
**Regression verdict:** PASS
**Validator:** code-reviewer (P12 regression sub-agent, a4128d005b3e7d966)

## Mandate

Verify that the honest scoreboard from P05 remains honest AND that no late edit
introduced a 5/5-vs-0/5 claim into the live docs scoped by the regression prompt
(`SPECIFICATION.md`, `README.md`, `COMPETITIVE-ANALYSIS.md`).

## Scorecard

| # | Pass criterion | Result | Evidence |
|---|----------------|--------|----------|
| 1 | `scoreboard.md` still shows 0/0 (honest ratio) | **PASS** | `evidence/05-benchmark/scoreboard.md` lines 9–10: `VF detected (FAIL verdict cites mutated path): 0 / 0`; `Oracle PASSes (exit 0 on pre-existing tests): 0 / 0`. Criteria Eval row 4 reads `PASS — honest 0/0`. Headline block marks the 5/5-vs-0/5 claim explicitly `INELIGIBLE`. |
| 2 | No 5/5-vs-0/5 claim reappears in `SPECIFICATION.md`, `README.md`, `COMPETITIVE-ANALYSIS.md` | **PASS** | `grep -nE '5/5\|five out of five' SPECIFICATION.md README.md COMPETITIVE-ANALYSIS.md` returns zero hits (three empty outputs). All three files are scrubbed. |
| 3 | B5 remains BLOCKED_WITH_USER | **PASS** | (a) scoreboard.md scenario table: all 5 rows = `BLOCKED_WITH_USER`. (b) validator `P05-verdict.md` frontmatter: `disposition: B5 stays OPEN — recommend mark BLOCKED_WITH_USER`. (c) `docs/ENGINES-DEFERRED.md` L11 cites `B5 → BLOCKED_WITH_USER` as the deferment rationale. |

## Raw commands (executed 2026-04-16)

```
ls plans/260416-1713-gap-remediation-loop/evidence/05-benchmark/
  → scenarios.md, scoreboard.md   (both non-empty)

grep -E 'N_vf|N_oracle|N_scope' plans/260416-1713-gap-remediation-loop/evidence/05-benchmark/scoreboard.md
  → 4 lines confirming N_vf/N_scope and N_oracle/N_scope formalism retained.

grep -nE '5/5|five out of five' SPECIFICATION.md     → (empty)
grep -nE '5/5|five out of five' README.md            → (empty)
grep -nE '5/5|five out of five' COMPETITIVE-ANALYSIS.md → (empty)

grep -E 'B5|benchmark|5-scenario' docs/ENGINES-DEFERRED.md
  → L11: "demo/* lacked pre-existing test oracles (see B5 → BLOCKED_WITH_USER)."
  → L18: benchmark evidence under `.vf/benchmarks/` path referenced.
```

## Supporting checks

- **B5 scoreboard shape:** scoreboard.md still uses the `N_vf/N_scope` and
  `N_oracle/N_scope` formalism. Criterion Eval row 4 confirms `PASS — honest 0/0`.
  No post-hoc substitution of `5/5` or `5/0` was found.
- **Executor discipline:** No worktree residue noted in P05 verdict
  (`git worktree list` showed only main). No test files authored under
  `src/`/`lib/`, no fabricated oracles in `demo/*`. The Iron Rule remained
  intact between P05 close-out and this regression.
- **docs/ENGINES-DEFERRED.md alignment:** explicitly cites the B5
  BLOCKED_WITH_USER state as the reason CONSENSUS and FORGE engines are deferred,
  with measurable exit criteria keyed to "≥ 10 distinct external repos" for
  CONSENSUS and "≥ 10 full 3-strike loops" for FORGE. Consistent with the honest
  scoreboard.

## Residual concerns (NOT regression failures — out of P12 P05 scope)

The regression prompt's pass-criteria grep scope is `SPECIFICATION.md`,
`README.md`, `COMPETITIVE-ANALYSIS.md` — those three files are clean. A wider
repo sweep still shows 5/5-vs-0/5 language in the following files, which are
*outside* the regression pass scope but are logged here so downstream phases can
pick them up:

| File | Line(s) | Nature | Status |
|------|---------|--------|--------|
| `PRD.md` | 610, 659 | "Backed by real data (5/5 vs 0/5)" persona copy | Scope drift — not a regression failure |
| `PRD.md` | 772 | Scorecard table `Bugs caught (of 5) 0/5 \| 1/5 \| 5/5 \| 4/5` | **Mitigated in-file** — §12.2 explicitly labels this "theoretical outcomes...design-level predictions, not empirical measurements", and cross-references TECHNICAL-DEBT §3.3. Honest disclaimer present. |
| `MARKETING-INTEGRATION.md` | 96 | "Present the evidence: 5/5 vs 0/5 benchmark table" | Marketing artifact, not production doc. Scope drift for P05. |
| `task_plan.md` | 7 | Historical "[x] Remove `Score: Unit tests catch 0/5...` from README" | Historical log — OK |
| `TECHNICAL-DEBT.md` | 136, 283 | Explicitly flags the unverified 5/5 claim as tech debt | OK — this is the tech-debt register, not a live product claim |
| `findings.md` | 48 | "Removed dishonest `Score: 0/5 vs 5/5` benchmark claim" | Historical — OK |
| `e2e-evidence/report.md`, `scripts/verify-plugin.sh`, `docs/case-studies/self-validation.md`, `whats-next.md`, `progress.md` | various | Non-benchmark `5/5` usages (criteria counts, step labels `[5/5]`, scoring out of 5, JSON parse counts) | OK — false positive for the benchmark claim |

The P05 validator's verdict had already recommended a doc-scrub of 5/5-vs-0/5
references as a P13 follow-up; the three pass-scoped files were scrubbed.
`PRD.md` and `MARKETING-INTEGRATION.md` remain follow-up candidates but are not
in regression scope per the prompt.

## Verdict

**Regression: PASS.** The honest scoreboard survives; the three live docs in
regression scope are free of `5/5` / `five out of five` hits; B5 remains
`BLOCKED_WITH_USER` across scoreboard, validator verdict, and the engines
deferment doc. No late edit introduced a 5/5-vs-0/5 claim into the scoped
surfaces.
