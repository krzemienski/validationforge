---
phase: P03
name: Inventory sync (CLAUDE.md vs disk)
date: 2026-04-16
status: pending
gap_ids: [INV-1, INV-2, INV-3]
executor: fullstack-developer
validator: code-reviewer
depends_on: [P02]
---

# Phase 03 — Inventory Sync

## Why

CLAUDE.md claims counts that disagree with disk:
- Skills: 46 claimed vs 48 actual (`coordinated-validation` + 1 other hidden)
- Commands: 16 claimed vs 17 actual (`vf-telemetry` not listed)
- Hooks: 7 registered (after Phase 02 this count may change)

Documentation drift undermines onboarding trust. Close the gap with authoritative
counts derived from disk.

Must run AFTER Phase 02 because the hook count depends on the orphan-hook decision.

## Pass criteria

1. CLAUDE.md Skills section count matches `ls -1 skills/ | wc -l` exactly.
2. CLAUDE.md Commands section count matches `ls -1 commands/*.md | wc -l` exactly.
3. CLAUDE.md Hooks section count matches hooks registered in `hooks/hooks.json`.
4. CLAUDE.md Agents count matches `ls -1 agents/*.md | wc -l` (expected 5).
5. CLAUDE.md Rules count matches `ls -1 rules/*.md | wc -l` (expected 8).
6. SKILLS.md Specialized section matches CLAUDE.md Specialized category exactly
   (both list same skills, same count).
7. COMMANDS.md matches CLAUDE.md Commands section.
8. `evidence/03-inventory/final-diff.txt` shows zero discrepancies between CLAUDE.md
   inventory and disk.

## Inputs

- `CLAUDE.md`
- `SKILLS.md`
- `COMMANDS.md`
- `skills/`, `commands/`, `hooks/`, `agents/`, `rules/` dirs
- `plans/reports/researcher-260416-1707-inventory-audit.md`
- Result of Phase 02 (final hooks.json)

## Steps

1. Dispatch executor.
2. Executor:
   - Capture actual counts per dir.
   - Diff CLAUDE.md inventory counts vs actuals.
   - Update CLAUDE.md inventory section:
     - Update "Skills (46)" → actual
     - Update "Commands (16)" → actual (add `vf-telemetry`)
     - Update "Hooks (7)" → actual post Phase 02
     - Add `coordinated-validation` to Specialized list
   - Update SKILLS.md counts / categories to match
   - Update COMMANDS.md to match
3. Run final diff: `diff <(grep -E "^- " CLAUDE.md | ...) <(ls skills/)` etc.
4. Commit with `docs: sync CLAUDE.md inventory to disk (Phase 03)`.
5. Dispatch validator.

## Evidence outputs

| File | Source |
|------|--------|
| `evidence/03-inventory/before-counts.txt` | pre-edit counts |
| `evidence/03-inventory/after-counts.txt` | post-edit counts |
| `evidence/03-inventory/claude-md-diff.patch` | `git diff CLAUDE.md` |
| `evidence/03-inventory/skills-md-diff.patch` | `git diff SKILLS.md` |
| `evidence/03-inventory/commands-md-diff.patch` | `git diff COMMANDS.md` |
| `evidence/03-inventory/final-diff.txt` | zero-discrepancy proof |

## Failure modes

- **SKILLS.md categorization conflicts with CLAUDE.md** → prefer SKILLS.md (newer);
  update CLAUDE.md to match.
- **Coordinated-validation category** (Specialized vs Forge Orchestration) →
  per researcher Q2: leave in Specialized per SKILLS.md precedent, document as
  known note.

## Duration estimate

30–45 min.
