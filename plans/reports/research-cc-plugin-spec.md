# Claude Code Plugin Spec Reference

## Plugin Manifest (.claude-plugin/plugin.json)

### Required Fields
- **name** (string): Unique plugin identifier in kebab-case format
  - Pattern: `/^[a-z][a-z0-9]*(-[a-z0-9]+)*$/`
  - Must start with lowercase letter
  - Only lowercase letters, numbers, hyphens allowed
  - No spaces or special characters

### Recommended Fields
- **version** (string): Semantic versioning format (MAJOR.MINOR.PATCH)
  - Example: "1.0.0"
- **description** (string): Brief explanation of plugin purpose
- **author** (object): Author metadata
  - name (string)
  - email (string)
  - url (string)
- **homepage** (string): Plugin documentation URL
- **repository** (string): GitHub or source repository URL
- **license** (string): License identifier (e.g., "MIT")
- **keywords** (array): String array for categorization and discovery

### Validation Rules
- JSON syntax must be valid
- Required fields must be present and non-empty
- Version must follow MAJOR.MINOR.PATCH if present
- All component paths must be relative with `./` prefix
- Referenced paths must exist and be accessible
- Unknown fields generate warnings but don't fail validation

**Source:** https://github.com/anthropics/claude-code/blob/main/plugins/plugin-dev/skills/plugin-structure/SKILL.md

---

## Component Paths Configuration

### Path Rules (All Required)
1. Must be relative to plugin root (not absolute)
2. Must start with `./` prefix
3. Cannot use `../` for parent directory navigation
4. Must use forward slashes only (even on Windows)
5. Cannot mix absolute and relative paths in same manifest

### Custom Path Configuration
- Plugins can specify custom locations via manifest fields
- Custom paths supplement default directories (both are loaded)
- Supports arrays for multiple locations per component type
- Default directories checked automatically:
  - `commands/` for slash commands
  - `agents/` for subagents
  - `skills/` for agent skills
  - `hooks/` for hooks.json

### Valid Examples
```json
{
  "commands": "./commands",
  "agents": "./src/agents",
  "skills": ["./skills", "./extended-skills"],
  "hooks": "./config/hooks.json"
}
```

**Source:** https://github.com/anthropics/claude-code/blob/main/plugins/plugin-dev/skills/plugin-structure/references/manifest-reference.md

---

## Plugin Directory Structure

### Standard Layout
```
plugin-name/
├── .claude-plugin/
│   └── plugin.json                 # Required: Plugin manifest
├── commands/                       # Slash commands (.md files)
│   ├── review.md                   # /review command
│   └── deploy.md                   # /deploy command
├── agents/                         # Subagent definitions (.md files)
│   ├── code-reviewer.md
│   └── security-auditor.md
├── skills/                         # Agent skills (subdirectories)
│   └── skill-name/
│       ├── SKILL.md                # Required for each skill
│       ├── scripts/                # Executable code (optional)
│       ├── references/             # Documentation (optional)
│       └── assets/                 # Resource files (optional)
├── hooks/
│   └── hooks.json                  # Event handler configuration
├── .mcp.json                       # MCP server definitions (optional)
├── scripts/                        # Helper scripts and utilities
└── README.md                       # Plugin documentation
```

### Component Discovery
- All `.md` files in `commands/` auto-discovered as slash commands
- All `.md` files in `agents/` auto-discovered as subagents
- All subdirectories in `skills/` must contain SKILL.md
- Custom paths loaded in addition to defaults (no conflicts)

**Source:** https://github.com/anthropics/claude-code/blob/main/plugins/plugin-dev/skills/plugin-structure/SKILL.md

---

## Hooks (hooks/hooks.json + Scripts)

### Hook Events
Supported lifecycle events:
- **PreToolUse**: Before Claude executes a tool
- **PostToolUse**: After tool execution completes
- **SessionStart**: When a new session begins
- **UserPromptSubmit**: When user submits a prompt
- **Stop**: When agent considers completing task
- **TaskCompleted**: After task finishes (implicit)
- **TeammateIdle**: When waiting for user input

### hooks.json Schema

```json
{
  "description": "Optional plugin description",
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit|Bash",
        "hooks": [
          {
            "type": "command" | "prompt",
            "command": "bash ${CLAUDE_PLUGIN_ROOT}/script.sh",
            "prompt": "Validation prompt text",
            "timeout": 30
          }
        ]
      }
    ],
    "PostToolUse": [...],
    "SessionStart": [...],
    "UserPromptSubmit": [...],
    "Stop": [...]
  }
}
```

### Matcher Syntax
- Tool name strings: `"Bash"`, `"Write"`, `"Read"`, `"Grep"`
- Pipe-separated alternatives: `"Write|Edit"` (OR logic)
- Wildcard: `"*"` (matches all)
- Regex patterns supported for precise matching

### Hook Types

#### Command Hooks
- Execute shell scripts/commands
- Receive JSON on stdin with structure:
  ```json
  {
    "tool_name": "string",
    "tool_input": { "...": "..." }
  }
  ```
- Exit codes:
  - `0`: Pass/allow (for PreToolUse)
  - `1`: Error (fails hook execution)
  - `2`: Block with warning (for PreToolUse)
- Output via stderr for messages
- Output via stdout for structured responses

#### Prompt Hooks
- Send query to Claude LLM
- Timeout in seconds (1-300)
- For Stop hooks, expect decision JSON:
  ```json
  {
    "decision": "approve|block",
    "reason": "Explanation",
    "systemMessage": "Additional context"
  }
  ```

### Environment Variables
- `${CLAUDE_PLUGIN_ROOT}`: Absolute path to plugin root directory
- Resolved at runtime before script execution

### Special Variables
- `$TRANSCRIPT_PATH`: Path to full session transcript (in Stop hooks)

**Source:** https://github.com/anthropics/claude-code/blob/main/plugins/plugin-dev/skills/hook-development/SKILL.md

---

## Skills (SKILL.md Frontmatter)

### SKILL.md Structure
Every skill requires `skill-name/SKILL.md` file with YAML frontmatter.

### Frontmatter Fields

#### Required
- **name** (string): Skill identifier (no regex restriction noted)
  - Human-readable name
  - Used in Skill tool invocation
- **description** (string): When and why to use this skill
  - Third-person format
  - Include specific trigger phrases users would say
  - Concrete, not generic
  - Examples: "create a hook", "add a PreToolUse hook"

#### Optional
- **version** (string): Semantic version (default: not required)

### Description Best Practices
```yaml
description: This skill should be used when the user asks to "specific phrase 1", "specific phrase 2", "specific phrase 3". Include exact phrases users would say. Be concrete and specific.
```

### Bundled Resources
Automatic discovery in skill directory:
```
skill-name/
├── SKILL.md                 # Frontmatter + instructions (1500-2000 words)
├── scripts/                 # Executable code
│   ├── script.sh
│   └── tool.py
├── references/              # Detailed documentation
│   ├── patterns.md
│   └── advanced.md
└── assets/                  # Resource files
    ├── template.json
    └── example.txt
```

### Progressive Disclosure (Context Efficiency)
- **Level 1 (Always Loaded):** Name + description metadata (~100 words)
- **Level 2 (On Trigger):** SKILL.md body with core instructions (<5000 words)
- **Level 3 (As Needed):** References and scripts (unlimited, loaded on demand)

### Skill Validation
- Each skill must have `SKILL.md` with frontmatter
- Frontmatter must include `name` and `description` fields
- Referenced files in `scripts/`, `references/`, `assets/` must exist
- Validator checks directory structure integrity

### Skill Invocation (Skill Tool)
- User triggers: "Use skill xyz"
- Claude uses `Skill` tool with skill name parameter
- Name lookup matches against skill metadata
- Triggered SKILL.md loads into context automatically

**Source:** https://github.com/anthropics/claude-code/blob/main/plugins/plugin-dev/skills/skill-development/SKILL.md

---

## Commands (Slash Commands)

### File Format
Markdown files in `commands/` directory with optional YAML frontmatter.

### Frontmatter Fields (All Optional)
- **description** (string): Brief description for UI/help
- **argument-hint** (string): Expected arguments for autocomplete
  - Format: `[arg1] [arg2] [arg3]`
  - Descriptive names preferred (e.g., `[source-branch]` not `[arg1]`)
  - Hint order must match positional arguments
  - Concise but clear
- **allowed-tools** (string): Comma-separated tool restrictions
  - Examples: `Read, Write, Bash(git:*)`
  - Tool name with optional namespace
  - If omitted, all tools available
- **model** (string): Model override for command execution
  - Options: `sonnet`, `opus`, `haiku`, `inherit`
  - Default inherits parent model

### Command Prompt Content
Markdown text after frontmatter.

### Dynamic Arguments
Three interpolation styles:

#### Positional Arguments
```markdown
---
argument-hint: [pr-number] [priority]
---

Review PR #$1 with priority $2
```
- `$1`, `$2`, `$3` ... map to argument positions
- Each position references one argument

#### All Arguments as String
```markdown
---
argument-hint: [issue-number]
---

Fix issue #$ARGUMENTS
```
- `$ARGUMENTS` captures all args as single string
- Useful when entire input is one cohesive value

#### File References
```markdown
Analyze file @path/to/file
```
- `@` prefix indicates file path
- File read into context automatically

#### Bash Execution
```markdown
Run: !`command here`
Run: !`${CLAUDE_PLUGIN_ROOT}/bin/script.sh $1 $2`
```
- `` !` `` prefix executes command
- Exit code and output captured
- `${CLAUDE_PLUGIN_ROOT}` resolves at runtime

### Command Discovery
- File name maps to command: `review.md` → `/review`
- Namespaced structure supported:
  ```
  commands/
  ├── ci/
  │   ├── build.md    # /build (ci namespace)
  │   └── test.md     # /test (ci namespace)
  └── git/
      ├── commit.md   # /commit (git namespace)
  ```

**Source:** https://github.com/anthropics/claude-code/blob/main/plugins/plugin-dev/skills/command-development/SKILL.md

---

## Subagents (agents/)

### File Format
Markdown files in `agents/` directory with YAML frontmatter and system prompt.

### Frontmatter Fields

#### Required
- **name** (string): Unique agent identifier
  - Kebab-case format (lowercase, hyphens, numbers)
  - Pattern similar to plugin names: `/^[a-z][a-z0-9]*(-[a-z0-9]+)*$/`
  - 3-50 characters typical
  - Descriptive (avoid "helper", "assistant")
  - Examples: `code-reviewer`, `test-generator`, `api-docs-writer`
  
- **description** (string): Triggering conditions and usage
  - Start with: "Use this agent when [conditions]"
  - Include 2-3 `<example>` blocks with format:
    ```markdown
    <example>
    Context: [Scenario description]
    user: "[User says this]"
    assistant: "[Claude responds and uses agent]"
    <commentary>
    [Why agent is appropriate]
    </commentary>
    </example>
    ```
  - Examples show when/why to invoke agent automatically

#### Optional
- **model** (string): Model selection
  - `inherit`: Use parent model (recommended)
  - `sonnet`: Claude Sonnet
  - `opus`: Claude Opus
  - `haiku`: Claude Haiku
  - Default: inherit
  
- **color** (string): UI color identifier
  - Example: `blue`, `green`, `red`, etc.
  - For visual distinction in UI
  
- **tools** (array): Allowed tools for this agent
  - Example: `["Read", "Write", "Grep", "Bash"]`
  - If omitted, all tools available
  - Restrict to specific tools for focused agents

### System Prompt (Body)
Markdown content after frontmatter defining agent behavior.

### Agent Invocation Patterns

#### Auto-Invocation
Agent triggered automatically based on description examples:
- User writes code → example shows code-reviewer auto-invoked
- User requests PR review → example shows pr-reviewer auto-invoked
- Session starts → implicit SessionStart conditions

#### Explicit Invocation
Claude explicitly calls agent with Task() or Skill tool when:
- User directly requests the agent
- Workflow explicitly routes to agent
- Fallback handling needed

### Agent Alignment
- Must reference CLAUDE.md for project context
- System prompt should align with project standards
- Inherit parent model for context efficiency
- Scope tool access to prevent unnecessary complexity

### Agent Validation
- Name field must use kebab-case
- Description must include examples with proper format
- Examples must show agent invocation (not just response)
- All referenced tools must exist

**Source:** https://github.com/anthropics/claude-code/blob/main/plugins/plugin-dev/skills/agent-development/SKILL.md

---

## Rules (CLAUDE.md / AGENTS.md)

### CLAUDE.md (Project-Level Rules)
- Markdown file at project root or `.claude/` directory
- Injected into every session context automatically
- Defines project-specific standards, conventions, patterns
- Takes precedence over plugin rules
- No executable semantics (informational only)

### AGENTS.md (Team/Org Rules)
- Similar to CLAUDE.md but organization-scoped
- Injected when available
- Lower precedence than project CLAUDE.md

### Rule Injection Precedence (Highest to Lowest)
1. Project CLAUDE.md (if exists)
2. Plugin SessionStart hooks
3. Org AGENTS.md (if exists)
4. Plugin default rules

### Semantics
- Rules are pure context injection
- Claude reads and follows them
- No automatic enforcement mechanism
- Hooks separate for automated validation/enforcement

### SessionStart Hook as Alternative
- Plugins can inject context via SessionStart hook
- Functionally similar to CLAUDE.md
- More flexible for distribution
- Supports parametrization

**Source:** https://github.com/anthropics/claude-code/blob/main/plugins/learning-output-style/README.md

---

## Plugin Distribution

### Local Installation
1. Copy plugin to user's plugins directory
2. `~/.claude/plugins/plugin-name/`
3. Claude Code auto-discovers on next start
4. Manifest validation performed immediately

### NPM Package Distribution
- Package plugin as npm module
- Include `.claude-plugin/plugin.json` in package
- Include component directories and hooks
- Metadata in package.json

### Marketplace.json (If Applicable)
- Metadata file for plugin marketplace
- Not part of core spec, used for discovery
- Version information
- Category and tags

### Package Contents Required
- `.claude-plugin/plugin.json` (manifest)
- Component directories (commands, agents, skills, hooks)
- Hook scripts and references
- LICENSE file
- README.md for documentation

### Installation Methods
1. Manual copy to `.claude/plugins/`
2. NPM package installation
3. Git clone via plugin installation tools
4. Plugin marketplace install (if available)

**Source:** https://github.com/anthropics/claude-code/blob/main/plugins/plugin-dev/skills/plugin-structure/SKILL.md

---

## Summary: Top 15 Conformance Requirements

ValidationForge must conform to:

1. **Plugin name** must be kebab-case matching `/^[a-z][a-z0-9]*(-[a-z0-9]+)*$/`
2. **.claude-plugin/plugin.json** required with valid JSON syntax and name field
3. **Version field** must follow MAJOR.MINOR.PATCH semantic versioning if present
4. **All paths** in manifest must be relative, start with `./`, use forward slashes, never `../`
5. **Component directories** (commands/, agents/, skills/, hooks/) auto-discovered at root level
6. **Every skill** requires `skill-name/SKILL.md` with YAML frontmatter including name and description
7. **Skill descriptions** must be third-person, concrete, include specific trigger phrases
8. **Every agent** requires name (kebab-case) and description with 2-3 `<example>` blocks showing trigger conditions
9. **Hooks.json** schema must specify event type, matcher (tool name or `*`), and hook array with type (command/prompt)
10. **Hook scripts** receive stdin JSON with tool_name and tool_input; exit codes: 0=pass, 1=error, 2=block
11. **Hook commands** must use `${CLAUDE_PLUGIN_ROOT}` for portable path references
12. **Slash commands** (.md files) support optional YAML frontmatter with description, argument-hint, allowed-tools, model
13. **Command arguments** interpolate via `$1`, `$2`, ... for positional args or `$ARGUMENTS` for all args
14. **Plugin validation** checks JSON syntax, required fields, path existence, semantic versioning, component structure
15. **CLAUDE.md rules** injected into context (informational only, no exec semantics); SessionStart hooks as alternative

---

## Citations Index

- Plugin manifest: https://github.com/anthropics/claude-code/blob/main/plugins/plugin-dev/skills/plugin-structure/SKILL.md
- Validation: https://github.com/anthropics/claude-code/blob/main/plugins/plugin-dev/agents/plugin-validator.md
- Paths: https://github.com/anthropics/claude-code/blob/main/plugins/plugin-dev/skills/plugin-structure/references/manifest-reference.md
- Hooks: https://github.com/anthropics/claude-code/blob/main/plugins/plugin-dev/skills/hook-development/SKILL.md
- Skills: https://github.com/anthropics/claude-code/blob/main/plugins/plugin-dev/skills/skill-development/SKILL.md
- Commands: https://github.com/anthropics/claude-code/blob/main/plugins/plugin-dev/skills/command-development/SKILL.md
- Agents: https://github.com/anthropics/claude-code/blob/main/plugins/plugin-dev/skills/agent-development/SKILL.md
- Rules: https://github.com/anthropics/claude-code/blob/main/plugins/learning-output-style/README.md
- Hook stdin schema: https://context7.com/anthropics/claude-code/llms.txt
