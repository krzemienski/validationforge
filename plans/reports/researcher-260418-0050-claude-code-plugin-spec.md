# Claude Code Plugin Specification Reference
**Date:** 2026-04-18  
**Source Authority:** https://code.claude.com/docs/en/plugins-reference (official)  
**Scope:** Plugin manifest, marketplace, hooks, agents, skills directory layouts  

---

## 1. Plugin Manifest (`.claude-plugin/plugin.json`)

### Required Fields
| Field | Type | Constraints |
|-------|------|------------|
| `name` | string | Kebab-case, no spaces. Used for namespacing: `/name:skill` |

### Optional Metadata
| Field | Type | Example |
|-------|------|---------|
| `version` | string | Semantic version (e.g., `"1.2.0"`). If set in both manifest and marketplace, manifest wins |
| `description` | string | Brief plugin purpose |
| `author` | object | `{"name": "...", "email": "..."}` |
| `homepage` | string | Documentation URL |
| `repository` | string | Source repo URL |
| `license` | string | SPDX identifier (e.g., `"MIT"`) |
| `keywords` | array | Discovery tags |

### Component Paths (Custom Locations)
| Field | Type | Default | Override Behavior |
|-------|------|---------|-------------------|
| `skills` | string\|array | `skills/` | Replaces default if specified |
| `commands` | string\|array | `commands/` | Replaces default if specified |
| `agents` | string\|array | `agents/` | Replaces default if specified |
| `hooks` | string\|array\|object | `hooks/hooks.json` | Can be inline object or path |
| `mcpServers` | string\|array\|object | `.mcp.json` | Can be inline object or path |
| `lspServers` | string\|array\|object | `.lsp.json` | Can be inline object or path |
| `outputStyles` | string\|array | `output-styles/` | Replaces default if specified |
| `monitors` | string\|array | `monitors/monitors.json` | Can be inline array or path |

**Path Rules:**  
- All paths relative to plugin root, start with `./`
- Path specified → default NOT scanned (except hooks/MCP/LSP which merge)
- To keep default AND add more: `"skills": ["./skills/", "./extras/"]`

### User Configuration & Channels
```json
{
  "userConfig": {
    "api_endpoint": {"description": "...", "sensitive": false},
    "api_token": {"description": "...", "sensitive": true}
  },
  "channels": [
    {"server": "telegram", "userConfig": {...}}
  ]
}
```
- Non-sensitive values → stored in `settings.json`
- Sensitive values → system keychain (or `~/.claude/.credentials.json` fallback)
- Available as `${user_config.KEY}` in configs and `CLAUDE_PLUGIN_OPTION_<KEY>` in env

### Plugin Dependencies
```json
{
  "dependencies": [
    "helper-lib",
    {"name": "secrets-vault", "version": "~2.1.0"}
  ]
}
```

### Default Settings
```json
{
  "settings.json": {
    "agent": "agent-name",
    "subagentStatusLine": "..."
  }
}
```
Only `agent` and `subagentStatusLine` keys currently supported.

---

## 2. Environment Variables in plugin.json

### Standard Substitutions (all components)
| Variable | Resolves To | Survives Updates |
|----------|-------------|------------------|
| `${CLAUDE_PLUGIN_ROOT}` | Plugin installation dir (in cache) | NO — changes on update |
| `${CLAUDE_PLUGIN_DATA}` | `~/.claude/plugins/data/{id}/` | YES — persistent across versions |
| `${user_config.*}` | User-configured values | YES |
| `${ENV_VAR}` | Environment variable | YES |

**ID Calculation:** Characters outside `a-z`, `A-Z`, `0-9`, `_`, `-` replaced by `-`.  
Example: `formatter@my-marketplace` → `~/.claude/plugins/data/formatter-my-marketplace/`

---

## 3. Directory Structure

### Standard Layout
```
plugin-root/
├── .claude-plugin/
│   ├── plugin.json         # Manifest (optional if defaults used)
│   └── marketplace.json    # Only in marketplace repos
├── skills/
│   └── <name>/
│       ├── SKILL.md        # Required
│       └── scripts/        # Optional
├── commands/               # Flat .md files (legacy, use skills/)
├── agents/                 # Agent definitions
├── hooks/
│   ├── hooks.json         # Main hook config
│   └── *.sh               # Hook scripts
├── .mcp.json              # MCP servers
├── .lsp.json              # LSP servers
├── monitors/
│   └── monitors.json      # Background monitors
├── bin/                   # Executables added to PATH
├── output-styles/         # Output style definitions
└── settings.json          # Default plugin settings
```

**Critical:** Components at plugin root, NOT inside `.claude-plugin/`. Only manifest goes in `.claude-plugin/`.

### File Location Defaults
| Component | Default | Purpose |
|-----------|---------|---------|
| Manifest | `.claude-plugin/plugin.json` | Plugin metadata |
| Skills | `skills/` | Skills as `<name>/SKILL.md` |
| Commands | `commands/` | Legacy flat `.md` files |
| Agents | `agents/` | Agent `.md` files |
| Output styles | `output-styles/` | Output style definitions |
| Hooks | `hooks/hooks.json` | Hook configuration |
| MCP servers | `.mcp.json` | MCP server definitions |
| LSP servers | `.lsp.json` | LSP server configurations |
| Monitors | `monitors/monitors.json` | Background monitors |

---

## 4. Skills (`skills/<name>/SKILL.md`)

### Frontmatter (YAML)
| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `description` | string | YES | Claude uses this to decide when to invoke |
| `disable-model-invocation` | boolean | NO | Default false (Claude can invoke automatically) |
| `name` | string | NO | For direct SKILL.md at plugin root; overrides directory name |

### Example
```yaml
---
description: Review code for bugs, security, and performance
disable-model-invocation: false
---

Review the code for [list criteria].
Support `$ARGUMENTS` for user input.
```

### Invocation
- Plugin skill: `/plugin-name:skill-name`
- Standalone skill: `/skill-name`
- With arguments: `/skill-name <arg1> <arg2>`

---

## 5. Agents (`agents/<name>.md`)

### Frontmatter (YAML)
| Field | Type | Required | Allowed Values |
|-------|------|----------|----------------|
| `name` | string | YES | Agent identifier |
| `description` | string | YES | When Claude should invoke |
| `model` | string | NO | `haiku`, `sonnet` (default), `opus` |
| `effort` | string | NO | `minimal`, `light`, `medium`, `thorough` |
| `maxTurns` | number | NO | Max conversation turns |
| `tools` | array | NO | Allowed tools list |
| `disallowedTools` | array | NO | Denied tools list |
| `skills` | array | NO | Available skills |
| `memory` | string | NO | Memory type |
| `background` | string | NO | Background context |
| `isolation` | string | NO | Only valid value: `"worktree"` |

**Unsupported in plugins:** `hooks`, `mcpServers`, `permissionMode` (for security).

### Example
```yaml
---
name: security-reviewer
description: Specialized code review for security vulnerabilities
model: opus
effort: thorough
maxTurns: 20
disallowedTools: [Read, Edit]
---

You are a security expert. Review code for vulnerabilities...
```

---

## 6. Hooks (`hooks/hooks.json`)

### Event Names (ALL VALID)
```
SessionStart, UserPromptSubmit, PreToolUse, PermissionRequest, PermissionDenied,
PostToolUse, PostToolUseFailure, Notification, SubagentStart, SubagentStop,
TaskCreated, TaskCompleted, Stop, StopFailure, TeammateIdle,
InstructionsLoaded, ConfigChange, CwdChanged, FileChanged,
WorktreeCreate, WorktreeRemove, PreCompact, PostCompact,
Elicitation, ElicitationResult, SessionEnd
```

### Hook Configuration Structure
```json
{
  "hooks": {
    "EventName": [
      {
        "matcher": "pattern|or|regex",
        "if": "Tool(args *)",
        "hooks": [
          {
            "type": "command|http|prompt|agent",
            "command": "shell command",
            "url": "http://endpoint",
            "prompt": "LLM prompt",
            "timeout": 600,
            "model": "haiku"
          }
        ]
      }
    ]
  }
}
```

### Matcher by Event Type
| Event | Matches On | Example |
|-------|-----------|---------|
| PreToolUse, PostToolUse, PostToolUseFailure, PermissionRequest, PermissionDenied | Tool name | `Bash`, `Edit\|Write`, `mcp__.*` |
| SessionStart | Session source | `startup`, `resume`, `clear`, `compact` |
| Notification | Notification type | `permission_prompt`, `idle_prompt` |
| SubagentStart, SubagentStop | Agent type | Built-in or custom agent names |
| ConfigChange | Config source | `user_settings`, `project_settings`, `policy_settings` |
| FileChanged | Filename (literal, not regex) | `.envrc\|.env` |
| Most other events | No matcher support | Always fires |

### Hook Input (stdin)
Common fields (all events):
```json
{
  "session_id": "abc123",
  "cwd": "/current/dir",
  "hook_event_name": "EventName",
  "permission_mode": "default|plan|acceptEdits|auto|dontAsk|bypassPermissions"
}
```
Event-specific fields added per event type (e.g., `tool_name`, `tool_input`, `prompt`).

### Hook Output (stdout/exit)
| Exit Code | Behavior | Notes |
|-----------|----------|-------|
| 0 | Success | Parse JSON from stdout if present; otherwise silent allow |
| 2 | Block | Error message on stderr; action denied |
| Other | Non-blocking error | Stderr shown as hook error notice |

**PreToolUse Decision (exit 0 with JSON):**
```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow|deny|ask|defer",
    "permissionDecisionReason": "explanation",
    "updatedInput": {"command": "modified command"}
  }
}
```

**PostToolUse/Stop Decision (exit 0 with JSON):**
```json
{
  "decision": "allow|block",
  "reason": "explanation"
}
```

**Context Injection (exit 0, stdout becomes context):**
```bash
#!/bin/bash
echo "Reminder: use Bun, not npm. Recent commits: $(git log --oneline -3)"
exit 0
```

### Hook Types
| Type | Used For | Example |
|------|----------|---------|
| `command` | Shell commands, scripts | `bash`, `python`, `jq` |
| `http` | Remote endpoints | POST JSON to server |
| `prompt` | Single-turn LLM decisions | Yes/no verification |
| `agent` | Multi-turn verification with tools | Full audit logic |

### Inline vs File
```json
{
  "hooks": {
    "PostToolUse": [...]           # Inline in plugin.json
  }
}
```
OR use `"hooks": "./hooks/hooks.json"` to reference external file.

---

## 7. Marketplace (`marketplace.json` at `.claude-plugin/marketplace.json`)

### Structure
```json
{
  "name": "marketplace-name",
  "owner": {"name": "Team", "email": "..."},
  "metadata": {
    "description": "...",
    "version": "1.0.0",
    "pluginRoot": "./plugins"
  },
  "plugins": [
    {
      "name": "plugin-name",
      "source": "./local/path" | {source fields},
      "description": "...",
      "version": "1.0.0",
      "strict": true|false
    }
  ]
}
```

### Plugin Source Types
| Type | Syntax | Example |
|------|--------|---------|
| Relative path | `"./path"` | `"./plugins/my-plugin"` |
| GitHub | `{"source": "github", "repo": "owner/repo", "ref": "v2.0", "sha": "..."}` | |
| Git URL | `{"source": "url", "url": "https://...", "ref": "...", "sha": "..."}` | GitLab, etc. |
| Git subdir | `{"source": "git-subdir", "url": "...", "path": "tools/plugin", "ref": "...", "sha": "..."}` | Monorepo |
| npm | `{"source": "npm", "package": "@org/plugin", "version": "^2.0.0", "registry": "..."}` | |

**Version in Marketplace vs Manifest:**  
- If both specified, manifest version wins (silently)
- For relative-path plugins, set version in marketplace entry
- For all other sources, set in plugin manifest

### Strict Mode
| Value | Behavior |
|-------|----------|
| `true` (default) | `plugin.json` is authority; marketplace entry supplements |
| `false` | Marketplace entry is entire definition; no `plugin.json` dependencies |

---

## 8. MCP Servers (`.mcp.json` or inline in `plugin.json`)

### Schema
```json
{
  "mcpServers": {
    "server-name": {
      "command": "${CLAUDE_PLUGIN_ROOT}/path/to/binary",
      "args": ["--flag", "${CLAUDE_PLUGIN_ROOT}/config.json"],
      "env": {"VAR": "${CLAUDE_PLUGIN_DATA}/path"},
      "cwd": "${CLAUDE_PLUGIN_ROOT}",
      "transport": "stdio|socket"
    }
  }
}
```

Supports `${CLAUDE_PLUGIN_ROOT}`, `${CLAUDE_PLUGIN_DATA}`, `${user_config.*}`, environment variables.

---

## 9. LSP Servers (`.lsp.json` or inline in `plugin.json`)

### Schema
```json
{
  "go": {
    "command": "gopls",
    "args": ["serve"],
    "extensionToLanguage": {".go": "go"},
    "initializationOptions": {...},
    "settings": {...},
    "transport": "stdio|socket",
    "startupTimeout": 5000,
    "restartOnCrash": true
  }
}
```

Binary must be installed separately; plugin only configures connection. Supports variable substitution.

---

## 10. Monitors (`monitors/monitors.json` or inline in `plugin.json`)

### Schema
```json
[
  {
    "name": "monitor-id",
    "command": "${CLAUDE_PLUGIN_ROOT}/script.sh",
    "description": "What is being watched",
    "when": "always|on-skill-invoke:<skill-name>"
  }
]
```

Supports `${CLAUDE_PLUGIN_ROOT}`, `${CLAUDE_PLUGIN_DATA}`, `${user_config.*}`, environment variables.

---

## 11. Plugin Caching & File Resolution

### Installed vs `--plugin-dir`
- **Marketplace plugins:** Copied to `~/.claude/plugins/cache/{marketplace}/{plugin}/{version}/`
- **`--plugin-dir` plugins:** Used in-place

### Path Traversal Security
- Installed plugins cannot reference `../` paths outside plugin root
- All relative component paths must be within plugin directory
- Symlinks ARE preserved and resolve at runtime

### Persistent Data Directory
Use `${CLAUDE_PLUGIN_DATA}` for files that survive plugin updates (dependencies, generated code, caches).

---

## 12. Auto-Discovery vs Manifest

| Component | Auto-Discovery | Manifest Required |
|-----------|----------------|-------------------|
| Skills | Yes, from `skills/` | No, unless custom path |
| Commands | Yes, from `commands/` | No, unless custom path |
| Agents | Yes, from `agents/` | No, unless custom path |
| Hooks | Yes, from `hooks/hooks.json` | No, unless custom path or inline |
| MCP servers | No | Required: `.mcp.json` or inline |
| LSP servers | No | Required: `.lsp.json` or inline |
| Monitors | Yes, from `monitors/monitors.json` | No, unless custom path |

**No manifest needed** if using all defaults. Manifest becomes optional; plugin name derived from directory.

---

## 13. Known Gotchas & Quirks

| Issue | Behavior | Mitigation |
|-------|----------|-----------|
| **Component directory placement** | Components must be at plugin root, NOT inside `.claude-plugin/` | Only `plugin.json` goes in `.claude-plugin/` |
| **Version precedence** | If `version` in both manifest + marketplace, manifest silently wins | Set version in ONE location only |
| **Hook execution order (multiple writes)** | When multiple PreToolUse hooks return `updatedInput`, last to finish wins (non-deterministic) | Avoid >1 hook modifying same tool input |
| **Custom path replaces default** | Specifying custom `skills` path means default `skills/` is NOT scanned | To keep both: `"skills": ["./skills/", "./custom/"]` |
| **PATH for hook commands** | Hooks inherit parent shell's PATH; no guaranteed additions | Use absolute paths or `${CLAUDE_PLUGIN_ROOT}/bin/` |
| **Working directory for hooks** | Hook runs in session `cwd` (can vary) | Use absolute paths, never rely on relative WD |
| **Shell used for hooks** | Bash or Zsh (depends on user's shell) | Use POSIX-compatible syntax; include shebang |
| **PostToolUse cannot undo** | Tool already executed; hook runs after | Use PreToolUse to prevent, PostToolUse to log/react |
| **JSON output ignored on non-zero exit** | Only parsed on exit 0 | Use exit 0 for JSON decisions, exit 2 for blocking |
| **Symlinks in cache** | Dereferenced at install time, symlinks preserved and resolve at runtime | Safe to use symlinks for external file sharing |

---

## 14. CLI Commands (Non-Interactive)

```bash
claude plugin install <plugin> --scope user|project|local
claude plugin uninstall <plugin> --scope user|project|local --keep-data
claude plugin enable <plugin> --scope user|project|local
claude plugin disable <plugin> --scope user|project|local
claude plugin update <plugin> --scope user|project|local|managed
claude plugin list [--json] [--available]
claude plugin marketplace add <source> --scope user|project|local --sparse paths...
claude plugin marketplace list [--json]
claude plugin marketplace remove <name>
claude plugin marketplace update [name]
claude plugin validate .
```

---

## Unresolved Questions

1. **Hook environment:** Does `.zshrc`/`.bashrc` source on every hook invocation? (Docs mention profil sourcing causes JSON parse failure if unconditional echo.)
2. **Marketplace.json auto-discovery:** Is `.claude-plugin/marketplace.json` auto-discovered, or must it be explicitly referenced?
3. **Plugin name uniqueness:** Are plugin names globally unique, or only within a marketplace?
4. **Hooks timeout behavior:** What happens if a hook exceeds the 10-minute default timeout mid-execution? (Docs mention configurable `timeout` field but not exact behavior on timeout.)
5. **MCP/LSP variable substitution scope:** Does `${user_config.*}` expansion work in inline `mcpServers`/`lspServers` objects in `plugin.json`, or only in referenced files?
6. **Agent tool isolation:** When `disallowedTools` is set on an agent, does it completely prevent tool availability, or just hide from Claude's defaults?
7. **Marketplace version field:** Docs say "If also set in marketplace entry, plugin.json takes priority" — does this mean marketplace version is always checked/compared, or can it be safely omitted?

---

## Summary for ValidationForge Audit

**Use this checklist when auditing `validationforge` plugin:**

- [ ] `.claude-plugin/plugin.json` exists and is valid JSON
- [ ] `name` field is kebab-case, no spaces
- [ ] All component paths (skills, agents, hooks, etc.) start with `./` and are relative to plugin root
- [ ] No components inside `.claude-plugin/` directory (only manifest there)
- [ ] If custom paths specified, defaults are not also scanned (unless explicitly included in array)
- [ ] `version` field is semantic versioning format
- [ ] Hook event names match official list (case-sensitive)
- [ ] Hook matchers are valid regex or literal tool names
- [ ] Hook commands have executable bit set (`chmod +x`)
- [ ] Hook input/output JSON schema matches official format
- [ ] All `${CLAUDE_PLUGIN_ROOT}` and `${CLAUDE_PLUGIN_DATA}` references are in supported fields
- [ ] Agent frontmatter uses only supported fields (no `hooks`, `mcpServers`, `permissionMode`)
- [ ] Skill SKILL.md has valid YAML frontmatter with `description` field
- [ ] Marketplace.json (if present) uses valid plugin source syntax
- [ ] No `../` paths in component or marketplace definitions
- [ ] MCP/LSP servers have required fields (`command`, `extensionToLanguage` for LSP)
