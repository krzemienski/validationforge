# Consensus Report: {{FEATURE_NAME}}

**Feature:** {{FEATURE_NAME}}
**Platform:** {{PLATFORM}}
**Validators:** {{VALIDATOR_COUNT}}
**Synthesis Date:** {{DATE}}
**Overall Verdict:** {{PASS | FAIL | DISAGREEMENT_UNRESOLVED}}
**Confidence:** {{HIGH | MEDIUM | LOW}}
**Synthesizer:** ValidationForge consensus-synthesizer

> Authoritative contract: `rules/consensus-engine.md`. Synthesis rules: `skills/consensus-synthesis/SKILL.md`. Disagreement protocol: `skills/consensus-disagreement-analysis/SKILL.md`.

---

## Summary: Per-Criterion Consensus Matrix

Each row shows one PASS criterion from one journey, each validator's independent verdict, the synthesized Consensus verdict, and the Confidence tier for that row.

| Journey | Criterion | V1 | V2 | V3 | Consensus | Confidence |
|---------|-----------|----|----|----|-----------|------------|
| {{J1_NAME}} | {{J1_C1}} | {{V1_J1_C1}} | {{V2_J1_C1}} | {{V3_J1_C1}} | {{CONSENSUS_J1_C1}} | {{CONF_J1_C1}} |
| {{J1_NAME}} | {{J1_C2}} | {{V1_J1_C2}} | {{V2_J1_C2}} | {{V3_J1_C2}} | {{CONSENSUS_J1_C2}} | {{CONF_J1_C2}} |
| {{J2_NAME}} | {{J2_C1}} | {{V1_J2_C1}} | {{V2_J2_C1}} | {{V3_J2_C1}} | {{CONSENSUS_J2_C1}} | {{CONF_J2_C1}} |
| {{J2_NAME}} | {{J2_C2}} | {{V1_J2_C2}} | {{V2_J2_C2}} | {{V3_J2_C2}} | {{CONSENSUS_J2_C2}} | {{CONF_J2_C2}} |

**Pass Rate:** {{PASS_COUNT}}/{{TOTAL_CRITERIA}} criteria at Consensus={{PASS}} ({{PERCENTAGE}}%)

---

## Validator Reports

Each validator operated independently on its own evidence subdirectory. Links below resolve to per-validator artifacts; the synthesizer re-read every cited evidence file before emitting the Consensus column above.

| # | Report | Evidence Inventory | Verdict Summary |
|---|--------|--------------------|-----------------|
| 1 | `e2e-evidence/consensus/validator-1/report.md` | `e2e-evidence/consensus/validator-1/evidence-inventory.txt` | {{V1_VERDICT_SUMMARY}} |
| 2 | `e2e-evidence/consensus/validator-2/report.md` | `e2e-evidence/consensus/validator-2/evidence-inventory.txt` | {{V2_VERDICT_SUMMARY}} |
| 3 | `e2e-evidence/consensus/validator-3/report.md` | `e2e-evidence/consensus/validator-3/evidence-inventory.txt` | {{V3_VERDICT_SUMMARY}} |

---

## Agreement Analysis

`agreement_ratio = majority_count / total_validators` per `rules/consensus-engine.md §Confidence Formula`.

### Per-Criterion Agreement

| Journey | Criterion | pass_count | fail_count | agreement_ratio | State |
|---------|-----------|------------|------------|-----------------|-------|
| {{J1_NAME}} | {{J1_C1}} | {{J1_C1_PASS_COUNT}} | {{J1_C1_FAIL_COUNT}} | {{J1_C1_AGREEMENT_RATIO}} | {{J1_C1_STATE}} |
| {{J1_NAME}} | {{J1_C2}} | {{J1_C2_PASS_COUNT}} | {{J1_C2_FAIL_COUNT}} | {{J1_C2_AGREEMENT_RATIO}} | {{J1_C2_STATE}} |
| {{J2_NAME}} | {{J2_C1}} | {{J2_C1_PASS_COUNT}} | {{J2_C1_FAIL_COUNT}} | {{J2_C1_AGREEMENT_RATIO}} | {{J2_C1_STATE}} |
| {{J2_NAME}} | {{J2_C2}} | {{J2_C2_PASS_COUNT}} | {{J2_C2_FAIL_COUNT}} | {{J2_C2_AGREEMENT_RATIO}} | {{J2_C2_STATE}} |

### Overall Agreement

**overall_agreement_ratio:** {{OVERALL_AGREEMENT_RATIO}}
**Computation:** {{OVERALL_AGREEMENT_COMPUTATION — e.g., mean of per-criterion agreement_ratios OR weakest-link rule from §Synthesis States}}
**Journey-state counts:** UNANIMOUS_PASS={{COUNT_UNANIMOUS_PASS}}, UNANIMOUS_FAIL={{COUNT_UNANIMOUS_FAIL}}, MAJORITY_PASS={{COUNT_MAJORITY_PASS}}, MAJORITY_FAIL={{COUNT_MAJORITY_FAIL}}, SPLIT={{COUNT_SPLIT}}
**Weakest-link journey:** {{WEAKEST_JOURNEY_NAME}} ({{WEAKEST_JOURNEY_STATE}})

---

## Dissenting Opinions

For each non-unanimous criterion, the minority validator's cited evidence and reasoning are preserved verbatim. Dissent is never discarded per `rules/consensus-engine.md §Iron Rules`. If there is no dissent (every criterion UNANIMOUS), record `None (UNANIMOUS run)` below.

### {{DISSENT_1_JOURNEY}} — {{DISSENT_1_CRITERION}}

**Minority Validator:** Validator-{{DISSENT_1_VALIDATOR_INDEX}}
**Minority Verdict:** {{DISSENT_1_MINORITY_VERDICT}}
**Majority Verdict:** {{DISSENT_1_MAJORITY_VERDICT}}
**Cited Evidence:**
- `e2e-evidence/consensus/validator-{{DISSENT_1_VALIDATOR_INDEX}}/{{DISSENT_1_EVIDENCE_FILE}}` — {{DISSENT_1_WHAT_WAS_OBSERVED}}

**Minority Reasoning:**
> {{DISSENT_1_REASONING_VERBATIM — quoted from the minority validator's report.md §Reasoning}}

---

### {{DISSENT_2_JOURNEY}} — {{DISSENT_2_CRITERION}}

**Minority Validator:** Validator-{{DISSENT_2_VALIDATOR_INDEX}}
**Minority Verdict:** {{DISSENT_2_MINORITY_VERDICT}}
**Majority Verdict:** {{DISSENT_2_MAJORITY_VERDICT}}
**Cited Evidence:**
- `e2e-evidence/consensus/validator-{{DISSENT_2_VALIDATOR_INDEX}}/{{DISSENT_2_EVIDENCE_FILE}}` — {{DISSENT_2_WHAT_WAS_OBSERVED}}

**Minority Reasoning:**
> {{DISSENT_2_REASONING_VERBATIM}}

---

## Disagreement Resolution

For each non-unanimous criterion, the sequential-analysis outcome is recorded below. Resolution states per `skills/consensus-disagreement-analysis/SKILL.md`:

- **MINORITY_CORRECT** — the dissenter found a real defect the majority missed; the consensus verdict is flipped to the minority's position.
- **MAJORITY_CORRECT** — the minority's evidence was weak, stale, or a flake; the majority verdict stands and the dissent is recorded for audit.
- **UNRESOLVABLE** — sequential-analysis could not conclude; the Consensus column is set to `DISAGREEMENT_UNRESOLVED` and the journey is escalated.

### {{DISSENT_1_JOURNEY}} — {{DISSENT_1_CRITERION}}

**Resolution:** {{DISSENT_1_RESOLUTION}} ({{MINORITY_CORRECT | MAJORITY_CORRECT | UNRESOLVABLE}})
**Diverging Criterion:** {{DISSENT_1_DIVERGING_CRITERION}}
**Sequential-Analysis Evidence:** `e2e-evidence/consensus/disagreement-analysis/{{DISSENT_1_ANALYSIS_FILE}}`
**Root Cause:** {{DISSENT_1_ROOT_CAUSE — specific defect, evidence gap, or validator error; not a guess}}
**Final Action Taken:** {{DISSENT_1_ACTION — e.g., flipped consensus to FAIL based on Validator-3's evidence / upheld majority PASS with dissent recorded / escalated as DISAGREEMENT_UNRESOLVED}}

---

### {{DISSENT_2_JOURNEY}} — {{DISSENT_2_CRITERION}}

**Resolution:** {{DISSENT_2_RESOLUTION}} ({{MINORITY_CORRECT | MAJORITY_CORRECT | UNRESOLVABLE}})
**Diverging Criterion:** {{DISSENT_2_DIVERGING_CRITERION}}
**Sequential-Analysis Evidence:** `e2e-evidence/consensus/disagreement-analysis/{{DISSENT_2_ANALYSIS_FILE}}`
**Root Cause:** {{DISSENT_2_ROOT_CAUSE}}
**Final Action Taken:** {{DISSENT_2_ACTION}}

---

## Final Verdict

```
overall_verdict = majority_verdict   IF majority_confidence >= MEDIUM
                = DISAGREEMENT_UNRESOLVED   OTHERWISE
```

Where `majority_verdict` is derived from the aggregated per-journey synthesis states and `majority_confidence` is the weakest-link confidence across all journeys (`HIGH` only if every journey is UNANIMOUS; `MEDIUM` if any journey resolved through MAJORITY with disagreement-analysis closure; `LOW` if any journey is SPLIT/UNRESOLVABLE). See `rules/consensus-engine.md §Synthesis States` and `§Confidence Formula`.

**majority_verdict:** {{MAJORITY_VERDICT}}
**majority_confidence:** {{MAJORITY_CONFIDENCE}}
**overall_verdict (applied):** {{OVERALL_VERDICT}}
**overall_confidence (applied):** {{OVERALL_CONFIDENCE}}

**Reasoning:** {{FINAL_VERDICT_REASONING — cite the weakest-link journey, the synthesis state that drove the overall tier, and the evidence that settled any disagreement}}

---

## Evidence Inventory

Complete list of files under `e2e-evidence/consensus/` across all validator subdirectories and the synthesizer's own subdirectory, with byte counts. Zero-byte files are INVALID evidence per Iron Rule #8.

### Validator-1 (`e2e-evidence/consensus/validator-1/`)

| # | File | Bytes | What Was Observed |
|---|------|-------|-------------------|
| 1 | `{{V1_FILE_1}}` | {{V1_FILE_1_BYTES}} | {{V1_FILE_1_DESCRIPTION}} |
| 2 | `{{V1_FILE_2}}` | {{V1_FILE_2_BYTES}} | {{V1_FILE_2_DESCRIPTION}} |

### Validator-2 (`e2e-evidence/consensus/validator-2/`)

| # | File | Bytes | What Was Observed |
|---|------|-------|-------------------|
| 1 | `{{V2_FILE_1}}` | {{V2_FILE_1_BYTES}} | {{V2_FILE_1_DESCRIPTION}} |
| 2 | `{{V2_FILE_2}}` | {{V2_FILE_2_BYTES}} | {{V2_FILE_2_DESCRIPTION}} |

### Validator-3 (`e2e-evidence/consensus/validator-3/`)

| # | File | Bytes | What Was Observed |
|---|------|-------|-------------------|
| 1 | `{{V3_FILE_1}}` | {{V3_FILE_1_BYTES}} | {{V3_FILE_1_DESCRIPTION}} |
| 2 | `{{V3_FILE_2}}` | {{V3_FILE_2_BYTES}} | {{V3_FILE_2_DESCRIPTION}} |

### Disagreement Analysis (`e2e-evidence/consensus/disagreement-analysis/`)

| # | File | Bytes | What Was Observed |
|---|------|-------|-------------------|
| 1 | `{{DA_FILE_1}}` | {{DA_FILE_1_BYTES}} | {{DA_FILE_1_DESCRIPTION}} |
| 2 | `{{DA_FILE_2}}` | {{DA_FILE_2_BYTES}} | {{DA_FILE_2_DESCRIPTION}} |

**Total Evidence Files:** {{TOTAL_EVIDENCE_FILES}}
**Total Evidence Bytes:** {{TOTAL_EVIDENCE_BYTES}}
**Zero-Byte Files Detected:** {{ZERO_BYTE_COUNT}} ({{ZERO_BYTE_STATUS — MUST be 0 for a valid run}})

---

## Stdout Summary

```
ValidationForge CONSENSUS: {{PASS_JOURNEY_COUNT}}/{{TOTAL_JOURNEY_COUNT}} journeys PASS. Overall: {{OVERALL_VERDICT}} ({{OVERALL_CONFIDENCE}}). Report: e2e-evidence/consensus/report.md
```
