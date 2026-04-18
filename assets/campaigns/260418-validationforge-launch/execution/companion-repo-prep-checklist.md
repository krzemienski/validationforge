# Companion Repo Pre-Launch Prep Checklist

**Owner:** Nick Krzemienski
**Audit source:** `companion-repo-audit-report.md` (2026-04-18)
**Calendar source:** `10-week-master-calendar.md`
**Rule:** Each repo must be polished **at least 7 days before** its associated blog post's send date.

> **Execution note (2026-04-18):** The agent run executed via `gh` CLI completed:
> ✅ topics for all 11 repos · ✅ 3 description rewrites · ✅ 11 README patches **staged** at
> `staged-readme-patches/{repo}-README.md` for user review-and-push (NOT auto-pushed). License,
> default-branch, homepage-URL, release-tag, install-verification, and refresh-commit items remain
> manual — see `companion-repo-prep-results.md` for the full per-repo report and flags.
>
> **Repo corrections from the original audit:** Post #3 → `claude-code-skills-factory` (was
> `functional-validation-framework`). Post #11 → `validationforge` (was `ai-dev-operating-system`).

## Standard Polish Tasks (apply to every repo)

For each repo, the launch-ready polish path is:

1. Add 5-7 topic tags via `gh repo edit --add-topic ai --add-topic claude-code --add-topic agentic-development ...` (1 min)
2. Add the "Featured in Agentic Development Blog — Post #N" badge to the top of the README (3 min)
3. Add a "## Related Post" section near the top of the README with the LinkedIn + canonical blog URL (3 min)
4. Push the polish commit (this also refreshes the "last commit" date past the 60-day dormant threshold) (1 min)
5. Set `homepageUrl` to the canonical blog post URL via `gh repo edit --homepage ...` (1 min)
6. Verify the install / quick-start command on a fresh terminal session (5-15 min)
7. Confirm `LICENSE` file is present and is MIT (already true for all 11 repos as of audit)

Total per repo: **~15-25 min**. Total across 11 repos: **~3-4 hours batchable**.

---

## Repo 1 — `agentic-development-guide` (Post 1: Series Overview)

**Post send date:** Mon May 26, 2026 · **Polish deadline:** Tue May 19, 2026 · **Owner:** Nick · **Est. effort:** 30 min

This is the series **meta-repo** — it gets pinned as the series hub, so README polish is highest-priority here.

- [x] README badge added: "Featured in Agentic Development Blog — Post #1" (✅ STAGED in `staged-readme-patches/agentic-development-guide-README.md`)
- [x] README "## Related Post" section linking to LinkedIn URL + canonical blog URL (✅ STAGED with placeholders for URLs)
- [ ] README updated to list all 11 companion repos with one-line descriptions (15 min — extra task because this is the hub) — **manual: not auto-generated**
- [ ] Update repo description from "10 deeply technical blog posts" → "11+ deeply technical blog posts" (1 min) — **deferred: existing copy reads as historical framing, user call**
- [ ] Last commit within past 60 days — push the staged README patch to refresh (currently 43 days since last commit; crosses 60d on May 5)
- [x] Topic tags added: `ai`, `claude-code`, `agentic-development`, `meta-repo`, `blog-series` (✅ APPLIED via `gh repo edit`)
- [ ] `homepageUrl` set to canonical blog post URL (1 min) — **deferred: blog URL TBD**
- [x] Default branch is `main` (already correct — no change needed)
- [x] LICENSE file present (verified MIT — no change)
- [x] No install command in this repo (it's a guide hub) — N/A

---

## Repo 2 — `multi-agent-consensus` (Post 2: Three Agents Found the P2 Bug)

**Post send date:** Mon May 18, 2026 · **Polish deadline:** Mon May 11, 2026 · **Owner:** Nick · **Est. effort:** 25 min

This is the **first blog post to send** and the **highest-importance post (10/10)**. Get this one perfect.

- [x] README badge added: "Featured in Agentic Development Blog — Post #2: A Single AI Agent Said 'Looks Correct.' Three Agents Found the P2 Bug." (✅ STAGED)
- [x] README "## Related Post" section linking to LinkedIn URL + canonical blog URL (✅ STAGED with URL placeholders)
- [ ] Last commit within past 60 days — **push staged README patch to refresh** (NOT auto-pushed per task rules)
- [x] Topic tags added: `ai`, `claude-code`, `agentic-development`, `multi-agent`, `consensus-validation`, `validation`, `claude` (✅ APPLIED via gh repo edit — note: final applied tag set may differ slightly; see companion-repo-prep-results.md)
- [ ] `homepageUrl` set to canonical blog post URL (1 min)
- [ ] Repo description already strong — no change
- [ ] Install command verified by running on a fresh terminal (10 min)
- [x] LICENSE file present (✅ verified MIT via gh api — no change)
- [ ] Optional: rename default branch `master` → `main` (defer if risk; do it ≥10 days before send if doing it)

---

## Repo 3 — `claude-code-skills-factory` (Post 3: I Banned Unit Tests) — corrected from `functional-validation-framework`

**Post send date:** Thu May 21, 2026 · **Polish deadline:** Thu May 14, 2026 · **Owner:** Nick · **Est. effort:** 25 min

Direct VF tie-in — cross-link to validationforge in the README. **Note:** the original audit listed `functional-validation-framework` here; the launch task corrected to `claude-code-skills-factory`. The `functional-validation-framework` repo was left untouched this run.

- [x] README badge added: "Featured in Agentic Development Blog — Post #3: I Banned Unit Tests From My AI Workflow" (✅ STAGED)
- [x] README "## Related Post" section linking to LinkedIn URL + canonical blog URL (✅ STAGED with URL placeholders)
- [ ] README cross-link to ValidationForge repo as the productionized version of the framework (5 min)
- [ ] Last commit within past 60 days — **push staged README patch to refresh** (NOT auto-pushed per task rules)
- [x] Topic tags added: `ai`, `claude-code`, `agentic-development`, `validation`, `e2e-testing`, `no-mocks`, `functional-testing` (✅ APPLIED via gh repo edit — note: final applied tag set may differ slightly; see companion-repo-prep-results.md)
- [ ] `homepageUrl` set to canonical blog post URL (1 min)
- [ ] Repo description already strong — no change
- [ ] Install command verified by running on a fresh terminal (10 min)
- [x] LICENSE file present (✅ verified MIT via gh api — no change)

---

## Repo 4 — `claude-ios-streaming-bridge` (Post 4: 5-Layer SSE Bridge)

**Post send date:** Thu Jun 11, 2026 · **Polish deadline:** Thu Jun 4, 2026 · **Owner:** Nick · **Est. effort:** 35 min

Niche post (7/10 importance) — but the install verification is heavier (Swift Package + Python bridge).

- [x] README badge added: "Featured in Agentic Development Blog — Post #4: The 5-Layer SSE Bridge — Building a Native iOS Client" (✅ STAGED)
- [x] README "## Related Post" section linking to Dev.to (primary) + LinkedIn URL + canonical blog URL (✅ STAGED with URL placeholders)
- [ ] Last commit within past 60 days — **push staged README patch to refresh** (NOT auto-pushed per task rules)
- [x] Topic tags added: `ai`, `claude-code`, `agentic-development`, `ios`, `swift`, `swift-package`, `sse`, `streaming` (✅ APPLIED via gh repo edit — note: final applied tag set may differ slightly; see companion-repo-prep-results.md)
- [ ] `homepageUrl` set to canonical blog post URL (1 min)
- [ ] Repo description already strong — no change
- [ ] Swift Package builds cleanly via `swift build` on a fresh checkout (10 min)
- [ ] Python bridge runs end-to-end against a real Claude Code session (15 min)
- [ ] Optional: tag a `v0.1.0` release so iOS devs can pin to a stable version (5 min)
- [x] LICENSE file present (✅ verified MIT via gh api — no change)

---

## Repo 5 — `claude-sdk-bridge` (Post 5: 5 Layers to Call an API)

**Post send date:** Mon Jun 1, 2026 · **Polish deadline:** Mon May 25, 2026 · **Owner:** Nick · **Est. effort:** 30 min

**Description rewrite required** — current "Reference implementation of the 5-layer bridge pattern with documented failure cases" is too vague.

- [x] **Rewrite repo description** → "Polyglot SDK bridge — call the Anthropic Claude SDK from iOS, Python, and Node clients through one unified bridge layer with documented failure modes." (✅ APPLIED)
- [x] README badge added: "Featured in Agentic Development Blog — Post #5: 5 Layers to Call an API" (✅ STAGED)
- [x] README "## Related Post" section linking to LinkedIn URL + canonical blog URL (✅ STAGED with URL placeholders)
- [ ] Last commit within past 60 days — **push staged README patch to refresh** (NOT auto-pushed per task rules)
- [x] Topic tags added: `ai`, `claude-code`, `agentic-development`, `anthropic-sdk`, `bridge-pattern`, `api-integration`, `failure-modes` (✅ APPLIED via gh repo edit — note: final applied tag set may differ slightly; see companion-repo-prep-results.md)
- [ ] `homepageUrl` set to canonical blog post URL (1 min)
- [ ] Reference implementation builds and runs (10 min)
- [ ] Each of the 5 documented failure cases is reproducible and labeled in the README (5 min)
- [x] LICENSE file present (✅ verified MIT via gh api — no change)

---

## Repo 6 — `auto-claude-worktrees` (Post 6: 194 Parallel AI Worktrees)

**Post send date:** Thu Jun 4, 2026 · **Polish deadline:** Thu May 28, 2026 · **Owner:** Nick · **Est. effort:** 40 min

Scale-demo post — HN crowd will want to install and try it. Tag a release.

- [x] README badge added: "Featured in Agentic Development Blog — Post #6: 194 Parallel AI Worktrees" (✅ STAGED)
- [x] README "## Related Post" section linking to LinkedIn URL + canonical blog URL + HN submission URL (✅ STAGED with URL placeholders)
- [ ] Last commit within past 60 days — **push staged README patch to refresh** (NOT auto-pushed per task rules)
- [x] Topic tags added: `ai`, `claude-code`, `agentic-development`, `git-worktrees`, `parallel-execution`, `cli`, `developer-tools` (✅ APPLIED via gh repo edit — note: final applied tag set may differ slightly; see companion-repo-prep-results.md)
- [ ] `homepageUrl` set to canonical blog post URL (1 min)
- [ ] Repo description adequate — no change required (could optionally sharpen with "Spin up dozens of parallel Claude Code agents in isolated git worktrees from one command.")
- [ ] CLI install command verified end-to-end on a fresh terminal (15 min)
- [ ] **Tag `v0.1.0` release** with copy-paste install snippet in release notes (10 min)
- [ ] README has a quick-start section showing the 30-second "spin up N worktrees" demo (5 min)
- [x] LICENSE file present (✅ verified MIT via gh api — no change)

---

## Repo 7 — `claude-prompt-stack` (Post 7: 7-Layer Prompt Engineering Stack)

**Post send date:** Thu May 29, 2026 · **Polish deadline:** Thu May 22, 2026 · **Owner:** Nick · **Est. effort:** 25 min

"Most actionable" post per the calendar — README should let readers copy-paste a working stack.

- [x] README badge added: "Featured in Agentic Development Blog — Post #7: The 7-Layer Prompt Engineering Stack" (✅ STAGED)
- [x] README "## Related Post" section linking to LinkedIn URL + canonical blog URL + Dev.to cross-post URL (✅ STAGED with URL placeholders)
- [ ] Last commit within past 60 days — **push staged README patch to refresh** (NOT auto-pushed per task rules)
- [x] Topic tags added: `ai`, `claude-code`, `agentic-development`, `prompt-engineering`, `template`, `defense-in-depth`, `claude` (✅ APPLIED via gh repo edit — note: final applied tag set may differ slightly; see companion-repo-prep-results.md)
- [ ] `homepageUrl` set to canonical blog post URL (1 min)
- [ ] Repo description already strong — no change
- [ ] Template repo button enabled in repo settings ("Use this template") (1 min)
- [ ] README has a layer-by-layer copy-paste section matching the post structure (10 min)
- [x] LICENSE file present (✅ verified MIT via gh api — no change)

---

## Repo 8 — `ralph-orchestrator-guide` (Post 8: Ralph Orchestrator)

**Post send date:** Thu Jun 18, 2026 · **Polish deadline:** Thu Jun 11, 2026 · **Owner:** Nick · **Est. effort:** 30 min

**Description rewrite required** — current "Getting started guide and example configurations for Ralph Orchestrator" doesn't explain what Ralph is.

- [x] **Rewrite repo description** → "Getting-started guide for Ralph — a Rust agent fleet platform implementing the self-referential AI loop pattern with examples, configs, and battle-tested setups." (✅ APPLIED)
- [x] README badge added: "Featured in Agentic Development Blog — Post #8: Ralph Orchestrator — A Rust Platform for AI Agent Fleets" (✅ STAGED)
- [x] README "## Related Post" section linking to LinkedIn URL + canonical blog URL + HN submission URL + r/rust thread URL (✅ STAGED with URL placeholders)
- [ ] Last commit within past 60 days — **push staged README patch to refresh** (NOT auto-pushed per task rules)
- [x] Topic tags added: `ai`, `claude-code`, `agentic-development`, `ralph`, `orchestration`, `rust`, `agent-loops`, `self-referential` (✅ APPLIED via gh repo edit — note: final applied tag set may differ slightly; see companion-repo-prep-results.md)
- [ ] `homepageUrl` set to canonical blog post URL (1 min)
- [ ] Example configurations in repo are runnable (e.g. `ralph init` → `ralph run`) (15 min)
- [ ] README has a "What is Ralph?" 3-sentence preamble before the configs (5 min)
- [x] LICENSE file present (✅ verified MIT via gh api — no change)

---

## Repo 9 — `code-tales` (Post 9: Audio Stories from GitHub Repos)

**Post send date:** Mon Jun 8, 2026 · **Polish deadline:** Mon Jun 1, 2026 · **Owner:** Nick · **Est. effort:** 45 min

Product-showcase post — Show HN + Product Hunt launch — install must work flawlessly. Highest install-verification cost.

- [x] README badge added: "Featured in Agentic Development Blog — Post #9: From GitHub Repos to Audio Stories" (✅ STAGED)
- [x] README "## Related Post" section linking to LinkedIn URL + canonical blog URL + Show HN URL + Product Hunt URL (✅ STAGED with URL placeholders)
- [ ] Last commit within past 60 days — **push staged README patch to refresh** (NOT auto-pushed per task rules)
- [x] Topic tags added: `ai`, `claude-code`, `agentic-development`, `text-to-speech`, `audio`, `github`, `narrative`, `code-explainer` (✅ APPLIED via gh repo edit — note: final applied tag set may differ slightly; see companion-repo-prep-results.md)
- [ ] `homepageUrl` set to canonical blog post URL (1 min)
- [ ] Repo description already strong — no change
- [ ] **End-to-end install + run on fresh machine** — clone → install deps → generate one audio story → verify .mp3 plays (25 min)
- [ ] **Tag `v0.1.0` release** with install snippet (5 min)
- [ ] README has a "Listen to a sample" link to a hosted .mp3 of one generated story (5 min)
- [x] LICENSE file present (✅ verified MIT via gh api — no change)

---

## Repo 10 — `stitch-design-to-code` (Post 10: 21 AI-Generated Screens)

**Post send date:** Mon Jun 15, 2026 · **Polish deadline:** Mon Jun 8, 2026 · **Owner:** Nick · **Est. effort:** 35 min

Visual post — README needs **screenshots** to match the visual-drama angle.

- [x] README badge added: "Featured in Agentic Development Blog — Post #10: 21 AI-Generated Screens, Zero Figma Files" (✅ STAGED)
- [x] README "## Related Post" section linking to LinkedIn URL + canonical blog URL + Dev.to cross-post URL + Dribbble case study URL (✅ STAGED with URL placeholders)
- [ ] Last commit within past 60 days — **push staged README patch to refresh** (NOT auto-pushed per task rules)
- [x] Topic tags added: `ai`, `claude-code`, `agentic-development`, `stitch`, `mcp`, `design-to-code`, `puppeteer`, `ui-generation` (✅ APPLIED via gh repo edit — note: final applied tag set may differ slightly; see companion-repo-prep-results.md)
- [ ] `homepageUrl` set to canonical blog post URL (1 min)
- [ ] Repo description already strong — no change
- [ ] **Embed 4-6 screenshots in README** showing the design → code transformation (15 min)
- [ ] Workflow template steps verified end-to-end (Stitch MCP → AI generation → Puppeteer validation) (10 min)
- [ ] Default branch is `main` (already correct — no change needed)
- [x] LICENSE file present (✅ verified MIT via gh api — no change)

---

## Repo 11 — `validationforge` (Post 11: Capstone) — corrected from `ai-dev-operating-system`

**Post send date:** Mon Jun 22, 2026 · **Polish deadline:** Mon Jun 15, 2026 · **Owner:** Nick · **Est. effort:** 60 min

Capstone post — README must tie together all 10 prior repos. **Highest README investment.**

**Note:** the original audit listed `ai-dev-operating-system` as the capstone; the launch task corrected to `validationforge` (the flagship repo). The `ai-dev-operating-system` repo was left untouched this run.

- [x] README badge added: "Featured in Agentic Development Blog — Post #11: The AI Development Operating System (Capstone)" (✅ STAGED)
- [x] README "## Related Post" section linking to LinkedIn URL + canonical blog URL + HN submission URL (✅ STAGED with URL placeholders)
- [ ] **README "Built On" section** linking to all 10 prior companion repos as building blocks (20 min)
- [ ] Last commit within past 60 days — **push staged README patch to refresh** (NOT auto-pushed per task rules)
- [x] Topic tags added: `ai`, `claude-code`, `agentic-development`, `developer-operating-system`, `starter-kit`, `claude`, `meta`, `framework` (✅ APPLIED via gh repo edit — note: final applied tag set may differ slightly; see companion-repo-prep-results.md)
- [ ] `homepageUrl` set to canonical blog post URL (1 min)
- [ ] Tighten description: current "Complete starter kit for building your own AI development operating system" is OK but could be sharpened to "Complete starter kit — kit-bash 11 proven patterns into your own AI development operating system." (3 min)
- [ ] Starter-kit install + scaffold command verified on a fresh machine (20 min)
- [ ] **Tag `v1.0.0` release** to mark capstone status (5 min)
- [x] LICENSE file present (✅ verified MIT via gh api — no change)

---

## Reference — `validationforge` (NOT in this checklist)

ValidationForge itself is the campaign hero repo and its launch prep is tracked in **`14-day-calendar.md`** under the VF Launch Track (Days 1-14 of the master calendar, posts on Apr 20 / Apr 22 / Apr 25 / Apr 29 / Apr 30). Do NOT duplicate VF prep tasks here — refer to `14-day-calendar.md` for VF's checklist.

---

## Master Deadline Table (sorted by polish deadline)

| Polish deadline | Repo | Post # | Post send date |
|---|---|---|---|
| Mon May 11 | `multi-agent-consensus` | 2 | Mon May 18 |
| Thu May 14 | `functional-validation-framework` | 3 | Thu May 21 |
| Tue May 19 | `agentic-development-guide` | 1 | Mon May 26 |
| Thu May 22 | `claude-prompt-stack` | 7 | Thu May 29 |
| Mon May 25 | `claude-sdk-bridge` | 5 | Mon Jun 1 |
| Thu May 28 | `auto-claude-worktrees` | 6 | Thu Jun 4 |
| Mon Jun 1 | `code-tales` | 9 | Mon Jun 8 |
| Thu Jun 4 | `claude-ios-streaming-bridge` | 4 | Thu Jun 11 |
| Mon Jun 8 | `stitch-design-to-code` | 10 | Mon Jun 15 |
| Thu Jun 11 | `ralph-orchestrator-guide` | 8 | Thu Jun 18 |
| Mon Jun 15 | `ai-dev-operating-system` | 11 | Mon Jun 22 |

**Total estimated effort across all 11 repos:** ~6 hours (sum of per-repo estimates: 30+25+25+35+30+40+25+30+45+35+60). Recommended batching: 2-3 repos per evening session, in deadline order.

## Open Questions

1. Standardize all repos onto `main` branch before launch, or accept the `master`/`main` split? (Audit recommends standardize, but only if done ≥10 days before each send date.)
2. Use a single shared `homepageUrl` (e.g. an org GitHub Pages site) or per-repo blog URLs?
3. Add `SECURITY.md` / `CODE_OF_CONDUCT.md` to each repo, or skip until traffic justifies?
4. Are the canonical blog post URLs known yet? Without them, the "Related Post" sections need a placeholder + a follow-up pass on send day.
