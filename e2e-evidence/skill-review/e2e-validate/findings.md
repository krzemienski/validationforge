# Skill Deep-Review: `e2e-validate`

**Reviewer:** auto-claude (phase-1-subtask-5)
**Date:** 2026-04-17
**Scope:** `./skills/e2e-validate/SKILL.md` + 8 workflows + 6 platform references
**Reference docs:** `./CLAUDE.md`, cross-referenced platform skills (`./skills/{ios,web,api,cli,fullstack}-validation/SKILL.md`)

## Summary

`e2e-validate` is the orchestrator entry point for ValidationForge. It routes to 8 workflow files based on command flags and cites 6 platform references. All structural cross-links resolve: every file named in SKILL.md physically exists, and every Related Skill listed resolves to an existing skill directory. `scripts/detect-platform.sh` (cited at SKILL.md line 40) exists and is executable.

However, the orchestrator has **one CRITICAL discrepancy with CLAUDE.md and the Iron Rules**, plus several HIGH-severity pipeline drift issues and multiple MEDIUM naming/documentation inconsistencies. The practical upshot: an agent following `e2e-validate` literally will skip the preflight gate that Iron Rule #4 forbids skipping, and will implement a 6-phase pipeline that does not map to CLAUDE.md's advertised 7-phase pipeline.

**Totals:** 1 CRITICAL, 3 HIGH, 6 MEDIUM, 5 LOW = 15 findings.

---

## Inventory Verification

### Files cited vs. files present

| Cited in SKILL.md | Exists? |
|---|---|
| `scripts/detect-platform.sh` | ✓ (executable, 1613 bytes) |
| `workflows/analyze.md` | ✓ (3045 bytes) |
| `workflows/plan.md` | ✓ (3372 bytes) |
| `workflows/execute.md` | ✓ (5953 bytes) |
| `workflows/fix-and-revalidate.md` | ✓ (5290 bytes) |
| `workflows/audit.md` | ✓ (3800 bytes) |
| `workflows/report.md` | ✓ (2708 bytes) |
| `workflows/full-run.md` | ✓ (5554 bytes) |
| `workflows/ci-mode.md` | ✓ (5036 bytes) |
| `references/ios-validation.md` | ✓ (5414 bytes) |
| `references/web-validation.md` | ✓ (6085 bytes) |
| `references/api-validation.md` | ✓ (6502 bytes) |
| `references/cli-validation.md` | ✓ (6177 bytes) |
| `references/fullstack-validation.md` | ✓ (7256 bytes) |
| `references/generic-validation.md` | ✓ (5090 bytes) |

### Related Skills cross-references

All 10 Related Skills in SKILL.md lines 114–127 resolve to existing directories under `./skills/`:
`functional-validation`, `gate-validation-discipline`, `no-mocking-validation-gates`, `create-validation-plan`, `verification-before-completion`, `full-functional-audit`, `preflight`, `baseline-quality-assessment`, `condition-based-waiting`, `error-recovery`. ✓

---

## Findings by Severity

### CRITICAL

#### F1 — Orchestrator never invokes the `preflight` skill, violating Iron Rule #4

- **Files:** `./skills/e2e-validate/workflows/full-run.md` lines 8–37 (pipeline diagram), `./skills/e2e-validate/workflows/ci-mode.md` lines 42–51 (phase list)
- **Contradicts:** `./CLAUDE.md` line 33 (7-phase pipeline lists PREFLIGHT as phase 2) and line 77 (Iron Rule #4: "NEVER skip preflight — if it fails, STOP.")
- **Observed:** `full-run.md` declares the pipeline as ANALYZE → PLAN → APPROVE → EXECUTE → FIX (if `--fix`) → REPORT. `ci-mode.md` restates the same 5-step sequence (Analyze → Plan → Execute → Fix → Report). The word "preflight" does not appear in any of the 8 workflow files. SKILL.md lists `preflight` only as a "Related Skill" (SKILL.md line 124) with the note "Environment checks before execution" — but no workflow ever calls it.
- **Impact:** Any agent running `/validate` (the default entry) will attempt to build-and-execute without first running the preflight gate mandated by the project's Iron Rules. The user-facing `/vf-setup` hook system cannot compensate because workflows are the authoritative step list.
- **Recommendation:** Insert a `PREFLIGHT` phase into `full-run.md` between Phase 2 (Plan) and Phase 4 (Execute), and into `ci-mode.md` Step 2's phase list. The phase should delegate to the `preflight` skill and halt on failure. Update SKILL.md's Command Routing table to add `--preflight` or make preflight an implicit gate.

### HIGH

#### F2 — Orchestrator's 6-phase pipeline does not implement CLAUDE.md's canonical 7-phase pipeline

- **Files:** `./skills/e2e-validate/workflows/full-run.md` lines 8–16 (ASCII diagram), `./skills/e2e-validate/SKILL.md` lines 44–54 (Command Routing)
- **Contradicts:** `./CLAUDE.md` lines 28–38 (canonical 7-phase pipeline: RESEARCH → PLAN → PREFLIGHT → EXECUTE → ANALYZE → VERDICT → SHIP)
- **Observed:** The orchestrator defines its own 6-phase pipeline (ANALYZE → PLAN → APPROVE → EXECUTE → FIX? → REPORT). Only PLAN and EXECUTE map cleanly to CLAUDE.md. RESEARCH (phase 0), PREFLIGHT (phase 2), ANALYZE-as-root-cause (phase 4), VERDICT (phase 5), and SHIP (phase 6) are entirely missing or conflated. The orchestrator's "REPORT" is not a direct synonym for CLAUDE.md's "VERDICT" — verdicts are written inside `execute.md` Step 4 (line 105–118), and the report workflow merely aggregates them.
- **Impact:** Users reading CLAUDE.md will expect a 7-phase pipeline; the orchestrator delivers a 6-phase pipeline with different semantics. This makes the `/validate` command inconsistent with the project's own documentation and breaks mental models.
- **Recommendation:** Either (a) update `full-run.md` and `ci-mode.md` to implement all 7 CLAUDE.md phases with distinct workflows, or (b) update CLAUDE.md's "7-Phase Pipeline" section to match the implemented 6-phase reality. Option (a) is preferred because CLAUDE.md is the contract.

#### F3 — Semantic collision on "ANALYZE" — same name, two different meanings

- **Files:** `./skills/e2e-validate/workflows/analyze.md` (all 88 lines), `./skills/e2e-validate/workflows/fix-and-revalidate.md` lines 77–91 (Strike 3)
- **Contradicts:** `./CLAUDE.md` line 35 ("4. ANALYZE → Root cause investigation for FAILs (sequential thinking)")
- **Observed:** The orchestrator uses "ANALYZE" for platform detection and journey discovery (analyze.md line 1: "Scan the codebase, detect the project platform, and produce a complete inventory of user journeys"). But CLAUDE.md's phase 4 "ANALYZE" is root-cause investigation of FAILs. The orchestrator's root-cause analysis is buried inside `fix-and-revalidate.md` Strike 3 ("Broader Investigation") — it is neither named ANALYZE nor a distinct phase.
- **Impact:** The name "analyze" points at incompatible concepts depending on which doc a user is reading. An LLM agent composing a plan based on CLAUDE.md's phase list and then invoking `--analyze` will run discovery instead of root-cause analysis.
- **Recommendation:** Rename `workflows/analyze.md` → `workflows/discover.md` (and `--analyze` → `--discover`), freeing "ANALYZE" to mean root-cause-investigation as in CLAUDE.md. Alternatively, document the collision prominently in SKILL.md.

#### F4 — Missing RESEARCH and SHIP phases from canonical pipeline

- **Files:** `./skills/e2e-validate/` (all workflows)
- **Contradicts:** `./CLAUDE.md` line 31 (RESEARCH: Standards, best practices, applicable criteria), line 37 (SHIP: Production readiness audit, deploy decision)
- **Observed:** No workflow file covers RESEARCH (gathering applicable standards) or SHIP (go/no-go for production). SKILL.md's Related Skills table omits both `research-validation` and `production-readiness-audit`, even though both exist under `./skills/` (and are listed in CLAUDE.md's skill inventory).
- **Impact:** An agent running `/validate` never consults `research-validation` to pick applicable standards, and never produces a SHIP decision. Production readiness is undefined in e2e-validate's output.
- **Recommendation:** Either add `research-validation` and `production-readiness-audit` to the Related Skills table and create workflows that invoke them, or document why these phases are intentionally out of scope.

### MEDIUM

#### F5 — Evidence file naming is inconsistent across 3 conventions

- **Files:** all e2e-validate references (use `j{N}-{slug}.{ext}`), `./skills/ios-validation/SKILL.md` (uses `ios-XX-name.png`), `./skills/web-validation/SKILL.md` (uses `web-XX-name.png`, `web-responsive-mobile.png`), `./skills/api-validation/SKILL.md` (uses `api-create-RESOURCE.json`), `./CLAUDE.md` lines 54–61 (recommends `{journey-slug}/step-01-{description}.png`)
- **Observed (examples):**
  - `e2e-validate/references/ios-validation.md` line 76: `xcrun simctl io booted screenshot e2e-evidence/j1-home-screen.png`
  - `ios-validation/SKILL.md` line 77: `xcrun simctl io booted screenshot e2e-evidence/ios-01-launch-screen.png`
  - `e2e-validate/references/web-validation.md` line 66: `filename="e2e-evidence/j1-homepage.png"`
  - `web-validation/SKILL.md` line 64: `filename="e2e-evidence/web-01-homepage.png"`
  - `CLAUDE.md` line 57: `step-01-{description}.png` nested under `{journey-slug}/`
- **Impact:** Three different conventions are live in the same repo. An agent running the orchestrator writes to `j{N}-*.png`; an agent running `ios-validation` directly writes to `ios-01-*.png`; and CLAUDE.md's Evidence Rules suggest yet a third nested structure. Report generation and evidence indexing cannot reliably locate files.
- **Recommendation:** Pick one canonical naming convention and update all three locations. The nested `{journey-slug}/step-NN-*.{ext}` pattern from CLAUDE.md is the most scalable.

#### F6 — SKILL.md description omits "generic" platform

- **File:** `./skills/e2e-validate/SKILL.md` line 6
- **Observed:** Description reads: `"Supports iOS, web, API, CLI, and fullstack projects."` — but the Platform Detection table (line 38) and references directory both include `generic` as priority-6 fallback (`references/generic-validation.md`, 5090 bytes).
- **Impact:** Users reading only the YAML description underestimate coverage.
- **Recommendation:** Change to `"Supports iOS, web, API, CLI, fullstack, and generic (fallback) projects."`.

#### F7 — Platform Detection table under-documents signals used by `detect-platform.sh`

- **Files:** `./skills/e2e-validate/SKILL.md` lines 32–38 (detection table), `./scripts/detect-platform.sh`
- **Observed:** `SKILL.md` row 2 (cli) lists signals `Cargo.toml [[bin]]`, `go.mod + main.go`, `package.json "bin"`. The actual `detect-platform.sh` script also detects:
  - `pyproject.toml` with `[project.scripts]` (Python CLI)
  - `cmd/` directory for Go CLI (not only `main.go`)
  - `argparse` / `click` imports for Python CLI
- **Impact:** Users comparing the table against detection behavior see inconsistencies. Python CLI projects may read SKILL.md and assume they're classified as "generic" when in fact the script classifies them as "cli."
- **Recommendation:** Update the SKILL.md detection table to mirror the script's actual signal list, or delete the inline table and reference the script as the single source of truth.

#### F8 — Relationship between `--fix` flag and `/validate-fix` command is undocumented

- **Files:** `./skills/e2e-validate/SKILL.md` lines 46–52 (Command Routing), `./CLAUDE.md` line 21 (`/validate-fix` command)
- **Observed:** SKILL.md's Command Routing table lists `--fix` as a flag routing to `workflows/fix-and-revalidate.md`. CLAUDE.md lists `/validate-fix` as a separate top-level command. Neither doc explains whether they are the same thing, nor which is the preferred invocation.
- **Impact:** Ambiguity in user-facing surface area. Users don't know if `/validate --fix` and `/validate-fix` do the same thing.
- **Recommendation:** Add a one-line note to SKILL.md explaining that `/validate-fix` is shorthand for `/validate --fix`, or that they have different defaults, whichever is accurate.

#### F9 — `audit.md` Step 3 implicit system-start behavior is ambiguous

- **File:** `./skills/e2e-validate/workflows/audit.md` lines 36–45
- **Observed:** Step 3 says "Run through each journey following `workflows/execute.md` steps" — which includes Step 1 (Build) and Step 2 (Start the Real System) as modifying steps. The "Key Constraint: NO CODE CHANGES" (lines 10–24) allows building and starting, but never states: does audit ALSO build-and-start, or does it assume the system is already running?
- **Impact:** An agent in audit mode may either (a) fail because the system isn't running, or (b) violate the read-only constraint by performing a build step if it assumes the caller hadn't already built.
- **Recommendation:** Add a sentence to Step 3 clarifying: "If the system is not already running, perform `execute.md` Steps 1–2 to build and start it (this is considered part of the read-only audit setup, not a code change)."

#### F10 — `execute.md` Step 3d lacks explicit tool names

- **File:** `./skills/e2e-validate/workflows/execute.md` lines 77–90
- **Observed:** Step 3d says "Open the file — Read the screenshot, response body, or output." It does not name the Read tool, Glob, or vision input. For screenshots specifically, the orchestrator never says "use the multimodal Read tool to view PNG content."
- **Impact:** LLM agents may save screenshots but never actually read them (silently "just checking they exist" — exactly what CLAUDE.md line 22–23 prohibits: "Evidence you don't READ is evidence you don't HAVE").
- **Recommendation:** Rewrite Step 3d to explicitly name the Read tool for text evidence and the Read tool (multimodal) for image evidence. Provide concrete tool-call examples.

### LOW

#### F11 — `e2e-testing` skill missing from Related Skills table

- **File:** `./skills/e2e-validate/SKILL.md` lines 114–127
- **Observed:** The "Related Skills" table omits `e2e-testing`, which CLAUDE.md's Specialized (6) group lists alongside `e2e-validate` (line 147). `e2e-testing` may be a logical peer skill worth cross-referencing.
- **Recommendation:** Add `e2e-testing` if it complements the orchestrator; otherwise note explicitly why it's excluded.

#### F12 — Hardcoded iPhone 16 simulator model in 3 places

- **Files:** `./skills/e2e-validate/workflows/execute.md` line 19, `./skills/e2e-validate/references/ios-validation.md` lines 13/20, `./skills/ios-validation/SKILL.md` lines 24/33/77
- **Observed:** All three locations hardcode `"iPhone 16"` as the simulator destination. No fallback path if iPhone 16 isn't installed on the machine.
- **Recommendation:** Show how to select any available simulator (`xcrun simctl list devices available | head -1`) before hardcoding a specific model.

#### F13 — `browser_network_requests includeStatic=false` not explained

- **Files:** `./skills/e2e-validate/workflows/execute.md` line 69, `./skills/e2e-validate/references/web-validation.md` lines 44, 95
- **Observed:** The `includeStatic=false` flag is used repeatedly but never explained (it filters out static asset requests to focus on API traffic). Agents unfamiliar with Playwright MCP may not know whether `false` or `true` is correct.
- **Recommendation:** Add a one-line note: `# includeStatic=false filters out image/CSS/JS requests to focus on API calls`.

#### F14 — `PORT` literal placeholder may be taken literally

- **Files:** `./skills/e2e-validate/references/api-validation.md` (many lines with `http://localhost:PORT/...`), `./skills/api-validation/SKILL.md` (same pattern)
- **Observed:** Most API references use `PORT` as an uppercased placeholder. Naive agents may issue requests to literal `localhost:PORT`, which obviously fails.
- **Recommendation:** Use `${PORT}` or `<port>` (lowercase placeholder) consistently and add a setup step defining `PORT=3000` or equivalent, as the web reference does on line 27.

#### F15 — SKILL.md "Validation Order" section duplicates fullstack reference guidance

- **File:** `./skills/e2e-validate/SKILL.md` lines 59–61
- **Observed:** The Validation Order section ("Data Layer → Backend API → Frontend Logic → UI/CLI") duplicates content in `references/fullstack-validation.md` (lines 9–15, the bottom-up principle) without cross-referencing it.
- **Recommendation:** Replace the inline paragraph with `See references/fullstack-validation.md` to avoid drift if the principle is updated in one place but not the other.

---

## Cross-Check Matrix: reference vs. platform skill

| Platform | Reference file | Platform skill | Content alignment |
|---|---|---|---|
| iOS | `references/ios-validation.md` | `skills/ios-validation/SKILL.md` | Build cmds identical; screenshot naming conflicts (F5); simctl/idb coverage matches; iPhone 16 hardcode consistent. |
| Web | `references/web-validation.md` | `skills/web-validation/SKILL.md` | Playwright + Chrome DevTools MCP tool names match; 4-viewport table matches; screenshot naming conflicts (F5). |
| API | `references/api-validation.md` | `skills/api-validation/SKILL.md` | curl/jq patterns match; CRUD + auth + error + pagination coverage matches; evidence file naming differs (j{N}-*.json vs api-*.json). |
| CLI | `references/cli-validation.md` | `skills/cli-validation/SKILL.md` | Build commands match (cargo/go/npm/pip); exit code tables match; stdin/pipe + error patterns match. No semantic contradictions beyond naming (F5). |
| Fullstack | `references/fullstack-validation.md` | `skills/fullstack-validation/SKILL.md` | Bottom-up principle identical; DB driver coverage matches (psql/mysql/sqlite/mongo); integration test steps match. |
| Generic | `references/generic-validation.md` | (none — no standalone `generic-validation/SKILL.md` under `./skills/`) | Standalone. No conflict possible. Note: could be a LOW finding if consistency demands a standalone generic skill. |

---

## What Passes the Review

- File structure is complete: every cited workflow and reference file physically exists with non-trivial content.
- Platform references cover the six declared platforms and are semantically consistent with their platform-skill counterparts (except for the naming issue F5).
- Command Routing table's 8 flags all map to existing workflows.
- Iron Rule (SKILL.md lines 17–23) is explicit, verbose, and matches CLAUDE.md's "Iron Rules" section.
- `detect-platform.sh` exists, is executable, and its priority ordering (ios > cli > (web+api→fullstack) > api > web > generic) matches SKILL.md's declared priority table.
- Success Criteria (SKILL.md lines 87–99) are specific, observable, and binary — matching the quality standard they impose on journeys.

---

## Recommended Remediation Order

1. **F1 (CRITICAL)** — Insert PREFLIGHT phase into `full-run.md` and `ci-mode.md`. This is an Iron-Rule violation.
2. **F2, F4 (HIGH)** — Reconcile the pipeline phase list with CLAUDE.md. Either extend the orchestrator to 7 phases or amend CLAUDE.md to the implemented 6.
3. **F3 (HIGH)** — Rename "analyze" → "discover" to free ANALYZE for root-cause.
4. **F5 (MEDIUM)** — Consolidate evidence file naming under one convention across CLAUDE.md, e2e-validate references, and platform skills.
5. **F6, F7, F8 (MEDIUM)** — Documentation touch-ups in SKILL.md.
6. **F9, F10 (MEDIUM)** — Workflow clarifications for audit-mode and evidence-reading.
7. **F11–F15 (LOW)** — Housekeeping.
