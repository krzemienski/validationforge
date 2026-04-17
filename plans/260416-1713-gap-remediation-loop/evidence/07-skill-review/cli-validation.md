---
skill: cli-validation
reviewer: R1
date: 2026-04-16
verdict: PASS
---

# cli-validation review

## Frontmatter check
- name: `cli-validation`
- description: `"Validate CLI binaries: build, help/version output, happy path, error cases (bad flags, missing args), exit codes, stdin/pipe, output format (JSON/CSV). Captures stdout/stderr."` (181 chars)
- description_well_formed: yes
- yaml_parses: yes

## Trigger realism
Would invoke on: `"binary validation"`, `"CLI testing"`, `"command-line tool"`, `"exit code verification"`.
Realism score: 5/5. Phrases are natural for CLI developers. Terminology is precise.

## Body-description alignment
PASS. Body delivers all promised validations:
- Build (Step 1: language-specific commands) ✓
- Help/version output (Steps 2-3) ✓
- Happy path (Step 4) ✓
- Error cases (Step 5: invalid flag, missing arg, file not found, permission denied) ✓
- Exit codes (Step 6: 0 vs non-zero) ✓
- Stdin/pipe (Step 7) ✓
- Output format (Step 8: JSON/CSV validation) ✓
- Captures stdout/stderr ✓

PASS Criteria template provides concrete verdicts. Common failures table aids debugging.

## MCP tool existence
None. All validation uses shell commands (cargo, go, npm, pip, chmod, echo, jq, etc.) that are always available.

## Example invocation proof
User: `"Validate the CLI tool's CRUD functionality"`
Would execute Steps 1-8 per documented protocol, capturing evidence to e2e-evidence/.

## Verdict
**PASS**

Complete step-by-step protocol. Language-specific build commands documented. Error cases are thorough. Exit code conventions explained. Evidence standards are explicit.
