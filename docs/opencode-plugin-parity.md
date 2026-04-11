# OpenCode Plugin Parity

This document tracks which ValidationForge primitives are surfaced by the OpenCode plugin (`.opencode/plugins/validationforge/`) and which remain Claude-Code-only.

## Verification Status

| Verification type | Status | Evidence |
|---|---|---|
| Static structural verification | **PASS** | `bash scripts/verify-opencode-plugin.sh` — 11/11 checks pass |
| Live-session plugin load | **Not verified** | Requires running OpenCode session; see README.md Known Limitations #6 |
| Runtime hook dispatch | **Not verified** | Requires live OpenCode tool invocation |
| `/validate` slash command execution in OpenCode | **Not verified** | Requires live session with plugin loaded |

Run `bash scripts/verify-opencode-plugin.sh` to reproduce the static verification.

## Primitive Coverage Matrix

| Primitive | Claude Code | OpenCode | Notes |
|---|---|---|---|
| Skills (48) | Loaded via `.claude-plugin/plugin.json` | Shared via `commands/` directory reference | OpenCode does not have a `skills/` equivalent; skill instructions are embedded in command prompts when invoked |
| Commands (17) | Loaded via `commands/*.md` | Discoverable via command reuse pattern | Claude-Code-native slash commands are prompt files; OpenCode reads the same files |
| Hooks (9 scripts) | Registered via `hooks/hooks.json` | Re-implemented in `index.ts` as `permission.ask`, `tool.execute.after`, `shell.env` handlers | Patterns sourced from shared `patterns.ts` (single source of truth); `patterns.js` bridges CC hooks |
| Agents (5) | Loaded via `agents/*.md` | **Not surfaced** | OpenCode plugin model does not expose a subagent registry matching Claude Code's; agent definitions remain CC-only |
| Rules (8) | Installed to `.claude/rules/` or `~/.claude/rules/` | **Not surfaced** | Rules are enforced by Claude Code context injection, not an OpenCode concept |
| Custom MCP-like tools | N/A | `vf_validate`, `vf_check_evidence` registered directly in the plugin | OpenCode-only — exposes ValidationForge pipeline entrypoints as first-class tools |

## What the OpenCode Plugin Provides

The OpenCode plugin (`index.ts`, 161 lines) registers:

1. **Two custom tools** (`vf_validate`, `vf_check_evidence`) — callable directly from the agent loop inside OpenCode sessions.
2. **Three hook handlers**:
   - `permission.ask` — intercepts file-write requests, denies writes whose path matches `isBlockedTestFile` (test/mock/spec patterns)
   - `tool.execute.after` — post-tool observer for reminding about validation discipline
   - `shell.env` — injects VF-aware environment variables into shell calls
3. **Shared pattern enforcement** — imports from `patterns.ts` (the same source used by `hooks/patterns.js` in Claude Code, via a CommonJS bridge)

## Known Limitations

1. **Never loaded in a live OpenCode session from this repository's test environment.** The `verify-opencode-plugin.sh` script confirms the plugin *can* load (imports resolve, hook names match the OpenCode plugin API, JSON is valid), but does not prove it *has* loaded.
2. **Agents and rules are not surfaced.** OpenCode users cannot invoke the 5 Claude-Code agents or benefit from the 8 enforcement rules that require Claude-Code-specific rule injection.
3. **Skill auto-loading does not apply.** In Claude Code, skills with matching triggers load automatically. In OpenCode, skill content must be referenced manually by commands.
4. **No `${CLAUDE_PLUGIN_ROOT}` equivalent.** Path resolution for OpenCode hook handlers uses the plugin's own `directory` parameter; Claude Code's plugin-root variable is not available.

## How to Run a Live Verification (requires OpenCode)

If you have OpenCode installed:

```bash
cd .opencode/plugins/validationforge
npm install
```

Then start OpenCode in a project directory and confirm:
1. The plugin is listed in OpenCode's plugin registry
2. `vf_validate` and `vf_check_evidence` appear as available tools
3. Attempting to write a file named `foo.test.ts` triggers the permission.ask hook and is denied
4. `/validate` (if surfaced by OpenCode's command discovery) runs to verdict

Record findings in `e2e-evidence/opencode-live-session/` and update this document.

## References

- Verification script: [`scripts/verify-opencode-plugin.sh`](../scripts/verify-opencode-plugin.sh)
- Plugin entrypoint: [`.opencode/plugins/validationforge/index.ts`](../.opencode/plugins/validationforge/index.ts)
- Shared patterns: [`.opencode/plugins/validationforge/patterns.ts`](../.opencode/plugins/validationforge/patterns.ts)
- CC-side bridge: [`hooks/patterns.js`](../hooks/patterns.js)
- README Known Limitations: [`../README.md`](../README.md#known-limitations) — item #6
