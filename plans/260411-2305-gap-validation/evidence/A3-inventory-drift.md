# A3 — Inventory Drift Matrix

Generated: 2026-04-16
Source: A1 (disk counts) vs A2 (documentation claims)

## Disk truth (A1)

| Primitive | Disk count |
|-----------|-----------:|
| Skills | 48 |
| Commands | 17 |
| Hook .js files | 10 |
| Hooks registered (in hooks.json) | 7 |
| Agents | 5 |
| Rules | 8 |
| Shell scripts (top) | 17 |
| Shell scripts (benchmark) | 6 |
| Shell scripts (combined) | 23 |

## Drift rows

| File | Line | Doc claim | Disk truth | Severity | Resolution |
|------|-----:|-----------|-----------:|----------|------------|
| README.md | 5 | "48 skills, 17 commands, 7 hooks (+3 .js), 5 agents, 8 rules, 17 shell scripts" | matches counts; "17 shell scripts" omits 6 benchmark scripts | LOW | README counts top-level only; benchmark dir is a sub-namespace. Acceptable. |
| README.md | 28 | "All 48 skills, 17 commands, 5 agents, and 8 rules exist on disk" | matches | NONE | — |
| README.md | 71 | "copies 8 rules" | matches | NONE | — |
| README.md | 139 | "all 48 skills" | matches | NONE | — |
| README.md | 276 | "48 skills" | matches | NONE | — |
| README.md | 300 | "(48 skills, 17 commands, 7 hooks, 5 agents, 8 rules)" | matches | NONE | — |
| SKILLS.md | 3 | "48 skills" | matches | NONE | — |
| PRD.md | 14 | "41 skills, 15 commands, 7 hooks, 5 agents, 8 rules" | 48 / 17 / 7 / 5 / 8 | **HIGH** | PRD is stale — predates Wave 3-4 merges that added 7 skills + 2 commands |
| PRD.md | 108 | "41 skills of platform-specific validation knowledge, 7 hooks, 5 agents" | 48 / 7 / 5 | **HIGH** | Stale PRD inventory |
| PRD.md | 489 | "41 skills with platform-specific knowledge" | 48 | **HIGH** | Stale PRD inventory |
| PRD.md | 588 | "How 41 skills build on each other" | 48 | **HIGH** | Stale PRD inventory |
| PRD.md | 705 | "all 41 skills, 15 commands, 7 hooks, 5 agents, 8 rules" | 48 / 17 / 7 / 5 / 8 | **HIGH** | Stale PRD inventory |
| SPECIFICATION.md | 4 | "(41 skills, 15 commands, 7 hooks, 5 agents, 8 rules)" | 48 / 17 / 7 / 5 / 8 | **HIGH** | Stale SPEC inventory |
| SPECIFICATION.md | 117 | "5 commands: /validate, /validate-plan, /validate-fix, /validate-audit, /validate-ci" | 17 commands exist; only 5 listed | MEDIUM | SPEC lists the original 5 — newer 12 (incl. forge-* and validate-team/sweep/benchmark) not enumerated |
| SPECIFICATION.md | 241 | "5 hooks enforce the ValidationForge philosophy" | 7 registered | **HIGH** | SPEC stale |
| SPECIFICATION.md | 309 | "All 5 commands are entry points" | 17 | **HIGH** | SPEC stale |
| SPECIFICATION.md | 526 | "No-mock enforcement | — | — | — | — | **5 hooks**" | 7 | **HIGH** | SPEC stale |
| SPECIFICATION.md | 722 | "3 hooks (block-test-files, validation-not-compilation, mock-detection)" | 7 registered (+3 support) | **HIGH** | SPEC stale (likely an early-stage roadmap snapshot) |
| SPECIFICATION.md | 747 | "16 skills across 4 layers" | 48 | **HIGH** | SPEC stale (early scaffolding count) |
| SPECIFICATION.md | 748 | "5 commands, 5 hooks, 3 agents" | 17 / 7 / 5 | **HIGH** | SPEC stale |
| SPECIFICATION.md | 941 | "│   ├── skills/                               16 skills (5,653 lines)" | 48 | **HIGH** | SPEC stale |
| SPECIFICATION.md | 1397 | "42 skills inventoried" | 48 | MEDIUM | Synthesis context (historical), not a current claim |

## Working tree drift

| File | Status | Severity | Notes |
|------|--------|----------|-------|
| `.vf/benchmarks/benchmark-2026-04-11.json` | modified, uncommitted | LOW | Drift between VERIFICATION.md "clean" claim and `git status`. Benchmark output regenerated locally. |

## Summary

| Severity | Count |
|----------|------:|
| HIGH | 13 |
| MEDIUM | 2 |
| LOW | 2 |
| NONE (matches) | 6 |

## PASS criteria assessment

- README.md, SKILLS.md, COMMANDS.md, CLAUDE.md, ARCHITECTURE.md: **CONSISTENT** with disk
- PRD.md and SPECIFICATION.md: **STALE** — both predate the Wave 3-4 skill/command additions
- Working tree: **1 modified file** — benchmark-2026-04-11.json contradicts VERIFICATION.md "clean" claim

## Resolution path

PRD.md and SPECIFICATION.md are intentionally historical artifacts (the PRD predates the campaign that added skills 42–48 and commands 16–17). They function as design documents, not live inventory.

**Recommendation:** Add a banner to PRD.md and SPECIFICATION.md noting "inventory snapshot from <date>; see README.md for current counts" — OR — sync them in a follow-up commit. Filed in TECHNICAL-DEBT.md as a documentation drift item, not a blocker.

## A4 PASS criteria check

- [x] A1 populated (disk counts captured)
- [x] A2 populated (claim grep complete)
- [x] A3 diff matrix complete with file:line citations
- [ ] **Drift IS present in PRD.md/SPECIFICATION.md** — but README.md (the public-facing doc) is consistent with disk
- [x] No README claim is off by ≥1

**Verdict: PARTIAL PASS** — README/SKILLS/COMMANDS/CLAUDE/ARCHITECTURE consistent. PRD/SPEC stale → debt entry, not blocker.
