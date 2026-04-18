# ValidationForge Commands Index

19 slash commands across 2 families.

## Validation Commands (13)

| # | Command | Description |
|---|---------|-------------|
| 1 | `/validate` | Run full end-to-end validation -- detect platform, map journeys, capture evidence, write verdicts. |
| 2 | `/validate-plan` | Analyze codebase and generate a validation plan with PASS criteria -- no execution. |
| 3 | `/validate-audit` | Read-only validation audit -- captures evidence and classifies findings without modifying code. |
| 4 | `/validate-fix` | Fix validation failures and re-validate until all journeys pass (3-strike limit). |
| 5 | `/validate-ci` | Non-interactive CI/CD mode -- auto-execute full validation pipeline with exit codes. |
| 6 | `/validate-team` | Spawn coordinated validation agents across platforms with evidence handoff. |
| 7 | `/validate-team-dashboard` | Aggregate team validation posture into a shared dashboard showing coverage, scores, regressions, and ownership across all registered projects. |
| 8 | `/validate-sweep` | Autonomous validation loop -- detect, validate, fix, re-validate until PASS or max attempts. |
| 9 | `/validate-benchmark` | Benchmark validation coverage, speed, and evidence quality against baseline metrics. |
| 10 | `/validate-consensus` | Multi-agent CONSENSUS validation -- spawns independent validators, synthesizes verdicts, resolves disagreements with confidence scoring. |
| 11 | `/validate-dashboard` | Generate or regenerate the evidence summary dashboard from e2e-evidence/. |
| 12 | `/vf-setup` | Setup and configure ValidationForge for a project or globally. |
| 13 | `/vf-telemetry` | Manage opt-in usage telemetry — enable, disable, show, or check status. |

## Forge Commands (6)

| # | Command | Description | Allowed Tools |
|---|---------|-------------|---------------|
| 14 | `/forge-setup` | Initialize ValidationForge for this project | Read, Write, Edit, Bash, Glob, Grep, Agent |
| 15 | `/forge-plan` | Generate a validation plan with journey discovery and PASS criteria | Read, Write, Bash, Glob, Grep, Agent |
| 16 | `/forge-execute` | [planned V2.0] Run validation journeys against the real system with fix-and-retry loop | Read, Write, Edit, Bash, Glob, Grep, Agent |
| 17 | `/forge-team` | Multi-agent parallel validation across platforms | Read, Write, Bash, Glob, Grep, Agent |
| 18 | `/forge-benchmark` | Measure validation posture across 5 dimensions with trend tracking | Read, Write, Bash, Glob, Grep |
| 19 | `/forge-install-rules` | Install ValidationForge rules to .claude/rules/ for cross-session enforcement | Read, Write, Bash, Glob |

## Command Pipeline Matrix

| Command | Research | Plan | Preflight | Execute | Analyze | Verdict | Ship |
|---------|:--------:|:----:|:---------:|:-------:|:-------:|:-------:|:----:|
| `/validate` | yes | yes | yes | yes | yes | yes | no |
| `/validate-plan` | yes | yes | yes | -- | -- | -- | -- |
| `/validate-audit` | yes | -- | yes | read-only | yes | yes | -- |
| `/validate-fix` | -- | -- | -- | yes | yes | yes | -- |
| `/validate-ci` | yes | yes | yes | yes | yes | yes | -- |
| `/validate-team` | yes | yes | yes | parallel | yes | unified | -- |
| `/validate-team-dashboard` | -- | -- | -- | -- | aggregate | report | -- |
| `/validate-sweep` | -- | -- | -- | loop | loop | loop | -- |
| `/validate-benchmark` | -- | -- | -- | -- | score | report | -- |
| `/validate-consensus` | yes | yes | yes | parallel | yes | synthesized | -- |
| `/vf-setup` | -- | -- | -- | -- | -- | -- | -- |
| `/vf-telemetry` | -- | -- | -- | -- | -- | -- | -- |

## Validation vs Forge Commands

Both families access the same pipeline. The difference:

- **Validation commands** (`/validate*`, `/vf-setup`, `/vf-telemetry`) are the user-facing interface. No `allowed-tools` restriction -- they use whatever Claude Code makes available.
- **Forge commands** (`/forge-*`) are the orchestration layer. Each specifies `allowed-tools` in frontmatter to constrain which Claude Code tools the command may invoke. Forge commands are typically called by skills or agents rather than directly by users.

## CLI (`vf`)

`npm install -g validationforge` installs a `vf` binary (points at `bin/vf.js`) for
out-of-Claude-Code tasks. Mirrors what `vf help` prints at runtime.

| Subcommand | Purpose |
|------------|---------|
| `vf --version` / `vf -v` | Print installed package version |
| `vf status` | Show plugin registration + rules install state |
| `vf install-rules` | Copy `rules/*.md` into `.claude/rules/` for the current project |
| `vf install-rules --global` | Copy `rules/*.md` into `~/.claude/rules/vf-*.md` (all projects) |
| `vf install-rules --local` | Explicit local install (same as default) |
| `vf help` / `vf --help` / `vf -h` | Show help (auto-generated from `commands/*.md`) |

The help subcommand enumerates every slash command in this index at runtime, so adding a
new `.md` under `commands/` automatically shows up in `vf help` without manual sync.
