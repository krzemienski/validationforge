# ValidationForge: 12-Week Launch Plan

**Version:** 1.0.0 | **Date:** March 10, 2026
**Goal:** From current state (scaffolding complete, unverified pipeline) to 500+ installs, 200+ stars, 2 consulting leads.

---

## 0. Current State Assessment

### What's Ready
- [x] 40 skills, 15 commands, 7 hooks, 5 agents, 8 rules (file inventory verified)
- [x] Cross-references intact (zero broken across 15 commands)
- [x] Hook bug fixed (object vs string coercion)
- [x] Manual validation: 7/7 journeys PASS against real Next.js project
- [x] Plugin manifest format matches ecosystem patterns
- [x] PRD v2.0.0 complete
- [x] Competitive analysis complete
- [x] 18-post blog series (content engine ready)

### What's NOT Ready (Launch Blockers)
- [ ] `/validate` end-to-end pipeline (never run as automated command)
- [ ] Plugin loads in fresh Claude Code session
- [ ] `/vf-setup` initialization flow
- [ ] Demo GIF showing real bug caught
- [ ] Install guide (<30 seconds)
- [ ] 10 skills deep-reviewed for instruction quality
- [ ] SPECIFICATION.md updated to match actual inventory (40/15/7/5/8)
- [ ] README.md updated with honest verification status
- [ ] GitHub repo created and pushed

---

## 1. Pre-Launch: Fix Launch Blockers (Weeks -4 to 0)

> **Buffer policy:** Each phase below includes buffer days. If pipeline verification fails (likely — it's never been tested), the timeline absorbs it without shifting downstream dates.

### Weeks -4 to -3: Pipeline Verification + Fix Cycle

| Day | Task | Success Criteria | Owner |
|-----|------|-----------------|-------|
| W-4 Mon | Fix plugin.json (add 5 directory declarations) | Plugin manifest complete | Dev |
| W-4 Mon | Verify plugin loads in fresh CC session | Plugin registers, skills discoverable | Dev |
| W-4 Tue | Test `/vf-setup` initialization | Creates `~/.claude/.vf-config.json` | Dev |
| W-4 Wed | Run `/validate` against blog-series/site | Full pipeline executes, report generated | Dev |
| W-4 Thu | Run `/validate` against a Python API project | Platform detection → API validation flow | Dev |
| W-4 Fri | Test `/validate-ci` exit codes | 0 on PASS, 1 on FAIL, evidence written | Dev |
| W-3 | **Buffer week:** Fix all pipeline failures discovered | All 5 tests from above work | Dev |
| W-3 | Run 5 benchmark scenarios for real evidence | Evidence captured for each scenario | Dev |

### Week -2: Content & Demo Preparation

| Day | Task | Success Criteria | Owner |
|-----|------|-----------------|-------|
| Mon | Deep-review 10 core skills (L0-L2) | No broken instructions, clear PASS criteria | Dev |
| Tue | Record demo GIF: real bug caught | 30-second GIF showing detection + evidence | Dev |
| Wed | Write install guide | Clone → install → first `/validate` in <30 seconds | Dev |
| Thu | Update README with verification status | Honest "what works / what doesn't" table | Dev |
| Fri | Create GitHub repo, push code | Public repo with README, LICENSE (MIT), demo GIF | Dev |

### Week -1: Launch Prep

| Day | Task | Success Criteria | Owner |
|-----|------|-----------------|-------|
| Mon | Submit to Anthropic plugin directory | PR submitted with plugin.json | Dev |
| Tue | Submit to 5 awesome lists | 5 PRs submitted | Dev |
| Wed | Write LinkedIn article (Post 03 adaptation) | 2,500 words, VF CTA embedded | Content |
| Thu | Prepare Twitter/X thread (10 tweets) | Draft with benchmark scenarios visual | Content |
| Fri | Final end-to-end test | Fresh machine install + validate works | Dev |

### Week 0: Customer Discovery (parallel with launch)

| Task | Target | Owner |
|------|--------|-------|
| DM 10 Claude Code power users for validation pain point interviews | 5 responses | Dev |
| Post in Claude Code Discord asking about validation workflows | 10 replies | Dev |
| Document findings in customer-discovery.md | Validated/invalidated persona assumptions | Dev |

---

## 2. Soft Launch (Weeks 1-2)

**Goal:** 100 installs, 50 stars, identify first bugs from real users.

### Week 1: Blog-Led Launch

| Day | Activity | Channel | Metric |
|-----|----------|---------|--------|
| Mon | Publish Post 03 on blog site | Blog | Page views |
| Mon | Post LinkedIn article + card | LinkedIn | Impressions |
| Tue | Twitter/X thread | Twitter | Impressions |
| Tue | Announce in Claude Code Discord | Discord | Reactions |
| Wed | Post to r/ClaudeAI | Reddit | Upvotes |
| Thu | Post to r/programming | Reddit | Upvotes |
| Fri | Respond to all comments/issues | All | Response time |

### Week 2: Beta Tester Recruitment

| Day | Activity | Target |
|-----|----------|--------|
| Mon-Wed | DM 20 Claude Code power users | 10 beta testers |
| Thu | Set up GitHub Discussions | Q&A channel live |
| Fri | First "Weekly Validation Report" (internal) | Track install/star velocity |

**Week 2 Targets:**
- 100 installs (GitHub clones)
- 50 GitHub stars
- 10 beta testers actively using VF
- 5 GitHub issues filed (signals real usage)
- 0 critical bugs unfixed

---

## 3. Community Push (Weeks 3-4)

**Goal:** 500 installs, 200 stars, community traction.

### Week 3: Amplification

| Activity | Channel | Target |
|----------|---------|--------|
| "Show HN: We stopped writing unit tests for AI code" | Hacker News | Front page |
| Cross-post to Dev.to | Dev.to | 1K views |
| Cross-post to Medium | Medium | SEO |
| Blog Post 08 (FORGE engine) publish | Blog | VF feature awareness |
| Discord server launched | Discord | 30 members |

### Week 4: Content Depth

| Activity | Channel | Target |
|----------|---------|--------|
| Blog Post 02 (CONSENSUS) publish | Blog | Feature awareness |
| First case study: "How VF caught 5 bugs in [project]" | Blog + LinkedIn | Credibility |
| Respond to HN comments (if front page) | HN | Engagement |
| Beta tester feedback synthesis | Internal | Feature priorities |

**Week 4 Targets:**
- 500 installs
- 200 stars
- 30 Discord members
- 1 case study published
- First awesome list PR merged

---

## 4. Growth Phase (Weeks 5-8)

**Goal:** 2,000 installs, 1,000 stars, first consulting lead.

### Week 5-6: ProductHunt & Expansion

| Activity | Channel | Target |
|----------|---------|--------|
| ProductHunt launch | ProductHunt | Top 10 daily |
| LinkedIn series (5 posts over 2 weeks) | LinkedIn | 25K total impressions |
| Guest post on testing/quality blog | External | New audience |
| V1.1 release (beta feedback fixes) | GitHub | Retention |

### Week 7-8: Depth & Authority

| Activity | Channel | Target |
|----------|---------|--------|
| Second case study | Blog | Enterprise credibility |
| "Validation Office Hours" livestream #1 | YouTube/Twitch | 20 live viewers |
| Community skill contribution guide | GitHub | Enable contributions |
| Blog posts 04-07 published (4 posts) | Blog | Sustained content |

**Week 8 Targets:**
- 2,000 installs
- 1,000 stars
- 100 Discord members
- 2 case studies
- V1.1 shipped
- 1 consulting inquiry

---

## 5. Enterprise Exploration (Weeks 9-16)

> **Note:** Enterprise sales cycles are 3-6 months minimum. This phase starts conversations; deals close in a separate Phase 2 plan after product-market fit is confirmed.

**Goal:** 3,000 installs, 1,500 stars, 5 enterprise conversations started.

### Week 9-12: Outreach & Learning

| Activity | Channel | Target |
|----------|---------|--------|
| Direct outreach to 10 companies using Claude Code | Email/LinkedIn | 5 conversations |
| "AI Code Validation Audit" service page | Website | Lead capture |
| Blog posts 09-11 published | Blog | Authority |
| V1.5 planning (CONSENSUS engine) | Internal | Roadmap signal |
| Customer discovery synthesis: validate/invalidate personas | Internal | Decision document |

### Week 13-16: Iteration

| Activity | Channel | Target |
|----------|---------|--------|
| "3 Months of VF" retrospective post | Blog + LinkedIn | Transparency |
| Community retrospective | Discord | Feedback synthesis |
| V1.5 beta (CONSENSUS engine) — only if validated | GitHub | Feature expansion |
| Revenue model decision based on customer discovery | Internal | Go/no-go on consulting |

**Week 16 Targets:**
- 3,000 installs
- 1,500 stars
- 200 Discord members
- 5 enterprise conversations completed
- Revenue model validated or pivoted based on customer discovery
- V1.5 beta shipped

---

## 6. Key Milestones

```
Week -2 ─── Pipeline works end-to-end
Week -1 ─── Demo GIF recorded, README updated
Week  0 ─── GitHub public, awesome list PRs submitted
Week  1 ─── Post 03 published, 50 stars
Week  3 ─── "Show HN" submission
Week  4 ─── 200 stars, 500 installs, first case study
Week  6 ─── ProductHunt launch
Week  8 ─── 1,000 stars, first consulting inquiry
Week 12 ─── 2,000 stars, 2 consulting deals, V1.5 beta
```

---

## 7. Risk Mitigations

| Risk | Mitigation | Trigger |
|------|------------|---------|
| `/validate` doesn't work end-to-end | Delay launch until fixed. No launch without working pipeline. | Pre-launch testing |
| Low HN traction | Have Reddit/Dev.to fallback. Don't depend on single channel. | <10 points after 4 hours |
| Negative "no unit tests" backlash | Prepare detailed rebuttal post with data. Lean into controversy. | Sustained negative comments |
| No consulting leads by Week 8 | Pivot to "free audit" offers. Lower barrier. | Zero inquiries |
| Beta testers find critical bugs | Hot-fix protocol: <24h for critical, <72h for high. | Any critical bug |
| Plugin directory PR rejected | Ship via direct GitHub install. Re-submit after feedback. | PR denied |

---

## 8. Budget

| Item | Cost | Notes |
|------|-----:|-------|
| Domain (validationforge.dev) | $12/yr | Redirect to GitHub initially |
| ProductHunt Ship subscription | $0 | Free tier |
| Discord server | $0 | Free |
| Demo recording tools | $0 | Screen capture built-in |
| LinkedIn premium (optional) | $60/mo | For outreach analytics |
| **Total pre-revenue** | **$72** | Essentially zero |

---

## 9. Success Criteria for Launch Decision

**Launch ONLY when ALL of these are true:**

- [ ] `/validate` completes successfully on 2+ project types (web + API minimum)
- [ ] Plugin loads and registers in a fresh Claude Code session
- [ ] Demo GIF recorded showing a real bug caught
- [ ] Install guide verified by someone who hasn't seen the project
- [ ] README accurately reflects verification status (no dishonest claims)
- [ ] At least 10 skills deep-reviewed for instruction quality
- [ ] SPECIFICATION.md matches actual inventory numbers

**If any blocker remains at Week 0:** Delay launch. No partial launches. Ship verified, not "it compiled."
