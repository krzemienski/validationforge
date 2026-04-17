# Workflow: Report

**Objective:** Aggregate all validation verdicts and evidence into a final structured report.

## Prerequisites

- Completed execution phase with verdicts
- Evidence files in `e2e-evidence/` directory

## Process

### Step 1: Gather Inputs

Collect from prior workflow phases:
- Platform detection result (from analyze)
- Journey inventory (from analyze)
- PASS criteria (from plan)
- Verdicts per journey (from execute)
- Fix log (from fix-and-revalidate, if applicable)
- Evidence file paths

### Step 2: Compute Summary Statistics

```
Total Journeys:    {count}
Passed:            {count} ({percentage}%)
Failed:            {count} ({percentage}%)
Unresolved:        {count}
Evidence Files:    {count}
Fix Attempts:      {count} (if --fix was used)
```

### Step 3: Generate Report

```markdown
# E2E Validation Report

**Project:** {name}
**Platform:** {detected}
**Date:** {timestamp}
**Duration:** {start_time} → {end_time}
**Result:** {PASS / FAIL / PARTIAL}

## Summary

| Metric | Value |
|--------|-------|
| Total Journeys | {N} |
| Passed | {N} ({%}) |
| Failed | {N} ({%}) |
| Unresolved | {N} |
| Evidence Files | {N} |

## Results by Journey

### PASSED

#### J{N}: {Journey Name} — PASS
- **Evidence:** `e2e-evidence/j{N}-{slug}.{ext}`
- **Criteria:** {N}/{N} met
- **Key observation:** {what the evidence showed}

### FAILED

#### J{N}: {Journey Name} — FAIL
- **Evidence:** `e2e-evidence/j{N}-{slug}.{ext}`
- **Criteria:** {passed}/{total} met
- **Root cause:** {diagnosis}
- **Failed criteria:**
  - {criterion}: Expected {X}, got {Y}

### UNRESOLVED (if any)

#### J{N}: {Journey Name} — UNRESOLVED
- **Attempts:** {strike count}
- **Last diagnosis:** {what was found}
- **Recommendation:** {manual investigation needed}

## Fix Log (if --fix was used)

| Journey | Attempts | Final Result |
|---------|----------|-------------|
| J{N} | {count} | PASS / UNRESOLVED |

## Evidence Index

| File | Journey | Type |
|------|---------|------|
| `j1-{slug}.png` | J1: {name} | Screenshot |
| `j2-{slug}.json` | J2: {name} | API Response |

## Validation Environment

- **OS:** {platform}
- **Runtime:** {node/python/swift/go version}
- **Build tool:** {tool and version}
- **Browser/Simulator:** {if applicable}
```

### Step 4: Save Report

Save to `e2e-evidence/report.md`.

If `--verbose` flag was set, embed evidence content inline in the report (base64 for images, full text for responses).

### Step 5: Print Summary to Console

Output a one-line summary:

```
Validation complete: {PASS|FAIL} — {passed}/{total} journeys passed. Report: e2e-evidence/report.md
```

## Output

- `e2e-evidence/report.md` — Final validation report
- Console summary line
