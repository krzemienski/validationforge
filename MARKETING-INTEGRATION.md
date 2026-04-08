# ValidationForge: Marketing Integration Plan

**Version:** 1.0.0 | **Date:** March 10, 2026
**Strategy:** Content-led growth using the 18-post "Agentic Development" blog series as VF's primary marketing engine.

---

## 1. Content Funnel Architecture

```
AWARENESS              CONSIDERATION            TRIAL                CONVERSION
─────────────────────  ─────────────────────    ─────────────────    ─────────────────
Blog posts (18)        /validate demo GIF       Free plugin install  VF Cloud signup
LinkedIn cards         Benchmark scenarios      GitHub clone         Consulting inquiry
HN/Reddit threads     Case studies (2+)        /validate-audit      Enterprise demo
Twitter threads       README walkthrough        Community Discord    Training workshop
Conference talks      Comparison matrix                              Custom platform ref
```

---

## 2. Post-by-Post VF Integration Map

Each of the 18 blog posts maps to specific VF features, messaging angles, and calls-to-action.

### Tier 1: Direct VF Posts (highest conversion)

| Post | Title | VF Feature | Why It Matters | CTA |
|:----:|-------|------------|----------------|-----|
| **03** | **Functional Validation** | **VALIDATE engine** | **This IS the VF manifesto.** Explains the philosophy, The Iron Rule, and why mocks fail. | **"Install ValidationForge and run `/validate` on your project today."** |
| **08** | **Ralph Orchestrator** | **FORGE engine** *(Planned V2.0)* | Autonomous build-validate-fix loops. Previews the FORGE vision. | "See the FORGE roadmap — autonomous validation loops coming in V2.0" |
| **02** | **Multi-Agent Consensus** | **CONSENSUS engine** *(Planned V1.5)* | 3-agent unanimous voting. Previews VF's multi-reviewer gate. | "CONSENSUS multi-reviewer gates coming in V1.5" |

### Tier 2: Strong VF Connections (feature showcases)

| Post | Title | VF Feature | Angle | CTA |
|:----:|-------|------------|-------|-----|
| 04 | iOS Streaming Bridge | iOS validation skills | "Validating SSE through the iOS simulator" | "VF auto-detects iOS projects" |
| 05 | iOS Patterns | ios-validation-gate | "4,241 files, zero unit tests — all validated through real devices" | "Read the methodology" |
| 06 | Parallel Worktrees | FORGE parallelism | "18,945 agent sessions need autonomous validation" | "See FORGE parallel validation" |
| 07 | Prompt Engineering Stack | Skill dependency graph | "How 40 VF skills build on each other in 5 layers" | "Explore the skill architecture" |
| 10 | Stitch Design-to-Code | design-validation | "Screenshot-driven visual validation" | "Try design validation" |
| 11 | Spec-Driven Development | create-validation-plan | "Specs become validation plans automatically" | "Generate a validation plan" |
| 13 | Sequential Thinking | error-recovery skill | "84 debugging steps distilled into VF's 3-strike protocol" | "See the fix protocol" |

### Tier 3: Contextual VF References (thought leadership)

| Post | Title | VF Feature | Angle | CTA |
|:----:|-------|------------|-------|-----|
| 01 | Series Launch | Volume context | "23,479 sessions — who validates all that code?" | "Follow the series" |
| 09 | Session Mining | evidence analysis | "Mining validation evidence for actionable insights" | "See the evidence pipeline" |
| 12 | Cross-Session Memory | evidence persistence | "Evidence that survives across sessions" | "Configure evidence retention" |
| 14 | Multi-Agent Merge | CONSENSUS conflicts | "When 3 reviewers disagree — how VF resolves" | "Explore CONSENSUS" |
| 15 | Skills Anatomy | SKILL.md architecture | "Inside a VF skill file — how 40 skills work" | "Contribute a platform skill" |
| 16 | Claude Code Plugins | plugin.json manifest | "VF as a Claude Code plugin — install guide" | "Install in 30 seconds" |
| 17 | CCB Evolution | FORGE autonomous | "From bash scripts to self-correcting agents" | "See FORGE engine" |
| 18 | SDK vs CLI | Distribution patterns | "How plugins reach developers at scale" | "Join the VF community" |

---

## 3. Pillar Content Strategy

### 3.1 Hero Post: Post 03 — Functional Validation

Post 03 is the **pillar content piece** for VF marketing. It must:

1. **Define the problem:** Mock-based testing creates false confidence
2. **Present the evidence:** 5/5 vs 0/5 benchmark table
3. **Introduce the methodology:** The Iron Rule, 7-phase pipeline, evidence tiers
4. **Show the tool:** VF as the implementation of the methodology
5. **Include the install CTA:** Zero-friction path to trying VF
6. **Link to companion repo:** validationforge/ with full source

**Distribution plan for Post 03:**
- LinkedIn article (long-form, 2,500 words)
- LinkedIn card with benchmark table graphic
- Twitter/X thread (10 tweets summarizing key points)
- Hacker News submission ("Show HN: We stopped writing unit tests...")
- r/ClaudeAI, r/programming, r/ExperiencedDevs
- Dev.to cross-post
- Medium cross-post (for SEO)

### 3.2 Controversy Leverage

The "no unit tests" stance is **intentionally polarizing:**

| Reaction | Value |
|----------|-------|
| Agreement | Converts to VF user immediately |
| Disagreement | Shares post to argue → free distribution |
| Curiosity | Clicks through to learn more → awareness |
| Outrage | Comments/quotes extensively → algorithm boost |

**Precise framing (avoid strawman):**
> "We're not against ALL testing. We're against MOCK-BASED testing that drifts from reality. VF validates through real systems, which is MORE rigorous than unit tests."

**Data shield:** The 5 benchmark scenarios illustrate categories of bugs that mock-based testing structurally cannot catch. Anyone arguing must explain why mocks that drift from reality are acceptable. *Note: Empirical benchmark execution is a pre-launch requirement — see TECHNICAL-DEBT.md.*

---

## 4. Social Media Assets Per Post

Each post gets a social media kit stored in `posts/post-{nn}-{slug}/social/`:

```
social/
├── linkedin-card.html       # 1200x627 Open Graph card
├── twitter-card.html        # 1200x628 Twitter card
├── hero-card.html           # Blog hero image
├── benchmark-table.png      # VF benchmark comparison (Post 03+)
├── thread-outline.md        # Twitter/X thread structure
└── linkedin-article.md      # LinkedIn long-form version
```

### Card Design System (Midnight Observatory)

All cards use the blog series design system:
- **Background:** Void Navy `#0f172a`
- **Cards:** Slate Abyss `#1e293b`
- **Accent:** Indigo Pulse `#6366f1`
- **Data:** Cyan Signal `#22d3ee`
- **PASS:** Emerald `#10b981`
- **FAIL:** Crimson `#ef4444`
- **Text:** Cloud `#f1f5f9` / Prose `#cbd5e1`

---

## 5. Cross-Promotion Matrix

### 5.1 Post → VF Feature Deep Links

Every blog post should include at least one of these contextual links:

| Context in Post | VF Deep Link |
|-----------------|--------------|
| Mentions validation | → VF GitHub README |
| Shows evidence/screenshots | → Evidence pipeline docs |
| Discusses multi-agent | → CONSENSUS engine |
| Shows build → test → fix loop | → FORGE engine |
| Mentions iOS | → iOS validation skills |
| Mentions web/Playwright | → Web validation skills |
| Shows code quality | → Benchmark framework |

### 5.2 VF Docs → Blog Post Back-Links

VF documentation should reference specific blog posts as case studies:

| VF Doc Section | Back-link to Post |
|----------------|-------------------|
| "Why not unit tests?" | Post 03 (Functional Validation) |
| Platform detection | Post 04 (iOS), Post 10 (Design) |
| Evidence pipeline | Post 09 (Session Mining) |
| FORGE engine | Post 08 (Ralph Orchestrator) |
| CONSENSUS engine | Post 02 (Multi-Agent Consensus) |
| Skill architecture | Post 07 (Prompt Stack), Post 15 (Skills) |
| Plugin installation | Post 16 (Claude Code Plugins) |

---

## 6. Launch Content Calendar

### Pre-Launch (Week -2 to 0)

| Day | Activity | Channel |
|-----|----------|---------|
| -14 | Record demo GIF (real bug caught by VF) | GitHub |
| -10 | Write install guide (<30 seconds) | README |
| -7 | Create LinkedIn card for Post 03 | Stitch |
| -5 | Draft HN submission text | Internal |
| -3 | Prepare Twitter thread (10 tweets) | Internal |
| -1 | Final README review, demo GIF embedded | GitHub |

### Launch Week (Week 1)

| Day | Activity | Channel | Target |
|-----|----------|---------|--------|
| Mon | Publish Post 03 on blog | Blog site | — |
| Mon | LinkedIn article + card | LinkedIn | 5K impressions |
| Tue | Twitter thread | X/Twitter | 2K impressions |
| Wed | "Show HN" submission | HN | Front page attempt |
| Thu | r/ClaudeAI, r/programming | Reddit | 100 upvotes |
| Fri | Dev.to cross-post | Dev.to | SEO |

### Post-Launch (Weeks 2-12)

| Week | Content | Channel |
|------|---------|---------|
| 2 | Post 04 (iOS Streaming Bridge — real platform validation) | Blog + LinkedIn |
| 3 | Post 07 (Prompt Engineering Stack — skill architecture) | Blog + LinkedIn |
| 4 | First case study (real project validated) | Blog |
| 6 | ProductHunt launch | ProductHunt |
| 8 | Second case study | Blog |
| 10 | Guest post on testing blog | External |
| 12 | "3 months of VF" retrospective | Blog + all channels |

---

## 7. Community Building Integration

### 7.1 Blog → Community Pipeline

```
Reader discovers post → Tries /validate → Joins Discord → Contributes skill → Becomes champion
```

### 7.2 Community Content Sources

| Source | Content Type | Frequency |
|--------|-------------|-----------|
| Blog series | Methodology articles | Weekly (18 posts) |
| Discord discussions | Q&A, troubleshooting | Daily |
| GitHub issues | Feature requests, bug reports | Ongoing |
| Community PRs | Platform skill contributions | Monthly |
| Office hours | Live validation demos | Monthly |

### 7.3 "VF Champions" Program

Criteria for recognition:
1. Contributed 1+ platform reference skill
2. Filed 3+ quality bug reports
3. Helped 5+ users in Discord
4. Published 1+ blog post about VF

Rewards: Featured in blog, contributor badge, early access to VF Cloud beta.

---

## 8. Key Metrics

| Metric | Week 4 | Month 3 | Month 6 |
|--------|:------:|:-------:|:-------:|
| Blog post views (total) | 5,000 | 25,000 | 100,000 |
| Blog → GitHub clicks | 500 | 2,000 | 8,000 |
| GitHub stars | 200 | 1,000 | 3,000 |
| Plugin installs | 500 | 2,000 | 5,000 |
| Discord members | 30 | 100 | 300 |
| LinkedIn followers (VF-related) | 100 | 500 | 1,500 |
| HN/Reddit threads | 3 | 10 | 20 |
| Community PRs | 0 | 5 | 20 |

---

## 9. Brand Voice Guidelines for Content

### Tone
- **Confident, not arrogant:** "The data shows..." not "Obviously..."
- **Technical, not academic:** Show real code, real sessions, real evidence
- **Provocative, not hostile:** Challenge unit tests with data, not insults
- **First-person plural:** "We stopped writing unit tests" creates tribal belonging

### Language Rules
- Always say "functional validation" not "functional testing"
- Always say "evidence" not "proof" (legal connotation)
- Always say "journey" not "test case" (differentiation from unit testing)
- Always say "verdict" not "result" (implies formal judgment)
- Never say "unit test" without "mock-based" qualifier
- Never say "100%" anything (credibility killer)

### Hashtags
- Primary: #AICodeValidation #ValidationForge #EvidenceBasedShipping
- Secondary: #ClaudeCode #AgenticDevelopment #NoMocks
- Series: #AgenticDev18 (for the blog series)
