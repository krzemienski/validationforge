# Oracle Audit: Merge Campaign Validation Rigor

**Date:** 2026-04-09
**Auditor:** Oracle (Opus critic agent)
**Subject:** Merge campaign validation gates VG-1 through VG-12
**Verdict:** REVISE — Level 3 (System Assembles), Level 4-5 NOT achieved

---

## Overall Assessment

The merge campaign executed 12 validation gates across 14 merged specs. **Every single gate checks structural properties** (files exist, JSON parses, npm installs, syntax passes). **Zero gates test actual plugin behavior in a live Claude Code session.** The campaign is a thorough structural assembly verification — Level 3 on the rigor scale — but it does not prove the system works.

---

## Per-Gate Assessment

### VG-1: Campaign State Accuracy — COSMETIC
- **Verified:** CAMPAIGN_STATE.md contains correct SHA hashes and status labels
- **Missed:** Whether merges introduced regressions or broken functionality
- **Could pass while broken?** Yes

### VG-2: A5 Validation Suite + Pinning — STRUCTURAL
- **Verified:** npm install exits 0, JSON parses, bash -n passes, node --check passes, pinning OK
- **Missed:** Whether any hook DOES what it claims. Whether skill YAML frontmatter is valid. Whether `${CLAUDE_PLUGIN_ROOT}` resolves in a real session
- **Could pass while broken?** Yes

### VG-3: Quarantine Decision for Spec 015 — CORRECTLY SCOPED
- **Verified:** Spec 015 NOT merged, branch preserved, evidence of destructive changes logged
- **Missed:** Nothing — this gate correctly prevented a destructive merge
- **Could pass while broken?** No. This is the one correctly designed gate.

### VG-4: Wave 4 Checkpoint — STRUCTURAL (repeat of VG-2)
- **Verified:** Same as VG-2 post-Wave-4 merges
- **Missed:** Whether newly merged specs (018, 021, 023, 024) introduced working functionality
- **Could pass while broken?** Yes

### VG-5: Wave 5 Checkpoint — STRUCTURAL (repeat of VG-2)
- **Verified:** Skill count >= baseline, wave tags exist, npm install, pinning
- **Missed:** Whether "quality normalization" from spec 008 actually improved anything measurable
- **Could pass while broken?** Yes

### VG-6: Worktree/Branch Cleanup — COSMETIC
- **Verified:** Only main worktree + quarantined 015 remain
- **Missed:** This is housekeeping, not validation
- **Could pass while broken?** N/A

### VG-7: Benchmark Completion — COSMETIC
- **Verified:** Benchmark file has >= 1 line per skill, opencode evidence exists
- **Missed:** Whether benchmark scores are ACCURATE. Scored documentation quality, not functional quality. Never ran a skill.
- **Could pass while broken?** Yes

### VG-8: Documentation Existence — COSMETIC
- **Verified:** 7 docs exist and are non-empty. README doesn't reference spec 015
- **Missed:** Whether documentation is ACCURATE
- **Could pass while broken?** Yes

### VG-9: Cold-Start + Consistency — STRUCTURAL (strongest)
- **Verified:** rm -rf node_modules && npm install succeeds. All syntax passes. plugin.json valid. package.json files array all present. npm pack --dry-run succeeds
- **Missed:** Whether the packed tarball actually loads as a plugin. Whether hooks fire in a real session
- **Could pass while broken?** Yes

### VG-10: Repository Hygiene — COSMETIC
- **Verified:** Worktrees clean, branches clean, tag exists, stash documented
- **Could pass while broken?** N/A

### VG-11: Branch Rename — COSMETIC
- **Verified:** Branch is `main`, tag exists
- **Could pass while broken?** N/A

### VG-12: Final Campaign Verdict — STRUCTURAL (rollup)
- **Verified:** Summary of all prior gates
- **Missed:** Everything all prior gates missed, compounded
- **Could pass while broken?** Yes

---

## Gate Category Summary

| Category | Gates | Count |
|----------|-------|-------|
| STRUCTURAL | VG-2, VG-4, VG-5, VG-9 | 4 |
| COSMETIC | VG-1, VG-6, VG-7, VG-8, VG-10, VG-11 | 6 |
| STRUCTURAL (rollup) | VG-12 | 1 |
| CORRECTLY SCOPED | VG-3 | 1 |
| **FUNCTIONAL** | **(none)** | **0** |

**Zero functional gates out of twelve.**

---

## Validation Rigor Rating: Level 3

| Level | Description | Status |
|-------|-------------|--------|
| 0 | No checks at all | -- |
| 1 | Files exist | ACHIEVED |
| 2 | Files are syntactically valid | ACHIEVED |
| 3 | System assembles (npm install, node --check, npm pack) | ACHIEVED |
| 4 | System loads and hooks fire in a real session | **NOT ACHIEVED** |
| 5 | Full behavioral validation | **NOT ACHIEVED** |

---

## Specific Bugs Found During Audit

### 1. Mock Pattern Gap
`jest.spyOn(obj, "method")` is NOT detected by any of the 20 MOCK_PATTERNS in `hooks/patterns.js`. The patterns check for `jest.mock(`, `.mockReturnValue`, `.mockResolvedValue`, `mockImplementation` — but not `jest.spyOn`, `jest.fn()`, or `jest.createMockFromModule`. A developer writing `const spy = jest.spyOn(router, 'push')` would NOT be blocked.

### 2. Completion Claim False Negative
The `completion-claim-validator.js` hook silently passes when `e2e-evidence/` exists with ANY content — even stale evidence from a previous run. It checks `fs.existsSync(EVIDENCE_DIR) && fs.readdirSync(EVIDENCE_DIR).length > 0` — it does not check whether evidence is RECENT or RELEVANT.

### 3. Config File Missing Enforcement Field
`~/.claude/.vf-config.json` has no `enforcement` field. The config-loader falls back to `'standard'`, but the setup process should write this explicitly. No evidence the user ever chose an enforcement level.

---

## The Irony

> A project whose entire purpose is to prevent "it compiled, ship it" validation was itself validated at the "it compiled" level.

The project's own CLAUDE.md says "Compilation success does not equal functional validation" — yet every gate in this campaign is a compilation-level check.

---

## What Would ACTUALLY Prove This Works

### To reach Level 4 (System Loads):
1. Install the plugin: `claude plugin install /path/to/validationforge`
2. Start a NEW Claude Code session
3. Attempt to create `foo.test.ts` — verify Claude Code shows deny from `block-test-files.js`
4. Run `npm run build` — verify `validation-not-compilation` hook fires
5. Check `/help` — verify slash commands appear

### To reach Level 5 (Full Behavioral):
6. Run `/validate` on a sample project — verify 7-phase pipeline output
7. Run `/vf-setup` — verify it writes config with correct enforcement level
8. Switch to `permissive` — verify `block-test-files` warns instead of blocks
9. Write `jest.mock()` — verify `mock-detection` fires
10. Mark task complete without evidence — verify `evidence-gate-reminder` fires
11. Test OpenCode plugin in OpenCode session
12. Test `install.sh` end-to-end from git clone
13. Test `npm pack && npm install -g` — verify tarball installs and plugin loads

---

## Open Questions

1. The `installed_plugins.json` entry was created at `2026-04-09T02:30:17.034Z`. Was a Claude Code session started AFTER this timestamp?
2. Was the "Known Verification Gaps" section deliberately removed from CLAUDE.md during a spec merge?
3. Evidence in `e2e-evidence/` — produced during merge campaign or carried over from spec branch work?
