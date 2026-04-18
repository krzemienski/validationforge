# Channel Playbooks: ValidationForge Launch

Per-channel rules of engagement. Each section: when to post, exactly what works, what kills you, escalation paths.

---

## X / Twitter

**Account:** Nick's personal handle (existing follower base is the seed).

**Cadence:**
- 1-2 standalone posts per day
- 1 long-form thread (8-10 tweets) every 3-4 days
- Quote-tweet ecosystem peers (OMC, Superpowers, Anthropic devrel) when natural — never piggyback awkwardly

**Best send times (ET):**
- 9:00am — dev community wake-up scroll
- 1:00pm — lunch scroll
- 7:30pm — evening engagement window

**Hook formula for primary posts:**
1. Bold technical claim (one line)
2. Screenshot of real terminal output / evidence file
3. CTA: repo link OR install command (NOT both)

**What works on X for dev launches:**
- Visible receipts (terminal output > marketing screenshots)
- Self-deprecating "I shipped this broken because..." framing
- Threading a real bug → real fix → real verdict story
- Dropping a single, undeniable artifact ("here is the file path")

**What kills you:**
- Hashtag stacking (#AI #LLM #ClaudeCode #Validation = spammer signal)
- Excessive emojis (any 🚀 in launch context = founder cringe)
- "Big day for our team" framing
- Tagging Anthropic accounts unsolicited

**Engagement protocol:**
- Reply to every substantive question within 1 hour during waking hours
- Ratio target: ≥1 reply per 5 likes on launch tweets (low ratio = dead post)
- Quote-tweet skeptics with evidence, never with rhetoric

**Escalation: post is bombing**
After 2 hours, if <100 impressions: do not delete. Pin the supporting receipt thread. Move on. Next day fresh.

---

## Hacker News

**Strategy:** ONE high-stakes Show HN. Drop on Tuesday Apr 28, 8:00am ET (Day 11). This is a single-shot event — treat it that way.

**Title selection (Variant A is recommended; full text in `copy/show-hn-drafts.md`):**
- A: "Show HN: ValidationForge – Claude Code plugin that blocks AI-generated mocks"
- B: "Show HN: I made Claude prove its code works (with cited evidence)"
- C: "Show HN: Compilation isn't validation – a new gate for AI code"

**Body length:** 200-400 words. Lead with the problem (real numbers), describe what VF does (concrete actions), publish the receipt (self-validation result), close with what it isn't.

**The 5-minute author comment (POST IMMEDIATELY after submission):**
A technical detail comment that anticipates the "but how does X work" question. This signals the author is present and primes commenters to ask substantive questions instead of dismissive ones. Draft is in `copy/show-hn-drafts.md`.

**Reply discipline:**
- Respond to every top-level comment within 1 hour during the first 4 hours (most critical window)
- Use evidence to defend, not rhetoric: "Here's the file path" beats "I assure you it works"
- Treat hostile comments as opportunities — calm technical replies often score more karma than the original criticism
- Never argue with someone who refuses to read the linked evidence

**Pre-launch primer (Day 10, evening):**
Notify 5-10 trusted dev friends of the planned 8am ET drop time. Ask for upvote within first 30 min if they like it. **Do not coordinate fake comments.** HN moderators detect upvote rings; they do not detect honest organic upvotes from people who actually read the post.

**Escalation: post buried within 30 min**
- Do NOT resubmit same day
- Do NOT email mods asking for reconsideration
- Wait 3 days. Refine title based on what you learned. Try again. Maximum 2 attempts.

**Escalation: post hits front page**
- Cancel everything else for the day
- Stay on the comment thread for 4-6 hours minimum
- Do NOT post the link to other channels for the first 2 hours (HN dislikes seeing the same URL trending elsewhere simultaneously)

---

## Reddit

**Targets:** r/ClaudeAI (Day 4), r/LocalLLaMA (Day 7), r/programming (Day 10).

**Universal rules:**
- Native long-form posts. No bare link drops.
- No CTA in title. CTA in last paragraph only.
- Read each subreddit's rules before posting. Many ban "I built this" without explicit Self-Promo flair.
- Never crosspost identical content to two subs the same day.

### r/ClaudeAI (warmest audience)

- **Title:** "I built a plugin that blocks Claude from creating mock files. 6/6 self-validation PASS." (full draft: `copy/reddit-posts.md`)
- **Lead:** demo GIF + the self-validation receipt
- **Length:** 300-500 words conversational
- **Day:** Day 4 (Tue Apr 21), 9:00am ET
- **Engagement:** answer every comment for first 4 hours

### r/LocalLLaMA

- **Angle:** agent-compatibility — "validation harness compatible with any AI coding agent, not just Claude"
- **Length:** 400-600 words technical
- **Day:** Day 7 (Fri Apr 24), 10:00am ET
- **Risk:** sub leans toward local models — frame VF as "agent-agnostic in spirit, Claude-Code-shaped today, contributions welcome for adapters"

### r/programming

- **Angle:** category-defining manifesto — "Compilation isn't validation: a new gate for AI-assisted development"
- **Length:** 500-800 words, code samples included
- **Day:** Day 10 (Mon Apr 27), 8:00am ET
- **Risk:** harshest audience; mods remove for self-promo regularly. Lead with the **idea**, not the **product**. Product reference moved to bottom paragraph.

**Escalation: post removed by mods**
- Read the removal reason before reposting
- Reach out to mods politely with the actual link if the reason was unclear
- Do not duplicate-post in the same sub within 7 days

---

## LinkedIn

**Format:** 3-part long-form blog series posted natively to LinkedIn (no Medium/Substack mirroring during sprint).

**Why LinkedIn:** the audience-of-audiences. Engineering leaders share to their teams. One viral LinkedIn post = 50 stars from people who would never visit HN.

**Cadence:**
- Part 1 (Day 5, Wed Apr 22): "The Validation Gap in AI-Assisted Development" — manifesto + 23,479-session origin story
- Part 2 (Day 8, Sat Apr 25): "What I Learned Shipping ValidationForge" — mid-sprint lessons + community feedback
- Part 3 (Day 13, Thu Apr 30): "Two Weeks of Evidence-Based Shipping: Results" — honest retro with real numbers

Drafts in `copy/linkedin-blog-series.md`.

**Format rules:**
- No carousels. No infographics. Plain text + occasional embedded screenshot.
- 1500-2200 words per part.
- Open with a story (real bug, specific commit, real consequence).
- Close with a single repo link. No newsletter signup, no mailing list.

**Engagement protocol:**
- Respond to every substantive comment for first 24 hours
- Tag nobody (LinkedIn tag-spam is a turnoff). Accept incoming tags from amplifiers.
- Cross-post link to X with a different framing — never copy-paste

---

## Discord

**Servers:** Anthropic Discord, OMC server, Superpowers community, plugin-dev server.

**Universal rule:** ONE post per server, in the appropriate channel, then engage as a peer in conversations. Never spam, never crosspost.

### Anthropic Discord — #showcase channel
"Just shipped ValidationForge — a Claude Code plugin that enforces evidence-based validation. Self-validated 6/6 PASS, 13/13 criteria. Free, MIT, install: `/plugin marketplace add krzemienski/validationforge`. Happy to answer questions in-thread."

### OMC server — #show-and-tell or equivalent
"For folks running OMC orchestration: VF integrates as a validation handoff. Use ralph/autopilot to build, then `/validate` to verify with cited evidence. Integration guide in repo: docs/integrations/vf-with-omc.md"

### Superpowers server
"VF complements Superpowers: Superpowers TDD discipline for logic, VF for real-system validation of the assembled feature. Composes cleanly. Guide: docs/integrations/vf-with-superpowers.md"

### Plugin-dev community
"For plugin devs: VF is a working reference for hook-driven enforcement (block-test-files.js, evidence-gate-reminder.js). Source is small and readable; might be useful as a pattern."

**What works on Discord:**
- Brevity. Helpful posture. Linking to the right place.
- Following up in threads with actual answers.

**What kills you:**
- @everyone or @here pings (instant ban-worthy)
- Bumping your own message later in the day
- Same message in multiple channels of one server

**Day:** All Discord drops on Day 3 (Mon Apr 20), late afternoon ET.

---

## Engagement Triage Matrix

| Comment type | Response | Time budget |
|---|---|---|
| Substantive technical question | Reply with evidence + file path | 5-10 min |
| Hostile but specific critique | Reply calmly with counter-evidence | 10-15 min |
| Hostile and vague ("this sucks") | One-line acknowledgment, no defense | 1 min |
| Off-topic spam | Ignore (do not feed) | 0 |
| Praise | Thank + ask "what would you want next" | 2 min |
| Bug report | Move to GitHub issue, link the issue back | 5 min |

## Escalation: When to Pull the Plug

If by Day 7 (mid-sprint review) the campaign is on track for <30 stars and zero ecosystem traction:
1. Do not panic-post.
2. Pause the calendar for 24 hours.
3. Identify the single weakest message and reframe it.
4. Resume Day 9 with the refined frame. Skip a planned post if it conflicts.
