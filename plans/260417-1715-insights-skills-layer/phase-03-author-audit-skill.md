# Phase 03 — Author `/audit` SKILL.md + visual-capture helper

## Context Links
- Plan: `plans/260417-1715-insights-skills-layer/plan.md`
- Authoritative skill authoring guide: `~/.claude/skills/skill-creator/SKILL.md`
- Platform-detection reference: `~/.claude/rules/vf-platform-detection.md`
- Plan A deliverables this skill depends on:
  - `~/.claude/rules/audit-workflow.md` (new in Plan A)
- ValidationForge skills this skill coordinates with (no ownership overlap): `playwright-validation`, `ios-validation`, `chrome-devtools`, `visual-inspection`

## Overview
- **Priority:** P1 — prevents the SessionForge-dashboard failure pattern where audits stalled on auth/workspace issues before any screenshot was taken.
- **Status:** pending (blocked by Plan A's `audit-workflow.md`)
- **Description:** Author a global skill at `~/.claude/skills/audit/` that enforces visual-first audit discipline. Step 1 is always: dump rendered frame / screenshot / OCR output and look at it. Only then does code-path investigation begin. Ships a platform-auto-detecting `scripts/capture-visuals.sh` wrapper so the model does not re-invent capture per platform.

## Key Insights (from discovery)
- The SessionForge incident: audit session spent hours on cross-workspace auth debugging before the dashboard was ever screenshotted. Visual inspection would have revealed the real defect in minutes.
- Platform detection is already solved by `vf-platform-detection.md` — the script should reuse that priority order, not invent its own.
- iOS capture uses `idb` + `simctl`; web uses Playwright MCP or chrome-devtools; CLI captures stdout. The skill should pick one per run and cite evidence-management conventions (`e2e-evidence/{journey}/step-NN-*.png`).
- "Seed data locally" and "DB schema check up-front" emerged from the insights report as the two multiplicative unblockers — they catch all missing tables at once instead of one per click.
- VF already has strong validation primitives (`playwright-validation`, `ios-validation`). This skill is a *coordinator*, not a replacement — its job is the gate ("screenshot first"), not the mechanics ("how to drive Playwright").

## Requirements

### Functional
- SKILL.md frontmatter `name: audit`. Description triggers on "audit the X", "QA this", "check if X is working end to end", "full functional review", "production readiness", "dashboard broken", "feature audit".
- SKILL.md body encodes the four-step gate:
  1. **Detect platform** (reuse logic from `vf-platform-detection.md`).
  2. **Seed local data** (explicit step: "do not debug cross-workspace auth before local seeding works").
  3. **Capture visual evidence FIRST** via `scripts/capture-visuals.sh` — the model must look at the captured artifact before any code-path investigation.
  4. **Run DB schema / migration check once, up-front** — accumulate all missing tables/columns in one pass.
  Only after those four steps does the model enter defect investigation.
- Bundled `scripts/capture-visuals.sh` that:
  - auto-detects platform (iOS / web / CLI / API) via the priority in `vf-platform-detection.md`;
  - dispatches to the right tool (idb/simctl, Playwright MCP, chrome-devtools MCP, `curl`, or stdout capture);
  - writes output to `e2e-evidence/{journey-slug}/step-NN-<description>.{png,json,txt}` matching the VF evidence-management convention;
  - exits non-zero if capture failed, with a one-line reason to stderr.
- SKILL.md cross-references `~/.claude/rules/audit-workflow.md`, `~/.claude/rules/vf-platform-detection.md`, and `~/.claude/rules/vf-evidence-management.md`.

### Non-functional
- SKILL.md <500 lines.
- `scripts/capture-visuals.sh` is a thin dispatcher (<150 lines), delegates heavy lifting to already-installed tools.
- Skill does NOT instruct the model to write test files, mocks, or stubs (see global `no-mocks.md`).

## Architecture

### Skill directory layout
```
~/.claude/skills/audit/
├── SKILL.md                          # Layer 2 — gate workflow
├── scripts/
│   └── capture-visuals.sh            # Layer 3 — platform-dispatching capture
└── references/
    ├── ios-capture.md                # Loaded only if platform = iOS
    ├── web-capture.md                # Loaded only if platform = web
    └── api-capture.md                # Loaded only if platform = API
```

### Progressive disclosure layers
1. **Metadata**: `name` + pushy description.
2. **SKILL.md body**: four-step gate + rationale + pointer to right reference file per platform.
3. **Platform-specific references**: loaded on demand — model reads only the file matching the detected platform.

### Frontmatter shape (example, not final copy)
```yaml
---
name: audit
description: Run a visual-first functional audit of any running system before touching code. Use WHENEVER the user says "audit the dashboard", "QA this feature", "full functional review", "production readiness check", "the X page looks broken", "check if the flow works end to end", or any phrasing that asks for a system-level health check. Step 1 is always to screenshot/dump the actual rendered output — this is the single highest-leverage move because past audits wasted hours on auth or workspace plumbing before ever looking at what the user sees.
---
```

### Data flow
```
user asks for audit of <feature>
      │
      ▼
detect platform (vf-platform-detection.md priority)
      │
      ▼
seed local fixtures (skip remote auth rabbit holes)
      │
      ▼
scripts/capture-visuals.sh → e2e-evidence/<feature>/step-01-<view>.png (or .json/.txt)
      │
      ▼
MODEL LOOKS AT THE ARTIFACT  ←  gate: no code investigation before this
      │
      ▼
one-pass DB schema / migration check (collect all gaps)
      │
      ▼
defect investigation (existing VF skills take over: playwright-validation, ios-validation, etc.)
```

## Related Code Files

### CREATE
- `/Users/nick/.claude/skills/audit/SKILL.md`
- `/Users/nick/.claude/skills/audit/scripts/capture-visuals.sh`
- `/Users/nick/.claude/skills/audit/references/ios-capture.md`
- `/Users/nick/.claude/skills/audit/references/web-capture.md`
- `/Users/nick/.claude/skills/audit/references/api-capture.md`

### MODIFY
- None. Plan A ships `audit-workflow.md`.

### DELETE
- None.

## Implementation Steps

Follow skill-creator's full draft sequence; pay special attention to *Domain organization* (references per-platform).

1. **(skill-creator §Capture Intent)** Pull 3 real audit-request phrasings from past sessions (SessionForge dashboard, detector QA, VF meta-audits).
2. **(skill-creator §Write the SKILL.md — description)** Draft pushy description naming all three domains explicitly; include the near-miss "debug" vs "audit" distinction so `/audit` does not steal triggers from `/root-cause-first`.
3. Draft SKILL.md body with the four-step gate. For each step, one paragraph explaining *why that order*:
   - seed before auth debug → auth plumbing is noise;
   - screenshot before code → cheapest ground truth;
   - one-pass schema check → batched failures beat per-click discovery.
4. **(skill-creator §Domain organization)** Split per-platform capture details into `references/{ios,web,api}-capture.md`. Keep the main SKILL.md body platform-agnostic.
5. Implement `scripts/capture-visuals.sh`:
   - Source platform detection (reuse priority from `vf-platform-detection.md`).
   - Dispatch: iOS → `idb` / `xcrun simctl io booted screenshot`; web → call Playwright MCP via `claude mcp` helper or fall back to `chrome-devtools-mcp`; API → `curl -sS -D <headers> <url>`; CLI → pipe stdout.
   - Output dir follows `vf-evidence-management.md` naming.
   - Fail fast with a clear error if no platform detected.
6. Write the three reference files (`ios-capture.md`, `web-capture.md`, `api-capture.md`). Each is a ~40-line primer: tool setup, single capture command, where output goes, how to verify non-empty.
7. **(skill-creator §Writing Style)** Fresh-eyes pass. Remove MUSTs; keep the four-step gate as a numbered list with *why* sentences.
8. Verify the skill does not overlap with `playwright-validation` / `ios-validation` — SKILL.md must explicitly defer to those skills for the driving mechanics, owning only the *gate and order*.
9. Stage for Phase 4 eval design.

## Todo List
- [ ] Extract 3 real audit-request phrasings from past sessions
- [ ] Draft pushy frontmatter description (include near-miss carve-out vs `/root-cause-first`)
- [ ] Draft SKILL.md body with four-step gate and per-step why
- [ ] Implement `scripts/capture-visuals.sh` with platform dispatch
- [ ] Author `references/ios-capture.md`, `web-capture.md`, `api-capture.md`
- [ ] Verify no overlap with `playwright-validation` / `ios-validation`
- [ ] Fresh-eyes pass: remove caps-MUSTs

## Success Criteria
- SKILL.md frontmatter parses as valid YAML.
- `scripts/capture-visuals.sh` on a known-good web project produces a non-empty PNG at `e2e-evidence/<feature>/step-01-<view>.png`.
- Same script against a running API produces a non-empty JSON at `step-01-<endpoint>.json` including response body AND headers.
- Same script against an iOS simulator produces a non-empty PNG.
- In Phase 5 with-skill runs, the model always captures visual evidence before attempting any code-path investigation; baseline runs skip visuals ≥50% of the time.

## Risk Assessment
| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Overlaps with existing VF validation skills | Medium | Medium | SKILL.md defers to `playwright-validation` / `ios-validation` for mechanics; owns only the order/gate |
| `capture-visuals.sh` fragile across platforms | High | Medium | Script exits non-zero with a clear message; SKILL.md tells the model to fall back to the platform-specific skill directly |
| idb/simctl not installed on target machine | Medium | Medium | Script detects and prints install hint; does not mask missing deps |
| Triggers on `/root-cause-first` territory (bug fixes) | Medium | Medium | Description carves out "fix a bug" vs "audit the system"; validated in Phase 7 |
| Seed-data step assumes a seed script exists | High | Medium | SKILL.md says "if no seed script exists, STOP and ask the user" — no cheating with fake data |

## Security Considerations
- `capture-visuals.sh` runs read-only commands by default (screenshot, curl, stdout) — no filesystem writes outside `e2e-evidence/`.
- Credential handling: the script must NOT log auth headers or cookies to stdout; only status line + body length. Sensitive values go to `step-NN-*.json` with a header-redaction pass.
- Script provenance: header comment with author, date, platforms supported, network surface (Playwright MCP only; no external HTTP).
- Reference data: the audit never writes to DB or state dirs — it only reads.

## Next Steps
- Phase 4 (eval design) depends on this phase complete.
- Phase 8 (functional validation) invokes `/audit` against a real SessionForge dashboard page.
- Long-term: fold learned platform-detection deltas back into `vf-platform-detection.md`.
