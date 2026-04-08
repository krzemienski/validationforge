# ValidationForge Commands Index

15 slash commands across 2 families.

## Validation Commands (9)

| # | Command | Description | Pipeline Stages |
|---|---------|-------------|-----------------|
| 1 | `/validate` | Full pipeline: detect → plan → execute → verdict | Research, Plan, Preflight, Execute, Analyze, Verdict |
| 2 | `/validate-plan` | Plan only — map journeys, define PASS criteria, no execution | Research, Plan, Preflight |
| 3 | `/validate-audit` | Read-only audit — capture evidence, classify severity, no code changes | Research, Preflight, Execute (read-only), Analyze, Verdict |
| 4 | `/validate-fix` | Fix FAIL verdicts and re-validate (3-strike limit per journey) | Execute, Analyze, Verdict, Fix Loop |
| 5 | `/validate-ci` | Non-interactive CI/CD mode — auto-approve plan, exit code 0/1 | Research, Plan, Preflight, Execute, Analyze, Verdict |
| 6 | `/validate-team` | Multi-agent parallel validation — one validator per platform | Research, Plan, Preflight, Execute (parallel), Analyze, Verdict (unified) |
| 7 | `/validate-sweep` | Autonomous fix-and-revalidate loop until all PASS or max attempts | Execute (loop), Analyze (loop), Verdict (loop) |
| 8 | `/validate-benchmark` | Score validation posture: coverage, evidence, enforcement, speed | Analyze (score), Verdict (report) |
| 9 | `/vf-setup` | Interactive setup wizard — detect platform, select enforcement, scaffold evidence dir | — (setup) |

## Forge Commands (6)

| # | Command | Description | Allowed Tools |
|---|---------|-------------|---------------|
| 10 | `/forge-setup` | Initialize ValidationForge for current project | Read, Write, Edit, Bash, Glob, Grep, Agent |
| 11 | `/forge-plan` | Generate validation plan with journey discovery | Read, Write, Bash, Glob, Grep, Agent |
| 12 | `/forge-execute` | Run validation journeys with autonomous fix loop | Read, Write, Edit, Bash, Glob, Grep, Agent |
| 13 | `/forge-team` | Spawn platform-specific validators for parallel validation | Read, Write, Bash, Glob, Grep, Agent |
| 14 | `/forge-benchmark` | Measure validation posture with trend tracking | Read, Write, Bash, Glob, Grep |
| 15 | `/forge-install-rules` | Install rules to `.claude/rules/` for cross-session enforcement | Read, Write, Bash, Glob |

## Command Pipeline Matrix

| Command | Research | Plan | Preflight | Execute | Analyze | Verdict | Ship |
|---------|:--------:|:----:|:---------:|:-------:|:-------:|:-------:|:----:|
| `/validate` | yes | yes | yes | yes | yes | yes | no |
| `/validate-plan` | yes | yes | yes | — | — | — | — |
| `/validate-audit` | yes | — | yes | read-only | yes | yes | — |
| `/validate-fix` | — | — | — | yes | yes | yes | — |
| `/validate-ci` | yes | yes | yes | yes | yes | yes | — |
| `/validate-team` | yes | yes | yes | parallel | yes | unified | — |
| `/validate-sweep` | — | — | — | loop | loop | loop | — |
| `/validate-benchmark` | — | — | — | — | score | report | — |
| `/vf-setup` | — | — | — | — | — | — | — |
