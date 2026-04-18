# ValidationForge Onboarding Walkthrough

Goal: go from "never heard of VF" to "first /validate verdict" in under 5 minutes on a standard web project.

## Timing Budget (Design Target)

| Step | Time | Cumulative |
|---|---:|---:|
| 1. Install plugin (`install.sh` or local symlink) | 30s | 0:30 |
| 2. Restart Claude Code | 15s | 0:45 |
| 3. Run `bash scripts/vf-setup.sh --standard` | 15s | 1:00 |
| 4. Open a project in Claude Code | 30s | 1:30 |
| 5. Run `/validate` and let pipeline execute | 3:00 | 4:30 |
| **Total** | | **~4:30** |

The 5-minute budget is a **design target**, not an empirically measured value. Actual time depends on project size, platform, and network. See the Known Limitations in the root README.

## Step-by-Step

### 1. Install the plugin

Pick one:

```bash
# Option A — curl (requires published GitHub repo)
curl -fsSL https://raw.githubusercontent.com/krzemienski/validationforge/main/install.sh | bash

# Option B — clone
git clone --depth 1 https://github.com/krzemienski/validationforge ~/.claude/plugins/validationforge

# Option C — local symlink (works without GitHub)
ln -s /path/to/your/local/validationforge ~/.claude/plugins/validationforge
```

The installer copies 8 rules to `~/.claude/rules/vf-*.md` and writes `~/.claude/.vf-config.json` stub.

### 2. Restart Claude Code

Plugins load at session startup. Running the installer in a live session does not activate hooks, skills, or commands until you restart. This is mandatory.

### 3. Run setup in your project

```bash
cd /path/to/your/project
bash ~/.claude/plugins/validationforge/scripts/vf-setup.sh --standard
```

Flags:
- `--strict` — maximum enforcement, no exceptions
- `--standard` — balanced (recommended for most projects)
- `--permissive` — warnings only, no blocking (for teams transitioning from unit tests)
- `--auto` — same as `--standard`

The script:
1. Detects your project platform (`web`, `api`, `cli`, `ios`, `fullstack`, `generic`)
2. Writes `~/.claude/.vf-config.json` with profile + platform
3. Creates `e2e-evidence/` in the current directory
4. Prints a "Next step" suggestion

It is **idempotent** — run it as many times as you want. Each run backs up the previous config to `~/.claude/.vf-config.json.bak`.

### 4. Open your project in Claude Code

Claude Code discovers `e2e-evidence/`, the config, and the plugin's 48 skills + 17 commands automatically on session start.

### 5. Run `/validate`

Type `/validate` in the Claude Code prompt. VF's 7-phase pipeline runs:

```
0. RESEARCH   — Standards, best practices, applicable criteria
1. PLAN       — Journeys, PASS criteria, evidence requirements
2. PREFLIGHT  — Build compiles, services running, MCP servers available
3. EXECUTE    — Run journeys against real system, capture evidence
4. ANALYZE    — Root cause investigation for FAILs
5. VERDICT    — Evidence-backed PASS/FAIL per journey, unified report
6. SHIP       — Production readiness audit, deploy decision
```

Evidence lands in `e2e-evidence/`. The final verdict is a PASS or FAIL report.

## Troubleshooting

### Plugin not loaded after install

**Symptom**: `/validate` is not recognized, no VF skills appear in autocomplete.

**Cause**: Claude Code was not restarted after installation. Plugins load at session startup only.

**Fix**: Fully quit and reopen Claude Code.

### `bash scripts/vf-setup.sh` fails with "cannot create ~/.claude"

**Symptom**: `ERROR: cannot create /Users/you/.claude`

**Cause**: Permission error or home directory differs from `$HOME`.

**Fix**: Create the directory manually: `mkdir -p ~/.claude`, then re-run setup. Or pass a custom path: `--config-path /path/you/control/.vf-config.json`.

### Platform detected as `generic`

**Symptom**: The setup output says "Detected platform: generic" even though your project is a web app.

**Cause**: `scripts/detect-platform.sh` looks for specific signals (`package.json` with `react`/`next`/`vue`, `.xcodeproj`, `go.mod + main.go`, etc.). If your project layout is non-standard, detection falls back to `generic`.

**Fix**: Not a blocker — `/validate` still works on generic projects. To override the detected platform, edit `~/.claude/.vf-config.json` and set `"platform": "web"` (or the correct value) manually.

## Verification Commands

After setup:

```bash
# Config was written
cat ~/.claude/.vf-config.json

# Evidence directory was created
ls -la e2e-evidence/

# Hook functionality verified
node /path/to/validationforge/scripts/verify-hooks.js
```

## What's Next

- Run `/validate-plan` to see the pipeline's journey plan before executing it
- Run `/validate-audit` for read-only analysis without evidence capture
- Read [ARCHITECTURE.md](../ARCHITECTURE.md) for the full pipeline detail
- Read [SKILLS.md](../SKILLS.md) for the 48 skills index
