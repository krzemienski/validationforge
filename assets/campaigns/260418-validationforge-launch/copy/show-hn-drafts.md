# Show HN: Drafts (3 variants + author comment)

**Drop window:** Tuesday April 28, 2026, 8:00am ET (Day 11).
**Backup window:** Wednesday April 29, 8:00am ET — only if Variant A flops within 30 min.

---

## Variant A — RECOMMENDED

### Title
> Show HN: ValidationForge – Claude Code plugin that blocks AI-generated mocks

### Body

I'm Nick. Over 42 days I ran 23,479 Claude Code sessions across 27 projects and shipped 3.4M lines of AI-generated code. Almost everything passed its unit tests. At least 5 things shipped broken in ways unit tests structurally couldn't catch — API renames, JWT expiry edge cases, iOS deep-link regressions, DB migrations under real data, CSS overflow on small screens.

ValidationForge is what I built to close that gap. It's a Claude Code plugin (also works as an OpenCode plugin) that:

- Blocks AI agents from creating test/mock/stub files in `src/` via a PreToolUse hook
- Provides a `/validate` command that runs a 7-phase pipeline: detect platform → plan journeys → preflight build → execute against the real system (curl, simctl, Playwright) → analyze evidence → write a PASS/FAIL verdict
- Requires every verdict to cite specific evidence — screenshot file path, exact HTTP response body, build log line. Confident prose without citations is rejected by hooks
- Captures evidence to `e2e-evidence/{journey}/step-NN-{description}.{ext}` so verdicts are auditable

I ran VF against itself last week: 6/6 journeys PASS, 13/13 criteria, 0 fix attempts. The complete evidence directory is committed in the repo at `e2e-evidence/self-validation/`. I wanted to publish the receipts before posting this.

What it doesn't do:

- It doesn't replace unit tests — those still have value for pure logic with no I/O
- It doesn't generate code (use Claude Code, OMC, or Superpowers for that)
- It doesn't run autonomously by default — you invoke `/validate` when you want a verdict

Free, MIT licensed, no telemetry on by default. Install in Claude Code:

```
/plugin marketplace add krzemienski/validationforge
/plugin install validationforge@validationforge
# restart Claude Code
/vf-setup
```

Repo: https://github.com/krzemienski/validationforge

Happy to answer questions about: the no-mock hook design, the evidence schema, why I think "Evidence-Based Shipping" is a real category, how it composes with OMC and Superpowers, or what unit tests it doesn't cover. Roast welcome.

---

## Variant B — backup if A is too long

### Title
> Show HN: I made Claude prove its code works (with cited evidence)

### Body

I shipped 3.4 million lines of AI-generated code in 42 days. Most passed unit tests. Five things broke in production in ways unit tests cannot detect — mock drift on a renamed API field, JWT expiry under real time, iOS deep links after a nav refactor, DB migration on real duplicate data, CSS overflow on small screens.

ValidationForge is a Claude Code plugin that enforces a different bar:

- Hook blocks creation of `.test.*` / `.spec.*` / mock / stub files in `src/`
- `/validate` runs a 7-phase pipeline against the real system (curl, simctl, Playwright)
- Every PASS/FAIL verdict must cite specific evidence — screenshot path, exact log line, exact response body
- Evidence is captured to `e2e-evidence/{journey}/step-NN-*.ext` and committed alongside the code

Self-validation result: 6/6 PASS, 13/13 criteria, 0 fix attempts. Evidence directory in repo.

Free, MIT, no telemetry. Composes with OMC and Superpowers (use those to build, VF to verify).

Repo: https://github.com/krzemienski/validationforge

---

## Variant C — backup if A flops with title rejection

### Title
> Show HN: Compilation isn't validation – a new gate for AI-generated code

### Body

Premise: "build passing" has become the quality bar for AI-assisted development. It is necessary but not sufficient. The gap between compilation and validation is where production bugs live.

ValidationForge implements a stricter gate. It is a Claude Code plugin that:

1. Blocks AI agents from creating mock files in `src/` (PreToolUse hook)
2. Runs `/validate` — a 7-phase pipeline that interacts with the real system through real interfaces (curl for APIs, simctl for iOS, Playwright for web, shell for CLI)
3. Captures evidence (screenshots, response bodies, build logs) into a structured `e2e-evidence/{journey}/` directory
4. Writes a PASS/FAIL verdict per journey that cites specific evidence files
5. Rejects completion claims that lack evidence citations

Tested against itself: 6/6 PASS, 0 fix attempts.

Free, MIT licensed. Repo: https://github.com/krzemienski/validationforge

What unit tests cover: pure logic with no I/O. What VF covers: every interface that touches a real system.

---

## Author First Comment (POST WITHIN 5 MIN OF SUBMISSION)

> Quick technical detail in case it's the first question:
>
> The "no-mock" enforcement is one PreToolUse hook (`hooks/block-test-files.js`, ~50 lines). It receives the tool-use payload before Claude can write the file, checks the path against `src/**/*.test.*`, `src/**/*.spec.*`, `src/**/__mocks__/**`, etc., and returns a `decision: "deny"` with a reason. Claude then gets the deny back as a tool-result and adapts.
>
> The hook source is the canonical "I don't trust the model to follow the rule, so the harness enforces it" pattern documented in the Claude Code hooks reference. It works because Claude can't write the file, period — not because Claude was asked nicely.
>
> Happy to dig into the evidence schema, the verdict-writer prompt, or the integration with OMC/Superpowers if anyone wants.

---

## Reply Templates

Pre-written replies for predictable HN comment patterns. Edit in voice before posting.

### "Isn't this just integration testing?"
> Related but distinct. Integration tests are written ahead of time and verify a contract you specified. VF runs against the actual system as it exists right now, captures evidence of the current behavior, and writes a verdict. The verdict is the deliverable — not the test code, which doesn't exist.
>
> Concretely: integration tests would have a fixture asserting `response.users[0].id`. If the API renames `users` → `data`, the test fails loudly and you fix the test. VF runs `curl /endpoint`, sees `data`, captures the actual response body to disk, and writes a verdict citing what the live system returned.
>
> Different layers. Both useful.

### "Why not just use Playwright/Cypress/Postman?"
> Use them. VF wraps them — the `web` validation skill literally drives Playwright; the `api` skill uses curl or fetch. The contribution isn't the runner. It's:
> 1. A uniform evidence schema across runners (so a Playwright screenshot and a curl response live next to each other in the same `e2e-evidence/journey/` dir)
> 2. A verdict layer that requires citation
> 3. Hooks that block AI agents from short-circuiting validation by writing mocks instead

### "How is this different from existing E2E frameworks?"
> Existing E2E frameworks assume a human wrote the tests carefully. They don't assume an AI agent is trying to declare success based on what it remembers being asked to do. VF assumes the latter and adds enforcement: hooks that block test-file creation, verdict structure that requires evidence citations, and a default-deny posture for unsupported claims. It's E2E framework-agnostic underneath.

### "Looks like a lot of ceremony for a small team."
> Fair. The opt-in path is `/vf-setup` with `permissive` config — minimal hooks, opt-in `/validate`. The opinionated path is `strict` config with all hooks active. Pick the level you want.

### "What about cost? AI-driven validation is expensive."
> The hooks are deterministic JS — zero token cost. The verdict-writer agent runs only when you invoke `/validate`. On a real Next.js project the full 7-phase run cost roughly equivalent to one moderately-sized debugging session — measured, not estimated.

### "Is the self-validation result really self-validating? Sounds circular."
> It is and it isn't. VF validated its own scaffolding (do the hooks load correctly, do the skills resolve, does the install script work, do the cross-references in docs match files on disk). That's what the 6/6 PASS measures. It does NOT validate VF's effectiveness against arbitrary application code — for that the right test is "run VF on your project and see if it catches bugs your tests didn't." That's the experiment I'm asking you to run, not one I can run for you.

### Hostile / dismissive comment
> Acknowledged. If you'd like to give it a real try, the install is in the README — would value the critique either way.

(Then move on. Do not argue further.)
