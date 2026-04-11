---
title: Skill Optimization Remediation
status: complete
created: 2026-04-11
mode: deep
blockedBy: []
blocks: [260411-2242-vf-gap-closure]
note: VERIFICATION.md shows all phases complete (5.0/5.0). Status flip to `complete` is Phase 0 of plan 260411-2242-vf-gap-closure.
---

# Skill Optimization Remediation

## Context

On 2026-04-11 a batch skill-description optimization pass was executed against all 48 VF skills. A subsequent deep reflection (reflexion:reflect) found the pass shipped with multiple defects. This plan remediates those defects and installs safeguards so the same mistakes don't recur.

**Plan scope:** `/Users/nick/Desktop/validationforge/skills/` — 48 VF skills (project-local, NOT user `~/.claude/skills`).

**Out of scope:** Re-running `run_loop.py` empirical trigger-rate testing (runtime incompatibility known). Touching user-level skills.

## What Went Wrong (from reflection)

Scored 2.30/5.0 — "Low, significant improvements needed."

| # | Defect | Severity | Status |
|---|--------|---------|--------|
| D1 | `coordinated-validation` missing `context_priority` — the exact skill that originally crashed `validate-skills.sh` | CRITICAL | FIXED in-session |
| D2 | `forge-benchmark` description propagated wrong dimension weights (Coverage 30%/Detection 25%/…) that don't match `scripts/benchmark/score-project.sh` (Coverage 35%/Evidence 30%/Enforcement 25%/Speed 10%) | HIGH | FIXED in-session |
| D3 | 4 descriptions exceed 300-char limit: `stitch-integration` (305), `verification-before-completion` (307), `visual-inspection` (337), `web-testing` (309) | LOW | PENDING |
| D4 | `forge-benchmark` SKILL.md **body** still lists 5 wrong dimensions (Coverage/Detection/Evidence Quality/Speed/Cost with wrong weights). Description now contradicts body. | HIGH | PENDING |
| D5 | +66% context bloat on always-loaded metadata layer (7 536 → 12 542 chars, +5 006 chars). No empirical evidence it improves triggering. | MEDIUM | PENDING |
| D6 | 22 skills silently converted from YAML block-scalar (`description: >`) to quoted single-line — style churn without justification. | LOW | PENDING (accept as trade-off) |
| D7 | Final summary fabricated statistics ("~41 context_priority added" → actual 0; "~20 triggers added" → actual 15). Broken parser output propagated into user-facing claims. | MEDIUM (trust) | Acknowledged in reflection |
| D8 | Subagent outputs (6 batches × 8 skills = 48 proposals) applied without spot-checking. One subagent returned `missing_context_priority: null` for coordinated-validation even though the key was missing. | HIGH (process) | PENDING (install verification step) |

## Root Cause Analysis

The surface-level problem is "bad descriptions." The deeper problems are process failures:

1. **Trusted outputs I didn't verify.** I batched 48 proposals across 6 subagents and applied all of them without reading a single file before or after. The one skill that could have blocked `validate-skills.sh` from running (`coordinated-validation`) was the one skill whose subagent missed the context_priority gap.
2. **Parser broken, numbers fabricated.** My `get_skill_info` Python parser couldn't handle `context_priority:` appearing after the `triggers:` block. It reported 41 skills missing the field. I used those numbers in the final summary without ever running `git diff` to check. Lesson: **claimed statistics must come from git, not memory or helper scripts.**
3. **No diff review before apply.** I wrote `apply.py`, ran it once on 48 files, and reported success. I didn't preview a single diff. The YAML block-scalar conversion happened because `apply.py` always writes `description: "…"` regardless of original style.
4. **Metadata is always-loaded; I treated it as free space.** The skill-creator guidance says metadata is always in context. I inflated descriptions by 66% without any empirical signal that it was justified. The token cost is paid on every prompt in every session.
5. **Body-description contradiction not checked.** My subagents were told to read `SKILL.md` and rewrite the description. None were told to cross-check that the improved description didn't contradict the body. `forge-benchmark` shows this failure: description now says "4 dimensions with X weights", body still says "5 dimensions with Y weights". A Claude instance reading the skill will see two sources of truth.

## Success Criteria

All must be verified with actual commands, not memory:

- [ ] `coordinated-validation/SKILL.md` has `context_priority: standard` in frontmatter (`grep context_priority`)
- [ ] `bash scripts/benchmark/validate-skills.sh` exits 0 and reports 48/48 pass
- [ ] `forge-benchmark` description AND body both reference "4 dimensions: Coverage 35%, Evidence Quality 30%, Enforcement 25%, Speed 10%" matching `score-project.sh`
- [ ] Every description ≤ 300 chars (verified by YAML parser on all 48)
- [ ] No description contradicts its own SKILL.md body on any quantitative claim (weights, phase counts, step counts) — spot-checked on 10 skills with numeric claims
- [ ] Description-total character count reduced by ≥30% from post-optimization peak (12 542) toward a budget around 9 000 (150-200 chars avg × 48)
- [ ] `git diff` summary in the final report cites exact counts; no "~" estimates
- [ ] `test-hooks.sh` 18/18 pass, `validate-cmds.sh` 17/17 pass, `score-project.sh` aggregate ≥ 88
- [ ] All 4 over-length descriptions trimmed to ≤ 300 chars without losing trigger coverage
- [ ] `forge-benchmark` body "## Dimensions" table updated to 4 dimensions matching implementation
- [ ] New file `.vf/skill-optimization/VERIFICATION.md` contains evidence for each criterion above, with the command run and its output

## Phases

### Phase 1 — Body-Description Consistency Audit (read-only)
**Goal:** Find every skill where the improved description makes a quantitative claim (count, weight, percentage, phase name) that isn't supported by the SKILL.md body.

**Why first:** Fixing over-length descriptions (Phase 2) could make this worse if we don't know where the contradictions are. Audit before trim.

**Steps:**
1. Extract every description with a numeric claim (`[0-9]+\s*(%|-stage|-phase|-step|-layer|-dimension|-viewport)` and similar)
2. For each, grep the SKILL.md body for the same number
3. Flag mismatches → `audit.md`

**Exit:** `audit.md` exists with one section per skill that has a quantitative claim, marked PASS/FAIL/UNVERIFIED.

### Phase 2 — Trim Over-Length Descriptions (D3)
**Goal:** Bring 4 descriptions at 305-337 chars down to ≤ 300 chars without losing triggering keywords.

**Affected skills:** `stitch-integration`, `verification-before-completion`, `visual-inspection`, `web-testing`

**Method:** Edit tool, one skill at a time. Show diff. Measure length after each edit.

**Exit:** Python YAML parser confirms all 48 descriptions ≤ 300 chars.

### Phase 3 — Fix forge-benchmark Body (D4)
**Goal:** Replace the wrong 5-dimension "## Dimensions" table in `forge-benchmark/SKILL.md` with the actual 4-dimension implementation from `score-project.sh`. Remove the orphaned Detection/Cost subsections.

**Steps:**
1. Read `score-project.sh` lines 15-200 to confirm exact weights and metric sources
2. Replace the dimensions table in SKILL.md
3. Remove `### Detection Metrics` and `### Cost Metrics` subsections
4. Update `### Coverage Metrics` formula to match `score-project.sh` actual formula
5. Verify body + description are consistent

**Exit:** `diff skills/forge-benchmark/SKILL.md <(cat)` output + grep shows no references to "5 dimensions", "Detection", or "Cost" weights in the body. A Claude reader would get one consistent story.

### Phase 4 — Context Bloat Trim (D5)
**Goal:** Reduce the total description char count from 12 542 back toward ~9 000 (~30% reduction) by trimming the bloated descriptions that don't justify their weight.

**Strategy:** Not mechanical. For each skill, ask: does the description add triggering value proportional to its char cost?
- Keep: concise descriptions that name tools and triggering contexts
- Trim: descriptions with marketing prose ("Use this even when slowness tempts shortcuts", "The IRON RULE", emphatic caps)
- Trim: redundant restating of the skill name (if skill is `accessibility-audit`, don't say "accessibility audit" three times)

**Rule:** No description exceeds 200 chars unless justified by naming ≥4 distinct trigger contexts. Enforced by parser.

**Exit:** Total description char count ≤ 9 500. Average ≤ 200 chars/skill. All 48 still have triggers that cover the original intent (spot-checked on a random sample of 10).

### Phase 5 — Spot-Check Verification Against Body (D8, regression prevention)
**Goal:** For every skill, read the first 30 lines of body and confirm the description is a faithful summary. Any mismatch → flag, don't auto-fix.

**Why:** D8 root cause was trusting subagents. This phase is the verification pass I should have done the first time.

**Steps:**
1. Spawn 3 parallel explore agents, each handling 16 skills, reading SKILL.md and producing a CONSISTENT/INCONSISTENT verdict with evidence quote
2. Collect results into `spot-check.md`
3. For INCONSISTENT skills, I read both and decide fix

**Exit:** `spot-check.md` with 48 verdicts. INCONSISTENT count ≤ 3 (or each manually justified).

### Phase 6 — Final Verification and Report (D7, trust restoration)
**Goal:** Produce `VERIFICATION.md` with evidence for every success criterion. No "~", no estimates, no memory-based claims. Every number comes from a command.

**Steps:**
1. For each success criterion, run the verification command
2. Capture exact stdout → `VERIFICATION.md`
3. Compute git diff statistics from `git diff --shortstat skills/` at start vs. end of this plan
4. Run `test-hooks.sh`, `validate-cmds.sh`, `validate-skills.sh`, `score-project.sh`
5. Update `.vf/skill-optimization/report.md` final summary with real numbers

**Exit:** `VERIFICATION.md` exists. All success criterion checkboxes verified. Final report has no fabricated numbers.

## Risks

| Risk | Mitigation |
|------|-----------|
| Trimming bloat (Phase 4) accidentally removes triggering keywords and tanks future triggering accuracy | Spot-check 10 random skills — each still has tool names, WHEN phrases, and adjacent keywords |
| Phase 3 reveals the `forge-benchmark` body has MORE drift than described (e.g., Coverage Metrics formula is also wrong) | Read `score-project.sh` in full first; expand scope of Phase 3 if needed |
| Phase 5 finds >10 inconsistencies, blowing scope | Cap at 10; remainder documented as TECHNICAL-DEBT |
| Running `score-project.sh` after changes produces score < 88 (regression) | Phase 6 compares against baseline; any drop investigated before committing |

## Non-Goals

- **Re-run `run_loop.py`.** Runtime incompatibility is known. Adding empirical trigger-rate testing is a separate, larger project (would need `claude-code` CLI fixture or equivalent).
- **Touch user-level skills.** Scope is strictly `/Users/nick/Desktop/validationforge/skills/`.
- **Rewrite the batch-optimizer script.** `.vf/skill-optimization/apply.py` can stay; it's a record of what happened. Future batches should use a different approach.
- **Fix all ecosystem validators.** `validate-skills.sh` pipefail bug is still latent (now masked because every skill has `context_priority`); scoped out.

## Files

```
plans/260411-1731-skill-optimization-remediation/
├── plan.md                        # This file
├── audit.md                       # Phase 1 output
├── spot-check.md                  # Phase 5 output
└── VERIFICATION.md                # Phase 6 output
```

Modifications will be in:
- `skills/forge-benchmark/SKILL.md` (Phases 3)
- `skills/stitch-integration/SKILL.md` (Phase 2)
- `skills/verification-before-completion/SKILL.md` (Phase 2)
- `skills/visual-inspection/SKILL.md` (Phase 2)
- `skills/web-testing/SKILL.md` (Phase 2)
- Up to ~30 other `skills/*/SKILL.md` (Phase 4 bloat trim)
- `.vf/skill-optimization/report.md` (Phase 6)

## Rules I'm Binding Myself To

These are the lessons from the reflection, encoded as enforcement:

1. **Every numeric claim in any report comes from a `git diff` or `grep -c` or YAML parser, run NOW, not from memory or parser output I wrote myself.**
2. **Never batch-apply subagent output without reading at least 1 in 8 results against the actual file.**
3. **Never extend a description past 200 chars without a justification recorded in the phase doc.**
4. **Never change YAML style (block-scalar ↔ quoted) silently. If I need to, it's a separate commit with a rationale.**
5. **If the description makes a quantitative claim (weight, count, percentage), grep the body for the same number BEFORE writing.**
6. **The word "optimized" in a completion report requires a measured baseline to optimize against. Without one, say "changed" not "optimized".**
