# Severity Classification Guide

Extended examples and edge cases for each severity level.

## CRITICAL — Immediate Fix Required

| Example | Why CRITICAL |
|---------|-------------|
| API returns 500 on all requests | Core functionality completely broken |
| Login bypassed without credentials | Security vulnerability |
| Database writes silently fail | Data loss risk |
| Payment processed but order not created | Financial data integrity |
| Admin panel accessible without auth | Privilege escalation |
| Form submission causes unhandled exception | User-facing crash |

**Rule:** Security issues are ALWAYS CRITICAL regardless of exploitability assessment.
Data loss risk is ALWAYS CRITICAL.

## HIGH — Fix Before Release

| Example | Why HIGH |
|---------|---------|
| Form submits but shows wrong confirmation | Misleading user feedback |
| Search returns results but pagination broken | Feature partially unusable |
| File upload works but progress bar stuck at 0% | Poor UX on core feature |
| API returns correct data but wrong status code (200 for error) | Integration breakage |
| Mobile nav menu opens but links don't navigate | Core feature broken on one platform |

**Rule:** "Works but misleads the user" or "works on one platform but not another" = HIGH.

## MEDIUM — Fix In Current Cycle

| Example | Why MEDIUM |
|---------|----------|
| Button requires double-click to register | Usability friction |
| Layout breaks at tablet width (768px) | Responsive design gap |
| Slow response >3s on common action | Performance below threshold |
| Form validation fires after submit, not inline | Suboptimal UX pattern |
| Dark mode has unreadable text on 2 pages | Accessibility issue (non-blocking) |

**Rule:** "Works but with notable friction" = MEDIUM. User can accomplish their goal but
experience is degraded.

## LOW — Fix When Convenient

| Example | Why LOW |
|---------|--------|
| Typo in error message | Cosmetic |
| Inconsistent button spacing (8px vs 12px) | Minor design inconsistency |
| Placeholder text not italicized | Style guide deviation |
| Footer copyright year is 2024 | Stale content |
| Console warning about deprecated API | No user impact currently |

**Rule:** User doesn't notice unless looking closely. No functional impact.

## INFO — Document For Awareness

| Example | Why INFO |
|---------|---------|
| Response time 180ms (well within threshold) | Positive observation |
| Using deprecated API that still works | Future risk, no current issue |
| Unused CSS rules detected | Code quality note |
| Bundle size 2.1MB (acceptable for this app type) | Metric baseline |
| Third-party widget loads from CDN | External dependency note |

**Rule:** Not a defect. Worth noting for context or future reference.

## Edge Cases

| Situation | Classification | Reasoning |
|-----------|---------------|-----------|
| Feature works but returns wrong HTTP status | HIGH | Integrations break on status codes |
| Console error that doesn't affect UI | MEDIUM | Indicates underlying issue |
| Feature works in Chrome, broken in Safari | HIGH | Platform-specific breakage |
| Slow load on first visit, fast on subsequent | MEDIUM | Cold start issue, affects first impression |
| Feature works but accessibility tree is wrong | MEDIUM | Screen reader users affected |
| "Works on my machine" — fails in CI | CRITICAL | Deployment will fail |
