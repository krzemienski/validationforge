---
channels: LinkedIn (native long-form article) + personal blog (canonical) + Dev.to cross-post
word_count: ~2,010
send_week: Week 6 — Thu May 29, 2026 (8:30am ET)
source_post: /Users/nick/Desktop/blog-series/posts/post-07-prompt-engineering-stack/post.md
companion_repo: https://github.com/krzemienski/shannon-framework
voice: Direct. Technical. Slightly contrarian. No emojis.
role_in_calendar: Most actionable post in the series — drop-in hooks readers can ship the same week.
---

# The 7-Layer Prompt Engineering Stack: Why Writing Better Rules Doesn't Work

I had 14 rules in my CLAUDE.md. The agent followed 11 consistently. The other three failed at rates that made them decorative.

The three that broke: "never create test files," "always compile after editing," "read the full file before modifying it." 47 test files created despite a clear prohibition. 112 edits to files the agent hadn't read. 63 premature "complete" declarations where the agent claimed a task was done without building the code.

Here is the thing. The agent understands every rule. It can explain why each one exists. It will recite them back if you ask. Then 11 tool calls later, deep in a problem-solving loop, it creates `auth.test.ts` because that is what its training says a responsible developer does.

Writing rules is easy. Getting an AI agent to follow them under pressure? Completely different problem.

## The gap between understanding and compliance

Watch this failure mode play out. You write a clear instruction at the top of CLAUDE.md:

> NEVER write mocks, stubs, test doubles, unit tests, or test files. ALWAYS build and run the real system. Validate through actual user interfaces. Capture and verify evidence before claiming completion.

Six lines. Unambiguous. The agent reads this at the start of every session. Then the session grows. By tool call 40, those six lines are competing with 30,000+ tokens of accumulated context: code it has read, errors it has debugged, plans it has made. The instruction does not disappear. It just loses salience. The agent has been reading Swift files for 20 minutes. It knows the codebase has no tests. Then it writes `UserServiceTests.swift` because the pattern is so deeply embedded in its training that it fires automatically.

You cannot solve this by writing better instructions. I tried for weeks — rephrasing, adding emphasis, bolding text, moving the instruction to different positions in the file. The violation rate barely moved. The problem is structural: a single-layer system cannot maintain discipline across a long session.

The solution borrows from Claude Shannon's information theory: reliable communication over a noisy channel requires redundant encoding. Same principle applies to agent discipline. Say the same thing seven different ways, through seven different mechanisms, and the message gets through.

Across 23,479 sessions spanning 42 days, the Skill tool fired 1,370 times. ExitPlanMode, the gate that prevents agents from writing code before planning, triggered 111 times. Those are enforcement mechanisms doing real work. They only work because they are part of a stack, not standalone instructions.

## The 7-layer stack

Seven layers. Each one reinforces the same rules through a different mechanism.

**Layer 1 — Global Constitution.** `~/.claude/CLAUDE.md`. Applies to every project on every machine. Projects can add laws but cannot override it. The non-negotiable mandates live here: functional validation only, no test files, no mocks, evidence-based completion claims.

**Layer 2 — Rules Directory.** `.claude/rules/*.md`. A 50-line focused file gets more reliable attention than 50 lines buried in a 500-line document. I split governance into nine files: `coding-style.md`, `security.md`, `testing.md`, `git-workflow.md`, `performance.md`, `agents.md`, `patterns.md`, `hooks.md`, `development-workflow.md`. Each file covers one concern.

**Layer 3 — Hooks.** Code that runs on every tool call. This is where rules become enforceable. PreToolUse hooks fire before a tool executes and can block the call entirely. PostToolUse hooks fire after and inject corrective reminders. The agent cannot ignore a hook that returns `{ "decision": "block" }`.

**Layer 4 — Skills.** Structured workflows with routing tables and gates. A skill like `functional-validation` is a step-by-step protocol an agent invokes when it needs to prove something works. Skills carry project-specific context the agent does not have by default. 1,370 skill invocations across the dataset kept agents on prescribed workflows instead of improvising.

**Layer 5 — Agents.** Specialized roles with scoped instructions. A `code-reviewer` agent has a review checklist baked into its prompt. A `build-fixer` agent knows to check DerivedData and clean caches. Each agent carries domain knowledge the main agent forgets under context pressure.

**Layer 6 — MCP Tools.** External capabilities with built-in constraints. The sequential thinking tool (327 invocations across all sessions) forces structured reasoning before implementation. These tools add discipline through their interface design, not through written rules.

**Layer 7 — Session Start Hooks.** Inject the full governance context from turn one. Before the agent has any competing context, it loads the rules, the project constitution, and the enforcement expectations. Sets the behavioral baseline before problem-solving begins.

The principle is defense in depth. If the agent forgets the build command (Layer 1 failure), the auto-build hook catches it (Layer 3). If the hook misses it, the evidence gate blocks premature completion claims (Layer 4). No single layer is sufficient. All seven together produce results that no single layer achieves alone.

## Hooks: where rules become enforceable

Layers 1 and 2 are suggestions. Layer 3 is enforcement. A hook is a JavaScript function Claude Code runs automatically on every tool call.

Here is `block-test-files.js` from the [shannon-framework](https://github.com/krzemienski/shannon-framework) repo. This hook dropped test file creation from a 23% violation rate to zero:

```javascript
const TEST_PATTERNS = [
  /\/__tests__\//, /\.test\.[jt]sx?$/, /\.spec\.[jt]sx?$/,
  /\.mock\.[jt]sx?$/, /test_.*\.py$/, /.*_test\.py$/,
  /.*_test\.go$/, /Tests?\.swift$/, /mock[_-]/i, /stub[_-]/i,
];

const ALLOWED_EXCEPTIONS = [/playwright/i, /e2e/i];

export default function blockTestFiles({ tool, input }) {
  if (!["Write", "Edit", "MultiEdit"].includes(tool)) {
    return { decision: "allow" };
  }
  const filePath = input.file_path || input.filePath || "";
  for (const exception of ALLOWED_EXCEPTIONS) {
    if (exception.test(filePath)) return { decision: "allow" };
  }
  for (const pattern of TEST_PATTERNS) {
    if (pattern.test(filePath)) {
      return {
        decision: "block",
        message: `BLOCKED: Cannot create test file: ${filePath}\n` +
          "This project uses functional validation, not unit tests.",
      };
    }
  }
  return { decision: "allow" };
}
```

This hook went through three versions. Version 1 blocked everything with "test" in the filename, which also blocked `testimonials.tsx`. Version 2 added the `ALLOWED_EXCEPTIONS` list. Version 3 added content-pattern detection after an agent created `search-verification.ts` with no `.test.` in the name — but the file contained assertion functions, expected-output comparisons, and a `runVerification()` entry point. A test suite wearing a trench coat.

## The five hooks that survived production

I built 23 hooks. Five survived. The 18 failures taught me more than the five successes.

**`block-test-files.js`** — PreToolUse on Write/Edit. Violation rate: 23% to 0%. The most dramatic improvement in the stack.

**`read-before-edit.js`** — PreToolUse on Edit. Violation rate: 31% to 4%. Tracks which files have been read in the session and warns when an agent tries to edit an unread file. The warn-not-block approach matters here: sometimes the agent legitimately creates a new file from scratch. Blocking would break that workflow.

**`validation-not-compilation.js`** — PostToolUse on Bash. Violation rate: 41% to 9%. Catches the failure mode where the agent runs `pnpm build`, sees "Build succeeded," and declares the feature complete. Something interesting happened after hundreds of sessions. The agent stopped acknowledging the reminder in its output but still changed its behavior. Learned compliance. The behavioral shift persists even when the agent stops visibly responding to the prompt. I am still not sure why that happens.

**`evidence-gate-reminder.js`** — Fires on TaskUpdate. When a subagent marks a task complete, this hook injects a five-point evidence checklist:

- Did I READ the actual evidence file (not just the report)?
- Did I VIEW the actual screenshot (not just confirm it exists)?
- Did I EXAMINE the actual command output (not just the exit code)?
- Can I CITE specific evidence for each validation criterion?
- Would a skeptical reviewer agree this is complete?

Task completion quality improved 34% after deploying this hook. The agent started quoting specific screenshot contents and command output lines instead of saying "screenshot confirms functionality."

**`skill-activation-check.js`** — UserPromptSubmit hook. Reminds the agent to scan available skills before jumping into code. This hook drives the 1,370 skill invocations I measured.

The 18 hooks that died: `max-file-size`, `no-console-log`, `import-order`, `commit-message-reviewer`, `type-annotation-enforcer`, `function-length`, `single-responsibility`, and ten more.

The pattern is clear: if the violation can be objectively detected from the tool input alone, a hook works. `block-test-files.js` checks a filename — deterministic, no judgment calls. `function-length` requires parsing the full file, understanding function boundaries, and deciding whether 52 lines is too many. Subjective, slow, wrong often enough to be counterproductive.

> Hooks should enforce safety invariants, not style preferences. "Don't commit API keys" is a safety invariant. "Functions should be under 50 lines" is a style preference with too many legitimate exceptions.

## Subagent inheritance: the gap that breaks everything

The main agent follows the constitution. Then it spawns a subagent via the Task tool, and the subagent starts with zero governance context. I measured this gap: 68% compliance for subagents without constitution injection versus 95% with it. A 27-point drop, just because the rules did not get passed along.

The fix is a PreToolUse hook on the Agent tool that automatically injects core rules into every subagent prompt. When the main agent spawns a `code-reviewer`, the hook appends the functional validation mandate, the no-test-files rule, and the evidence-gate checklist to the subagent's instructions.

This is the single most important lesson from the stack: governance must be automatic and inherited. 2,827 Task spawns and 929 Agent calls across all 23,479 sessions. That is 3,756 opportunities for governance to drop. Automatic injection eliminates the failure mode entirely.

## The CLAUDE.md inheritance chain

The constitution layer is not a single file. It is a hierarchy.

**Global** (`~/.claude/CLAUDE.md`) sets the non-negotiables that apply to every project. **Project** (`./CLAUDE.md`) adds project-specific context: the build command, the tech stack, known pitfalls. **Rules** (`.claude/rules/*.md`) break concerns into focused files.

Why not just one big file? I tested both. A single 800-line CLAUDE.md produced 72% compliance on rules in the bottom half of the file. The same rules split into focused files: 89% compliance. Position in the file matters for a single document. Position in a separate file does not, because each file starts at line 1.

The agent follows rules at the top of a long file more than rules at the bottom. That is wild and worth absorbing.

## What the numbers show

Across the measured sessions, the aggregate violation rate dropped from 3.1 per session to 0.4 — an 87% reduction. Hook overhead: 7ms per tool call, undetectable in practice.

The Read-to-Write ratio is 9.6:1. Agents read roughly ten times more than they write. Before the read-before-edit hook existed, the ratio was closer to 4:1. The hook did not just prevent blind edits. It changed the agent's entire approach to code modification. More reading means more context means fewer bugs. I was not expecting a single hook to shift the reading behavior that dramatically.

CLAUDE.md alone: 60% compliance. Hooks alone: 75%. Skills alone: 80%. All seven layers together: 95%+. The remaining 5% is why you still review the output. The difference between 60% and 95% is the difference between an agent that creates work and an agent that saves it.

## Building your own stack

The [shannon-framework](https://github.com/krzemienski/shannon-framework) repo contains working implementations of every hook and skill described above. Drop them into your project:

```bash
cp -r hooks/ .claude/hooks/
cp -r skills/ .claude/skills/
cp -r agents/ .claude/agents/
```

Start with three hooks. `block-test-files.js` if you want functional validation discipline. `read-before-edit.js` if your agents make blind edits. `validation-not-compilation.js` if you are tired of premature "done" declarations. Measure violation rates for a week before adding more.

The hooks that survive production share two properties: objective detection from tool inputs alone, and low false-positive rates after calibration. If you cannot define the violation in a regular expression or a simple conditional, it does not belong in a hook. Put it in a skill or an agent prompt instead, where the agent can apply judgment.

This stack came out of the same 42 days that produced ValidationForge. The no-test-files hook in this post is the same hook that ships with VF, just with a different rules layer wrapped around it.

If you are an engineering leader trying to install this kind of governance for a team that has already adopted AI-assisted development and is starting to feel the discipline gap, that is the conversation I am taking on this quarter. A LinkedIn DM with a one-paragraph note on your current stack and where you would like the violation rate to be in 90 days is the fastest way to start. I respond within two business days.

The prompt engineering stack is not a document. It is a system. Treat it like one.

---

*Nick Krzemienski — building ValidationForge and the Shannon framework. 23,479 Claude Code sessions across 27 projects taught me that writing better rules does not work. Encoding them in seven layers does. Repo: github.com/krzemienski/shannon-framework*
