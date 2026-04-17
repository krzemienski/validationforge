---
phase: P04
name: Platform detection on external repos
date: 2026-04-16
status: pending
gap_ids: [H4]
executor: researcher
validator: researcher
depends_on: [P01]
---

# Phase 04 — Platform Detection on External Repos

## Why

`agents/platform-detector.md` has been tested only against ValidationForge's own
demo directories. TECHNICAL-DEBT.md H4 flags that iOS, API, CLI, Fullstack have
never been verified against real external repos.

## Pass criteria

1. `agents/platform-detector` invoked against ≥ 5 external repo specimens:
   - At least one iOS (`.xcodeproj` or `.xcworkspace` present)
   - At least one Python API (Flask/Django/FastAPI)
   - At least one CLI (Rust `Cargo.toml` OR Go `go.mod` OR Python `[project.scripts]`)
   - At least one Fullstack (frontend + backend in same repo)
   - At least one ambiguous edge case (e.g., monorepo with many platforms)
2. For each specimen: evidence file `evidence/04-platform-detect/<specimen>.md`
   with repo name / source URL / HEAD SHA / expected classification / agent
   output (verbatim) / match verdict (TRUE / FALSE / PARTIAL).
3. Aggregate accuracy ≥ 4/5 = 80%. Below 80% → FAIL.
4. For every mismatch, root cause + proposed patch recorded in `mismatches.md`.
5. No modifications to `agents/platform-detector.md` unless accuracy < 80%.

## Inputs

- `agents/platform-detector.md`
- Existing external repos on disk (preferred) OR clone via `gh repo clone` into
  `/tmp/vf-platform-specimens/` (never commit specimens)

## Steps

1. Dispatch executor (researcher).
2. Executor selects 5+ specimens (prefer user's existing repos; else clone
   small public repos like `facebook/react-native-template`, `pallets/flask`,
   `BurntSushi/ripgrep`, `tauri-apps/tauri`).
3. For each specimen: invoke `agents/platform-detector` (via Agent tool or
   direct prompt). Capture classification.
4. Compare to expected classification.
5. Aggregate + write `summary.md`.
6. If accuracy < 80%: flag per-specimen errors, propose one-diff fix.
7. Dispatch validator (read-only researcher).

## Evidence outputs

| File | Source |
|------|--------|
| `evidence/04-platform-detect/specimens.md` | List of repos + URLs + SHA |
| `evidence/04-platform-detect/<specimen>.md` | Per-specimen run |
| `evidence/04-platform-detect/summary.md` | Aggregate accuracy table |
| `evidence/04-platform-detect/mismatches.md` | Only if mismatches present |

## Failure modes

- No iOS specimen available → document, skip that class, mark partial.
- Clone rate-limited → use existing demo dirs + document partial breadth.
- Platform-detector returns `generic` for everything → probable regression;
  escalate.

## Duration estimate

1.5–2.5 hours.
