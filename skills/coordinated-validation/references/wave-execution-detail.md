# Wave Execution Detail

Loaded by `coordinated-validation` when you reach Phase 3 and need the step-by-step wave execution protocol. Read this before running the first wave.

## Phase 3: Wave Execution (Full Walkthrough)

### Wave 0 — Independent Platforms

```
Launch in parallel (run_in_background: true):
  Agent A: DB validation  → e2e-evidence/db/
  Agent B: Design validation → e2e-evidence/design/
```

Wait for ALL Wave 0 agents to complete.

Evaluate Wave 0:
- All PASS or CONDITIONAL → proceed to Wave 1
- Any FAIL → mark all downstream as BLOCKED, skip to Phase 5 (report)

### Wave 1 — API (depends on DB)

```
Launch in parallel (run_in_background: true):
  Agent C: API validation → e2e-evidence/api/
```

Wait for ALL Wave 1 agents to complete.

Evaluate Wave 1:
- All PASS or CONDITIONAL → proceed to Wave 2
- Any FAIL → mark Web and iOS as BLOCKED, skip to Phase 5 (report)

### Wave 2 — Frontend Platforms (depend on API)

```
Launch in parallel (run_in_background: true):
  Agent D: Web validation → e2e-evidence/web/
  Agent E: iOS validation → e2e-evidence/ios/
```

Wait for ALL Wave 2 agents to complete.

## Phase 4: Evidence Coordination

After all waves complete, the Lead collects cross-platform evidence:

```
1. Read each platform's evidence-inventory.txt
2. Verify evidence files exist and are non-empty
3. Cross-reference: API responses in api/ should match data shown in web/ and ios/
4. Note any cross-platform discrepancies as CONDITIONAL issues
```

Cross-platform evidence check:
- API returned N users → Web should display N users
- API create endpoint succeeded → DB should have the new record
- iOS received API response → API evidence should show the same request

## Phase 5: Unified Report

Spawn a verdict-writer agent with all evidence directories as input. It produces:
- `e2e-evidence/coordinated-report.md` — unified report with per-wave breakdown

## Evidence Directory Structure

```
e2e-evidence/
  db/                    ← Wave 0, Agent A ONLY
    step-01-schema.txt
    step-02-seed-count.txt
    evidence-inventory.txt
    report.md
  design/                ← Wave 0, Agent B ONLY
    reference/
    implementation/
    evidence-inventory.txt
    report.md
  api/                   ← Wave 1, Agent C ONLY
    step-01-health.json
    step-02-create.json
    evidence-inventory.txt
    report.md
  web/                   ← Wave 2, Agent D ONLY
    step-01-homepage.png
    step-02-dashboard.png
    evidence-inventory.txt
    report.md
  ios/                   ← Wave 2, Agent E ONLY
    step-01-launch.png
    step-02-login.png
    evidence-inventory.txt
    report.md
  coordinated-report.md  ← Lead / Verdict Writer ONLY
```

**NEVER** let two agents write to the same directory. Evidence corruption invalidates the entire report.
