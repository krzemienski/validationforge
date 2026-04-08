# Error Log & Escalation Templates

## Error Log Format

Track every error and recovery attempt in `e2e-evidence/error-log.md`:

```markdown
# Error Log

## Error 1
**Time:** [HH:MM:SS]
**Phase:** [Which validation journey / step]
**Error:** [Full error message — first 5 lines minimum]

| Attempt | Action Taken | Result | Duration |
|---------|-------------|--------|----------|
| Strike 1 | [Specific action] | [PASS or still failing] | [Xm] |
| Strike 2 | [Different approach] | [PASS or still failing] | [Xm] |
| Strike 3 | [Broader rethink] | [PASS or ESCALATE] | [Xm] |

**Resolution:** [SUCCESS after N attempts | ESCALATED — reason]
**Root Cause:** [What was actually wrong]
```

## Escalation Template

When 3 strikes are exhausted:

```markdown
## Escalation: [Journey ID] — [Brief description]

### Error
[Full error output — do not truncate]

### Attempts
1. **Strike 1:** [What you tried] — Result: [What happened]
2. **Strike 2:** [What you tried] — Result: [What happened]
3. **Strike 3:** [What you tried] — Result: [What happened]

### Analysis
- **Root cause hypothesis:** [Your best guess]
- **What you learned:** [Partial progress or clues]
- **Ruled out:** [Approaches that definitively don't work]

### Suggested Next Steps
1. [Specific action a human could take]
2. [Alternative approach not yet tried]
```

## Error Classification Quick Reference

| Error Type | Symptoms | Recovery Action |
|---|---|---|
| Build failure | Compilation errors, type errors | Fix source code at file:line, rebuild |
| Runtime crash | App exits, uncaught exception | Read crash log, fix throwing code path |
| Network timeout | ETIMEDOUT, ECONNREFUSED | Verify server running and reachable |
| Auth failure | 401, 403, "unauthorized" | Check credentials, token expiry |
| Database error | Connection refused, relation not found | Verify DB running, check migrations |
| File not found | ENOENT, 404 on static assets | Check file path, verify build output |
| Permission denied | EACCES, 403 on filesystem | Check ownership, chmod |
| Port in use | EADDRINUSE | Find and kill process using port |
| Dependency missing | Module not found | Install missing dependency |
| Configuration error | Missing env vars | Check config files, verify env vars |

For detailed recovery commands, see `references/recovery-commands.md`.
