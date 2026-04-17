---
skill: rust-cli-validation
reviewed_at: 2026-04-16T20:15:00Z
reviewer: R4
---

## Frontmatter Check
- **name:** rust-cli-validation ✓
- **description:** "Validate Rust CLI apps via cargo: check, clippy, release build, binary execution. Detects panics, exit codes, error messages. Tests help, version, happy path, error cases." (161 chars) ✓
- **yaml_parses:** Yes ✓

## Trigger Realism
**ISSUE FOUND:** NO triggers defined in frontmatter.
Only `context_priority: standard` present.

**Impact:** Skill cannot be auto-invoked or discovered via natural language.

## Body-Description Alignment
**Verdict:** PASS (despite missing triggers) — All description claims verified: cargo check/clippy/build, binary execution, help/version/happy/error paths, panic detection (exit code 101), exit codes, error messages.

## MCP Tool Existence
Bash (cargo, shell execution), tee (log capture) ✓

## Example Invocation Proof
**Prompt:** "validate my rust cli tool" (5 words, viable once triggers added)

## Verdict
**Status:** NEEDS_FIX

### Required Action
Add triggers to frontmatter:
```yaml
triggers:
  - "rust cli validation"
  - "validate rust app"
  - "cargo validation"
  - "rust cargo"
  - "cli validation"
context_priority: standard
```

## Notes
- Excellent platform-specific validation
- 6 explicit steps with evidence capture
- 10-item "Common Failures" table very thorough
- 10-item PASS Criteria template clear and complete
- Missing triggers is only defect
