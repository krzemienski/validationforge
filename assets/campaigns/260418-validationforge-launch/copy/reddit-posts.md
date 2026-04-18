# Reddit Posts (subreddit-specific drafts)

Three posts, three subreddits, three angles. Never crosspost. Read each sub's rules before posting.

---

## r/ClaudeAI — Day 4 (Tue Apr 21), 9:00am ET

### Title
> I built a plugin that blocks Claude from creating mock files. 6/6 self-validation PASS.

### Body

After 23,479 Claude Code sessions across 27 projects, I started noticing a pattern: Claude would happily declare a feature "done" because the build passed and the tests passed — but the feature itself was broken. The tests were mocks Claude itself wrote, returning the data Claude expected. They tested the agreement between the mock and the test, not the contract with the real system.

So I built ValidationForge — a Claude Code plugin (works in OpenCode too) that does a few stubborn things:

1. **PreToolUse hook blocks test/mock/stub file creation in `src/`.** If Claude tries to write `src/auth/login.test.ts`, the harness denies the tool call. Claude has to validate against the real system instead.

2. **`/validate` runs a 7-phase pipeline against the actual app**: detect platform → plan journeys → run preflight → execute through real interfaces (curl, simctl, Playwright) → analyze evidence → write a PASS/FAIL verdict.

3. **Every verdict cites specific evidence**: file path of a captured screenshot, the exact HTTP response body, the exact build log line. No "I think it works." Confident prose without citations is rejected.

4. **Evidence is captured into `e2e-evidence/{journey}/step-NN-*.{ext}` and committed.** Verdicts are auditable.

To prove it isn't just talk, I ran VF against itself. Result: **6/6 journeys PASS, 13/13 criteria, 0 fix attempts.** The complete evidence directory is committed at `e2e-evidence/self-validation/` so you can read the actual artifacts, not just my claim about them.

What it isn't:
- It is not a unit-test replacement. Pure logic with no I/O still benefits from unit tests.
- It is not a code generator. Use Claude Code, OMC, or Superpowers to build; use VF to verify.
- It is not autonomous by default. You invoke `/validate` when you want a verdict.

It composes cleanly with the rest of the Claude Code plugin ecosystem. There are integration guides for OMC and Superpowers in the repo.

Free, MIT, no telemetry by default. Install:

```
/plugin marketplace add krzemienski/validationforge
/plugin install validationforge@validationforge
# restart Claude Code
/vf-setup
```

Repo: https://github.com/krzemienski/validationforge

If you've ever shipped AI-generated code that broke despite passing every check, I'd genuinely like to know whether VF would have caught it. Drop the bug pattern in the comments.

---

## r/LocalLLaMA — Day 7 (Fri Apr 24), 10:00am ET

### Title
> Open-source: validation harness for AI-generated code. Today Claude-Code-shaped, agent-agnostic in spirit.

### Body

Open-source validation harness for code produced by AI agents. Currently shaped around Claude Code (because that's what I use daily), but the design is agent-agnostic and contributions are welcome to add adapters for other agents.

**The core idea:** AI agents declare "done" based on whether the code they wrote agrees with the tests they wrote. That agreement is not the same as the code working in the real system. A renamed API field, a JWT expiry change, a CSS layout regression — all things mocks structurally cannot detect — ship to prod.

**What ValidationForge does:**

- A PreToolUse hook (deterministic JS, zero LLM cost) blocks the agent from creating mock/stub/test files inside `src/`. The agent has to validate against the real system or not at all.
- A `/validate` workflow runs a 7-phase pipeline: detect platform → plan validation journeys → preflight build → execute against real interfaces (curl, simctl, Playwright, shell) → analyze evidence → write a PASS/FAIL verdict.
- Evidence is captured to a structured `e2e-evidence/{journey}/step-NN-*.{ext}` directory.
- Verdicts must cite evidence files. Confident prose without citations is rejected.

**Agent compatibility:**

Today, the hook layer is Claude Code's hook protocol (PreToolUse / PostToolUse with stdin JSON contract). The `/validate` workflow is a slash-command-callable script — most of the underlying logic is bash, not Claude-specific. The verdict-writer prompt is a portable text template.

To adapt to a different agent harness you'd need to:
1. Map the hook events to your agent's tool-call interception (most agentic frameworks have an equivalent)
2. Wire your slash-command equivalent to invoke `bin/vf-validate`
3. Use whatever LLM you prefer as the verdict-writer (the prompt is in `prompts/verdict-writer.md`)

I'd love adapters for Aider, OpenCode (already partial), or any local-model agent that has a tool-call interception layer. Issues / PRs welcome.

Self-validated 6/6 PASS, 0 fix attempts. Evidence directory in the repo.

Repo: https://github.com/krzemienski/validationforge

---

## r/programming — Day 10 (Mon Apr 27), 8:00am ET

### Title
> Compilation isn't validation: a new gate for AI-assisted development

### Body

Hot take that I'd like the room to refute: as AI assistants generate the bulk of code on many real projects, the industry's quality bar has quietly slipped from "this feature works" to "the build passes and the type-checker is happy." Those are necessary but not sufficient gates. The gap between them and "the feature actually works" is where production bugs live now.

I want to argue for a third gate, sitting between compilation and human review. Call it Evidence-Based Shipping: every claim of completion must cite specific evidence captured from the running system.

**Concrete examples of bugs the existing gates miss:**

| Bug pattern | Type-check | Unit tests | Real system |
|---|---|---|---|
| API field renamed `users` → `data` | ✓ | ✓ (mock returns old field) | ✗ (curl shows new field) |
| JWT expiry reduced 60min → 15min | ✓ | ✓ (mock skips time) | ✗ (real refresh fails) |
| iOS deep link breaks after nav refactor | ✓ | ✓ (mock URL handler) | ✗ (`simctl openurl` opens wrong screen) |
| DB migration fails on duplicate emails | ✓ | ✓ (clean in-memory DB) | ✗ (real migration aborts) |
| CSS grid overflow on viewport <768px | ✓ | ✓ (no rendering) | ✗ (Playwright screenshot shows overflow) |

These are categories where mock-based testing is structurally blind. The mock returns what the test expects; the real system has changed. The test passes, the deploy ships, the bug surfaces in prod.

**What "Evidence-Based Shipping" looks like in practice:**

- Validation runs against the real system through the same interfaces a real user would touch (HTTP for APIs, the simulator for iOS, the rendered browser for web, the shell for CLIs)
- The output of validation is a structured directory of artifacts (screenshots, response bodies, build logs) plus a written verdict
- The verdict says PASS or FAIL per journey and **cites specific evidence files for each claim**
- Confident prose without evidence citations is rejected

I built a Claude Code plugin (ValidationForge) that implements this. It's free, MIT, and the source is small enough to read in an afternoon. Self-validated against itself: 6/6 journeys PASS with the full evidence directory committed in the repo so you can audit the artifacts.

Whether you use my implementation or write your own, the argument is independent of the tool: **compilation is necessary, not sufficient**. AI-assisted development needs a stricter gate.

Source: https://github.com/krzemienski/validationforge

What am I getting wrong? Where does this argument break down? I'd rather hear it now than learn it the hard way.

---

## Reply Templates (Reddit)

### "This sounds like just E2E testing"
Almost — but with a key wrinkle. Traditional E2E test frameworks assume a human wrote the test carefully. They don't assume an AI agent is trying to declare success based on what it remembers being asked to do. VF adds the enforcement layer (block mocks, require evidence citations, default-deny on unsupported claims) that's needed when an AI is the author. The E2E framework underneath (Playwright, curl, simctl) is the same.

### "Mocks have legitimate uses"
Strongly agree. VF blocks them in `src/` specifically. Pure-logic units with no I/O still benefit from unit tests with mocks. The argument is narrower: mocks at the system boundary (where AI-generated code most often drifts) are where production bugs hide.

### "Why MIT and not GPL"
MIT keeps the friction to adoption low. The methodology is the contribution; the code is small enough that anyone could re-implement it under any license they want.

### "Isn't this just monitoring/observability for dev?"
Closer to that than to traditional testing, yes. The evidence directory is essentially a structured incident-response artifact for the dev loop, captured before the code ships.
