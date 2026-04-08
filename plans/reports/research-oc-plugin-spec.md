# OpenCode Plugin Spec Reference

## 1. Plugin SDK (@opencode-ai/plugin)

### Plugin Type Signature
```typescript
export type Plugin = (input: PluginInput, options?: PluginOptions) => Promise<Hooks>

export type PluginInput = {
  client: ReturnType<typeof createOpencodeClient>
  project: Project
  directory: string
  worktree: string
  serverUrl: URL
  $: BunShell
}

export type PluginModule = {
  id?: string
  server: Plugin
  tui?: never
}
```

### Basic Plugin Structure
```typescript
import type { Plugin } from "@opencode-ai/plugin"

export const MyPlugin: Plugin = async ({ project, client, $, directory, worktree, serverUrl }) => {
  return {
    // Hook implementations go here
  }
}
```

## 2. Context Object

| Property | Type | Purpose |
|----------|------|---------|
| `client` | OpenCode SDK client | Interact with AI via `client.app.log()`, structured logging |
| `project` | Project info | Current project metadata |
| `directory` | string | Current working directory |
| `worktree` | string | Git worktree path |
| `serverUrl` | URL | OpenCode server URL |
| `$` | Bun shell API | Execute shell commands via Bun's shell API |

## 3. Lifecycle Hooks

| Hook Name | Input | Output | Purpose |
|-----------|-------|--------|---------|
| `event` | `{ event: Event }` | void | Subscribe to any OpenCode event (session, file, message, tool, etc.) |
| `config` | `Config` | void | Modify configuration at runtime |
| `chat.message` | `{ sessionID, agent?, model?, messageID?, variant? }` | `{ message: UserMessage, parts: Part[] }` | Intercept new messages |
| `chat.params` | `{ sessionID, agent, model, provider, message }` | `{ temperature, topP, topK, maxOutputTokens, options }` | Customize LLM parameters |
| `chat.headers` | `{ sessionID, agent, model, provider, message }` | `{ headers: Record<string, string> }` | Add custom HTTP headers |
| `permission.ask` | `Permission` | `{ status: "ask" \| "deny" \| "allow" }` | Control permission prompts |
| `command.execute.before` | `{ command, sessionID, arguments }` | `{ parts: Part[] }` | Intercept command execution |
| `tool.execute.before` | `{ tool, sessionID, callID }` | `{ args: any }` | Modify tool arguments pre-execution |
| `tool.execute.after` | `{ tool, sessionID, callID, args }` | `{ title, output, metadata }` | Transform tool results |
| `tool.definition` | `{ toolID }` | `{ description, parameters }` | Modify tool definitions sent to LLM |
| `shell.env` | `{ cwd, sessionID?, callID? }` | `{ env: Record<string, string> }` | Inject environment variables |
| `experimental.chat.messages.transform` | `{}` | `{ messages: { info: Message, parts: Part[] }[] }` | Transform all chat messages |
| `experimental.chat.system.transform` | `{ sessionID?, model }` | `{ system: string[] }` | Customize system prompts |
| `experimental.session.compacting` | `{ sessionID }` | `{ context: string[], prompt?: string }` | Inject context or replace compaction prompt |
| `experimental.text.complete` | `{ sessionID, messageID, partID }` | `{ text: string }` | Transform text completion |

## 4. Custom Tools via tool() Helper

### Tool Definition
```typescript
import { type Plugin, tool } from "@opencode-ai/plugin"

export const CustomToolsPlugin: Plugin = async (ctx) => {
  return {
    tool: {
      mytool: tool({
        description: "What this tool does",
        args: {
          foo: tool.schema.string(),
          count: tool.schema.number().optional(),
          // Zod schema methods: string(), number(), boolean(), etc.
        },
        async execute(args, context) {
          // context: { directory, worktree, sessionID?, messageID?, agent?, abort? }
          return `Result: ${args.foo}`
        },
      }),
    },
  }
}
```

### Tool Context (execute function parameter)
- `directory`: Current working directory
- `worktree`: Git worktree path
- `sessionID?`: Session identifier
- `messageID?`: Message identifier
- `agent?`: Current agent name
- `abort?`: AbortSignal for cancellation

## 5. opencode.json Configuration

```json
{
  "$schema": "https://opencode.ai/config.json",
  "model": "anthropic/claude-sonnet-4-5",
  "small_model": "anthropic/claude-haiku-4-5",
  "plugin": [
    "opencode-helicone-session",
    "@my-org/custom-plugin",
    ["local-plugin-path", { "option": "value" }]
  ],
  "mcp": {
    "my-mcp": {
      "type": "local",
      "command": ["npx", "-y", "my-mcp-command"],
      "enabled": true
    }
  },
  "tools": {
    "write": false,
    "bash": true
  },
  "command": {
    "test": {
      "template": "Run full test suite with coverage",
      "description": "Run tests with coverage",
      "agent": "build",
      "model": "anthropic/claude-haiku-4-5"
    }
  },
  "agent": {
    "plan": {
      "model": "anthropic/claude-haiku-4-20250514"
    }
  }
}
```

### Plugin Loading
```json
{
  "plugin": [
    "npm-package-name",
    "@scoped/npm-package",
    ["./local/path", { "option1": "value1" }]
  ]
}
```

### Plugin Dependencies
Create `~/.config/opencode/package.json`:
```json
{
  "dependencies": {
    "shescape": "^2.1.0",
    "axios": "^1.4.0"
  }
}
```
OpenCode automatically runs `bun install` at startup.

## 6. OpenCode Skills

Located in `.opencode/skill/<name>/SKILL.md`:

```markdown
---
name: my-skill
description: What this skill does
tags: [tag1, tag2]
---

# Skill Implementation

Detailed instructions for the skill...
```

### Key Differences from Claude Code
- OpenCode skills use same `.opencode/skill/` directory structure
- Supports Claude Code `.claude/skills/` for backward compatibility
- Skills are automatically discovered and registered as dynamic tools
- Frontmatter: `name`, `description`, `tags` (OpenCode adds `tags`)

## 7. OpenCode Commands

Located in `.opencode/command/<name>.md`:

```markdown
---
description: What this command does
agent: plan
subtask: true
model: anthropic/claude-sonnet-4-5
---

Command implementation or template...
```

Config-based alternative in `opencode.json`:
```json
{
  "command": {
    "review": {
      "template": "Review @$1 for code quality...",
      "description": "Review code",
      "agent": "plan",
      "model": "anthropic/claude-haiku-4-5"
    }
  }
}
```

### Arguments
- `$ARGUMENTS`: All CLI arguments as a single string
- `$1`, `$2`, etc.: Individual arguments
- Example: `opencode mycommand arg1 arg2` passes to template

## 8. OpenCode Rules (AGENTS.md)

Located in `.opencode/AGENTS.md`:

```markdown
# Agents

## Rules

Precedence: first-match-wins
- Global config → Project config
- Global plugin dir → Project plugin dir
```

Agents defined in AGENTS.md or via config-based agent definitions.

## 9. Plugin Loading Order

1. **Remote config** (`.well-known/opencode`) - organizational defaults
2. **Global config** (`~/.config/opencode/opencode.json`) - user preferences
3. **Custom config** (`$OPENCODE_CONFIG` env var)
4. **Project config** (`opencode.json` in project root)
5. **`.opencode` directories** - agents, commands, plugins, skills
6. **Inline config** (`$OPENCODE_CONFIG_CONTENT` env var)
7. **Managed config** (system admin-controlled settings)
8. **macOS MDM preferences** (highest priority, non-user-overridable)

Later sources override earlier ones for conflicting keys. Non-conflicting settings merge.

### Local vs npm Plugins
- **npm plugins**: Auto-installed via Bun into `~/.cache/opencode/node_modules/`
- **Local plugins**: Loaded from `.opencode/plugins/` and `~/.config/opencode/plugins/`
- Both run in the same process; npm plugins available in config, local plugins auto-discovered

## 10. MCP Server Integration (Separate from Plugins)

Located in `opencode.json` under `mcp` key:

```json
{
  "mcp": {
    "my-local-mcp": {
      "type": "local",
      "command": ["npx", "-y", "my-mcp-server"],
      "environment": { "API_KEY": "secret" },
      "enabled": true,
      "timeout": 5000
    },
    "my-remote-mcp": {
      "type": "remote",
      "url": "https://mcp.example.com",
      "enabled": true,
      "headers": { "Authorization": "Bearer TOKEN" },
      "oauth": {}
    }
  }
}
```

MCP servers are separate from plugins. Both add tools to the LLM, but MCPs use Model Context Protocol standard.

## 11. Plugin Scaffolding

```bash
bunx create-opencode-plugin
```

Generates boilerplate plugin with TypeScript setup.

## 12. Required TypeScript Configuration

```json
{
  "compilerOptions": {
    "module": "preserve",
    "moduleResolution": "bundler",
    "target": "ES2020"
  }
}
```

Node 22+ required for plugins.

## 13. Event Types Available

### Command Events
- `command.executed`

### File Events
- `file.edited`
- `file.watcher.updated`

### Installation Events
- `installation.updated`

### LSP Events
- `lsp.client.diagnostics`
- `lsp.updated`

### Message Events
- `message.part.removed`
- `message.part.updated`
- `message.removed`
- `message.updated`

### Permission Events
- `permission.asked`
- `permission.replied`

### Server Events
- `server.connected`

### Session Events
- `session.created`
- `session.compacted`
- `session.deleted`
- `session.diff`
- `session.error`
- `session.idle`
- `session.status`
- `session.updated`

### Todo Events
- `todo.updated`

### Shell Events
- `shell.env`

### Tool Events
- `tool.execute.after`
- `tool.execute.before`

### TUI Events
- `tui.prompt.append`
- `tui.command.execute`
- `tui.toast.show`

## 14. Comparison: Claude Code vs OpenCode Primitives

| Primitive | Claude Code | OpenCode | Notes |
|-----------|-------------|----------|-------|
| **Plugin Entry** | Export function from `.ts` | Export `Plugin` typed function | OC is strongly typed |
| **Context Param** | `{ project, directory, agent }` | `{ client, project, directory, worktree, serverUrl, $ }` | OC adds client, shell API, server URL |
| **Hook Types** | `PermissionRequest` (1 hook) | 15+ hooks (event, config, chat.*, tool.*, etc.) | OC vastly more extensible |
| **Tool Creation** | Not in plugins, via MCP | `tool()` helper with Zod schema | OC has built-in tool creation |
| **Hooks Styling** | Command string to stdout (JSON) | Async functions with input/output objects | OC is more functional |
| **Config File** | `.claude/config.json` | `opencode.json` + `opencode.jsonc` | Same structure, different names |
| **Plugin Loading** | Automatic from `.claude/plugins/` | `.opencode/plugins/` + npm config | Similar but OC supports npm centrally |
| **Skills Format** | `.claude/skills/SKILL.md` frontmatter | `.opencode/skill/SKILL.md` similar | Nearly identical |
| **Command Format** | `.claude/commands/*.md` | `.opencode/command/*.md` | Nearly identical |
| **MCP Integration** | Via config, separate from plugins | Via config `mcp` key, separate from plugins | Same approach |
| **Shell API** | Not available in plugins | `$` (Bun shell) available in context | OC plugin feature |

## 15. Top 10 Format Differences

1. **Plugin typing**: Claude Code plugins are untyped; OpenCode uses strict `Plugin` type from SDK
2. **Context object**: OC includes `client` (SDK client), `serverUrl`, and `$` (Bun shell); CC doesn't
3. **Hook architecture**: OC has 15+ async hooks with input/output objects; CC has 1 PermissionRequest hook via command string
4. **Tool creation**: OC plugins can define custom tools inline via `tool()` helper; CC cannot
5. **Tool execution context**: OC passes `{ sessionID, messageID, agent, abort }` to tools; CC plugins don't have tool context
6. **Event system**: OC has granular event subscriptions (event hook); CC doesn't expose events to plugins
7. **LLM parameter hooks**: OC has `chat.params` and `chat.headers` hooks; CC doesn't
8. **Hook naming**: OC uses dot notation (`tool.execute.before`); CC uses camelCase (`PermissionRequest`)
9. **Shell integration**: OC provides Bun shell API in context; CC doesn't
10. **Configuration**: OC uses `opencode.json`/`opencode.jsonc`; CC uses `.claude/config.json`

## 16. Porting Strategy: What Ports Cleanly vs Requires Adapters

### Ports Cleanly (1:1 mapping)
- **Skills** (`.claude/skills/` → `.opencode/skill/`) — Same SKILL.md format, auto-discovery works
- **Commands** (`.claude/commands/` → `.opencode/command/`) — Same markdown format, config is similar
- **MCP servers** — Already separate from plugins; no changes needed
- **Permission logic** — `permission.ask` hook directly replaces PermissionRequest
- **File operations** — Same tool names and behavior in both systems
- **Session management** — Similar session concepts, OC exposes more via hooks

### Requires Runtime Adapters
- **Claude Code plugins** → Use wrapper that maps CC hook patterns to OC hooks
- **Custom auth flows** — Migrate from MCP to OpenCode `auth` hook if needed
- **Tool interception** — Rewrite PermissionRequest hooks as `tool.execute.before`
- **Configuration** — Rename `.claude/config.json` to `opencode.json` (schema compatible with manual adjustments)
- **Event handling** — Create `event` hook wrapper to catch events CC plugins had no access to
- **LLM customization** — Migrate from prompt injection to `chat.params` and `experimental.chat.system.transform` hooks
- **Shell commands** — Wrap Bash tool calls; OC's `$` API in context is additional capability, not required

## 17. Citations

- OpenCode Plugins Documentation: https://opencode.ai/docs/plugins/
- OpenCode Config Documentation: https://opencode.ai/docs/config/
- OpenCode MCP Servers: https://opencode.ai/docs/mcp-servers/
- Plugin SDK Type Definitions: https://raw.githubusercontent.com/sst/opencode/dev/packages/plugin/src/index.ts
- Context7: /websites/opencode_ai_plugins (OpenCode Plugins library)
- Context7: /anthropics/claude-code (Claude Code library)

