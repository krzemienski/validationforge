# Validation Discipline

## The No-Mock Mandate

NEVER create:
- Test files (*.test.*, *.spec.*, *_test.*)
- Mock objects, stubs, test doubles, or fixtures
- Test frameworks, test runners, or test harnesses
- Fake data generators or mock APIs

ALWAYS:
- Build and run the real system
- Validate through actual user interfaces
- Capture evidence (screenshots, logs, API responses)
- Cite specific evidence for every PASS/FAIL verdict

## Evidence Standards

Every completion claim MUST include:
1. **Screenshot evidence** — Describe what you SEE, not that it exists
2. **API response evidence** — Quote actual response body, not just status code
3. **Build evidence** — Quote actual output line, not just "build succeeded"
4. **Log evidence** — Include relevant log entries with timestamps

## Gate Protocol

Before marking ANY gate, task, or checkpoint as complete:
- [ ] READ the actual evidence file (not just the report about it)
- [ ] VIEW the actual screenshot (not just confirm it exists)
- [ ] EXAMINE actual command output (not just exit code)
- [ ] CITE specific evidence for each validation criterion
- [ ] A skeptical reviewer would agree this is complete

## Compilation vs Validation

```
Build passing ≠ Feature working
Type-check clean ≠ UI rendering correctly
No lint errors ≠ User journey functional
```

Build gates are NECESSARY but NOT SUFFICIENT. Always follow with functional validation.
