# X/Twitter Thread — Post 3: I Banned Unit Tests From My AI Workflow

**Send:** Thu May 21, 8:30am ET (paired with LinkedIn long-form drop)
**Length:** 10 tweets
**Companion repo:** github.com/krzemienski/claude-code-skills-factory

---

### 1/10 — Hook (controversial thesis)

> I banned unit tests from my AI development workflow.
>
> Across 23,479 sessions, a hook I built has now blocked AI agents from creating test files 642 times.
>
> When the AI writes the code AND the tests, passing tests prove exactly nothing.

Char count: 247

---

### 2/10 — The Delete Account button

> The agent said "complete." Build green. TypeScript zero errors.
>
> The function body:
>
> async function deleteUserAccount(id) {
>   // TODO: Implement
> }
>
> Compiled clean. Shipped. User filed a ticket asking why they couldn't delete their account.

Char count: 254

---

### 3/10 — The mirror problem

> The agent that wrote a TODO function body will gladly write a test that mocks the deletion service, asserts the function was called, and reports green.
>
> Test passes. Feature broken. The test confirmed the function exists. It never confirmed it does anything.

Char count: 261

---

### 4/10 — 4 categories of bugs unit tests miss

> When AI writes both sides:
>
> 1. Visual: DOM node exists but CSS hides it
> 2. Integration: client sends JSON, server wants form-data
> 3. Stale state on 2nd interaction
> 4. Platform: works at 1440px, breaks at 375x667
>
> Mocks accept anything. That's what mocks do.

Char count: 273

---

### 5/10 — The hook

> 50 lines of deterministic JavaScript. PreToolUse on Write/Edit.
>
> If the file path matches *.test, *.spec, *.mock, /__tests__/, mock_*, stub_*, fake_*, fixture_* — blocked.
>
> Fired 642 times across 23,479 sessions. One session triggered it 166 times alone.

Char count: 268

---

### 6/10 — The 3-hook chain

> Hook 1: block-test-files (can't write a mirror)
> Hook 2: validation-not-compilation (build success ≠ validation)
> Hook 3: completion-claim-validator (no evidence cited = no completion)
>
> Together they close every escape route. Only path to "done" is the real app.

Char count: 274

---

### 7/10 — The 3-layer stack

> Layer 1: Compile + type-check + lint (necessary, never sufficient)
> Layer 2: Runtime — TCP connect, HTTP 200, expected content marker
> Layer 3: Real UI exercise — Playwright clicks, simulator taps, screenshots
>
> Delete Account passed L1 cleanly. L3 caught it.

Char count: 263

---

### 8/10 — The receipts

> 23,479 sessions. Real numbers:
>
> 2,620 iOS screen taps on real simulators
> 2,165 simulator screenshots
> 2,068 browser automation calls
> 1,239 accessibility tree queries
>
> Not assertions. Actual taps. Actual screenshots. Actual users would see the same thing.

Char count: 273

---

### 9/10 — The result

> 127 agent-generated PRs merged.
>
> Zero "works on my machine" failures.
> Zero post-merge incidents from compiled-but-broken features.
> Zero TODO function bodies in production.
>
> Cost: more validation time per PR. Savings: every other minute.

Char count: 246

---

### 10/10 — Repo + LinkedIn

> The functional-validation skill, the skill generator, and the 3 hooks (block-test-files, validation-not-compilation, completion-claim-validator) — all in the repo.
>
> https://github.com/krzemienski/claude-code-skills-factory
>
> LinkedIn: [LinkedIn URL — fill at post time]

Char count: 215 (URLs count as 23 each)

---

## Posting Protocol

**Best send time:** Thu May 21, 8:30am ET. Paired with LinkedIn drop. Thursday morning is the highest-engagement window for technical contrarian threads on X.

**Pin recommendation:** Pin tweet 1 for the full week. The "banned unit tests" hook is engineered to provoke replies — keep it visible.

**Engagement window:** First 4 hours are critical. This thread will get hostile replies from test-purists. Reply to the substantive ones with concrete numbers (642 blocks, 2,620 taps, 127 PRs with zero post-merge failures). Do not reply to the "this is obviously wrong" replies — they drive engagement either way.

**Cross-link strategy:** Drop the LinkedIn URL as a reply to tweet 10 once live. Don't put it in the main tweet — link previews compete with thread aesthetic.

**Companion media for tweet 2:** Screenshot of the actual TODO function body in a code block. The visual is the proof.

**Companion media for tweet 5:** Snippet of the actual TEST_PATTERNS regex array from `block-test-files.js`. Real code beats prose.

**Anticipated objections + canned replies:**

- "But unit tests catch regressions" → "When AI writes the regression AND the test, the test regresses with it. That's the bug."
- "You're throwing out 50 years of best practices" → "I'm throwing out one specific failure mode: AI-written test for AI-written code. Use unit tests where humans write both sides."
- "What about CI speed?" → "127 PRs merged with zero post-merge incidents. That's the speed metric that matters."
- "This won't scale" → "23,479 sessions in the dataset. It scaled."

**Do not reply with:** "great point!" "appreciate this!" — empty replies tank algorithmic visibility. Reply with a sharper version of the original thesis or a new data point.
