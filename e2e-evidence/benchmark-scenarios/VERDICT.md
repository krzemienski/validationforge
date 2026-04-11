# Benchmark Scenario Comparison — VERDICT

Generated: 2026-04-11T09:26:39Z

## Scenario Comparison Table

| Scenario | Defect Type | Grade | Aggregate | Coverage | Enforcement | Evidence Quality |
|----------|-------------|-------|-----------|----------|-------------|-----------------|
| scenario-01-api-rename | API rename without validation | C | 76 | 60 | 90 | 82 |
| scenario-02-jwt-expiry | Evidence without enforcement | F | 59 | 50 | 50 | 70 |
| scenario-03-ios-deeplink | Enforcement without evidence | F | 30 | 0 | 90 | 0 |
| scenario-04-db-migration | Full posture with verdicts | B | 84 | 60 | 100 | 100 |
| scenario-05-css-overflow | Zero validation, mocks present | F | 8 | 0 | 0 | 0 |
| vf-self-assessment | ValidationForge itself | B | 88 | 95 | 70 | 100 |

## Differentiation Validation

The benchmark model must differentiate good from poor validation posture.

Expected order (highest to lowest):
- scenario-04-db-migration (full posture) → highest grade
- scenario-01-api-rename (partial posture) → mid grade
- scenario-02-jwt-expiry, scenario-03-ios-deeplink, scenario-05-css-overflow → lowest grades (D/F)

Actual grades: scenario-04=B, scenario-01=C, scenario-02=F, scenario-03=F, scenario-05=F

Differentiation validated: YES — grade spread from F to B.

## Evidence Files

Each scenario directory in e2e-evidence/benchmark-scenarios/ contains:
- `step-01-score-output.md` — full scorer output with dimension breakdown
- `benchmark-result.json` — compact JSON result (coverage, evidence, enforcement, speed, aggregate, grade)
- `evidence-inventory.txt` — evidence manifest

## Conclusion

The 4-dimension scoring model (Coverage 35%, Evidence Quality 30%, Enforcement 25%, Speed 10%)
produces meaningfully differentiated results across different validation postures.
