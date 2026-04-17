# Evidence Citation Examples

## Citation Format

Every criterion must be documented:

```
CRITERION: [What was required]
EVIDENCE: [File path or command output]
OBSERVATION: [What I actually saw/read — be specific]
VERDICT: PASS / FAIL
```

### Good Citation

```
CRITERION: Homepage renders with navigation bar and hero section
EVIDENCE: e2e-evidence/homepage-final.png
OBSERVATION: Screenshot shows header with logo "Acme Corp" left-aligned, nav links
  "Home | Products | About | Contact" right-aligned, hero section with heading
  "Build Better Software" and blue CTA button "Get Started"
VERDICT: PASS
```

### Bad Citation (Rejected)

```
CRITERION: Homepage renders with navigation bar and hero section
EVIDENCE: e2e-evidence/homepage-final.png
OBSERVATION: Screenshot looks correct
VERDICT: PASS
```

"Looks correct" is subjective. A skeptical reviewer cannot verify it.

## Anti-Patterns

| # | Anti-Pattern | Why It Fails | Correct Approach |
|---|-------------|--------------|------------------|
| 1 | "Build succeeded, must be done" | Compilation proves syntax, not behavior | Run the app, exercise the feature through UI |
| 2 | "Tests pass" | Tests verify test logic, not user experience | Exercise through real UI, capture evidence |
| 3 | "No errors in console" | Absence of error does not prove correctness | Verify expected output IS present |
| 4 | "Screenshot captured" | File existence proves nothing about content | Open screenshot, describe what you see |
| 5 | "Subagent reported success" | Delegation is not verification | Read the subagent's evidence yourself |
| 6 | "It worked on my last run" | State changes between runs | Re-capture evidence after final changes |
| 7 | "The diff looks right" | Code review is not functional validation | Run it |
| 8 | "API returns 200" | Status code without body inspection | Read the full response body |
| 9 | "Logs show no warnings" | Many failures are silent | Verify positive outcomes |
| 10 | "Same pattern as last time" | Context changes | Verify each instance independently |

## Completion Statement Template

Use this format when claiming any task is complete:

```markdown
## Completion Evidence

### Evidence Examined
1. `e2e-evidence/homepage.png` — Shows hero section with "Welcome to Acme" heading,
   3 feature cards titled "Speed", "Security", "Scale", footer with copyright 2026
2. `e2e-evidence/api-users-response.json` — GET /api/users returns 200,
   body contains array of 5 user objects each with id, name, email
3. `e2e-evidence/build-output.txt` — Line 142: "Build Succeeded", 4 targets,
   0 errors, 0 warnings

### Criteria Verification
| Criterion | Evidence | Observation | Verdict |
|-----------|----------|-------------|---------|
| Homepage renders correctly | Screenshot #1 | Hero, 3 cards, footer present | PASS |
| API returns user list | Response #2 | 5 users with complete fields | PASS |
| Production build succeeds | Log #3 | Clean build, binary produced | PASS |

### Verdict: PASS (3/3 criteria met)
```
