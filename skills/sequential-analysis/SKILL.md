---
name: sequential-analysis
description: "Root cause analysis for FAIL verdicts: structured hypothesis testing, evidence investigation, sequential thinking. Use when validation fails unexpectedly, errors are ambiguous, or journeys share causes."
triggers:
  - "sequential analysis"
  - "root cause analysis"
  - "why did validation fail"
  - "trace the failure"
  - "debug validation"
context_priority: standard
---

# Sequential Analysis

When a validation produces a FAIL verdict, systematically trace the root cause through step-by-step reasoning. Uses the sequential-thinking MCP tool wrapped in ValidationForge's evidence framework.

## When to Use

- After a validation journey produces a FAIL verdict
- When a FAIL is unexpected (the feature "should" work)
- When multiple journeys fail and you suspect a common root cause
- When error messages are ambiguous or misleading
- When you need documented root cause analysis for the team

## Analysis Protocol

```
Phase 1: SYMPTOM     Phase 2: HYPOTHESIZE   Phase 3: INVESTIGATE   Phase 4: CONCLUDE
What failed?         Why might it have      Test each hypothesis   Document root cause
Expected vs actual   failed? List 5+        with evidence          and recommend fix
```

## Phase 1: Document the Symptom

Read the FAIL verdict and capture the exact discrepancy.

```markdown
## Failure Symptom

**Journey:** {journey name from validation plan}
**Verdict:** FAIL
**Expected:** {what should have happened — from PASS criteria}
**Actual:** {what was observed — from evidence files}
**Evidence files:**
- {path to screenshot showing failure}
- {path to console log}
- {path to network response}

**Discrepancy:** {precise description of the gap between expected and actual}
```

Save to `e2e-evidence/analysis/step-01-symptom.md`.

## Phase 2: Generate Hypotheses

List at least 5 possible causes, ordered by likelihood.

### Hypothesis Categories

| Category | Example Causes |
|----------|---------------|
| Data | Missing/stale data, wrong seed state, migration not run |
| Timing | Race condition, async not awaited, animation blocking |
| Environment | Wrong port, missing env var, stale build, wrong branch |
| Code | Logic error, typo, wrong import, missing return |
| Integration | API changed, CORS blocked, auth expired, rate limited |
| Infrastructure | Server down, DB connection lost, DNS failure |
| Validation setup | Wrong selector, stale snapshot, incorrect PASS criteria |

### Hypothesis Template

```markdown
## Hypotheses

### H1: {most likely cause} (Likelihood: HIGH)
**Category:** {from table above}
**Evidence needed to confirm:** {what would prove this}
**Evidence needed to rule out:** {what would disprove this}

### H2: {second most likely} (Likelihood: MEDIUM)
...

### H3-H5: ...
```

Save to `e2e-evidence/analysis/step-02-hypotheses.md`.

## Phase 3: Investigate Each Hypothesis

Use the sequential-thinking MCP tool for structured reasoning.

### Investigation Protocol

For each hypothesis (starting with highest likelihood):

1. **State the hypothesis** clearly
2. **Identify the evidence** that would confirm or deny it
3. **Collect the evidence** (read files, check logs, inspect screenshots, run commands)
4. **Evaluate** — does the evidence support or contradict the hypothesis?
5. **Conclude** — CONFIRMED, RULED OUT, or INCONCLUSIVE

### Evidence Collection Commands

```bash
mkdir -p e2e-evidence/analysis/investigation

# Check environment
env | grep -i "port\|host\|url\|key\|env" \
  > e2e-evidence/analysis/investigation/environment.txt

# Check recent code changes
git log --oneline -20 \
  > e2e-evidence/analysis/investigation/recent-changes.txt

# Check for runtime errors in logs
# (platform-specific — adapt to your app)
```

### Sequential Thinking Integration

Use `sequentialthinking` MCP tool with this pattern:

```
Thought 1: "FAIL symptom is X. Most likely cause is H1 because..."
Thought 2: "Evidence for H1: I found... This [confirms/contradicts] H1."
Thought 3: "H1 is [confirmed/ruled out]. Moving to H2..."
...continue until root cause found...
Thought N: "Root cause confirmed: {cause}. Evidence: {files}."
```

Document each investigation step in `e2e-evidence/analysis/step-03-investigation.md`.

## Phase 4: Conclude and Recommend

```markdown
# Root Cause Analysis Report

**Journey:** {name}
**FAIL verdict date:** YYYY-MM-DD
**Analysis date:** YYYY-MM-DD

## Root Cause
**Category:** {from hypothesis categories}
**Cause:** {specific root cause}
**Confidence:** HIGH / MEDIUM / LOW

## Evidence Chain
1. {evidence file} — shows {what it proves}
2. {evidence file} — shows {what it proves}
3. ...

## Hypotheses Evaluated
| # | Hypothesis | Result | Key Evidence |
|---|-----------|--------|-------------|
| H1 | {description} | CONFIRMED/RULED OUT | {file reference} |
| H2 | {description} | RULED OUT | {file reference} |
| ... | | | |

## Recommended Fix
**What to change:** {specific code/config change}
**Files affected:** {list of files}
**Risk of fix:** LOW / MEDIUM / HIGH
**Re-validation needed:** {which journeys to re-run}

## Prevention
**How to prevent recurrence:**
- {process change, additional validation criteria, etc.}
```

Save to `e2e-evidence/analysis/report.md`.

## Multi-Failure Correlation

When multiple journeys fail:

1. Run Phase 1 for each failure independently
2. Look for common patterns:
   - Same error message across failures?
   - Same timestamp / same deployment?
   - Same subsystem (all API, all UI, all auth)?
3. If common root cause found → single analysis report
4. If independent causes → separate reports per failure

## Integration with ValidationForge

- Takes FAIL verdicts from `verdict-writer` agent as input
- Uses evidence files from failed validation journeys
- Produces root-cause analysis in `e2e-evidence/analysis/`
- Informs `error-recovery` skill for fix implementation
- Re-validation uses original `create-validation-plan` journeys
- The sequential-thinking MCP tool provides structured reasoning
- Evidence chain creates accountability trail for the fix
