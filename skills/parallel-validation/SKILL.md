---
name: parallel-validation
description: "Use when you need fan-out concurrent validation across multiple independent scopes (e.g. web + api + ios in parallel) and the scopes don't depend on each other — unlike `coordinated-validation` which handles dependent scopes with wave gating, or `forge-team` which runs multi-agent teams. Strict file ownership per agent prevents evidence collisions. Verdict aggregation: any FAIL = overall FAIL. Reach for it on phrases like 'run validation in parallel', 'fan out validation', 'concurrent agents', or when you have many isolated journeys and want max throughput."
triggers:
  - "parallel validation"
  - "validate in parallel"
  - "concurrent validation"
  - "multi-platform validation"
  - "fan out validation"
  - "concurrent agents"
  - "validate all at once"
context_priority: standard
---

# Parallel Validation

Orchestrate multiple validation agents working simultaneously on independent validation journeys. Maximizes throughput by running non-overlapping validations concurrently while maintaining evidence integrity and preventing file conflicts.

## When to Use

- Validating multiple independent pages or features simultaneously
- Cross-platform validation (iOS + Web + API in parallel)
- Large applications where sequential validation would take too long
- CI/CD pipelines requiring fast validation turnaround
- Multi-viewport responsive validation across device categories

## Parallelization Rules

### Safe to Parallelize

| Scenario | Why Safe |
|----------|----------|
| Different pages/routes | No shared state |
| Different platforms (iOS vs Web) | Separate toolchains |
| Different viewport categories | Independent captures |
| Independent API endpoints | No request dependencies |
| Read-only audits | No mutations |

### Must Be Sequential

| Scenario | Why Sequential |
|----------|----------------|
| Auth flow → authenticated pages | Login state required |
| Create → Read → Update → Delete | Data dependencies |
| Build → Deploy → Validate | Pipeline order |
| Shared database state | Mutation conflicts |

## Orchestration Protocol

### Phase 1: Journey Analysis

```
1. Inventory all validation journeys
2. Build dependency graph
3. Identify independent clusters
4. Assign each cluster to an agent
```

### Phase 2: Agent Assignment

```markdown
## Agent Allocation

| Agent | Platform | Journeys | Evidence Directory |
|-------|----------|----------|--------------------|
| Agent 1 | iOS | login, profile | e2e-evidence/ios/ |
| Agent 2 | Web | homepage, dashboard | e2e-evidence/web/ |
| Agent 3 | API | auth, users, posts | e2e-evidence/api/ |
| Agent 4 | Design | fidelity, tokens | e2e-evidence/design/ |
```

### Phase 3: Parallel Execution

```
Launch agents using Task tool with run_in_background:

Agent 1: Task(subagent_type="general-purpose", prompt="...", run_in_background=true)
Agent 2: Task(subagent_type="general-purpose", prompt="...", run_in_background=true)
Agent 3: Task(subagent_type="general-purpose", prompt="...", run_in_background=true)

Each agent prompt MUST include:
- Platform and journeys to validate
- Evidence directory (unique per agent — NO OVERLAP)
- Validation criteria and verdict rules
- The Iron Rule: no mocks, no stubs, no false claims
```

### Phase 4: Evidence Collection

```
1. Wait for all agents to complete
2. Collect evidence inventories from each agent
3. Verify no evidence directory conflicts
4. Merge individual reports into unified report
```

### Phase 5: Unified Verdict

```
1. Read each agent's journey verdicts
2. Apply verdict aggregation rules
3. Produce unified validation report
4. Overall verdict = worst individual verdict
```

## File Ownership Rules (CRITICAL)

Each parallel agent MUST own distinct evidence directories:

```
e2e-evidence/
  ios-validation/          ← Agent 1 ONLY
    step-01-*.png
    report.md
  web-validation/          ← Agent 2 ONLY
    step-01-*.png
    report.md
  api-validation/          ← Agent 3 ONLY
    step-01-*.json
    report.md
  design-validation/       ← Agent 4 ONLY
    reference/
    implementation/
    report.md
  unified-report.md        ← Orchestrator ONLY
```

**NEVER** let two agents write to the same directory. This prevents evidence corruption and merge conflicts.

## Verdict Aggregation

| Individual Verdicts | Overall Verdict |
|--------------------|-----------------|
| All PASS | PASS |
| Any CONDITIONAL, no FAIL | CONDITIONAL |
| Any FAIL | FAIL |
| Any agent crashed/incomplete | INCOMPLETE |

## Agent Prompt Template

```markdown
You are a ValidationForge validation agent. Your assignment:

**Platform:** {platform}
**Journeys:** {journey list}
**Evidence Directory:** e2e-evidence/{platform}-validation/

## Rules
1. NO mocks, stubs, or test files — validate the REAL system
2. Capture evidence for every step (screenshots, logs, responses)
3. Name evidence: step-{NN}-{description}.{ext}
4. Write journey verdict with specific evidence citations
5. Write report.md with per-journey results

## Journeys to Validate
{detailed journey descriptions with acceptance criteria}

## Verdict Rules
- PASS: All criteria met with evidence
- CONDITIONAL: Minor issues, non-blocking
- FAIL: Any criteria unmet or evidence missing
```

## Performance Guidelines

| App Size | Recommended Agents | Expected Speedup |
|----------|-------------------|-------------------|
| Small (1-3 pages) | 1-2 | 1.5x |
| Medium (4-10 pages) | 2-4 | 2-3x |
| Large (10+ pages) | 3-6 | 3-5x |
| Multi-platform | 1 per platform | Linear with platforms |

## Evidence Structure

```
e2e-evidence/
  {platform-1}-validation/
    step-01-{description}.png
    step-02-{description}.json
    evidence-inventory.txt
    report.md
  {platform-2}-validation/
    ...
  unified-report.md
```

## Report Template

```markdown
# Parallel Validation Report

**Agents deployed:** N
**Platforms covered:** {list}
**Total journeys:** N
**Execution time:** {wall clock}
**Date:** YYYY-MM-DD

## Agent Results

| Agent | Platform | Journeys | Pass | Fail | Verdict |
|-------|----------|----------|------|------|---------|
| 1 | iOS | 3 | 3 | 0 | PASS |
| 2 | Web | 4 | 3 | 1 | FAIL |
| 3 | API | 5 | 5 | 0 | PASS |

## Failed Journeys
1. {journey name} — {failure reason with evidence reference}

## Overall Verdict: PASS / CONDITIONAL / FAIL / INCOMPLETE

## Evidence Inventory
{merged list from all agents}
```

## Integration with ValidationForge

- Orchestrates agents that each use platform-specific skills (ios-validation, web-validation, api-validation, design-validation)
- File ownership rules prevent evidence corruption
- Unified report consumed by `verdict-writer` agent
- Pairs with `preflight` to verify all platforms are ready before parallel launch
- Uses `create-validation-plan` output to determine parallelization strategy
