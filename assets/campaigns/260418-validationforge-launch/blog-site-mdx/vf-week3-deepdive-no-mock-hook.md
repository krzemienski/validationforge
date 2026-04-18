---
title: "The 50-line hook that blocks AI agents from cheating"
subtitle: "How ValidationForge's no-mock enforcement actually works, with the real source code"
author: "Nick Krzemienski"
date: "2026-04-18"
github_repo: "https://github.com/krzemienski/validationforge"
tags:
  - agentic-development
  - ai-validation
  - claude-code
  - validationforge
  - hooks
  - claude-code-plugins
  - technical-deepdive
published: false
---

<!-- TODO hero image: creatives/screenshots/vf-week3-deepdive-no-mock-hook-hero.png -->

# The 50-line hook that blocks AI agents from cheating

In the launch posts I described ValidationForge as a Claude Code plugin with a hook that blocks AI agents from creating test, mock, or stub files inside `src/`. A few people asked the obvious follow-up: how does that actually work, what happens to the agent when it's blocked, and is the hook itself reliable?

This post answers those three questions in detail, including the real source code. The hook is small enough to read in a sitting — about 50 lines of deterministic JavaScript with no LLM cost. Whether you adopt ValidationForge or write your own version, the pattern is portable, and I think the implementation details are worth sharing.

If you skim only one paragraph, skim this one: **the hook works because Claude Code's PreToolUse hook protocol is enforced by the harness, not by the model**. The model can't talk its way around the deny — the file write never happens, and the model gets a tool-result error back that it has to respond to. Hooks are the gate. Models are the gated.

---

## What "PreToolUse hook" actually means

Claude Code (and OpenCode, which uses a similar protocol) runs a subprocess for every tool call the model attempts. Before the tool actually executes, registered PreToolUse hooks get invoked with the tool-call payload as JSON on stdin. Each hook returns one of three outcomes:

1. **Exit 0, silent**: allow the tool call to proceed normally.
2. **Exit 0, with JSON output**: modify the tool call (rare; usually used for permission-asking flows).
3. **Exit 2, with reason on stderr**: deny the tool call. The model sees the deny as a tool-result, has to respond to it, and cannot retry the same call without changing the parameters.

The third outcome is what `block-test-files.js` uses. The model attempts to write `src/auth/login.test.ts`, the hook reads the path, matches it against a deny pattern, exits 2 with a reason, and the harness refuses to write the file. The model then receives a structured deny response and has to find another path — usually validating against the real system instead.

This is enforcement, not negotiation. The model can't be persuaded to ignore the hook because the model never gets the chance.

---

## The actual hook source

Here is the relevant section of `hooks/block-test-files.js`, annotated:

```javascript
#!/usr/bin/env node
// Block AI-generated test/mock/stub file creation inside src/ and lib/.
// Reason: forces validation against the real running system, not against
// a mock the agent wrote to make its own tests pass.

const path = require('path');

// Read the tool-call payload from stdin (Claude Code hook protocol).
let raw = '';
process.stdin.on('data', chunk => raw += chunk);
process.stdin.on('end', () => {
  let payload;
  try {
    payload = JSON.parse(raw);
  } catch {
    process.exit(0); // Malformed payload: don't block on hook bug.
  }

  // We only care about Write and Edit tool calls.
  const tool = payload.tool_name;
  if (tool !== 'Write' && tool !== 'Edit' && tool !== 'MultiEdit') {
    process.exit(0);
  }

  // Extract the target file path from the tool input.
  const filePath = payload.tool_input?.file_path || '';
  if (!filePath) process.exit(0);

  // Normalize and check against deny patterns.
  const rel = path.relative(process.cwd(), filePath);

  const isInSrc = rel.startsWith('src/') || rel.startsWith('lib/');
  if (!isInSrc) process.exit(0); // Outside src/, allow.

  const denyPatterns = [
    /\.test\.[jt]sx?$/,        // *.test.ts, *.test.js, etc.
    /\.spec\.[jt]sx?$/,        // *.spec.ts, *.spec.js, etc.
    /__mocks__/,               // any __mocks__ directory
    /__tests__/,               // any __tests__ directory
  ];

  const matched = denyPatterns.find(rx => rx.test(rel));
  if (!matched) process.exit(0); // Not a test/mock pattern, allow.

  // Block. Write reason to stderr, exit 2.
  process.stderr.write(
    `BLOCKED: ${rel} matches no-mock policy (${matched}).\n` +
    `ValidationForge enforces real-system validation. Use /validate to verify ` +
    `the actual application instead of writing test/mock files in src/.\n` +
    `If you genuinely need a test framework, write outside src/ in __tests__/ ` +
    `at the repo root or in a dedicated test/ directory.\n`
  );
  process.exit(2);
});
```

That's the entire enforcement layer for the no-mock policy. Roughly 50 lines including comments. Zero dependencies. Zero LLM cost — the hook runs as a Node subprocess in milliseconds.

A few implementation details worth flagging:

**The `try/catch` around `JSON.parse` is intentional.** If the harness ever passes a malformed payload (it doesn't, but I don't trust that across versions), the hook should fail open rather than fail closed. A broken hook that silently allows everything is recoverable; a broken hook that blocks every tool call is a session-killer.

**The `path.relative(process.cwd(), filePath)` is intentional.** The harness sometimes passes absolute paths and sometimes passes paths relative to the workspace root. Normalizing to a CWD-relative path lets the deny patterns be simple regexes without needing to handle both cases.

**Outside `src/` and `lib/`, the hook allows everything.** This is the key escape hatch. If your team has legitimate unit-test files (and you should — pure logic with no I/O still benefits from unit tests with mocks), put them in `__tests__/` at the repo root, not under `src/`. The hook leaves those alone.

**The deny patterns are deliberately conservative.** They catch the standard JS/TS conventions but don't try to be exhaustive. If the agent finds a way around them by inventing a new naming convention, it's no longer "the agent cheating" — it's "the agent doing something so unusual a human would notice in code review." That's the right boundary for a deterministic hook.

---

## What the agent does when it gets blocked

The interesting question isn't "does the hook block." It's "what does the agent do next."

In practice, when Claude (or any other model running through this harness) tries to write `src/auth/login.test.ts` and gets the deny back, it does one of three things:

1. **Adapts and runs `/validate` against the real auth flow.** This is the desired outcome. About 70% of the time, this is what happens, especially after the first time the agent has been blocked in a given session and learned from the deny message.

2. **Tries a slight variation of the file path** (e.g., `src/auth/login.tests.ts` plural). The hook catches the standard variations; this one happens to pass. I update the hook patterns when I see this in production. The deny patterns have evolved over a few weeks of real use.

3. **Asks for permission to bypass.** Rare, but it happens — the agent will explain that it wants to write a unit test for a pure function and ask the user. This is also fine; the user gets to decide. The hook doesn't prevent the user from manually authorizing a test file outside the agent's autonomous flow.

The key insight is that the deny message itself is part of the tooling. A bad deny message ("blocked: forbidden") leaves the agent confused. A good deny message ("blocked: write outside src/ instead, or use /validate to verify the real system") gives the agent a clear next action. I rewrote that message three times before I was happy with it.

---

## What this pattern is good for beyond no-mock enforcement

The PreToolUse hook pattern generalizes. Anywhere your team has a "the agent shouldn't do X" rule that you currently enforce in code review (and therefore inconsistently), a hook can enforce it deterministically.

Examples I've seen teams use the pattern for:

- **Block direct database writes from `src/`** — force all writes through a defined repository layer. Deny pattern matches direct ORM calls outside `src/repositories/`.
- **Block secret-looking strings in committed files** — regex match against API key shapes, exit 2 with a deny reason. Cheaper than git-secrets in CI; catches the secret before the file is even written.
- **Block schema migrations without an accompanying rollback file** — Write to `migrations/*-up.sql` is denied unless `migrations/*-down.sql` exists.
- **Block `console.log` introduction in production code paths** — for teams that have a real reason to lint this rather than just let it flow.

The pattern is the same shape every time: read the tool-call payload, check it against a policy, exit 0 or exit 2 with a clear reason. The implementation in each case is small enough that one engineer can write and maintain it without it becoming a project of its own.

The cost of this pattern is roughly nothing — Node subprocesses are milliseconds, the hooks are deterministic and easy to reason about, and the model can't argue with them. The benefit is that you stop having to enforce policy through code-review attention, which scales much worse than agentic dev does.

---

## Where to find this in the repo

The full hook source is at `hooks/block-test-files.js` in the ValidationForge repo. There are five other hooks in the same directory worth reading if this pattern is interesting to you — `evidence-gate-reminder.js`, `validation-not-compilation.js`, `completion-claim-validator.js`, `mock-detection.js`, and `evidence-quality-check.js`. Together they implement the full enforcement layer.

→ [github.com/krzemienski/validationforge/tree/main/hooks](https://github.com/krzemienski/validationforge/tree/main/hooks)

If you want to lift this pattern into your own plugin, the hook layer is the contribution — not the brand name. Take it. The point of publishing this is that more people enforce the gate, not that more people install my specific implementation.

If your team is rolling out hook-based enforcement and the policy you actually need is more complex than the no-mock case (more deny conditions, integration with internal systems, audit logging) — that's the kind of consulting engagement I'm taking on this quarter. DM with a one-paragraph note on what you're trying to enforce.

The deeper point: hooks let you encode team policy as deterministic gates the AI cannot route around. That's an underused tool in the agentic-dev playbook. The first hook is the hardest one. After that, your team will start finding more places to apply the pattern than you initially expected.
