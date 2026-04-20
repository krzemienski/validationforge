# X Thread — VF Launch (v2, aligned with LinkedIn share urn:li:share:7451771702121934848)

All tweets ≤ 280 chars. URLs count as 23. Verified counts below each tweet.
Companion to LinkedIn post: https://www.linkedin.com/feed/update/urn:li:share:7451771702121934848/

---

## T1 — Hook (post first, standalone)

3.4M lines of AI-generated code shipped in 42 days across 27 projects.

Every single line passed unit tests.

Five shipped broken in ways unit tests structurally cannot catch.

Open-sourced the tool I built to close the gap. 🧵

*(234 chars)*

---

## T2 — The five patterns (reply to T1)

Five patterns. Every one a category mocks structurally can't see:

— API field rename (mock returned old field)
— JWT expiry change (mock skipped time)
— iOS deep link (simctl opened wrong screen)
— DB migration (mock had no duplicates)
— CSS overflow (JSDOM doesn't paint)

*(273 chars ✓)*

---

## T3 — Compilation Theater (reply to T2)

When the agent writes both the code AND the test, "build passing" means the agent agrees with itself. That's not the feature working.

I call it Compilation Theater. The missing gate sits between compilation and human review: Evidence-Based Shipping.

*(254 chars)*

---

## T4 — The product (reply to T3)

So I built ValidationForge. Claude Code / OpenCode plugin.

Pre-tool hook blocks mocks in src/. /validate runs against the real system — curl, simctl, Playwright. Every PASS/FAIL verdict has to cite specific evidence: a file path, a response body, a build log line.

*(264 chars)*

---

## T5 — Self-validation receipt (reply to T4)

Pointed VF at itself last week.

6/6 journeys PASS. 13/13 criteria. 0 fix attempts.

The evidence directory is public in the repo. If you think a verdict looks wrong, argue with the file directly — the artifacts are versioned alongside the code.

*(243 chars)*

---

## T6 — Positioning + repo (reply to T5)

Open source, MIT, no telemetry by default.

Composes with OMC (orchestration), Superpowers (TDD), ECC (multi-language rules).

This is product #1 of several at withagents.dev — runbooks, memory, operator UX in the oven.

github.com/krzemienski/validationforge

*(246 chars + URL = 269 effective)*

---

## T7 — For-hire + DM invite (reply to T6)

Taking a small number of architecture review / embedded sprint / monthly retainer engagements this quarter — for teams shipping AI-generated code feeling the validation gap.

If you just want to talk agent dev — DMs open. Can't stop thinking about this and I like the company.

*(277 chars)*

---

## Reply to T7 (amplification — linkback to LinkedIn)

Full writeup with the 3 failure modes I see most often in teams adopting agentic dev + what engagements look like:

https://www.linkedin.com/feed/update/urn:li:share:7451771702121934848/

*(166 chars + URL = 189 effective)*

---

## Posting protocol

### Pre-flight
1. Verify LinkedIn post is live ✓ (already confirmed — urn:li:share:7451771702121934848)
2. Remove 🧵 emoji in T1 if preferred — rest of thread is emoji-free
3. Final voice read before posting

### Post order
- T1 standalone → wait for it to land
- T2–T7 as sequential replies (use x.com "Add post" button, don't quote-tweet)
- Reply to T7 with LinkedIn URL as amplification
- Pin T1 to profile for 48h

### First-2-hour engagement discipline
- Reply to every substantive reply within 10 min
- Quote-tweet skeptical replies with receipt screenshots from `e2e-evidence/self-validation/`
- Do NOT stack hashtags (#AI #LLM #ClaudeCode = downranked by dev algo)
- Do NOT tag @AnthropicAI unsolicited

### Avoid
- "Big day" / "excited to share" openers (T1 is doing that work)
- Emoji stacking beyond the single 🧵
- Cross-tagging unrelated accounts

---

## Posting routes (choose one)

### Route A — Manual paste (fastest, 5-7 min)
Copy each tweet, paste into x.com compose, add each subsequent as a "reply to my tweet above". Pin T1 after all 7 post.

### Route B — X API v2 via OAuth 2.0 (requires one-time setup)
X now requires a developer account ($200/mo Basic tier minimum for write access as of 2024).
If the tier is already provisioned, flow is:
  1. POST /2/tweets { text: T1 } → capture tweet.id
  2. POST /2/tweets { text: T2, reply: { in_reply_to_tweet_id: T1.id } } → repeat T3-T7
  3. POST /2/tweets { text: amplification, reply: { in_reply_to_tweet_id: T7.id } }
  4. POST /2/users/:id/pinned_tweets { tweet_id: T1.id }
No X creds currently in integrations/ — setup would add ~30-45 min.

### Route C — Chrome MCP drives x.com (60-90 min)
Similar to the LinkedIn Pulse attempt. Requires you log into x.com in the Chrome MCP window, then I drive the compose flow.
