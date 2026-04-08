# forge-team

Multi-agent parallel validation. Spawns platform-specific validators that work in parallel with strict evidence directory ownership.

## Trigger

- "team validation", "parallel validation", "validate all platforms"
- Projects with 2+ detected platforms

## Architecture

```
Lead (you)
├── Web Validator    → e2e-evidence/web/
├── API Validator    → e2e-evidence/api/
├── iOS Validator    → e2e-evidence/ios/
├── CLI Validator    → e2e-evidence/cli/
├── Design Validator → e2e-evidence/design/
└── Verdict Writer   → e2e-evidence/report.md
```

## Team Roles

| Role | Agent Type | Owns | Responsibilities |
|------|-----------|------|-----------------|
| Lead | You | Orchestration | Spawn validators, assign journeys, collect verdicts |
| Web Validator | general-purpose | `e2e-evidence/web/` | Playwright-based web journey validation |
| API Validator | general-purpose | `e2e-evidence/api/` | HTTP endpoint validation with real requests |
| iOS Validator | general-purpose | `e2e-evidence/ios/` | Simulator-based iOS validation |
| CLI Validator | general-purpose | `e2e-evidence/cli/` | Direct CLI invocation and output capture |
| Design Validator | general-purpose | `e2e-evidence/design/` | Visual inspection, token audit, accessibility |
| Verdict Writer | general-purpose | `e2e-evidence/report.md` | Synthesize all evidence into unified report |

## Workflow

### Step 1: Platform Detection

Read `.validationforge/config.json` for detected platforms. Only spawn validators for detected platforms.

### Step 2: Journey Assignment

Partition validation plan journeys by platform. Each validator receives only its platform's journeys.

### Step 3: Spawn Validators (parallel)

Launch one agent per platform using `Agent` tool with `run_in_background: true`.

Each validator prompt MUST include:
- The validation plan (its journeys only)
- Evidence directory path (exclusive ownership)
- PASS criteria for each journey
- Evidence capture requirements
- The iron rules (no mocks, real evidence, cite specific proof)

### Step 4: Monitor Progress

Check validator progress via TaskOutput. Do not interfere unless a validator is stuck.

### Step 5: Collect Results

When all validators complete, read each `evidence-inventory.txt` and verify evidence files exist and are non-empty.

### Step 6: Verdict Synthesis

Spawn verdict-writer agent with all evidence directories as input. It produces the unified `e2e-evidence/report.md`.

### Step 7: Report

Present summary to user with per-platform breakdown.

## Evidence Ownership Rules

- Each validator EXCLUSIVELY owns its evidence directory
- No validator may write to another validator's directory
- The lead does NOT write evidence — only the verdict writer writes the report
- If a validator needs cross-platform evidence (e.g., API call from web test), it captures its OWN evidence of the API response

## Conflict Resolution

| Conflict | Resolution |
|----------|-----------|
| Two validators need same endpoint | Each captures independently |
| Validator stuck > 5 min | Lead investigates, may reassign |
| Contradictory verdicts | Lead re-validates the specific journey |
| Missing evidence | Journey marked FAIL, not INCONCLUSIVE |

## Team Size Guidelines

| Platforms | Validators | Parallel Agents |
|-----------|-----------|----------------|
| 1 | 1 + verdict writer | 2 |
| 2 | 2 + verdict writer | 3 |
| 3-4 | 3-4 + verdict writer | 4-5 |
| 5 | 5 + verdict writer | 6 |

Never spawn more than 5 validators. For 5+ platforms, batch into rounds.
