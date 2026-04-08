# ValidationForge Dual-Target Architecture

## Overview

ValidationForge targets both Claude Code and OpenCode. The architecture separates **shared content** (portable markdown) from **runtime adapters** (platform-specific hook implementations).

```
validationforge/
├── skills/              ← SHARED: identical SKILL.md works in both
├── commands/            ← SHARED: identical .md works in both
├── rules/               ← SHARED: identical .md works in both
├── agents/              ← SHARED: identical .md works in both
├── config/              ← SHARED: enforcement level configs
│
├── .claude-plugin/      ← CC ADAPTER: plugin.json, marketplace.json
├── hooks/               ← CC ADAPTER: Node.js scripts + hooks.json
│
├── .opencode/           ← OC ADAPTER: TypeScript plugin + config
│   ├── plugins/
│   │   └── validationforge/
│   │       ├── index.ts       ← Plugin entry point
│   │       ├── hooks.ts       ← Hook implementations
│   │       ├── tools.ts       ← Custom validation tools
│   │       ├── patterns.ts    ← Shared pattern constants
│   │       ├── package.json
│   │       └── tsconfig.json
│   ├── skill/           ← Symlinks to ../skills/*
│   └── command/         ← Symlinks to ../commands/*
│
└── opencode.json        ← OC config (plugin registration)
```

## What Ports 1:1 (Zero Changes)

| Primitive | CC Location | OC Location | Notes |
|-----------|-------------|-------------|-------|
| Skills | `skills/*/SKILL.md` | `.opencode/skill/*/SKILL.md` | Symlink or copy. Same frontmatter format. |
| Commands | `commands/*.md` | `.opencode/command/*.md` | Symlink or copy. Same frontmatter. OC adds `$1`/`$2` arg syntax. |
| Rules | `CLAUDE.md` | `AGENTS.md` | Keep both files with same content. |
| Agents | `agents/*.md` | Same or `.opencode/agents/` | CC agent format works in OC. |

## What Requires Runtime Adapters

### Hooks: CC Node.js Scripts → OC TypeScript Plugin

CC hooks are standalone Node.js scripts that:
1. Read JSON from stdin
2. Pattern-match against tool_input/tool_result
3. Output JSON to stdout (hookSpecificOutput)
4. Exit with code 0 (allow) or 2 (block)

OC hooks are async TypeScript functions that:
1. Receive typed `(input, output)` parameters
2. Mutate the `output` object directly
3. Return void (no exit codes, no stdin/stdout)

### Mapping Table

| CC Hook Script | CC Event | OC Hook | Adaptation |
|---------------|----------|---------|------------|
| block-test-files.js | PreToolUse (Write\|Edit) | `permission.ask` | Check input.tool + file path, set `output.status = "deny"` |
| evidence-gate-reminder.js | PreToolUse (TaskUpdate) | `tool.execute.before` | Check tool name + args.status, inject context via output mutation |
| validation-not-compilation.js | PostToolUse (Bash) | `tool.execute.after` | Check output for build patterns, append to output.metadata |
| completion-claim-validator.js | PostToolUse (Bash) | `tool.execute.after` | Check output for completion patterns, verify evidence dir |
| validation-state-tracker.js | PostToolUse (Bash) | `tool.execute.after` | Detect validation commands, track state |
| mock-detection.js | PostToolUse (Edit\|Write) | `tool.execute.after` | Scan content for mock patterns |
| evidence-quality-check.js | PostToolUse (Edit\|Write) | `tool.execute.after` | Check evidence file content length |

### OC-Only Enhancements (Not Possible in CC)

| Feature | OC Hook | What It Enables |
|---------|---------|-----------------|
| Custom `validate` tool | `tool()` helper | Agent can call `validate(journey, platform)` directly |
| LLM parameter control | `chat.params` | Force lower temperature during validation for determinism |
| System prompt injection | `experimental.chat.system.transform` | Inject iron rules into every conversation |
| Event-driven evidence tracking | `event` | React to file.edited, session.idle for automatic evidence capture |
| Shell environment | `shell.env` | Inject VF_EVIDENCE_DIR, VF_ENFORCEMENT_LEVEL |

## Shared Logic (patterns.ts)

Both CC and OC adapters use the same validation patterns. Extract to a shared module:

```typescript
// patterns.ts — shared between CC hooks and OC plugin

export const TEST_PATTERNS = [
  /\.test\.[jt]sx?$/,
  /\.spec\.[jt]sx?$/,
  /_test\.go$/,
  /test_[^/]+\.py$/,
  /Tests?\.swift$/,
  // ... full list
];

export const MOCK_PATTERNS = [
  /jest\.mock\(/,
  /sinon\.stub\(/,
  /unittest\.mock/,
  // ... full list
];

export const BUILD_PATTERNS = [
  /build succeeded/i,
  /compiled successfully/i,
  // ... full list
];

export const COMPLETION_PATTERNS = [
  /all.*pass/i,
  /tests.*pass/i,
  /successfully deployed/i,
  /implementation complete/i,
];

export const VALIDATION_COMMAND_PATTERNS = [
  /playwright/i,
  /lighthouse/i,
  /simctl/i,
  /curl.*localhost/i,
  // ... full list
];

export const ALLOWLIST = [
  /e2e-evidence/,
  /validation-evidence/,
];
```

CC hooks `require('./patterns.js')`. OC plugin `import { TEST_PATTERNS } from './patterns'`.

## Installation

### Claude Code
```bash
/plugin marketplace add ./validationforge  # or from GitHub
/plugin install validationforge@validationforge
# Restart Claude Code
```

### OpenCode
```bash
# Option A: Local plugin
cp -r validationforge/.opencode/plugins/validationforge ~/.config/opencode/plugins/

# Option B: npm (when published)
# In opencode.json:
{
  "plugin": ["validationforge"]
}
```

## Build Script

A `scripts/sync-opencode.sh` script symlinks shared content:

```bash
#!/bin/bash
# Sync shared content to .opencode/ directories
mkdir -p .opencode/skill .opencode/command

for skill in skills/*/; do
  name=$(basename "$skill")
  ln -sf "../../$skill" ".opencode/skill/$name"
done

for cmd in commands/*.md; do
  name=$(basename "$cmd")
  ln -sf "../../$cmd" ".opencode/command/$name"
done

echo "Synced $(ls .opencode/skill | wc -l) skills and $(ls .opencode/command | wc -l) commands"
```

## Testing Both Targets

```bash
# CC: Install locally and test
/plugin install validationforge@validationforge
/validate  # Should work

# OC: Load plugin and test
opencode  # With opencode.json pointing to local plugin
/validate  # Should work identically
```

## Maintenance

When adding a new skill or command:
1. Create in the shared `skills/` or `commands/` directory
2. Run `scripts/sync-opencode.sh` to update symlinks
3. Both CC and OC get the new primitive automatically

When adding a new hook:
1. Add the shared pattern to `patterns.ts`
2. Implement CC version in `hooks/<name>.js`
3. Implement OC version in `.opencode/plugins/validationforge/hooks.ts`
4. Register CC hook in `hooks/hooks.json`
5. OC hook is auto-registered by the plugin return object
