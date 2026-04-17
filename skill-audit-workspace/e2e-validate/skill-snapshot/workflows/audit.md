# Workflow: Audit

**Objective:** Perform a read-only validation assessment. Capture evidence and write verdicts WITHOUT making any code changes. Classify findings by severity.

## Prerequisites

- System is built and running (or can be started)
- Access to project source code (read-only)

## Key Constraint: NO CODE CHANGES

This workflow is strictly read-only. You may:
- Build and start the system
- Navigate the UI / call APIs / run CLI commands
- Capture screenshots, responses, logs
- Write findings and verdicts

You may NOT:
- Edit any source code files
- Modify configuration files
- Change database records
- Install new dependencies

If you find a bug, DOCUMENT IT — don't fix it.

## Process

### Step 1: Run Analysis

Execute `workflows/analyze.md` to detect platform and map journeys.

### Step 2: Quick Plan

For each journey, define PASS criteria (same as plan workflow) but skip the approval gate — audits don't need user approval to proceed.

### Step 3: Execute Validation

Run through each journey following `workflows/execute.md` steps:
- Navigate to entry point
- Perform journey steps
- Capture evidence
- READ evidence
- Match to PASS criteria

### Step 4: Classify Findings

For each finding (whether PASS or FAIL), assign a severity:

| Severity | Definition | Example |
|----------|-----------|---------|
| **CRITICAL** | System is broken, data loss possible, security vulnerability | Login bypass, data corruption, crash on core flow |
| **HIGH** | Major feature doesn't work, no workaround | Search returns wrong results, form submission fails |
| **MEDIUM** | Feature partially broken, workaround exists | Export works but misses one column, slow but functional |
| **LOW** | Minor issue, cosmetic or edge case | Typo in label, alignment off by a few pixels |
| **INFO** | Observation, not a defect | "Using deprecated API version", "No favicon configured" |

### Step 5: Write Audit Report

```markdown
## Validation Audit Report

**Project:** {name}
**Platform:** {detected}
**Date:** {timestamp}
**Auditor:** ValidationForge (automated)
**Mode:** Read-only audit (no code changes)

### Summary

| Severity | Count |
|----------|-------|
| CRITICAL | {n} |
| HIGH | {n} |
| MEDIUM | {n} |
| LOW | {n} |
| INFO | {n} |

**Overall Assessment:** {PASS if zero CRITICAL/HIGH, CONDITIONAL PASS if HIGH only, FAIL if CRITICAL}

### Findings

#### CRITICAL

**F1: {Finding Title}**
- **Journey:** J{N} — {name}
- **Evidence:** `e2e-evidence/j{N}-{slug}.{ext}`
- **Observed:** {what actually happened}
- **Expected:** {what should have happened}
- **Impact:** {who is affected, how badly}
- **Recommendation:** {what to fix}

(repeat for each finding, grouped by severity)

### Journeys Validated

| # | Journey | Verdict | Findings |
|---|---------|---------|----------|
| J1 | {name} | PASS | — |
| J2 | {name} | FAIL | F1 (CRITICAL), F3 (MEDIUM) |

### Evidence Index

| File | Journey | Type | Description |
|------|---------|------|-------------|
| `j1-login.png` | J1 | Screenshot | Login page with form fields |
| `j2-dashboard.json` | J2 | API Response | Dashboard data endpoint |
```

Save to `e2e-evidence/audit-report.md`.

## Use Cases

| Use Case | Why Audit Instead of Execute |
|----------|----------------------------|
| Pre-release assessment | Need documented evidence before shipping |
| Compliance documentation | Auditor needs proof of functionality |
| Third-party code review | Can't modify code you don't own |
| Baseline measurement | Measuring current state before changes |
| Regression check | Verifying nothing broke after a deploy |

## Output

- `e2e-evidence/audit-report.md` — Full audit report with severity classifications
- `e2e-evidence/j{N}-{slug}.{ext}` — Evidence files
- Overall assessment: PASS / CONDITIONAL PASS / FAIL
