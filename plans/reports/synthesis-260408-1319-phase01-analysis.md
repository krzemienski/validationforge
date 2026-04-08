# ValidationForge Phase 0+1 Analysis

## Inventory Summary

| Primitive | Count | Status |
|-----------|-------|--------|
| Skills | 40 | 37/40 compliant, 3 missing frontmatter |
| Commands | 15 | 15/15 valid frontmatter, inconsistent field usage |
| Hooks | 7 scripts + hooks.json | 1 deprecated protocol, `|| true` anti-pattern on all |
| Agents | 5 | 5/5 valid, no `name` field (uses filename) |
| Rules | 8 | 8/8 consistent, minor redundancy with CLAUDE.md |
| Manifests | plugin.json + marketplace.json | Sparse — missing recommended fields |

## Critical Issues (Priority Order)

### P0 — Must Fix

1. **block-test-files.js uses deprecated PreToolUse protocol**
   - Uses `{"decision":"block","reason":"..."}` on stdout + exit(0)
   - Should use `hookSpecificOutput.permissionDecision: "deny"` + `permissionDecisionReason`
   - Currently functional (deprecated maps to "deny" internally) but fragile

2. **`|| true` on ALL hook commands in hooks.json**
   - Every hook command ends with `|| true`
   - Masks crash errors — harness never knows if hook failed
   - Would completely break `exit(2) + stderr` blocking protocol
   - MUST remove to enable proper error visibility

3. **3 skills missing YAML frontmatter** (won't load in frontmatter-aware systems)
   - `forge-benchmark/SKILL.md`
   - `forge-execute/SKILL.md`
   - `forge-plan/SKILL.md`

### P1 — Should Fix

4. **Inconsistent command frontmatter patterns**
   - forge-* commands: `description` + `allowed-tools` (no `name`)
   - validate-* commands: `name` + `description` + optional `triggers` (no `allowed-tools`)
   - Should standardize: all should have `description` at minimum

5. **evidence-quality-check.js is noisy**
   - Outputs feedback message on EVERY e2e-evidence write, even successful ones
   - Should only output on empty/problematic files

6. **plugin.json too sparse**
   - Has: name, version, description, author
   - Missing: homepage, repository, license, keywords
   - marketplace.json missing: version, homepage fields on plugin entries

### P2 — Nice to Have

7. **No `name` field in agent frontmatter** — CC uses filename, so non-breaking but explicit is better
8. **validation-discipline.md rule redundant with CLAUDE.md** — intentional emphasis but adds token load
9. **No `description` field in hooks.json** — CC supports it for documentation

## Hooks Deep Analysis

### Protocol Compliance

| Script | Event | Protocol | Status |
|--------|-------|----------|--------|
| block-test-files.js | PreToolUse | JSON `{"decision":"block"}` + exit(0) | ⚠️ DEPRECATED |
| completion-claim-validator.js | PostToolUse | `hookSpecificOutput.additionalContext` | ✅ Correct |
| evidence-gate-reminder.js | PreToolUse | `hookSpecificOutput.additionalContext` | ✅ Context injection |
| evidence-quality-check.js | PostToolUse | `hookSpecificOutput.additionalContext` | ✅ Correct (noisy) |
| mock-detection.js | PostToolUse | `hookSpecificOutput.additionalContext` | ✅ Correct |
| validation-not-compilation.js | PostToolUse | `hookSpecificOutput.additionalContext` | ✅ Correct |
| validation-state-tracker.js | PostToolUse | `hookSpecificOutput.additionalContext` | ✅ Correct |

### Security Review

- ✅ No shell injection — hooks read stdin JSON, no exec of untrusted input
- ✅ No file traversal — hooks check paths against pattern allowlists
- ✅ No hardcoded secrets
- ⚠️ Error handling uses `catch(e) { process.exit(0) }` — swallows errors silently
- ✅ stdin reading uses async stream pattern correctly

### hooks.json Structure

- ✅ PreToolUse matchers: `Write|Edit|MultiEdit`, `TaskUpdate`
- ✅ PostToolUse matchers: `Bash`, `Edit|Write|MultiEdit`
- ✅ All commands use `${CLAUDE_PLUGIN_ROOT}`
- ⚠️ Missing `description` field (optional but good practice)
- ❌ All commands end with `|| true` — masks failures

## Skills Analysis

- **37/40 fully compliant**: Valid frontmatter, proper naming, clean descriptions, no security issues
- **3 missing frontmatter**: forge-benchmark, forge-execute, forge-plan — begin with markdown heading instead of `---` fence
- No hardcoded paths, secrets, or broken tool references found
- All skills reference only real CC tools

## Commands Analysis

### Frontmatter Patterns

| Command | name | description | allowed-tools | triggers |
|---------|------|-------------|---------------|----------|
| forge-benchmark | ❌ | ✅ | ✅ | ❌ |
| forge-execute | ❌ | ✅ | ✅ | ❌ |
| forge-install-rules | ❌ | ✅ | ✅ | ❌ |
| forge-plan | ❌ | ✅ | ✅ | ❌ |
| forge-setup | ❌ | ✅ | ✅ | ❌ |
| forge-team | ❌ | ✅ | ✅ | ❌ |
| validate-audit | ✅ | ✅ | ❌ | ❌ |
| validate-benchmark | ✅ | ✅ | ❌ | ✅ |
| validate-ci | ✅ | ✅ | ❌ | ❌ |
| validate-fix | ✅ | ✅ | ❌ | ❌ |
| validate-plan | ✅ | ✅ | ❌ | ❌ |
| validate-sweep | ✅ | ✅ | ❌ | ✅ |
| validate-team | ✅ | ✅ | ❌ | ✅ |
| validate | ✅ | ✅ | ❌ | ❌ |
| vf-setup | ✅ | ✅ | ❌ | ✅ |

No $ARGUMENTS injection risks found. No broken skill/agent references.

## Agents Analysis

All 5 agents have valid frontmatter with `description` + `capabilities` array. Clear identity/role/constraints. Reference real skills and commands.

## Rules Analysis

All 8 rules are declarative, consistent with CLAUDE.md iron rules, reference existing skills/commands/agents. Minor redundancy with CLAUDE.md (no-mock mandate) is intentional.

## Manifest Analysis

### plugin.json
```json
{
  "name": "validationforge",         // ✅
  "version": "1.0.0",                // ✅
  "description": "...",              // ✅
  "author": { "name": "...", "url": "..." } // ✅
  // MISSING: homepage, repository, license, keywords
}
```

### marketplace.json
```json
{
  "name": "validationforge",          // ✅
  "owner": { "name": "...", "url": "..." }, // ✅
  "plugins": [{ "name": "...", "source": "./" }] // ✅ but missing version
}
```

### package.json
- `files` array covers all plugin directories ✅
- Has homepage, repository, license, keywords ✅
- BUT plugin.json doesn't mirror these — should sync

## Fix Plan

1. Fix block-test-files.js → migrate to non-deprecated protocol
2. Remove `|| true` from all hooks.json commands
3. Add YAML frontmatter to 3 forge-* skills
4. Standardize command frontmatter (add description to all, add name to forge-*)
5. Reduce evidence-quality-check.js noise
6. Enrich plugin.json + marketplace.json with missing fields
7. Add `description` field to hooks.json
8. Improve error handling in hooks (log instead of silent swallow)
