---
phase: P08
name: CONSENSUS + FORGE engines - test or defer
date: 2026-04-16
status: pending
gap_ids: [M1, M2]
executor: fullstack-developer (if test) OR researcher (if defer)
validator: code-reviewer
depends_on: [P05, P07]
---

# Phase 08 — CONSENSUS + FORGE Engines

## Why

PRD.md names three engines: VALIDATE (shipping), CONSENSUS (V1.5 planned), FORGE
(V2.0 planned). TECHNICAL-DEBT.md M1/M2 flag that CONSENSUS (3-reviewer unanimous
voting) and FORGE (autonomous fix loop, 3-strike) have never been executed
end-to-end. Decision U1 from Phase 00 decides test-now vs formally-defer.

## Pass criteria

<validation_gate id="VG-08" blocking="true">
  <prerequisites>
    - P05 verdict = PASS (scoreboard provides a defect for FORGE test branch)
    - P07 verdict = PASS (forge-execute skill not broken)
    - `logs/decisions.md` contains a line matching `^U1: (test|defer)$`
  </prerequisites>

  <branch condition="U1 == test">
    <execute>
      CONSENSUS: `/validate-team` with 3 validators on one P05 in-scope scenario;
      stage three vote configurations: 3-agree, 2-agree, 1-agree (staged at the
      INPUT-DATA level — no test files, no source mocks).
      FORGE: `/forge-execute` on a shallow P05 scenario (≤3 fix iterations).
      Worktree-isolated; cleaned up after.
    </execute>
    <pass_criteria>
      1. `evidence/08-engines/consensus-3agree.md` cites 3 validators all PASS
         AND final CONSENSUS verdict = PASS (literal on last line).
      2. `evidence/08-engines/consensus-2agree.md` cites 2 PASS + 1 FAIL AND
         final CONSENSUS verdict = HOLD (literal on last line; NOT PASS).
      3. `evidence/08-engines/consensus-1agree.md` cites 1 PASS + 2 FAIL AND
         final CONSENSUS verdict = FAIL (literal on last line).
      4. `evidence/08-engines/forge-loop-transcript.md` shows chronological
         attempt 1 FAIL → fix proposal → patch applied (diff quoted) → attempt 2
         verdict. Loop terminates at PASS OR at attempt 3 with final FAIL.
         NEVER exceeds 3 attempts.
      5. `evidence/08-engines/forge-fix-diff.patch` is non-empty AND
         `git apply --check <patch>` exits 0.
      6. NO new files under `src/`, `lib/`, or matching `*.test.*` / `*.spec.*` /
         `_test.go` / `test_*.py`. Validator greps `git diff` for these and
         expects zero matches.
    </pass_criteria>
  </branch>

  <branch condition="U1 == defer">
    <execute>
      BEFORE: run greps below, capture to `claims-grep-before.txt`.
      Patch each match to "planned" language.
      AFTER: re-run greps, capture to `claims-grep-after.txt`. Zero AFTER matches
      of forbidden phrases is the pass bar.
    </execute>
    <scrub_targets>
      Files to grep (and edit where matches found):
        `README.md`, `COMPETITIVE-ANALYSIS.md`, `CLAUDE.md`, `SPECIFICATION.md`,
        `SKILLS.md`, `COMMANDS.md`,
        every `.md` under `docs/` and `site/` (`find docs site -name '*.md' 2>/dev/null`).
      Forbidden phrases (case-insensitive, PCRE):
        `(CONSENSUS|FORGE) (engine|mode) (ships?|is available|works|is supported|is production)`
        `3-reviewer (unanimous|voting)` (unless preceded by "planned" within 10 chars)
        `autonomous fix loop` (unless preceded by "planned" within 10 chars)
        `(consensus|forge)-(execute|validate)` presented as a CURRENT capability
    </scrub_targets>
    <pass_criteria>
      1. `docs/ENGINES-DEFERRED.md` exists and includes ALL of:
         - Deferment: CONSENSUS → V1.5, FORGE → V2.0 (explicit)
         - Measurable deferment-exit criteria (e.g., "CONSENSUS exits deferment
           when `/validate-team` is successfully invoked in N=10 distinct external
           repos with evidence under `.vf/benchmarks/`") — no vague aspiration
         - Verbatim user-facing statement ready to paste into README
         - Owner + target re-visit date (ISO 8601 `YYYY-MM-DD`)
      2. `evidence/08-engines/claims-grep-before.txt` is non-empty AND lists ≥1
         match (proves there was something to scrub). If empty, record why.
      3. `evidence/08-engines/claims-grep-after.txt` shows ZERO matches for every
         forbidden phrase (validator re-runs the greps and confirms).
      4. `evidence/08-engines/defer-scrub-diff.patch` shows every edited file.
      5. CLAUDE.md Commands section marks `validate-team` / `forge-execute` as
         "planned" or removes them from the current-inventory count (Phase 03
         sync must reflect this in the regression gate).
    </pass_criteria>
  </branch>

  <review>
    Validator reads `logs/decisions.md` line matching `^U1:` to select the branch.
    Opens every cited evidence file, asserts bytes > 0, re-runs the greps in
    scrub-targets against the post-scrub tree, and asserts required literals are
    present/absent per the branch's criteria.
  </review>
  <verdict>PASS → advance P09. FAIL → escalate per LOOP-CONTROLLER.</verdict>
  <mock_guard>
    Test branch: `/forge-execute` fixes a REAL defect in a REAL demo worktree.
    No test files authored by this phase. The 3-strike cap is a FORGE property,
    not a testing harness. Defer branch: no mocks applicable.
  </mock_guard>
</validation_gate>

## Inputs

- `logs/decisions.md` (U1)
- `skills/parallel-validation/SKILL.md`, `commands/validate-team.md`
- `skills/forge-benchmark/SKILL.md`, `commands/forge-execute.md`
- Phase 05 scoreboard scenarios (suitable as FORGE test bed)

## Steps (test branch)

1. Dispatch executor.
2. Stage CONSENSUS test: run `/validate-team` with 3 sub-agent validators.
3. Introduce deliberate FAIL in test project; run `/forge-execute`; observe
   propose→fix→retry loop.
4. Record every output verbatim to `evidence/08-engines/`.
5. Dispatch validator.

## Steps (defer branch)

1. Dispatch executor (researcher).
2. Write `docs/ENGINES-DEFERRED.md` with explicit acceptance criteria.
3. Grep README/COMPETITIVE-ANALYSIS.md for any CONSENSUS/FORGE claims;
   patch to "planned" where found.
4. Dispatch validator to confirm all such claims scrubbed.

## Evidence outputs

| File | Source | Branch |
|------|--------|--------|
| `evidence/08-engines/consensus-3agree.md` | test | test |
| `evidence/08-engines/consensus-2agree.md` | test | test |
| `evidence/08-engines/consensus-1agree.md` | test | test |
| `evidence/08-engines/forge-loop-transcript.md` | test | test |
| `evidence/08-engines/forge-fix-diff.patch` | test | test |
| `docs/ENGINES-DEFERRED.md` | defer | defer |
| `evidence/08-engines/defer-scrub-diff.patch` | defer | defer |

## Failure modes

- **Test: 3-strike not respected:** FAIL; root-cause in FORGE skill.
- **Test: CONSENSUS returns WRONG verdict for 2-agree:** FAIL; fix rule.
- **Defer: README still claims engines ship:** FAIL until scrubbed.

## Duration estimate

- Test: 4–6 hours
- Defer: 1–2 hours
