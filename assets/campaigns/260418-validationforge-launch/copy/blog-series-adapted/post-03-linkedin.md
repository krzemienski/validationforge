# I Banned Unit Tests From My AI Workflow

**Channels:** LinkedIn (native long-form article) + Reddit r/ExperiencedDevs + Medium (Better Programming) + Dev.to.
**Word count target:** 2,000-2,400 (body, excluding frontmatter and sign-off).
**Send week:** Week 5 — Thu May 21, 8:30am ET.
**Source post:** /Users/nick/Desktop/blog-series/posts/post-03-functional-validation/post.md
**Companion repo:** github.com/krzemienski/claude-code-skills-factory
**Voice notes:** Direct, technical, deliberately controversial. No emojis. The thesis is the headline. Defend it with receipts.

---

The agent said the feature was complete. Build passed. TypeScript reported zero errors. I merged the PR, and within minutes a Slack message arrived: "Login button doesn't do anything."

Structurally perfect. Functionally empty. That failure, and the 642 times my system has now blocked agents from creating test files since, is why I banned unit tests from my AI development workflow. I am not anti-test in general. I am anti-mirror. When the AI writes both the implementation and the tests, passing tests prove exactly nothing.

## The Delete Account Button That Did Nothing

Correct icon. Correct confirmation dialog with "Are you sure?" text and a red destructive action style. Loading spinner that appeared on tap. The `onClick` handler called `deleteUserAccount()` with the correct signature, the correct parameter types, the correct error handling wrapper.

The function body:

```typescript
async function deleteUserAccount(userId: string): Promise<void> {
  // TODO: Implement account deletion
}
```

Every static check passed. TypeScript compiled clean. Linter, silent. The agent's self-review confirmed the feature was "complete with proper error handling and user confirmation flow."

Then a user filed a ticket asking why they could not delete their account. Of course they did.

That same week I found six more TODO bodies across the codebase. A password reset function that returned a success response without sending an email. An export endpoint that created an empty file and returned a download link to it. A notification preferences save that validated the input, confirmed the format, and quietly threw the payload away. Each one compiled. Each one linted clean. Each one was "complete" by every metric except the one that matters: does the thing actually do the thing?

## The Mirror Problem

When AI writes both the implementation and the tests, passing tests prove exactly nothing. They are a mirror. Same assumptions reflected back.

The agent that wrote `deleteUserAccount()` with a TODO body would absolutely write a test that mocks the deletion service, asserts the function was called, and reports green. Test passes. Feature broken. The mock replaced the only part that matters (the actual database deletion) with a no-op that always succeeds.

I watched this happen dozens of times before I snapped. Four categories of bugs unit tests miss when the same AI writes both sides:

**Visual rendering bugs.** The component renders, the test confirms the DOM node exists, but CSS places it behind another element or collapses it to zero height. Invisible to automated tests. Obvious in a screenshot.

**Integration boundary failures.** The API client sends `application/json`. The server expects `multipart/form-data`. The unit test mocks the API boundary and never discovers the mismatch. The mock accepts anything. That is what mocks do.

**State management bugs on second interaction.** Form works on first submission. On second submission, stale state from the first interaction corrupts the payload. Tests exercise a feature once and move on. Seven bugs in one admin panel only surfaced through full-flow testing — navigating the complete workflow rather than testing each page in isolation.

**Platform-specific rendering issues.** Layout works on the viewport size the test framework uses. Breaks on iPhone SE. The test never renders at 375x667. Why would it?

A passing test suite is an assertion. A timestamped screenshot is evidence.

## 642 Blocked Test Files

So I built a hook. A `block-test-files` PreToolUse hook that intercepts every file Write and Edit operation. If the target path matches any of 13 regex patterns (test directories, `.test/.spec/.mock` extensions, case-insensitive `mock/stub/fake/fixture` prefixes) the operation gets blocked.

The blocking message: "This project uses functional validation, not unit tests. Instead of writing tests: Build the real system. Run it in the simulator/browser/CLI. Exercise the feature through the actual UI. Capture screenshots/logs as evidence."

Across 23,479 sessions in my dataset, this hook fired 642 times. That is 642 instances where an agent tried to create a test file and got stopped. Every single one was the system preventing an agent from building a mirror instead of exercising the real feature.

The blocked files tell their own story. Session `ad5769ce` alone triggered 166 blocks. Session `5368cad3` triggered 143. Session `fc444b36` hit 75. Look at the filenames and you see what agents want to do when left unchecked: `tests/integration/session-scan.test.ts`, `tests/integration/insight-extraction.test.ts`, `tests/e2e/content-generation.spec.ts`. Every one of these would have tested a mock of the feature, not the feature itself. Every one would have passed while the feature remained broken.

It sounds like I am fighting my tools. I am not. Every block redirects the agent back to the real system. The real thing either works or it does not. There is no mock to hide behind.

## The Three-Hook Enforcement Chain

One hook is not enough. Agents are persistent. Block one path and they will find another. So I built three hooks that form a closed enforcement loop.

**Hook 1: `block-test-files.js`** is the front door. Cannot create a test file, cannot build a mirror. Fired 642 times across the dataset.

**Hook 2: `validation-not-compilation.js`** fires after every Bash command that looks like a build. Agent runs `npm run build` or `xcodebuild`, output shows success, and the hook injects: "Compilation success is NOT functional validation. The real feature must be exercised through the actual user interface." This catches agents that skip test creation but declare victory after a green build.

**Hook 3: `completion-claim-validator.js`** fires when an agent tries to mark a task as complete. It searches the conversation history for evidence of functional validation — Playwright interactions, screenshots, simulator taps. No evidence? Blocked: "BUILD SUCCESS does not equal VALIDATION. You must provide screenshot or log evidence of the feature working through the real UI."

Together, these three hooks close every escape route. Cannot write tests (Hook 1). Cannot pretend compilation equals validation (Hook 2). Cannot claim completion without evidence (Hook 3). The only path to "done" runs through the real application.

## The Three-Layer Validation Stack

After the Delete Account incident, I built a validation stack with three layers. Each catches a different class of failure.

**Layer 1: Compilation and static analysis.** Docker build, TypeScript strict mode, ESLint, Swift compiler. This catches missing dependencies, type mismatches, import errors, syntax mistakes. Necessary but nowhere near sufficient. The Delete Account button passed this layer cleanly. A TODO function body is valid TypeScript, and that is the whole problem.

**Layer 2: Runtime verification.** Start the server. Confirm it responds to HTTP. Verify the response contains expected content markers, not just a 200 status code. This catches runtime crashes, missing environment variables, database connection failures, configuration mismatches.

I kept hitting three false positives in Layer 2 and it drove me nuts. Port open but server crashing on first request: TCP check passes, HTTP request fails. Server responding 200 but body is a framework error page, not the application. Cached response from a previous build served by a reverse proxy while the actual server is not running. The three-check readiness pattern (TCP connect → HTTP 200 → expected content marker) handles all of them.

The content marker is key. Not "does the server respond?" but "does the server respond with the expected application content?" A marker like `<div id="app-root">` confirms the correct application is running, not just any process squatting on the expected port.

**Layer 3: Functional verification through real UI.** Navigate to the page. Snapshot the accessibility tree. Click the button. Check the outcome. If the redirect does not happen, the validation fails. Not because a test assertion fired, but because the screenshot shows the user is still on the settings page after clicking "confirm delete." The agent sees the same thing a user would see. No abstraction layer. No mock. Just the real app.

## 2,068 Browser Automation Calls

"Click the button and check" undersells what this looks like at scale. Across all 23,479 sessions, my agents made 2,068 browser automation calls: 604 `browser_click`, 524 `browser_navigate`, 465 `browser_take_screenshot`, plus hundreds more snapshots and form fills.

One session ran 674 Playwright calls in a single validation pass: 262 clicks, 172 screenshots, 128 navigations, 64 accessibility snapshots, 34 text inputs. Every page. Every form. Every navigation link. Every error state triggerable through the UI.

This session caught a real bug compilation missed. The agent ran `next build` successfully (exit code 0, zero type errors) then navigated to the Automation page via Playwright. The page crashed at runtime: `Cannot find module './vendor-chunks/@opentelemetry.js'`. Build compiled. TypeScript type-checked. The page was broken by a stale `.next` cache. Only browser validation found it. Eleven build/restart cycles before it rendered correctly.

No unit test would have caught that. The stale cache was a runtime artifact that only appeared when the real application loaded the real page in a real browser.

## iOS Validation: 2,620 Screen Taps

The iOS side runs harder. Across all sessions, agents executed 2,620 `idb_tap` calls on real simulators, captured 2,165 `simulator_screenshot` images, and ran 1,239 `idb_describe` calls to query accessibility trees.

The accessibility tree is the coordinate source. No hardcoded pixel positions. When the layout changes, accessibility labels stay the same and tap coordinates update automatically. The automation doesn't break when a button moves 20 pixels. It queries the tree, finds the element by label, calculates the center of its frame, taps there. I expected the coordinate math to be fragile. The accessibility tree turned out to be a rock-solid anchor.

2,620 screen taps. Not test assertions. Actual taps on actual buttons in actual simulators. Each tap followed by a screenshot or accessibility query to verify the result. The validation did not assume the tap worked. It checked.

## The Evidence Standard

Every claim of "done" requires a screenshot, a log, or a recording. Not an assertion that it works. Evidence that it works.

The validation gate tables from real sessions show what this looks like. Phase 1 Gate from session `ad5769ce`: 8 criteria, each with specific evidence. VG1.2: "EventBus emits events" — evidence: `curl emit&count=10` returns `{"emitted":10, "subscriberCount":1, "ringBufferSize":10}`. VG1.5: "Ring buffer works" — evidence: emitted 1001 events, `ringBufferSize: 1000` (capped at configured maximum). Not "it works" but "here is the exact output proving it works, and here is the specific number that confirms the boundary condition."

The iron rule, loaded into every agent session:

```
IF the real system doesn't work, FIX THE REAL SYSTEM.
NEVER create mocks, stubs, test doubles, or test files.
ALWAYS validate through the same interfaces real users experience.
```

And the mock detection responses that catch agents trying to take shortcuts:

- "Let me add a mock fallback" → Fix why the real dependency is unavailable
- "I'll write a quick unit test" → Run the real app, look at the real output
- "I'll stub this database" → Start a real database instance
- "The real system is too slow" → That is a real bug. Fix it.
- "I'll add a test mode flag" → There is one mode: production. Test that.

## Gap Analysis: Finding What Was Never Built

Catching bugs in existing features is half the problem. The other half: discovering features that were never built in the first place.

I tracked spec compliance across 12 projects. The average gap rate was 14.7%. One in seven specified features was missing, incomplete, or implemented differently than the spec described.

Three categories repeated. **Missing:** the spec says "users can export data as CSV" and the export button doesn't exist. **Partial:** filtering works for date range and status, but the assignee filter populates its dropdown without actually filtering results. Looks right. Does nothing. **Divergent:** spec says "password reset link expires in 24 hours" and the implementation uses 1 hour. Not broken. Just wrong.

Continuous gap analysis at phase gates dropped the final gap rate from 14.7% to 2.1%. Catching a gap while the agent is still on the feature costs minutes. Catching it three weeks later during QA costs days.

## The Numbers

Across 23,479 sessions:

- 642 blocked test file creations
- 2,620 iOS screen taps on real simulators
- 2,165 simulator screenshots as evidence
- 2,068 browser automation calls (Playwright + Puppeteer)
- 1,370 skill invocations
- 1,239 iOS accessibility tree queries
- 604 browser clicks on real web pages
- 524 browser navigations
- 465 browser screenshots
- 128 Xcode builds

Every one of those numbers represents a real interaction with a real application running on a real device or browser. Not a mock. Not a stub. Not a test double. Not a green checkmark from a test suite that confirmed a function existed without confirming it did anything.

After I put the three-layer stack together with the three-hook enforcement chain: 127 agent-generated PRs merged with zero "works on my machine" failures. The cost is more validation time per PR. The savings is zero post-merge incidents caused by features that compiled but did not function.

## What I Actually Believe Now

I am not anti-unit-test as some universal principle. Unit tests are great in plenty of contexts. In my AI-generated-code setup specifically, they are theater. When AI writes the code and AI writes the tests and the tests pass and the feature is broken, the tests were never doing what people thought they were doing. They made everyone feel good about a system that did not work.

What replaced them is harder. Real databases, real simulators, real browsers. You cannot run it in a 30-second CI pipeline. When validation passes, the feature works. The user clicks the button and the thing happens. That is the bar.

The companion repo includes the functional validation skill, the skill generator that creates SKILL.md files, the validator that ensures skills have proper validation criteria, and the three hooks (block-test-files, validation-not-compilation, completion-claim-validator).

→ **github.com/krzemienski/claude-code-skills-factory**

The hooks and the validation stack came out of the same 90-day stretch that produced ValidationForge — the Claude Code plugin that productizes the three-layer pattern (github.com/krzemienski/validationforge).

If your team is shipping AI-generated code and seeing "build green, feature broken" incidents, you are at the leading edge of a curve a lot of organizations are about to ride down. I am taking on a small number of advisory engagements this quarter for engineering leadership rolling out agentic development at scale — specifically helping teams replace mock-based testing with evidence-based functional validation. Send me a LinkedIn DM with a one-paragraph note on where you are now and where you want to be in 90 days. I respond within two business days.

Compilation is necessary. Mocks confirm internal consistency. Neither one tells you the user can click the button. The next bar is evidence.

---

*Nick Krzemienski — building functional validation infrastructure and ValidationForge. 23,479 sessions, 642 blocked test files, one stubborn opinion: AI-generated code should ship with screenshots, not assertions. github.com/krzemienski/claude-code-skills-factory*
