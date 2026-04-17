---
name: consensus-disagreement-analysis
description: >
  When validators disagree on a consensus verdict, run root cause analysis to
  determine whose evidence is stronger.
triggers:
  - "validators disagree"
  - "consensus disagreement"
  - "resolve disagreement"
  - "split verdict"
---

# Consensus Disagreement Analysis

When `skills/consensus-synthesis` detects a non-unanimous verdict for a journey,
this skill resolves the disagreement by applying `skills/sequential-analysis`
to each diverging criterion. It is the arbitration layer between vote
tabulation and final verdict emission.

The authoritative contract for when this skill runs, and what resolutions it
may emit, is `rules/consensus-engine.md §Disagreement Protocol` and
`§Synthesis States`. In any conflict between this SKILL.md and the rule, the
rule wins.

This skill is **strictly read-only** against validator subdirectories. It
NEVER writes to `validator-N/`. It writes only to
`e2e-evidence/consensus/disagreement-analysis/`.

## When This Skill Runs

Triggered when `consensus-synthesis` computes a journey state of anything
other than UNANIMOUS_PASS or UNANIMOUS_FAIL:

- **MAJORITY_PASS** → resolve whether the minority FAIL was validator error,
  missing evidence, or a real defect the majority missed.
- **MAJORITY_FAIL** → resolve whether the minority PASS was premature or
  evidence-weak, or whether the majority FAIL is wrong.
- **SPLIT** → attempt resolution; if unresolvable, return
  DISAGREEMENT_UNRESOLVED (LOW confidence).

Do NOT invoke this skill when the journey is UNANIMOUS — there is no
disagreement to resolve, and forcing the protocol wastes cycles and risks
fabricating a dissent that does not exist.

## Protocol

```
Step 1: IDENTIFY    Step 2: LOAD         Step 3: INVOKE           Step 4: APPLY
Which criterion     Both validators'     sequential-analysis      Phases 1–4
did validators      evidence files for   with FAIL as symptom,    (Symptom → Hypothesize
rate differently?   the diverging        PASS evidence as         → Investigate → Conclude)
                    criterion            hypothesis to test

                                        Step 5: EMIT RESOLUTION
                                        MINORITY_CORRECT  → flip majority
                                        MAJORITY_CORRECT  → keep majority, record dissent
                                        UNRESOLVABLE      → DISAGREEMENT_UNRESOLVED
```

### Step 1: Identify the Diverging Criterion

Read the per-criterion tabulation table emitted by `consensus-synthesis`. For
a journey with K PASS criteria, find the rows where at least one validator
disagreed with the others. A journey-level MAJORITY or SPLIT always has at
least one diverging criterion — if it does not, the tabulation is malformed
and must be regenerated before this skill proceeds.

| # | Criterion | V1 | V2 | V3 | Agreement |
|---|-----------|----|----|----|-----------|
| 1 | Login submits valid creds | PASS | PASS | PASS | UNANIMOUS (skip) |
| 2 | Error shown on bad pwd    | PASS | PASS | FAIL | **DIVERGING** |
| 3 | Session persists refresh  | PASS | FAIL | FAIL | **DIVERGING** |

Emit `e2e-evidence/consensus/disagreement-analysis/step-01-diverging-criteria.md`
listing each diverging criterion, the vote tuple, and which validators are in
the majority vs the minority for that criterion.

**Criterion-level, not journey-level.** Two validators can both emit journey
PASS while disagreeing on criterion #3 internally, if one counted criterion
#3 as a non-blocker. Always operate on the criterion grain — that is what the
per-criterion tabulation is for.

### Step 2: Load Both Validators' Evidence (Read-Only)

For each diverging criterion, enumerate the evidence files cited by each side
from their respective `validator-N/` subdirectories:

```
e2e-evidence/consensus/validator-1/step-04-error-banner.png
e2e-evidence/consensus/validator-1/step-05-network-response.json
e2e-evidence/consensus/validator-3/step-04-error-banner.png
e2e-evidence/consensus/validator-3/step-05-console-error.txt
```

Open, read, and summarize each file. **Do not modify any file inside
`validator-N/`.** Writes into another validator's evidence directory
invalidate the independence guarantee of the whole consensus run — see
`rules/consensus-engine.md §File Ownership`.

If a cited evidence file is missing or zero-byte, that is a first-class
signal: the validator's verdict for this criterion is validator error
(`rules/consensus-engine.md §Disagreement Protocol` case d). Record it and
skip to Step 5 with a RESOLUTION of `MAJORITY_CORRECT (minority discarded as
validator error)` — do NOT fabricate evidence to fill the gap.

Emit
`e2e-evidence/consensus/disagreement-analysis/step-02-evidence-inventory.md`
with one subsection per diverging criterion listing:

- Majority evidence files (path + one-line observation)
- Minority evidence files (path + one-line observation)
- Obvious gaps (missing files, zero-byte files, unreachable citations)

### Step 3: Invoke `skills/sequential-analysis`

For each diverging criterion, call `skills/sequential-analysis` with this
framing:

- **Symptom (Phase 1 input):** the FAIL verdict — "Validator-X reports FAIL
  for criterion {C} in journey {J}. Expected: {PASS criterion text}. Actual:
  {FAIL validator's cited observation}."
- **Hypothesis to test (Phase 2 seed):** the PASS verdict's evidence — "The
  PASS validators cited {files} which purport to show criterion {C} passing.
  Is this evidence sufficient, contradicted, or stale?"

Because the analysis is now comparative (PASS evidence vs FAIL evidence), the
hypothesis set must include at minimum:

| # | Hypothesis | How to confirm |
|---|-----------|----------------|
| H1 | FAIL is correct; PASS evidence is stale/misread | Re-read PASS evidence against criterion wording; look for version/timestamp drift |
| H2 | PASS is correct; FAIL captured a pre-fix state or flake | Check FAIL timestamps vs PASS timestamps; look for "works on retry" signal |
| H3 | Criterion is under-specified; both readings are valid | Re-read criterion against both sides' citations; check for ambiguity |
| H4 | FAIL validator made a reachability/tooling error | Check FAIL evidence for empty files, broken selectors, wrong URLs |
| H5 | PASS validator made an evidence-quality error | Check PASS evidence for missing observations, bare status codes, 0-byte files |

Additional hypotheses from the categories in
`skills/sequential-analysis` (Data / Timing / Environment / Code /
Integration / Infrastructure / Validation setup) are required when they
apply.

Save the sequential-analysis inputs and thought log to
`e2e-evidence/consensus/disagreement-analysis/step-03-sequential-analysis-inputs.md`.

### Step 4: Apply Sequential-Analysis Phases 1–4

Execute the four phases defined in `skills/sequential-analysis/SKILL.md`
within this consensus context. The phases map one-to-one:

| Sequential-Analysis Phase | Consensus Context |
|---------------------------|-------------------|
| Phase 1: SYMPTOM          | Diverging criterion: exact PASS/FAIL wording + cited evidence on each side |
| Phase 2: HYPOTHESIZE      | The comparative hypothesis table above, plus any category-specific additions |
| Phase 3: INVESTIGATE      | Read both sides' evidence; confirm or rule out each hypothesis using only the already-captured files (no re-running of validators from inside this skill) |
| Phase 4: CONCLUDE         | Root cause: which side's evidence is stronger, or whether the criterion is under-specified |

Write the analysis report to
`e2e-evidence/consensus/disagreement-analysis/step-04-analysis.md` in the
format `skills/sequential-analysis/SKILL.md` specifies (Root Cause → Evidence
Chain → Hypotheses Evaluated → Recommended Fix / Prevention).

**Re-runs are the coordinator's job, not this skill's.** If Phase 3
investigation concludes that a validator must re-capture evidence (case a or
b in `rules/consensus-engine.md §Disagreement Protocol`), record the request
and return control to the coordinator. This skill must not spawn a validator.

### Step 5: Emit a Resolution

Each diverging criterion resolves to exactly one of three states. The
criterion's resolution rolls up into the journey's final verdict per the
rules in `consensus-synthesis`.

| Resolution | Condition | Journey Effect |
|------------|-----------|----------------|
| **MINORITY_CORRECT** | Phase 4 concludes the minority validator's evidence is stronger — the majority missed a real defect, misread the criterion, or captured stale state. | Flip the journey verdict to match the minority. The final verdict reflects the dissent; confidence stays at the agreement-ratio tier (MEDIUM at best, because the ratio was < 1.0 to begin with). |
| **MAJORITY_CORRECT** | Phase 4 concludes the majority's evidence is stronger — the minority validator erred (missing evidence, wrong selector, stale snapshot, misread criterion). | Keep the majority verdict. Record the dissenting validator's evidence and the analysis in the report so the dissent is never silently dropped. |
| **UNRESOLVABLE** | Phase 4 cannot decide — criterion is under-specified, evidence is genuinely contradictory, or the real system is non-deterministic and no re-run is feasible in this run. | Journey resolves to `DISAGREEMENT_UNRESOLVED` (LOW confidence). Escalate to human with the full analysis. Do NOT downgrade to MAJORITY to avoid the escalation. |

Emit `e2e-evidence/consensus/disagreement-analysis/step-05-resolution.md`
with one row per diverging criterion:

| # | Criterion | Majority | Minority | Resolution | Rationale |
|---|-----------|----------|----------|------------|-----------|
| 2 | Error shown on bad pwd | PASS (V1,V2) | FAIL (V3) | MAJORITY_CORRECT | V3 captured 0-byte screenshot; cited evidence unreadable. |
| 3 | Session persists refresh | PASS (V1) | FAIL (V2,V3) | MINORITY_CORRECT | V1's screenshot is from pre-refresh state; V2+V3 captured post-refresh cookie clear. |

The resolution set is returned to `consensus-synthesis`, which re-synthesizes
the journey with the post-analysis verdicts and finalizes the report.

**No fourth state.** The three resolutions above are exhaustive. Inventing a
"MOSTLY_CORRECT" or "INCONCLUSIVE" bucket to dodge the UNRESOLVABLE
escalation is an anti-pattern; see `consensus-synthesis` on the prohibition
of `inconclusive`.

## Evidence Path

All artifacts from this skill live under:

```
e2e-evidence/consensus/disagreement-analysis/
  step-01-diverging-criteria.md
  step-02-evidence-inventory.md
  step-03-sequential-analysis-inputs.md
  step-04-analysis.md
  step-05-resolution.md
```

Additional investigation artifacts (e.g., diffs between validators' screenshots,
terminal transcripts) go in the same directory with `step-NN-*` prefixes so
ordering is preserved.

This directory is owned by this skill. `consensus-synthesis` reads from it
but does not write here; validators never touch it.

## Integration

| Skill / File | Relationship |
|--------------|-------------|
| `rules/consensus-engine.md` | Authoritative contract. §Disagreement Protocol specifies when this skill runs and what resolutions are permitted. In conflict, rule wins. |
| `skills/consensus-synthesis` | Invokes this skill whenever a journey's state is not UNANIMOUS. Consumes this skill's resolution set to produce the final synthesized verdict. |
| `skills/sequential-analysis` | Called in Step 3–4. This skill is a specialization of sequential-analysis: the FAIL verdict is the symptom, the PASS evidence is the seed hypothesis, and the resolution maps back to the consensus state machine. |
| `agents/consensus-synthesizer` | Agent that drives `consensus-synthesis` and therefore this skill. Owns the final write to `e2e-evidence/consensus/report.md`. |
| `agents/verdict-writer` | This skill inherits verdict-writer discipline: every resolution cites evidence; no dissent is silently dropped; no fabricated verdicts. |

## Iron Rules (Carry-Over)

1. **Read-only against validator subdirectories.** NEVER modify another
   validator's evidence — doing so invalidates the run.
2. **No fabricated verdicts.** If Phase 4 cannot decide, emit UNRESOLVABLE
   and escalate. Do not invent a tiebreaker.
3. **No silent dissent.** Even MAJORITY_CORRECT resolutions record the
   dissenter's evidence and the analysis reasoning.
4. **No re-synthesis inside this skill.** Return resolutions; let
   `consensus-synthesis` re-tabulate.
5. **No validator spawning inside this skill.** If a re-run is required,
   return that as an output and let the coordinator handle it.
6. **No confidence upgrades.** A resolved MAJORITY is still MEDIUM; flipping
   MINORITY_CORRECT does not become HIGH. Agreement ratio gates confidence.
7. **Criterion-grain analysis only.** Operate on the per-criterion
   tabulation; journey-level disagreement is always decomposable into one or
   more diverging criteria.
