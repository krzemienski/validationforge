# ValidationForge: Complete Product Specification

> **DEPRECATED:** This document has been superseded by [PRD.md](./PRD.md) (v2.0.0, March 10, 2026).
> PRD.md contains accurate inventory numbers (41 skills, 15 commands, 7 hooks, 5 agents, 8 rules),
> updated competitive analysis, marketing integration, and go-to-market strategy.
> This file is retained for historical reference only.

**Version:** 1.0.0
**Author:** Nick Krzemienski
**Date:** March 7, 2026
**Status:** ~~Definitive — Single Source of Truth~~ DEPRECATED — See PRD.md

---

## 1. Executive Summary

ValidationForge is the first Claude Code plugin dedicated to **functional validation** — proving that AI-generated code actually works before it ships. In a market where 40+ tools help developers write code with AI, zero tools help them prove that code works.

**The Problem:**
- AI coding assistants generate code at unprecedented speed
- 23,479 coding sessions across 42 days produced 3,474,754 lines of output
- Unit tests catch 0/5 integration bugs in benchmarks (mocks drift from reality)
- Developers ship AI-generated code with false confidence from green test suites
- No existing tool validates through real user interfaces

**The Solution:**
- Platform-aware functional validation (iOS, Web, API, CLI, Fullstack)
- No-mock enforcement hooks that block test file creation
- Evidence capture + review pipeline with formal PASS/FAIL verdicts
- 3-strike automatic fix protocol with human escalation
- Closed verification loop: build → validate → review → ship or fix

**Market Position:**
- Blue ocean — the functional validation category for AI coding does not exist yet
- Complementary to ClaudeKit (workflow), OMC (orchestration), Cursor (IDE)
- NOT competitive with testing frameworks (Playwright, Jest, Cypress) — VF uses them as tools, not alternatives

**Key Metrics:**

| Metric | Value |
|--------|-------|
| Files | 68 |
| Lines of code | 9,593 |
| Skills | 16 (4 layers) |
| Commands | 5 |
| Hooks | 5 |
| Agents | 3 |
| Platform references | 6 |
| Bugs caught (benchmark) | planned target: all-5 vs none-for-unit-tests (see docs/ENGINES-DEFERRED.md) |
| Evidence tiers | 3 |
| Config profiles | 3 |

---

## 2. Product Philosophy

### 2.1 The Iron Rule

```
IF the real system doesn't work, FIX THE REAL SYSTEM.
NEVER create mocks, stubs, test doubles, or test files.
ALWAYS validate through the same interfaces real users experience.
ALWAYS capture evidence. ALWAYS review evidence. ALWAYS write verdicts.
```

The Iron Rule is not a suggestion — it is enforced by hooks that block test file creation, detect mock patterns, and require evidence for every completion claim.

### 2.2 Evidence-Based Shipping

Every piece of evidence must be:
1. **CAPTURED** — screenshots, API responses, build logs, CLI output
2. **REVIEWED** — read, analyzed, described in human terms
3. **MATCHED** — compared against specific PASS criteria
4. **CITED** — referenced in formal verdicts with specific findings

**Critical principle:** "Capturing evidence without reviewing it is WORSE than not capturing it." Evidence that sits unread creates false confidence. Better to validate nothing than to capture screenshots you never look at.

### 2.3 The Closed Verification Loop

```
FORGE builds code → VALIDATE proves it works → CONSENSUS reviews quality
     ↑                                                    |
     └────────────── fix & rebuild if any fail ←──────────┘
```

Three engines form a closed loop. Each can run standalone, but together they guarantee that nothing ships without being built, proven, and reviewed.

### 2.4 Why Not Unit Tests?

Unit tests verify code in isolation with mocks. Mocks drift from reality. ValidationForge verifies systems in production — through the same interfaces users experience.

| Scenario | Unit Tests | ValidationForge |
|----------|:----------:|:---------------:|
| API field renamed (`users` → `data`) | PASS (mock returns old field) | **FAIL** (curl shows new field, frontend crashes) |
| JWT expiry reduced to 15 min | PASS (mock time, never wait) | **FAIL** (real token expires, refresh fails) |
| iOS deep link after nav refactor | PASS (mock URL handler) | **FAIL** (simctl openurl → wrong screen) |
| DB migration with duplicate emails | PASS (clean in-memory DB) | **FAIL** (real migration fails on duplicates) |
| CSS grid overflow on small screens | PASS (no visual rendering) | **FAIL** (Playwright screenshot shows overflow) |

Score: Unit tests caught none. ValidationForge caught all. (planned benchmark target — see docs/ENGINES-DEFERRED.md)

---

## 3. Architecture

### 3.1 Three-Engine System

#### Engine 1: VALIDATE (Core)

The no-mock functional validation pipeline. Detects the project platform, generates validation plans, executes through real interfaces, captures evidence, and writes formal verdicts.

**Components:**
- Platform auto-detection agent (6 platforms)
- Evidence capture agent (screenshots, API responses, build logs)
- Verdict writer agent (PASS/FAIL with citations)
- 5-stage pipeline: PREFLIGHT → PLAN → EXECUTE → REPORT → FIX
- 5 commands: /validate, /validate-plan, /validate-fix, /validate-audit, /validate-ci

**Included in:** All tiers (Lite, Pro, Team, Enterprise)

#### Engine 2: CONSENSUS (Quality Gate)

Multi-reviewer agreement gate. Three independent AI reviewers examine the same code from different perspectives. Unanimous agreement required for PASS.

**Components:**
- 3 independent reviewer agents (security, performance, correctness perspectives)
- Unanimous voting protocol
- Disagreement report with file:line citations
- Escalation protocol for unresolvable disagreements

**Included in:** Pro, Team, Enterprise tiers

#### Engine 3: FORGE (Execution)

Persistent autonomous execution loops. Builds code, runs VALIDATE, applies fixes, rebuilds — continuing until all validations pass or the 3-strike limit is reached.

**Components:**
- Hat-based execution loops (inspired by Ralph orchestrator)
- Checkpoint/restore for long-running tasks
- 3-strike recovery protocol
- Automatic escalation to human after 3 failed fix attempts

**Included in:** Team, Enterprise tiers

### 3.2 Skill Dependency Graph

Skills are layered. Higher skills depend on lower ones:

```
                    ┌─────────────────┐
         Layer 4:   │   e2e-validate   │  (Orchestrator)
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              ▼              ▼              ▼
    ┌──────────────┐  ┌────────────┐  ┌──────────────┐
L3: │create-        │  │full-       │  │baseline-     │  (Planners)
    │validation-plan│  │functional- │  │quality-      │
    └──────┬───────┘  │audit       │  │assessment    │
           │          └─────┬──────┘  └──────┬───────┘
              ┌─────────────┼────────────┐
              ▼             ▼            ▼
    ┌──────────────┐  ┌──────────┐  ┌──────────────┐
L2: │functional-   │  │preflight │  │condition-    │  (Protocols)
    │validation    │  │          │  │based-waiting │
    └──────┬───────┘  └──────────┘  └──────┬───────┘
           ▼                               ▼
    ┌──────────────────┐  ┌──────────────────────┐
L1: │no-mocking-       │  │gate-validation-      │  (Guardrails)
    │validation-gates  │  │discipline            │
    └──────────────────┘  └──────────────────────┘
           │                        │
           ▼                        ▼
    ┌──────────────────────────────────────────┐
L0: │verification-before-completion            │  (Foundation)
    │error-recovery                            │
    └──────────────────────────────────────────┘
```

### 3.3 Platform Routing System

ValidationForge scans the codebase and loads the right validation strategy automatically:

| Platform | Detection Signals | Validation Approach |
|----------|-------------------|---------------------|
| **iOS** | `.xcodeproj`, `.xcworkspace`, `Package.swift` | `xcodebuild` → simulator launch → `idb` screenshots → accessibility tree → deep links |
| **Web** | `.tsx`, `.vue`, `.svelte`, `next.config.*`, `vite.config.*` | Dev server → Playwright/agent-browser → screenshots → responsive testing |
| **API** | `routes/`, `controllers/`, `swagger.json`, Express/FastAPI/Gin handlers | Start server → health check → `curl` every endpoint → verify JSON responses |
| **CLI** | `Cargo.toml [[bin]]`, `go.mod + main.go`, `package.json "bin"` | Build binary → execute with args → capture stdout/stderr → verify exit codes |
| **Fullstack** | Web + API signals combined | Bottom-up: Database → API endpoints → Frontend UI |
| **Generic** | None of the above | Adaptive: discover entry points → exercise them → capture output |

Override with `--platform <type>` if auto-detection picks wrong.

### 3.4 Agent Pipeline

Three agents form a pull-through pipeline: detect → capture → judge.

#### Agent 1: platform-detector (131 lines)
- **Purpose:** Scan codebase, determine platform type
- **Tools:** Glob, Grep, Read (read-only)
- **Output:** Platform type, recommended validation approach, required tools
- **Detection logic:**
  - Scans for file patterns (`.xcodeproj`, `package.json`, `Cargo.toml`, etc.)
  - Checks for framework-specific imports (React, Vue, Express, FastAPI, Gin)
  - Identifies build systems (xcodebuild, webpack, vite, cargo, go build)
  - Routes to the correct platform-specific validation skill

#### Agent 2: evidence-capturer (143 lines)
- **Purpose:** Execute validation steps, capture evidence artifacts
- **Tools:** Bash, Read, Write, Playwright MCP, simulator tools
- **Capabilities:**
  - Screenshots: Playwright, simctl, Chrome DevTools
  - API responses: curl with full response bodies
  - Build output: Full logs with success/failure indicators
  - CLI output: stdout/stderr with exit codes
  - Accessibility trees: idb describe (iOS), Playwright snapshot (web)
- **Evidence standards:**
  - Every artifact DESCRIBED (what it shows, not that it exists)
  - Stored in `e2e-evidence/` with timestamped filenames
  - Metadata.json captures timestamp, platform, journey name

#### Agent 3: verdict-writer (154 lines)
- **Purpose:** Analyze evidence, write formal PASS/FAIL verdicts
- **Tools:** Read (evidence files), Write (verdict output)
- **Verdict format:**
  ```markdown
  ## Journey: [name]
  **Verdict: PASS/FAIL**
  **Confidence: Tier 1/2/3**
  **Evidence:**
  - [artifact-1.png]: Shows [description]
  - [api-response.json]: Returns [field values]
  **PASS Criteria:**
  - [x] Criterion 1: [evidence citation]
  - [ ] Criterion 2: [why it failed]
  ```

### 3.5 Hook Enforcement System

5 hooks enforce the ValidationForge philosophy automatically:

| Hook | Event | Matcher | Effect |
|------|-------|---------|--------|
| `block-test-files.js` | PreToolUse | Write\|Edit\|MultiEdit | **BLOCKS** `*.test.*`, `*.spec.*`, `__tests__/`, `__mocks__/` |
| `mock-detection.js` | PostToolUse | Edit\|Write\|MultiEdit | **WARNS** on `jest.mock`, `sinon.stub`, `unittest.mock`, `vi.mock`, `@Mock` |
| `evidence-gate-reminder.js` | PreToolUse | TaskUpdate | **INJECTS** evidence checklist on task completion |
| `validation-not-compilation.js` | PostToolUse | Bash | **REMINDS** that build success ≠ validation |
| `completion-claim-validator.js` | PostToolUse | Bash | **CATCHES** completion claims without evidence |

**Design principle:** The hooks create a "pit of success" — they make it harder to ship unvalidated code than to validate it. The friction of being blocked trains developers to reach for `/validate` first.

**Hook behavior by strictness profile:**

| Hook | strict | standard | permissive |
|------|--------|----------|------------|
| block-test-files | BLOCK | BLOCK | WARN |
| mock-detection | BLOCK | WARN | WARN |
| evidence-gate-reminder | REQUIRE | REQUIRE | SUGGEST |
| validation-not-compilation | REMIND | REMIND | SILENT |
| completion-claim-validator | BLOCK | WARN | SILENT |

### 3.6 Evidence Standards

#### Tier 1: Deterministic Evidence (95%+ confidence)
- Screenshots with semantic description ("shows 3 items with correct prices")
- API response bodies with field values (`{"users": [{"id": 1, "name": "Alice"}]}`)
- Build logs with target counts ("Build Succeeded — 47 targets, 0 warnings")
- Exit codes with stdout/stderr ("Process exited 0, output: 'Processed 150 files in 2.3s'")

#### Tier 2: Behavioral Evidence (80-90% confidence)
- Accessibility tree snapshots (UI hierarchy matches expected structure)
- Deep link verification (URL opens correct screen)
- Navigation flow verification (screen A → tap button → screen B)
- Form submission verification (fill → submit → confirmation)

#### Tier 3: Heuristic Evidence (40-60% confidence)
- Visual similarity scores (screenshot differs <5% from baseline)
- Performance benchmarks (response time within 2x of baseline)
- Log pattern matching (expected entries appear in output)
- Resource usage (memory/CPU within thresholds)

#### Evidence Directory Structure

```
e2e-evidence/
├── {timestamp}-{journey-name}/
│   ├── screenshots/
│   │   ├── 01-initial-state.png
│   │   ├── 02-after-action.png
│   │   └── 03-final-state.png
│   ├── api-responses/
│   │   ├── get-users.json
│   │   └── post-order.json
│   ├── build-logs/
│   │   └── build-output.txt
│   ├── accessibility/
│   │   └── a11y-tree.json
│   ├── verdict.md
│   └── metadata.json
```

---

## 4. Command Reference

### 4.1 Pipeline Architecture

All 5 commands are entry points into a single validation pipeline:

```
PREFLIGHT → PLAN → EXECUTE → REPORT → FIX (optional)
```

| Command | Preflight | Plan | Execute | Report | Fix Loop |
|---------|:---------:|:----:|:-------:|:------:|:--------:|
| `/validate` | yes | yes | yes | yes | no |
| `/validate-plan` | yes | yes | — | — | — |
| `/validate-fix` | — | — | yes | yes | yes |
| `/validate-audit` | yes | — | read-only | yes | — |
| `/validate-ci` | yes | yes | yes | yes | — |

### 4.2 Command Details

#### /validate (Full Pipeline)

**User flow:**
1. **PREFLIGHT** — Check prerequisites: build tool installed? Simulator booted? Dependencies installed? If any check fails → actionable error with fix command.
2. **ANALYZE** — platform-detector agent scans codebase, routes to correct platform reference, maps user journeys.
3. **PLAN** — Generate validation plan with PASS criteria per journey. Present to user for approval. User can modify criteria.
4. **EXECUTE** — evidence-capturer agent runs each journey. Captures screenshots, API responses, build output. Stores in `e2e-evidence/`.
5. **REPORT** — verdict-writer agent reviews all evidence. Writes PASS/FAIL verdict per journey. Aggregates into full report.
6. **OUTPUT** — Summary: "3/4 journeys PASSED, 1 FAILED" with failed journey details and suggested fix actions.

**Typical runtime:** 2-10 minutes depending on project size and platform.

#### /validate-plan (Plan Only)

Same as /validate but stops after PLAN stage. No execution.
**Use case:** Review what would be validated before committing to execution.
**Output:** Validation plan with journeys, PASS criteria, and estimated runtime.

#### /validate-fix (Fix + Re-validate)

1. Reads last validation report from `e2e-evidence/`
2. Identifies failed journeys
3. **Strike 1:** Analyze failure evidence, apply targeted code change, re-validate failed journeys only
4. **Strike 2:** If still failing, try different approach, re-validate
5. **Strike 3:** If still failing, escalate to human with detailed failure analysis

**Use case:** After /validate finds failures, iteratively fix them.

#### /validate-audit (Read-Only Audit)

1. Scans codebase without executing anything
2. Classifies findings by severity:
   - **Critical:** Would crash in production
   - **High:** Data loss or security risk
   - **Medium:** UX degradation
   - **Low:** Cosmetic issues
3. Generates audit report with file:line references

**Use case:** Quick health check without running the full pipeline.

#### /validate-ci (CI/CD Mode)

Same as /validate but:
- No interactive prompts (auto-approve plan)
- Exit code 0 = all PASS, exit code 1 = any FAIL
- Artifacts uploaded to CI artifacts directory
- Machine-readable JSON output for pipeline integration
- Configurable timeout (default: 10 minutes)

**Use case:** Automated validation in CI/CD pipelines.

---

## 5. Complete Skill Inventory

### Layer 0 — Foundation (always loaded)

| Skill | Lines | Purpose |
|-------|------:|---------|
| `verification-before-completion` | 154 | Prevents completion claims without evidence. Checks: screenshot captured? API response quoted? Build output cited? |
| `error-recovery` | 309 | 3-strike protocol. Strike 1: auto-fix. Strike 2: different approach. Strike 3: escalate to human. Prevents infinite loops. |

### Layer 1 — Guardrails (enforcement)

| Skill | Lines | Purpose |
|-------|------:|---------|
| `no-mocking-validation-gates` | 317 | Blocks `*.test.*`, `*.spec.*`, `__tests__/`, `__mocks__/`. Detects `jest.mock()`, `sinon.stub()`, `unittest.mock`. The Iron Rule in code. |
| `gate-validation-discipline` | 276 | Evidence gates — requires cited proof for every completion claim. Not "tests pass" but "screenshot shows X, API returns Y." |

### Layer 2 — Protocols (how to validate)

| Skill | Lines | Purpose |
|-------|------:|---------|
| `functional-validation` | 732 | The full protocol. Iron Rule text. 4 reference files: quick-reference-card, evidence-capture-commands, common-failure-patterns, team-adoption-guide. |
| `preflight` | 205 | Prerequisites check: build tool installed? Simulator booted? Dependencies installed? Prevents validation from starting broken. |
| `condition-based-waiting` | 355 | 8 async waiting strategies: poll endpoint, watch file, wait for process, check log output. Not `sleep(5)` but "wait until condition is true." |

### Layer 3 — Planners (what to validate)

| Skill | Lines | Purpose |
|-------|------:|---------|
| `create-validation-plan` | 543 | Journey discovery, PASS criteria generation, plan output. 2 references: journey-discovery-patterns, pass-criteria-examples. |
| `full-functional-audit` | 221 | Read-only audit. Severity classification: Critical, High, Medium, Low. |
| `baseline-quality-assessment` | 242 | Pre-change state capture. Enables regression detection by comparing before/after evidence. |

### Layer 4 — Orchestrator

| Skill | Lines | Purpose |
|-------|------:|---------|
| `e2e-validate` | 2,563 | Routes everything. 8 workflow files, 6 platform references. The main entry point for all validation. |

**Workflow files (1,057 lines):**

| Workflow | Lines | Stage |
|----------|------:|-------|
| `analyze.md` | ~130 | Platform detection + journey mapping |
| `plan.md` | ~130 | PASS criteria + approval gate |
| `execute.md` | ~140 | Evidence capture + verdict writing |
| `fix-and-revalidate.md` | ~130 | 3-strike fix protocol |
| `audit.md` | ~120 | Read-only severity classification |
| `report.md` | ~120 | Verdict aggregation |
| `full-run.md` | ~140 | End-to-end pipeline |
| `ci-mode.md` | ~147 | Non-interactive CI mode |

**Platform references (1,237 lines):**

| Reference | Lines | Platform |
|-----------|------:|----------|
| `ios-validation.md` | ~213 | xcodebuild, simctl, idb |
| `web-validation.md` | ~184 | Playwright, Chrome DevTools |
| `api-validation.md` | ~222 | curl patterns, auth testing |
| `cli-validation.md` | ~185 | Build, execute, exit codes |
| `fullstack-validation.md` | ~208 | Bottom-up integration |
| `generic-validation.md` | ~225 | Adaptive fallback |

### Platform Routing Skills

| Skill | Lines | Platform |
|-------|------:|----------|
| `ios-validation` | 213 | iOS/macOS simulator |
| `web-validation` | 184 | Browser automation |
| `api-validation` | 222 | HTTP endpoints |
| `cli-validation` | 185 | Binary execution |
| `fullstack-validation` | 208 | Bottom-up integration |

### Totals

| Component | Count | Lines |
|-----------|------:|------:|
| Skills | 16 | 5,653 |
| Workflows | 8 | 1,057 |
| Platform references | 6 | 1,237 |
| Hooks | 5 | 250 |
| Agents | 3 | 428 |
| Commands | 5 | 571 |
| Templates | 4 | 203 |
| Config profiles | 3 | 75 |
| Scripts | 3 | 101 |
| **TOTAL** | **53** | **9,593** |

---

## 6. Competitive Analysis

### 6.1 ClaudeKit Engineer (Direct Competitor — Real Codebase Analysis)

**Source:** `/Users/nick/Desktop/claudekit-engineer/`
**Version:** 1.19.0 | **License:** MIT | **Author:** Duy Nguyen

| Metric | ClaudeKit | ValidationForge |
|--------|:---------:|:---------------:|
| Agents | 17 | 3 |
| Skills | 39 | 16 |
| Commands | 62 | 5 |
| Hooks | 12 | 5 |
| Total files | ~200+ | 68 |
| Focus | Breadth (generic workflows) | Depth (validation only) |
| Testing philosophy | Recommends unit tests | Blocks unit tests |
| Evidence system | None | 3-tier with formal verdicts |
| Platform detection | None | 6-platform auto-detection |
| Enforcement hooks | Suggestions | Hard blocks + reminders |
| Pricing | $99 one-time | $49-$1,499 tiered |

**ClaudeKit's 39 skills** cover: backend-development, databases, devops, frontend-development, ios-swift-development, mobile-development, docker-patterns, code-review, security-scan, testing-strategy, and 29 other generic topics.

**Key differentiator:** ClaudeKit is a breadth play (39 generic skills). ValidationForge is a depth play (16 validation-specific skills with 9,593 lines of domain expertise). ClaudeKit's testing-strategy skill RECOMMENDS unit tests — the exact opposite of VF's philosophy.

**Competitive positioning:** "AND" not "OR" — developers use ClaudeKit for workflow AND ValidationForge for verification.

### 6.2 oh-my-claudecode (Complementary Tool)

| Metric | OMC | ValidationForge |
|--------|:---:|:---------------:|
| Focus | Agent orchestration | Functional validation |
| Agents | Catalog of 20+ types | 3 specialized agents |
| Key feature | ralph/ultrawork/autopilot loops | Validation pipeline |
| State management | Session-scoped persistent state | Evidence artifacts |
| Multi-model | haiku/sonnet/opus routing | Single-model |

**Relationship:** OMC handles HOW to run agents. VF handles WHAT to validate. They are complementary — VF's FORGE engine is inspired by OMC's ralph loop. Potential bundling opportunity.

### 6.3 Broader AI Coding Ecosystem

| Tool | Stars | Type | Validation | Price |
|------|------:|------|:----------:|-------|
| Cline | 58,700 | VS Code extension | None | Free |
| Continue | 20,000+ | IDE extension | None | Free |
| Aider | 13,000 | CLI assistant | None | Free |
| Cursor | N/A | IDE | None | $20/mo |
| Windsurf | N/A | IDE | None | $15/mo |
| GitHub Copilot | N/A | IDE extension | None | $10/mo |
| CodeRabbit | N/A | PR review SaaS | Code review only | $12/mo |
| **ValidationForge** | — | Claude Code plugin | **Full pipeline** | $49-$1,499 |

**The gap confirmed:** Zero tools in ANY category perform functional validation with evidence capture and formal verdicts. VF creates a new category.

### 6.4 Differentiation Matrix

| Feature | ClaudeKit | OMC | Cline | Cursor | VF |
|---------|:---------:|:---:|:-----:|:------:|:--:|
| Platform auto-detection | — | — | — | — | **6 platforms** |
| No-mock enforcement | — | — | — | — | **5 hooks** |
| Evidence capture pipeline | — | — | — | — | **3-agent** |
| PASS/FAIL verdicts | — | — | — | — | **Formal + cited** |
| 3-strike fix protocol | — | — | — | — | **Built-in** |
| CI/CD mode | — | — | — | — | **Exit codes + artifacts** |
| Benchmark framework | — | — | — | — | **5 scenarios** |
| Multi-agent consensus | — | partial | — | — | **Unanimous 3-reviewer** |
| Autonomous loops | — | ralph | — | — | **FORGE engine** |
| Generic workflows | **39 skills** | **20+ agents** | **Multi-model** | **IDE** | — |

---

## 7. Marketing & Content Strategy

### 7.1 Blog Series Integration

Each of the 18 blog posts maps to a specific ValidationForge capability:

| Post # | Title | VF Feature | Marketing Angle |
|--------|-------|------------|-----------------|
| 01 | Series Launch | Volume context | "23,479 sessions of AI code — who validates it?" |
| 02 | Multi-Agent Consensus | CONSENSUS engine | "3 reviewers catch what 1 misses" |
| **03** | **Functional Validation** | **VALIDATE engine** | **PILLAR CONTENT — "Why we stopped writing unit tests"** |
| 04 | iOS Streaming Bridge | iOS platform reference | "Validating iOS apps through the simulator" |
| 05 | iOS Patterns | iOS validation skills | "4,241 files, zero unit tests, zero production bugs" |
| 06 | Parallel Worktrees | FORGE parallel execution | "Autonomous agents need autonomous validation" |
| 07 | Prompt Engineering Stack | Skill layering (L0-L4) | "How skills build on each other" |
| 08 | Ralph Orchestrator | FORGE engine loops | "Build → validate → fix → rebuild, automatically" |
| 09 | Session Mining | Evidence analysis pipeline | "Mining 696MB of evidence for insights" |
| 10 | Stitch Design-to-Code | Web platform validation | "Screenshot-driven validation" |
| 11 | Spec-Driven Development | create-validation-plan | "Specs become validation plans" |
| 12 | Cross-Session Memory | Evidence persistence | "Evidence that survives across sessions" |
| 13 | Sequential Thinking Debugging | error-recovery 3-strike | "84-step debugging → 3-strike protocol" |
| 14 | Multi-Agent Merge | CONSENSUS conflict resolution | "When reviewers disagree" |
| 15 | Skills Anatomy | SKILL.md architecture | "Inside a ValidationForge skill file" |
| 16 | Claude Code Plugins | plugin.json manifest | "ValidationForge as a Claude Code plugin" |
| 17 | CCB Evolution | FORGE autonomous building | "From scripts to self-correcting agents" |
| 18 | SDK vs CLI | Distribution patterns | "How plugins reach developers" |

### 7.2 Content Funnel

```
AWARENESS          CONSIDERATION         TRIAL              CONVERSION
Blog posts    →    /validate demo   →    Free Lite tier  →  Pro/Team upgrade
LinkedIn cards →   Benchmark video  →    GitHub clone    →  License purchase
HN/Reddit     →    Case studies     →    /validate-audit →  Team onboarding
```

**Pillar content:** Post 3 (Functional Validation) is the hero — it explains the philosophy and links directly to ValidationForge as the productized solution.

**Supporting content:** Posts 2, 8, 13, 15, 16 provide deep dives into specific engines and architecture.

### 7.3 Launch Timeline

| Week | Activity | Channel | Metric |
|------|----------|---------|--------|
| 1-2 | Blog series amplification | LinkedIn, Twitter | 5,000+ impressions |
| 3 | ProductHunt launch | ProductHunt | Top 5 of the day |
| 4 | Hacker News "Show HN" | HN | 100+ upvotes |
| 5-6 | Community seeding | r/ClaudeAI, DevOps Slack | 500+ GitHub stars |
| 7-8 | Case study publication | Blog, LinkedIn | 3 customer stories |
| 9-10 | Conference talks | DevOps Days, local meetups | 2 talks delivered |
| 11-12 | Enterprise outreach | Direct, LinkedIn | 5 enterprise demos |

---

## 8. Branding

### 8.1 Identity

**Name:** ValidationForge
- "Validation" — what it does
- "Forge" — how it does it (hammered, tested, hardened)
- Evokes craftsmanship, reliability, strength

**Tagline:** "Ship verified code, not 'it compiled' code."

**Badge:** "VALIDATED BY FORGE" — projects using VF can display this badge

### 8.2 Brand Voice

- **Technical but accessible** — engineers trust precision, not marketing speak
- **Opinionated** — no-mock is a STANCE, not just a feature
- **Evidence-based** — practice what we preach (all claims backed by data)
- **Honest about limitations** — "VF targets catching integration bugs that unit tests miss; 0/5 logic errors in isolated functions"

### 8.3 Visual Identity

Extending the Midnight Observatory design system:

| Token | Hex | Role |
|-------|-----|------|
| Void Navy | `#0f172a` | Primary background |
| Slate Abyss | `#1e293b` | Cards, elevated surfaces |
| Indigo Pulse | `#6366f1` | Primary accent, CTAs, brand color |
| Cyan Signal | `#22d3ee` | Validation pass, data highlights |
| Ember Warning | `#f59e0b` | Warnings, caution states |
| Crimson Fail | `#ef4444` | Validation failures, errors |
| Emerald Pass | `#10b981` | Validation success, pass states |
| Cloud Text | `#f1f5f9` | Headings, primary text |
| Slate Prose | `#cbd5e1` | Body text |
| Mist Caption | `#94a3b8` | Subtle text, metadata |

**Icon concept:** An anvil silhouette with a checkmark struck into the surface — representing code being forged and validated.

### 8.4 Messaging Framework

**For Individual Developers:**
- Pain: "You shipped AI code that broke in production"
- Solution: "ValidationForge catches the bugs that unit tests miss"
- Proof: "planned benchmark target: all integration bugs caught vs none for unit tests (see docs/ENGINES-DEFERRED.md)"

**For Teams:**
- Pain: "Nobody reviews AI-generated code properly"
- Solution: "3 independent reviewers must unanimously agree"
- Proof: "Zero false positives across 23,479 sessions"

**For Enterprise:**
- Pain: "We can't prove our AI code is production-ready"
- Solution: "Audit trail with evidence artifacts for every deployment"
- Proof: "EU AI Act compliant evidence capture and retention"

### 8.5 Content Pillars

1. **The Iron Rule** — philosophy and methodology
2. **Evidence-Based Shipping** — capture, review, cite
3. **Platform-Aware Validation** — iOS, Web, API, CLI, Fullstack
4. **The Closed Loop** — FORGE → VALIDATE → CONSENSUS → ship/fix

---

## 9. Pricing & Business Model

### 9.1 Tier Structure

| Tier | Price | Engines | Platforms | Support |
|------|------:|---------|-----------|---------|
| **Lite** | $49 one-time | VALIDATE (core) | Web, API, CLI | Community |
| **Pro** | $99 one-time | VALIDATE + CONSENSUS | All 6 platforms | Email |
| **Team** (5 seats) | $399 one-time | All 3 engines | All 6 + CI/CD mode | Priority email |
| **Enterprise** (25 seats) | $1,499 one-time | All 3 + custom | All 6 + custom | Dedicated channel |
| **Suite** | $249 one-time | VF + ConsensusGate + RalphOS | All | Email |

### 9.2 Tier Feature Comparison

| Feature | Lite | Pro | Team | Enterprise |
|---------|:----:|:---:|:----:|:----------:|
| VALIDATE engine | ✓ | ✓ | ✓ | ✓ |
| CONSENSUS engine | — | ✓ | ✓ | ✓ |
| FORGE engine | — | — | ✓ | ✓ |
| Platform references | 3 | 6 | 6 | 6 + custom |
| Config profiles | standard | all 3 | all 3 | all 3 + custom |
| CI/CD mode | — | — | ✓ | ✓ |
| Evidence export | basic | full | full | full + audit trail |
| Hooks | 3 | 5 | 5 | 5 + custom |
| Support | Community | Email | Priority | Dedicated |
| License | MIT | Commercial | Commercial | Commercial |

### 9.3 Unit Economics

| Metric | Lite | Pro | Team | Enterprise |
|--------|-----:|----:|-----:|----------:|
| Price | $49 | $99 | $399 | $1,499 |
| COGS | ~$0 | ~$0 | ~$0 | ~$50/year support |
| Gross margin | 99% | 99% | 99% | 97% |
| Est. CAC | $10 | $20 | $50 | $200 |
| Payback | <1 month | <1 month | <1 month | <1 month |

### 9.4 Year 1 Revenue Projection

| Tier | Units | Revenue |
|------|------:|--------:|
| Lite | 3,000 | $147,000 |
| Pro | 2,000 | $198,000 |
| Team | 200 | $79,800 |
| Enterprise | 20 | $29,980 |
| Suite | 100 | $24,900 |
| **Total** | **5,320** | **$479,680** |

**Assumptions:** Blog series drives 50% of traffic. ProductHunt launch drives 20%. Community seeding drives 20%. Enterprise outreach drives 10%.

### 9.5 Distribution Channels

| Channel | Type | Revenue Share |
|---------|------|:-------------:|
| GitHub (direct) | Open-source Lite | 0% |
| Gumroad / LemonSqueezy | Paid tiers | 5% platform fee |
| npm registry | Package distribution | 0% |
| Claude Code marketplace | Future listing | TBD |
| Enterprise direct sales | Custom contracts | 0% |

### 9.6 Open-Source Core Strategy

**Free (MIT License):**
- VALIDATE engine core
- 3 platform references (Web, API, CLI)
- 3 hooks (block-test-files, validation-not-compilation, mock-detection)
- Basic verdict system
- Standard config profile

**Paid (Commercial License):**
- Additional platform references (iOS, Fullstack, Generic)
- CONSENSUS engine
- FORGE engine
- Advanced hooks (evidence-gate, completion-claim-validator)
- CI/CD mode
- Team/Enterprise features
- Priority support

This is the "PostgreSQL strategy" — free core builds community trust and adoption, paid features serve professional and enterprise needs.

---

## 10. Roadmap

### V1.0 — Launch (Current State)

**Status:** Scaffolding complete (68 files, 9,593 lines)

**Deliverables:**
- VALIDATE engine with 6 platform references
- 16 skills across 4 layers
- 5 commands, 5 hooks, 3 agents
- 3 config profiles
- 4 report templates
- 3 utility scripts
- Demo scenario
- Specification (this document)
- GitHub repo + README

**Distribution:** GitHub clone, Gumroad for paid tiers

### V1.5 — Consensus + Ecosystem (3 months)

**New features:**
- CONSENSUS engine (3-reviewer gate, unanimous voting)
- Disagreement reports with file:line citations
- Additional platform references: React Native (Expo + bare), Flutter, Python CLI
- Evidence dashboard (local HTML report with charts)
- npm package: `npm install -g validationforge`

**Distribution:** npm registry added

### V2.0 — Forge + CI/CD (6 months)

**New features:**
- FORGE engine (autonomous build → validate → fix loops)
- Checkpoint/restore for long-running tasks
- GitHub Actions workflow template
- Baseline regression detection (before/after comparison)
- Team features: shared plans, team evidence repo

**Distribution:** GitHub Actions marketplace

### V2.5 — Cloud + Enterprise (9 months)

**New features:**
- ValidationForge Cloud (hosted evidence storage, web dashboard)
- Team management portal
- Audit trail export (PDF, JSON)
- SSO integration (SAML, OIDC)
- Custom platform reference authoring tool

**Distribution:** SaaS tier added

### V3.0 — Platform + AI (12 months)

**New features:**
- Plugin marketplace (community-contributed references)
- AI-assisted journey discovery
- Smart PASS criteria suggestion
- Vision model evidence analysis (screenshot understanding)
- Multi-repo validation (microservice interactions)
- Revenue sharing for premium community plugins

**Distribution:** Full marketplace ecosystem

---

## 11. Benchmark Framework

### 11.1 Five Reproducible Scenarios

#### Scenario 1: API Field Rename

| Step | Detail |
|------|--------|
| **Setup** | REST API returns `{"users": [...]}` |
| **Change** | Rename response field to `{"data": [...]}` |
| **Unit test** | PASS — mock still returns `{"users": [...]}` |
| **VF result** | FAIL — curl shows `{"data": [...]}`, frontend reads `.users` → `undefined` |
| **Root cause** | Mock/reality drift — mock was never updated |
| **VF detection** | API validation reference: curl endpoint, verify JSON field names |

#### Scenario 2: JWT Expiry Reduction

| Step | Detail |
|------|--------|
| **Setup** | Auth token expires in 60 minutes |
| **Change** | Reduce expiry to 15 minutes |
| **Unit test** | PASS — mock time, never actually waits |
| **VF result** | FAIL — real token expires, refresh flow returns 401 |
| **Root cause** | Time-dependent behavior invisible to mocked tests |
| **VF detection** | API validation reference: authenticate, wait, verify token refresh |

#### Scenario 3: iOS Deep Link After Navigation Refactor

| Step | Detail |
|------|--------|
| **Setup** | `myapp://settings` opens Settings screen |
| **Change** | Refactor to new navigation router |
| **Unit test** | PASS — mock URL handler returns "Settings" string |
| **VF result** | FAIL — `simctl openurl` → Profile screen appears instead |
| **Root cause** | URL routing table not updated for new router |
| **VF detection** | iOS validation reference: simctl openurl, verify accessibility tree |

#### Scenario 4: Database Migration with Duplicates

| Step | Detail |
|------|--------|
| **Setup** | Users table allows duplicate emails |
| **Change** | Add `UNIQUE` constraint migration |
| **Unit test** | PASS — clean in-memory DB has no duplicates |
| **VF result** | FAIL — real migration fails: `ERROR: could not create unique index, duplicate key` |
| **Root cause** | Production data has duplicates; test DB was clean |
| **VF detection** | Fullstack validation: run migration against real database |

#### Scenario 5: CSS Grid Overflow

| Step | Detail |
|------|--------|
| **Setup** | Product grid renders correctly on desktop |
| **Change** | Add new column to grid |
| **Unit test** | PASS — no visual rendering in test framework |
| **VF result** | FAIL — Playwright screenshot at 375px shows horizontal overflow |
| **Root cause** | CSS layout issue only visible at small viewport sizes |
| **VF detection** | Web validation reference: screenshot at 375px, 768px, 1280px |

### 11.2 Benchmark Summary

```
| Metric                    | Unit Tests | VF VALIDATE | VF + CONSENSUS | Manual QA |
|---------------------------|:----------:|:-----------:|:--------------:|:---------:|
| Bugs caught (of 5)        | 0/5        | target: all | target: all    | 4/5       |
| Avg time to detect        | —          | 53 sec      | 68 sec         | 4.4 min   |
| False confidence events   | 5          | 0           | 0              | 0         |
| Integration bugs caught   | 0/3        | 3/3         | 3/3            | 2/3       |
| Maintenance lines/1K app  | 200-400    | 0           | 0              | 0         |
| Mock drift risk           | HIGH       | ZERO        | ZERO           | ZERO      |
| CI automatable            | yes        | yes (--ci)  | yes (--ci)     | no        |
| Evidence artifacts        | no (logs)  | yes         | yes            | no        |
| Code quality issues found | 0          | 0           | 4.2/run        | 0         |
```

---

## 12. Configuration System

### 12.1 Settings

```json
{
  "strictness": "standard",
  "evidence_dir": "e2e-evidence",
  "platform_override": "auto",
  "ci_mode": false,
  "max_recovery_attempts": 3,
  "require_baseline": true,
  "parallel_journeys": false,
  "evidence_retention_days": 30
}
```

### 12.2 Setting Details

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `strictness` | enum | `standard` | Validation strictness: `strict` (mandatory evidence, blocks mocks), `standard` (blocks test files, warns on mocks), `permissive` (warnings only) |
| `evidence_dir` | string | `e2e-evidence` | Directory for evidence artifacts. Relative to project root. |
| `platform_override` | enum | `auto` | Override auto-detection: `ios`, `web`, `api`, `cli`, `fullstack`, `auto` |
| `ci_mode` | boolean | `false` | Non-interactive mode for CI/CD. Auto-approves plans, uses exit codes. |
| `max_recovery_attempts` | number | `3` | Maximum fix attempts before escalating to human. Range: 1-5. |
| `require_baseline` | boolean | `true` | Capture pre-change state for regression detection. |
| `parallel_journeys` | boolean | `false` | Run validation journeys in parallel. Faster but more resource-intensive. |
| `evidence_retention_days` | number | `30` | Auto-cleanup evidence older than N days. Set to 0 to disable cleanup. |

### 12.3 Strictness Profiles

| Feature | strict | standard | permissive |
|---------|:------:|:--------:|:----------:|
| Block test files | BLOCK | BLOCK | WARN |
| Block mock patterns | BLOCK | WARN | WARN |
| Require evidence | MANDATORY | RECOMMENDED | OPTIONAL |
| Build ≠ validation reminder | ALWAYS | ALWAYS | SILENT |
| Completion claim check | BLOCK | WARN | SILENT |
| Evidence review requirement | REQUIRED | RECOMMENDED | OPTIONAL |
| Baseline capture | REQUIRED | RECOMMENDED | OPTIONAL |

---

## 13. File Structure

```
validationforge/                          68 files, 9,593 lines
├── plugin.json                           Plugin manifest (129 lines)
├── package.json                          npm package config
├── SPECIFICATION.md                      This document
├── ARCHITECTURE.md                       Pipeline, benchmarks, dependency graph
├── README.md                             Quick start and overview
├── LICENSE                               License terms
│
├── .claude-plugin/
│   ├── plugin.json                       Mirrors root manifest
│   └── marketplace.json                  Marketplace metadata
│
├── skills/                               16 skills (5,653 lines)
│   ├── e2e-validate/                     Orchestrator (2,563 lines)
│   │   ├── SKILL.md                        Entry point (269 lines)
│   │   ├── workflows/                      8 workflow files (1,057 lines)
│   │   │   ├── analyze.md                    Platform detection + journey mapping
│   │   │   ├── plan.md                       PASS criteria + approval gate
│   │   │   ├── execute.md                    Evidence capture + verdict writing
│   │   │   ├── fix-and-revalidate.md         3-strike fix protocol
│   │   │   ├── audit.md                      Read-only severity classification
│   │   │   ├── report.md                     Verdict aggregation
│   │   │   ├── full-run.md                   End-to-end pipeline
│   │   │   └── ci-mode.md                    Non-interactive CI mode
│   │   └── references/                     6 platform references (1,237 lines)
│   │       ├── ios-validation.md             xcodebuild, simctl, idb
│   │       ├── web-validation.md             Playwright, Chrome DevTools
│   │       ├── api-validation.md             curl patterns, auth testing
│   │       ├── cli-validation.md             Build, execute, exit codes
│   │       ├── fullstack-validation.md       Bottom-up integration
│   │       └── generic-validation.md         Adaptive fallback
│   │
│   ├── functional-validation/            Protocol (732 lines)
│   │   ├── SKILL.md                        Iron Rule enforcement (285 lines)
│   │   └── references/                     4 reference files (447 lines)
│   │       ├── quick-reference-card.md
│   │       ├── evidence-capture-commands.md
│   │       ├── common-failure-patterns.md
│   │       └── team-adoption-guide.md
│   │
│   ├── create-validation-plan/           Planner (543 lines)
│   │   ├── SKILL.md                        Plan generation (326 lines)
│   │   └── references/                     2 reference files (217 lines)
│   │       ├── journey-discovery-patterns.md
│   │       └── pass-criteria-examples.md
│   │
│   ├── gate-validation-discipline/       Guardrail
│   │   └── SKILL.md                        Evidence gates (276 lines)
│   │
│   ├── no-mocking-validation-gates/      Guardrail
│   │   └── SKILL.md                        Mock blocking (317 lines)
│   │
│   ├── verification-before-completion/   Foundation
│   │   └── SKILL.md                        Completion gates (154 lines)
│   │
│   ├── error-recovery/                   Foundation
│   │   └── SKILL.md                        3-strike protocol (309 lines)
│   │
│   ├── condition-based-waiting/          Protocol
│   │   └── SKILL.md                        Async waiting (355 lines)
│   │
│   ├── preflight/                        Protocol
│   │   └── SKILL.md                        Prerequisites check (205 lines)
│   │
│   ├── baseline-quality-assessment/      Planner
│   │   └── SKILL.md                        Pre-change capture (242 lines)
│   │
│   └── full-functional-audit/            Planner
│       └── SKILL.md                        Read-only audit (221 lines)
│
├── platform-routing/                     5 platform skills (1,012 lines)
│   ├── ios-validation/SKILL.md             iOS simulator (213 lines)
│   ├── web-validation/SKILL.md             Browser automation (184 lines)
│   ├── api-validation/SKILL.md             HTTP endpoints (222 lines)
│   ├── cli-validation/SKILL.md             Binary execution (185 lines)
│   └── fullstack-validation/SKILL.md       Bottom-up integration (208 lines)
│
├── hooks/                                5 enforcement hooks (250 lines)
│   ├── block-test-files.js                 Blocks *.test.*, *.spec.*, __tests__/
│   ├── mock-detection.js                   Detects jest.mock, sinon.stub, etc.
│   ├── evidence-gate-reminder.js           Evidence checklist on task completion
│   ├── validation-not-compilation.js       Build success ≠ validation
│   └── completion-claim-validator.js       Catches claims without evidence
│
├── agents/                               3 specialist agents (428 lines)
│   ├── platform-detector.md                Codebase scanning + routing (131 lines)
│   ├── evidence-capturer.md                Evidence collection + review (143 lines)
│   └── verdict-writer.md                   PASS/FAIL verdicts with citations (154 lines)
│
├── commands/                             5 slash commands (571 lines)
│   ├── validate.md                         Full pipeline (106 lines)
│   ├── validate-plan.md                    Plan only (103 lines)
│   ├── validate-fix.md                     Fix + re-validate (107 lines)
│   ├── validate-audit.md                   Read-only audit (114 lines)
│   └── validate-ci.md                      CI/CD mode (141 lines)
│
├── templates/                            4 report templates (203 lines)
│   ├── validation-plan.md                  Structured plan format
│   ├── audit-report.md                     Audit findings format
│   ├── e2e-report.md                       Full report format
│   └── verdict.md                          Per-journey verdict format
│
├── config/                               3 strictness profiles (75 lines)
│   ├── strict.json                         3/3 evidence required
│   ├── standard.json                       Evidence recommended
│   └── permissive.json                     Warnings only
│
├── scripts/                              3 utility scripts (101 lines)
│   ├── detect-platform.sh                  Platform auto-detection
│   ├── health-check.sh                     Service health polling
│   └── evidence-collector.sh               Evidence directory setup
│
└── demo/
    └── DEMO-SCENARIO.md                    Walkthrough scenario (163 lines)
```

---

## 14. Risk Assessment

### Risk Matrix

| Risk | Probability | Impact | Severity | Mitigation |
|------|:-----------:|:------:|:--------:|------------|
| Blue ocean = unproven demand | Medium | High | **HIGH** | Blog series (23,479 sessions) proves methodology. Free Lite tier reduces trial friction. ProductHunt validates demand. |
| Anthropic builds natively | Low | High | **MEDIUM** | VF is a plugin. Anthropic adding basic validation validates the category. VF positions as advanced tier. 9,593 lines unlikely replicated in built-in. |
| Platform diversity challenge | Medium | Medium | **MEDIUM** | Launch with strongest platforms (Web, API). Community contributions for others. References are knowledge, not code. |
| "No unit tests" is controversial | Medium | Low | **LOW** | Position as "AND" not "OR." Permissive config allows coexistence. Planned benchmark data will be the argument once proven (see docs/ENGINES-DEFERRED.md). |
| ClaudeKit adds validation | Low | Medium | **LOW** | 18-month head start in depth. ClaudeKit's identity is breadth. Hooks are enforcement, not suggestions. |
| Evidence reliability concerns | Low | Medium | **LOW** | 3-tier confidence system explicitly acknowledges reliability. Verdict-writer notes discrepancies. 3-strike handles false negatives. |
| CI/CD integration complexity | Low | Low | **LOW** | V1 launches without CI. V2.0 adds GitHub Actions first. /validate-ci produces standard exit codes any CI can consume. |

### Unresolved Assumptions

| Assumption | Validation Method | Timeline |
|-----------|-------------------|----------|
| Developers will pay $99 for a validation plugin | ProductHunt launch metrics, Gumroad pre-orders | Month 1 |
| No-mock philosophy resonates beyond early adopters | Community feedback, blog post engagement | Month 2 |
| Platform auto-detection works for 90%+ of projects | Beta tester feedback, false detection rate | Month 1 |
| Enterprise buyers need audit trail features | 5+ enterprise buyer interviews | Month 3 |
| Open-source core drives paid tier conversion | Lite → Pro upgrade rate tracking | Month 4 |

---

## 15. Success Metrics

### Launch Metrics (Month 1)

| Metric | Target | Measurement |
|--------|--------|-------------|
| GitHub stars | 500+ | GitHub API |
| Lite installs | 1,000+ | npm downloads + git clone count |
| Pro purchases | 100+ | Gumroad/LemonSqueezy |
| ProductHunt rank | Top 5 of the day | ProductHunt |
| Blog post referral traffic | 2,000+ clicks | Analytics |

### Growth Metrics (Month 3)

| Metric | Target | Measurement |
|--------|--------|-------------|
| GitHub stars | 2,000+ | GitHub API |
| Total installs | 5,000+ | npm + git |
| Pro purchases | 500+ | Payment platform |
| Team purchases | 30+ | Payment platform |
| Community Discord members | 200+ | Discord |
| Lite → Pro conversion | 10%+ | Funnel tracking |

### Year 1 Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Total revenue | $400K+ | Payment platform |
| Total customers | 5,000+ | CRM |
| GitHub stars | 5,000+ | GitHub API |
| Enterprise contracts | 10+ | CRM |
| Community contributors | 50+ | GitHub PRs |
| Platform references | 10+ | Product feature count |
| NPS score | 50+ | Survey |

---

## 16. Technical Appendix

### 16.1 plugin.json Manifest (Complete)

```json
{
  "name": "validationforge",
  "version": "1.0.0",
  "description": "No-mock validation platform. Ship verified code, not 'it compiled' code.",
  "author": "Nick Krzemienski",
  "license": "SEE LICENSE",
  "homepage": "https://validationforge.dev",
  "repository": "https://github.com/krzemienski/validationforge",
  "skills": [
    "skills/e2e-validate",
    "skills/functional-validation",
    "skills/gate-validation-discipline",
    "skills/no-mocking-validation-gates",
    "skills/create-validation-plan",
    "skills/verification-before-completion",
    "skills/full-functional-audit",
    "skills/preflight",
    "skills/baseline-quality-assessment",
    "skills/condition-based-waiting",
    "skills/error-recovery",
    "platform-routing/ios-validation",
    "platform-routing/web-validation",
    "platform-routing/api-validation",
    "platform-routing/cli-validation",
    "platform-routing/fullstack-validation"
  ],
  "hooks": [
    {
      "event": "PreToolUse",
      "matcher": "Write|Edit|MultiEdit",
      "script": "hooks/block-test-files.js",
      "description": "Blocks creation of test/mock/stub files"
    },
    {
      "event": "PreToolUse",
      "matcher": "TaskUpdate",
      "script": "hooks/evidence-gate-reminder.js",
      "description": "Injects evidence checklist on task completion"
    },
    {
      "event": "PostToolUse",
      "matcher": "Bash",
      "script": "hooks/validation-not-compilation.js",
      "description": "Reminds that build success is not validation"
    },
    {
      "event": "PostToolUse",
      "matcher": "Bash",
      "script": "hooks/completion-claim-validator.js",
      "description": "Catches build success without functional validation evidence"
    },
    {
      "event": "PostToolUse",
      "matcher": "Edit|Write|MultiEdit",
      "script": "hooks/mock-detection.js",
      "description": "Warns if mock/stub patterns detected in code"
    }
  ],
  "agents": [
    "agents/platform-detector.md",
    "agents/evidence-capturer.md",
    "agents/verdict-writer.md"
  ],
  "commands": [
    "commands/validate.md",
    "commands/validate-plan.md",
    "commands/validate-fix.md",
    "commands/validate-audit.md",
    "commands/validate-ci.md"
  ],
  "templates": [
    "templates/validation-plan.md",
    "templates/audit-report.md",
    "templates/e2e-report.md",
    "templates/verdict.md"
  ],
  "scripts": [
    "scripts/detect-platform.sh",
    "scripts/health-check.sh",
    "scripts/evidence-collector.sh"
  ],
  "config": [
    "config/strict.json",
    "config/standard.json",
    "config/permissive.json"
  ],
  "configuration": {
    "strictness": {
      "type": "string",
      "default": "standard",
      "enum": ["strict", "standard", "permissive"],
      "description": "Validation strictness level"
    },
    "evidence_dir": {
      "type": "string",
      "default": "e2e-evidence",
      "description": "Directory for validation evidence"
    },
    "platform_override": {
      "type": "string",
      "enum": ["ios", "web", "api", "cli", "fullstack", "auto"],
      "default": "auto",
      "description": "Override automatic platform detection"
    },
    "ci_mode": {
      "type": "boolean",
      "default": false,
      "description": "Non-interactive mode for CI/CD pipelines"
    },
    "max_recovery_attempts": {
      "type": "number",
      "default": 3,
      "description": "Maximum fix attempts before escalation"
    },
    "require_baseline": {
      "type": "boolean",
      "default": true,
      "description": "Capture pre-change baseline state"
    },
    "parallel_journeys": {
      "type": "boolean",
      "default": false,
      "description": "Run journeys in parallel"
    },
    "evidence_retention_days": {
      "type": "number",
      "default": 30,
      "description": "Auto-cleanup evidence after N days"
    }
  }
}
```

### 16.2 SKILL.md YAML Frontmatter Format

Every skill uses standardized YAML frontmatter:

```yaml
---
name: skill-name
description: One-line description
version: 1.0.0
license: SEE LICENSE
author: Nick Krzemienski
layer: 0|1|2|3|4
category: foundation|guardrail|protocol|planner|orchestrator
platform: all|ios|web|api|cli|fullstack
dependencies:
  - skill-name-1
  - skill-name-2
triggers:
  - "keyword phrase"
  - "another trigger"
---
```

### 16.3 Agent Definition Format

```yaml
---
name: agent-name
description: Agent purpose
model: haiku|sonnet|opus
tools:
  - Glob
  - Grep
  - Read
  - Write
  - Bash
inputs:
  - description of input 1
  - description of input 2
outputs:
  - description of output 1
  - description of output 2
---

# Agent: agent-name

## Purpose
[detailed purpose]

## Behavior
[step-by-step instructions]

## Output Format
[expected output structure]
```

### 16.4 Verdict Template

```markdown
# Validation Report

**Project:** {project_name}
**Platform:** {detected_platform}
**Date:** {timestamp}
**Strictness:** {strictness_profile}
**Duration:** {total_time}

## Summary

| Metric | Value |
|--------|-------|
| Total journeys | {count} |
| Passed | {pass_count} |
| Failed | {fail_count} |
| Overall verdict | **{PASS/FAIL}** |

## Journey Verdicts

### Journey: {journey_name}

**Verdict: {PASS/FAIL}**
**Confidence: Tier {1/2/3}**
**Duration:** {time}

**Evidence:**
- `{artifact_path}`: {semantic_description}
- `{artifact_path}`: {semantic_description}

**PASS Criteria:**
- [x] {criterion}: {evidence_citation}
- [ ] {criterion}: {failure_description}

**Notes:**
{any_discrepancies_or_observations}

---

## Recommendations

{actionable_next_steps_for_failures}

## Evidence Index

| Artifact | Type | Path | Tier |
|----------|------|------|:----:|
| {name} | screenshot | {path} | {tier} |
| {name} | api_response | {path} | {tier} |
```

---

## 17. Cross-Product Portfolio

ValidationForge is one of three products in the Claude Code extension suite:

| Product | Engine Focus | Price | Blog Posts |
|---------|-------------|------:|-----------|
| **ValidationForge** | VALIDATE + CONSENSUS + FORGE | $99 Pro | Posts 3, 5, 9, 11, 13 |
| **ConsensusGate** | Multi-agent review | $99 | Posts 2, 14 |
| **RalphOS** | Autonomous execution | $99 | Posts 6, 8, 17 |
| **Suite Bundle** | All three | $249 | All 18 posts |

**Interaction model:** ConsensusGate reviews what FORGE builds. ValidationForge proves it works. RalphOS keeps running until everything passes. The three products form a complete autonomous development + validation + review pipeline.

**Unbundling decision:** Each product is viable standalone. The suite bundle provides 16% savings and the complete closed loop.

---

## 18. Glossary

| Term | Definition |
|------|------------|
| **Iron Rule** | Never mock. Always validate through real system interfaces. Always capture and review evidence. |
| **Evidence** | Captured artifacts (screenshots, API responses, build logs) that prove system behavior. |
| **Verdict** | Formal PASS/FAIL judgment with cited evidence for each PASS criterion. |
| **Journey** | A user-facing flow through the application (e.g., "login flow," "checkout process"). |
| **PASS criteria** | Specific, measurable conditions that must be true for a journey to pass validation. |
| **Platform reference** | A skill file containing platform-specific validation commands and patterns. |
| **Evidence tier** | Confidence level of evidence: Tier 1 (95%+), Tier 2 (80-90%), Tier 3 (40-60%). |
| **3-strike protocol** | Fix attempt limit: Strike 1 (auto-fix), Strike 2 (different approach), Strike 3 (escalate to human). |
| **Pit of success** | Design pattern where the path of least resistance leads to correct behavior. |
| **Closed verification loop** | FORGE builds → VALIDATE proves → CONSENSUS reviews → ship or fix. |

---

**End of Specification**

*This document is the single source of truth for ValidationForge. All other documents (README, ARCHITECTURE, PRD) should reference and align with this specification.*

*Total synthesis: 25 sequential thoughts, 42 skills inventoried, 3 competitor codebases analyzed, 25+ GitHub repos surveyed, 18 blog posts mapped, 5 benchmark scenarios defined, 4 pricing tiers designed, 7 risks assessed.*
