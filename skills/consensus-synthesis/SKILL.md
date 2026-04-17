---
name: consensus-synthesis
description: Synthesize N per-validator verdicts into a single consensus verdict with confidence scoring based on agreement level.
triggers:
  - "synthesize consensus"
  - "consensus verdict"
  - "validator agreement"
  - "confidence score"
---

# Consensus Synthesis

Tabulate N per-validator verdicts into a single consensus verdict per journey, then
assign a confidence tier based on the agreement ratio. This is the voting and
confidence-scoring skill used by the `consensus-synthesizer` agent. It turns independent
per-validator reports into one synthesized report without silently discarding any
dissent.

The authoritative contract for synthesis states and the confidence formula is
`rules/consensus-engine.md §Synthesis States` and `§Confidence Formula`. In any
conflict between this SKILL.md and the rule, the rule wins.

This skill is read-only against validator evidence directories. It never writes to
`validator-N/` — it writes only to `e2e-evidence/consensus/report.md`.

## Input

N validator reports, one per spawned validator:

```
e2e-evidence/consensus/
  validator-1/report.md   ← or verdict.md, per the validator's emission convention
  validator-2/report.md
  validator-3/report.md
  ...
  validator-N/report.md
```

Preconditions before running this skill:

- **All N validators have completed.** A missing `validator-N/report.md` is a blocking
  condition — partial synthesis is forbidden. If any validator is missing, stop and
  signal the coordinator; do NOT compute an agreement ratio over fewer than N inputs.
- **Each report is non-empty.** A zero-byte report is invalid evidence of a verdict;
  treat it as validator error (see `rules/consensus-engine.md §Iron Rules` case d).
- **Each report cites evidence files in its own `validator-N/` directory.** The
  synthesizer re-reads those evidence files during disagreement analysis; reports
  without citations cannot be validated and must be treated as validator error.

The skill operates per-journey. For a plan with J journeys, the skill runs the
tabulation → synthesis → confidence cycle J times, then aggregates an overall run
verdict (see Output Schema below).

## Vote Tabulation

For each journey in the plan, extract each validator's PASS/FAIL verdict and each
validator's per-criterion verdicts (from the Criteria Assessment table defined in
`agents/verdict-writer.md`). Build a tabulation matrix:

### Per-journey tabulation

| Journey | Validator-1 | Validator-2 | Validator-3 | pass_count | fail_count | total_validators |
|---------|-------------|-------------|-------------|------------|------------|------------------|
| login | PASS | PASS | PASS | 3 | 0 | 3 |
| checkout | PASS | PASS | FAIL | 2 | 1 | 3 |
| settings | PASS | FAIL | FAIL | 1 | 2 | 3 |

### Per-criterion tabulation (within a journey)

When a journey has K PASS criteria, build a K-row sub-table so the disagreement
protocol can isolate the diverging criterion rather than re-running the whole journey:

| Criterion | V1 | V2 | V3 | Agreement |
|-----------|----|----|----|-----------|
| Login form submits valid credentials | PASS | PASS | PASS | UNANIMOUS |
| Error message shown on bad password | PASS | PASS | FAIL | MAJORITY |
| Session persists across refresh | PASS | FAIL | FAIL | MAJORITY (inverse) |

The per-criterion view is what feeds `skills/consensus-disagreement-analysis` when the
journey-level state is not UNANIMOUS.

## Synthesis Rules

Apply these rules per journey. See `rules/consensus-engine.md §Synthesis States` for
the authoritative table.

| State | Condition | Final Verdict | Confidence | Action |
|-------|-----------|---------------|------------|--------|
| **UNANIMOUS_PASS** | pass_count == total_validators | PASS | HIGH | Emit PASS with consensus citation; no disagreement analysis needed. |
| **UNANIMOUS_FAIL** | fail_count == total_validators | FAIL | HIGH | Emit FAIL with consensus citation; no disagreement analysis needed. |
| **MAJORITY_PASS** | pass_count > fail_count AND pass_count / total ≥ ⅔ | PASS | MEDIUM | Invoke `skills/consensus-disagreement-analysis`. Only emit PASS (MEDIUM) after analysis confirms the minority FAIL was validator error, missing evidence, or a re-runnable flake. Record the dissenting validator's evidence. |
| **MAJORITY_FAIL** | fail_count > pass_count AND fail_count / total ≥ ⅔ | FAIL | MEDIUM | Invoke `skills/consensus-disagreement-analysis`. Only emit FAIL (MEDIUM) after analysis confirms the minority PASS was premature or evidence-weak. Record the dissenting validator's evidence. |
| **SPLIT** | Neither side reaches ⅔ | DISAGREEMENT_UNRESOLVED | LOW | Invoke `skills/consensus-disagreement-analysis`. If analysis resolves it, promote to the appropriate MAJORITY state and re-synthesize. If unresolved, keep as DISAGREEMENT_UNRESOLVED (LOW) and escalate to human in the report. |

**Never shortcut the majority path.** A MAJORITY_PASS verdict is not safe to emit
until the disagreement protocol has looked at the dissenting validator's evidence and
either validated the majority's position or flipped it. Promoting a MAJORITY to a final
PASS/FAIL without analysis is equivalent to silently dropping the minority — see
Anti-Patterns below.

**Overall run verdict.** After each journey has a synthesized verdict, the overall run
verdict is the weakest journey verdict (weakest-link rule):

- If every journey is UNANIMOUS_PASS → overall PASS (HIGH)
- If any journey is DISAGREEMENT_UNRESOLVED → overall DISAGREEMENT_UNRESOLVED (LOW)
- Otherwise the weakest per-journey confidence sets the overall confidence tier

## Confidence Formula

Confidence is a direct function of the agreement ratio. See
`rules/consensus-engine.md §Confidence Formula`.

```
majority_count  = max(pass_count, fail_count)
agreement_ratio = majority_count / total_validators

confidence = HIGH    if agreement_ratio == 1.0               (unanimous)
confidence = MEDIUM  if 0.67 <= agreement_ratio < 1.0        (supermajority, after analysis resolves)
confidence = LOW     if agreement_ratio < 0.67               (split, unresolved)
```

Worked examples (total_validators = 3):

| pass_count | fail_count | majority_count | agreement_ratio | Tier |
|------------|------------|----------------|-----------------|------|
| 3 | 0 | 3 | 1.00 | HIGH |
| 0 | 3 | 3 | 1.00 | HIGH |
| 2 | 1 | 2 | 0.67 | MEDIUM |
| 1 | 2 | 2 | 0.67 | MEDIUM |
| 0 | 0 | 0 | undefined | validator error — all empty |

Worked examples (total_validators = 5):

| pass_count | fail_count | majority_count | agreement_ratio | Tier |
|------------|------------|----------------|-----------------|------|
| 5 | 0 | 5 | 1.00 | HIGH |
| 4 | 1 | 4 | 0.80 | MEDIUM |
| 3 | 2 | 3 | 0.60 | LOW (SPLIT) |
| 2 | 3 | 3 | 0.60 | LOW (SPLIT) |

**Confidence degrades monotonically.** Evidence quality cannot substitute for
agreement; no amount of compelling screenshots moves a MEDIUM verdict to HIGH. HIGH
requires unanimity. A re-run that flips a validator's vote does not retroactively
upgrade confidence — only the final tuple counts. If a re-run is needed, record it as
a separate synthesis pass with its own tuple and timestamp.

**Edge case: total_validators < 2.** The consensus engine requires ≥2 validators by
contract. If only one validator's report is present, abort synthesis and return to
the coordinator with a `CONSENSUS_ABORTED_INSUFFICIENT_VALIDATORS` signal. Do NOT emit
a HIGH confidence verdict from a single validator — that is single-validator mode,
not consensus, and misusing this skill that way defeats its purpose.

## Anti-Patterns

Treat every item below as a blocking violation. If you are tempted by any of these,
stop and re-read `rules/consensus-engine.md`.

| Anti-pattern | Why it is wrong |
|--------------|-----------------|
| Silently dropping a minority verdict | The minority is signal. A 2/3 PASS with 1/3 FAIL might mean the majority missed a bug only the dissenter found. Record and analyze, never drop. |
| Emitting MAJORITY as PASS/FAIL without running disagreement analysis | The table above requires disagreement analysis before MAJORITY resolves. Skipping it reduces consensus to simple voting. |
| Using the verdict `inconclusive` | There is no `inconclusive` state. A journey where agreement is below ⅔ is `DISAGREEMENT_UNRESOLVED`. Naming matters — it signals that a human must look at the dissent rather than accepting a soft-pass. |
| Averaging confidence levels | Confidence tiers are ordinal, not cardinal. "Average of HIGH and LOW" is not MEDIUM; it is a LOW-confidence run with one strong validator and one weak one, and the weakness dominates. |
| Upgrading confidence based on evidence quality | A validator with "better" screenshots does not trump disagreement. Confidence is a function of agreement ratio, period. |
| Emitting a final report before disagreement analysis completes for non-unanimous journeys | Partial synthesis produces misleading verdicts. Wait for the analysis skill's resolution. |
| Writing to any `validator-N/` directory from the synthesizer | This skill is strictly read-only against validator subdirectories. Writing there contaminates independence and invalidates the run. |
| Fabricating a validator verdict to break a tie | Synthesizer may not invent verdicts. If total is even and the tuple is exactly split, the state is SPLIT and the outcome is DISAGREEMENT_UNRESOLVED. |

## Output Schema

The synthesizer emits `e2e-evidence/consensus/report.md` matching
`templates/consensus-report.md`. At minimum, the report contains the following
sections for each journey:

```markdown
## Journey: {NAME}

**Synthesis State:** UNANIMOUS_PASS | UNANIMOUS_FAIL | MAJORITY_PASS | MAJORITY_FAIL | SPLIT
**Final Verdict:** PASS | FAIL | DISAGREEMENT_UNRESOLVED
**Confidence:** HIGH | MEDIUM | LOW
**agreement_ratio:** 0.00 – 1.00
**Validators:** N

### Vote Tabulation

| Validator | Verdict | Evidence Directory |
|-----------|---------|--------------------|
| Validator-1 | PASS | `e2e-evidence/consensus/validator-1/` |
| Validator-2 | PASS | `e2e-evidence/consensus/validator-2/` |
| Validator-3 | FAIL | `e2e-evidence/consensus/validator-3/` |

### Per-Criterion Tabulation

| # | Criterion | V1 | V2 | V3 | Agreement |
|---|-----------|----|----|----|-----------|
| 1 | {criterion} | PASS | PASS | PASS | UNANIMOUS |
| 2 | {criterion} | PASS | PASS | FAIL | MAJORITY |

### Dissenting Opinions

{For each dissenting validator: which criterion, what evidence they cited, what their
reasoning was. Never drop this section — if there is no dissent, write "None (UNANIMOUS)".}

### Disagreement Analysis (non-UNANIMOUS only)

{Summary of `skills/consensus-disagreement-analysis` output: diverging criterion,
sequential-analysis conclusion, resolution taken. Cite
`e2e-evidence/consensus/disagreement-analysis/`.}

### Final Verdict Reasoning

{Why the final verdict follows from the tuple and the synthesis state. Cite specific
evidence files from the majority validators' subdirectories.}
```

The report closes with:

```markdown
## Overall Run Verdict

**Verdict:** PASS | FAIL | DISAGREEMENT_UNRESOLVED
**Confidence:** HIGH | MEDIUM | LOW
**Journeys:** J total; {counts per state}
**Weakest-link journey:** {name} ({synthesis state})
```

The one-line stdout summary, for pipeline consumers:

```
ValidationForge CONSENSUS: J/K journeys PASS. Overall: {verdict} ({tier}). Report: e2e-evidence/consensus/report.md
```

## Integration

| Skill / File | Relationship |
|--------------|-------------|
| `rules/consensus-engine.md` | Authoritative contract. Defines synthesis states, confidence formula, roles, and iron rules. This skill implements §Synthesis States and §Confidence Formula. |
| `skills/consensus-engine` | Calls this skill in Step 4 after all validators complete. Provides the per-validator report list and the path where the synthesized report should be written. |
| `skills/consensus-disagreement-analysis` | Invoked by this skill whenever a journey's state is not UNANIMOUS. Must complete before a MAJORITY or SPLIT state resolves to a final verdict. |
| `agents/consensus-synthesizer` | The agent that invokes this skill. Supplies the validator report list and owns the final report write. |
| `agents/verdict-writer` | This skill extends verdict-writer discipline — every synthesized verdict cites evidence; dissent is never dropped; MAJORITY never resolves without analysis. |
| `templates/consensus-report.md` | Output format. The Output Schema above is the minimum required; the template defines the full structure. |

## Iron Rules (carry-over)

1. **No silent dissent.** Every minority verdict is recorded, analyzed, and either
   resolved or escalated.
2. **No partial synthesis.** All N validator reports must be present and non-empty
   before this skill runs.
3. **No writing to `validator-N/`.** Synthesis is strictly read-only against
   validator subdirectories.
4. **No `inconclusive` verdicts.** Use DISAGREEMENT_UNRESOLVED.
5. **No confidence inflation.** HIGH requires unanimity; no amount of evidence
   quality moves MEDIUM to HIGH.
6. **No synthesis from a single validator.** Consensus requires ≥2 inputs; single
   input aborts with CONSENSUS_ABORTED_INSUFFICIENT_VALIDATORS.
7. **Every PASS/FAIL in the synthesized report cites evidence from at least one
   validator's directory.** The synthesizer does not invent citations.
