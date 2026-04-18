# Context Window Budget Management

Authoritative guide to how ValidationForge manages its context window footprint. The 41-skill library totals ~6,782 lines — loading all skills simultaneously would crowd out user codebase context. The `context_priority` system keeps initial load to ~777 lines while making every skill available on demand.

---

## The Problem

Claude Code's context window is finite. ValidationForge has 52 skills totaling ~8,400 lines. Loading all of them at session start leaves little room for the user's actual codebase — defeating the purpose of a validation tool.

| Scenario | Lines Consumed | Risk |
|----------|---------------|------|
| All 52 skills loaded | ~8,400 | User codebase crowded out |
| Critical only (default) | ~777 | ✅ Safe — codebase remains visible |
| Critical + standard | ~2,655 | Acceptable for active validation run |
| Critical + standard + reference | ~6,782 | Avoid — full load |

---

## The Solution: `context_priority` Tiers

Every skill's `SKILL.md` frontmatter declares a `context_priority` field:

```yaml
---
name: skill-name
description: What the skill does
context_priority: critical | standard | reference
---
```

Three tiers control when each skill loads:

| Tier | Count | Lines | Load Policy |
|------|------:|------:|-------------|
| `critical` | 8 | ~777 | Always loaded — every session, every project |
| `standard` | 11 | ~1,878 | Loaded when matching platform or phase detected |
| `reference` | 22 | ~4,127 | Loaded only when explicitly invoked |

---

## Critical Skills — Always Loaded (~777 lines)

These 8 skills form the invariant core. Every validation run requires them regardless of project type. They enforce foundational rules and orchestrate the pipeline.

| Skill | Lines | Purpose |
|-------|------:|---------|
| `e2e-validate` | 143 | Main validation orchestrator — entry point for all runs |
| `functional-validation` | 97 | Core no-mock protocol — real system only |
| `create-validation-plan` | 102 | Journey discovery and PASS criteria before execution |
| `error-recovery` | 101 | 3-strike fix loop for failed validations |
| `preflight` | 90 | Prerequisite checks before every validation run |
| `verification-before-completion` | 84 | Prevents premature completion claims |
| `gate-validation-discipline` | 83 | Evidence-before-verdict gate enforcement |
| `no-mocking-validation-gates` | 77 | Iron Rule enforcement — blocks mock creation |
| **Total** | **777** | |

**Load condition:** Loaded on every session start. Never unloaded.

---

## Standard Skills — Loaded on Platform Match (~1,878 lines)

These 11 skills load when the platform detector identifies a matching project type during preflight. They cover the most common validation scenarios.

| Skill | Lines | Load Trigger |
|-------|------:|-------------|
| `parallel-validation` | 219 | Multi-agent run detected |
| `e2e-testing` | 198 | Any validation run (journey patterns) |
| `sequential-analysis` | 192 | Analysis phase entered |
| `build-quality-gates` | 193 | Build step present in project |
| `cli-validation` | 186 | CLI platform detected |
| `web-validation` | 185 | Web platform detected |
| `fullstack-validation` | 209 | Fullstack platform detected |
| `api-validation` | 223 | API platform detected |
| `full-functional-audit` | 101 | Audit mode (`/validate-audit`) |
| `baseline-quality-assessment` | 90 | Baseline requested before changes |
| `condition-based-waiting` | 82 | Async operations requiring smart waits |
| **Total** | **1,878** | |

**Load condition:** Loaded when the corresponding platform or phase is detected. Unload after the phase completes to reclaim budget.

### Platform Detection Triggers

```
Project files scanned during preflight
        │
        ├── .xcodeproj / .swift found      → load ios-validation skills (reference tier)
        ├── package.json + framework config  → load web-validation (standard)
        ├── route handlers / OpenAPI spec   → load api-validation (standard)
        ├── bin entries / arg parsers       → load cli-validation (standard)
        └── multiple layers detected        → load fullstack-validation (standard)
```

---

## Reference Skills — Loaded on Explicit Invocation (~4,127 lines)

These 22 skills are highly specialized. They load only when a command explicitly invokes them or when a dependency chain requires them. They are never pre-loaded.

| Skill | Invoke Condition |
|-------|-----------------|
| `ios-validation` | iOS platform detected |
| `ios-validation-gate` | iOS three-gate workflow |
| `ios-validation-runner` | iOS five-phase validation |
| `ios-simulator-control` | iOS simulator lifecycle required |
| `playwright-validation` | Browser automation via Playwright MCP |
| `web-testing` | Comprehensive web test strategy |
| `chrome-devtools` | Deep browser inspection requested |
| `design-validation` | Design spec present |
| `design-token-audit` | Token diff requested |
| `stitch-integration` | Stitch MCP present |
| `visual-inspection` | UI visual evidence required |
| `research-validation` | Research phase entered |
| `retrospective-validation` | Historical evidence review |
| `accessibility-audit` | WCAG audit requested |
| `responsive-validation` | Viewport matrix testing |
| `production-readiness-audit` | Production gate or deploy decision |
| `forge-setup` | Project initialization (`/vf-setup`) |
| `forge-plan` | Validation plan generation |
| `forge-execute` | Autonomous execution loop |
| `forge-team` | Multi-agent parallel validation |
| `forge-benchmark` | Benchmark scoring (`/validate-benchmark`) |
| `validate-audit-benchmarks` | Audit benchmark suite |

**Load condition:** Loaded only when explicitly invoked by command or when a skill dependency demands it. Unloaded immediately after the invocation completes.

---

## Budget Targets

| Tier | Target | Actual | Status |
|------|-------:|-------:|--------|
| Critical initial load | < 2,000 lines | 777 lines | ✅ Under budget |
| Standard (added on platform match) | < 3,000 lines total | ~2,655 lines | ✅ Under budget |
| All skills combined | 6,782 lines | 6,782 lines | ⚠️ Never load all at once |

---

## Implementation: How `context_priority` Works

Claude Code discovers skills by scanning `SKILL.md` files in the plugin directory. The `context_priority` field is read by the orchestration layer (`e2e-validate` skill) to enforce the loading policy:

1. **Session start**: Only `critical` skills are loaded into context.
2. **Preflight**: Platform detection runs, sets `DETECTED_PLATFORMS` in session context.
3. **Platform match**: Matching `standard` skills load for the duration of the validation run.
4. **Explicit invocation**: `reference` skills load when commanded, unload when done.

### In Skill Instructions

Reference skills by name rather than loading them eagerly:

```
✅ DO: "Invoke the `playwright-validation` skill for browser automation."
❌ DON'T: Load all browser skills at session start just in case they're needed.
```

The orchestrator (`e2e-validate`) maintains a dependency map. When a skill is referenced by name in instructions, it loads only that skill — not the entire tier.

---

## Maintenance: Adding New Skills

When adding a new skill, assign `context_priority` according to these rules:

| Choose | When the skill is... |
|--------|---------------------|
| `critical` | Required by every single validation run, regardless of platform |
| `standard` | Needed for one of the three most common project types (web, api, cli, fullstack) |
| `reference` | Specialized, platform-specific, or invoked only by explicit command |

**Budget accounting**: Before assigning `critical`, verify the total critical skill line count stays under 2,000 lines. Run:

```bash
wc -l skills/*/SKILL.md | grep -v total
```

Filter by priority, sum the lines for all `critical` skills, and confirm the total is under budget.

---

## Related Documents

- [`ARCHITECTURE.md`](../ARCHITECTURE.md) — Skill lifecycle and hook registration
- [`SKILLS.md`](../SKILLS.md) — Full 41-skill inventory with priority assignments
- [`skills/e2e-validate/SKILL.md`](../skills/e2e-validate/SKILL.md) — Orchestrator that enforces loading policy
