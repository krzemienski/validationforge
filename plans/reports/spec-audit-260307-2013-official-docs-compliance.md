# ValidationForge: Official Spec Compliance Audit

**Date:** 2026-03-07
**Source of truth:** docs.claude.com (via working-with-claude-code skill references)
**Verdict:** FAIL — 9 critical spec violations, plugin would NOT work if installed

---

## CRITICAL ISSUE #1: Two plugin.json files — STALE MANIFEST

| File | Purpose | Status |
|------|---------|--------|
| `plugin.json` (root) | Non-standard location | Cleaned in Phase 5, BUT Claude Code doesn't read this |
| `.claude-plugin/plugin.json` | **Official location** (what CC reads) | STALE — still has 38 skill entries incl. individual .md files |

**Impact:** All Phase 5 cleanup work was applied to the WRONG file. Claude Code reads `.claude-plugin/plugin.json`.

---

## CRITICAL ISSUE #2: `skills` field does NOT exist in official schema

Official plugin.json schema fields:
- `name` (required), `version`, `description`, `author`, `homepage`, `repository`, `license`, `keywords`
- `commands` (string|array — additional paths, `commands/` auto-discovered)
- `agents` (string|array — additional paths, `agents/` auto-discovered)
- `hooks` (string|object — path to hooks config or inline)
- `mcpServers` (string|object — path or inline)

**NOT in schema:** `skills`, `templates`, `scripts`, `config`, `configuration`

Skills in `skills/` are AUTO-DISCOVERED. No listing needed or supported.

---

## CRITICAL ISSUE #3: Hook format is COMPLETELY WRONG

### What we have (WRONG):
```json
"hooks": [
  {
    "event": "PreToolUse",
    "matcher": "Write|Edit|MultiEdit",
    "script": "hooks/block-test-files.js",
    "description": "Blocks creation of test/mock/stub files"
  }
]
```

### What the spec requires:
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/hooks/block-test-files.js"
          }
        ]
      }
    ]
  }
}
```

**Differences:**
1. Hooks is an OBJECT keyed by event name, not an array
2. Each event contains an array of matcher groups
3. Each matcher group has a `hooks` array (not `script`)
4. Each hook needs `type: "command"` and `command` (not `script`)
5. Must use `${CLAUDE_PLUGIN_ROOT}` for plugin-relative paths
6. No `event` or `description` fields

---

## CRITICAL ISSUE #4: Non-standard fields in plugin.json

| Field | In Official Schema? | What happens |
|-------|---------------------|-------------|
| `skills` | NO | Ignored — skills auto-discovered from `skills/` |
| `templates` | NO | Ignored entirely |
| `scripts` | NO | Ignored entirely |
| `config` | NO | Ignored entirely |
| `configuration` | NO | Ignored entirely |

---

## CRITICAL ISSUE #5: `author` field format wrong

**Official:** `"author": {"name": "...", "email": "...", "url": "..."}`
**Ours:** `"author": "Nick Krzemienski"` (string, not object)

---

## CRITICAL ISSUE #6: Agents missing YAML frontmatter

**Official agent format:**
```yaml
---
description: What this agent specializes in
capabilities: ["task1", "task2", "task3"]
---

# Agent Name
...
```

**Our agents:** No `---` frontmatter at all. Just start with `# Agent Name`.

All 3 agents (`platform-detector.md`, `evidence-capturer.md`, `verdict-writer.md`) are missing required frontmatter.

---

## CRITICAL ISSUE #7: `platform-routing/` skills outside `skills/` directory

Skills auto-discovery scans `skills/` directory only. The 5 platform-routing skills at `platform-routing/` root level will NOT be discovered.

**Must move to:** `skills/platform-routing/{name}/SKILL.md` or equivalent under `skills/`.

---

## CRITICAL ISSUE #8: `hooks/hooks.json` doesn't exist

Standard plugin hook location is `hooks/hooks.json`. File is missing. Hooks are only defined inline in plugin.json — but in the wrong format (Issue #3).

---

## CRITICAL ISSUE #9: Hook scripts use wrong path format

Current: relative paths like `hooks/block-test-files.js`
Required: `${CLAUDE_PLUGIN_ROOT}/hooks/block-test-files.js`

Plugin scripts must use `${CLAUDE_PLUGIN_ROOT}` to resolve paths correctly when installed via marketplace.

---

## What IS Correct

| Component | Status | Notes |
|-----------|--------|-------|
| SKILL.md frontmatter (name + description) | CORRECT | All 16 skills have valid YAML |
| SKILL.md line counts (<150) | CORRECT | 76-127 range |
| SKILL.md scope + security sections | CORRECT | All present |
| Command frontmatter (name + description) | CORRECT | 5/5 valid |
| Command content quality | CORRECT | Well-structured |
| Hook JS logic (stdin/stdout) | CORRECT | All 5 produce valid output |
| Script functionality | CORRECT | All 3 execute correctly |
| Reference files | CORRECT | All exist and <150 lines |

---

## Required Fixes (Priority Order)

### P0 — Plugin won't load without these
1. Fix `.claude-plugin/plugin.json` to match official schema
2. Create `hooks/hooks.json` in official format (or use inline in plugin.json correctly)
3. Move `platform-routing/` skills into `skills/` directory
4. Remove non-standard fields (`skills`, `templates`, `scripts`, `config`, `configuration`)

### P1 — Components won't be recognized
5. Add YAML frontmatter to all 3 agent files
6. Fix `author` field to object format

### P2 — Cleanup
7. Delete root `plugin.json` (redundant, non-standard location)
8. Use `${CLAUDE_PLUGIN_ROOT}` in hook commands

---

## Unresolved Questions

1. Does Claude Code support `hooks` inline in `.claude-plugin/plugin.json` directly, or must it be a separate `hooks/hooks.json` file?
   - Spec says: "Plugin hooks are defined in the plugin's `hooks/hooks.json` file or in a file given by a custom path to the `hooks` field."
   - This suggests inline in plugin.json via the `hooks` field pointing to a file, OR `hooks/hooks.json` default location.

2. Can the `commands` and `agents` fields point to individual files, or only directories?
   - Spec shows both: `"./custom/cmd.md"` and `"./utilities/"` — both file and directory paths work.
   - BUT `commands/` and `agents/` are auto-discovered, so explicit listing is unnecessary if files are in default locations.
