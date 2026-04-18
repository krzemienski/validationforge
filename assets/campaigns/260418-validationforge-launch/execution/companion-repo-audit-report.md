# Companion Repo Audit Report

**Audit date:** 2026-04-18
**Auditor:** general-purpose subagent (data via `gh` CLI)
**Scope:** 11 GitHub companion repos backing blog posts 1-11. (ValidationForge itself is tracked in `14-day-calendar.md` and excluded here.)
**Tooling:** `gh repo view`, `gh issue list`, `gh pr list`, `gh release list`, `gh api repos/{}/readme`, `gh api repos/{}/commits`.

---

## TL;DR

- **11 of 11 repos exist, are public, and have a README + MIT license.** No 404s, no archived repos, no audit failures.
- **0 open issues, 0 open PRs, 0 releases across all 11 repos.** Clean slate; no triage backlog.
- **All 11 repos are dormant.** Last commit dates cluster 2026-03-01 → 2026-03-06 (43-48 days ago). They are still inside the 60-day "dormant" threshold today (2026-04-18), but every single one will cross it before its associated blog-post send date. Every repo needs at least a refresher commit before launch.
- **0 of 11 repos have topic tags set.** This is the single biggest discoverability gap.
- **0 of 11 repos have a homepage URL set.** No link back to the canonical blog post.
- **Default branch is inconsistent:** 2 use `main` (agentic-development-guide, stitch-design-to-code), 9 use `master`. Standardizing to `main` is recommended but not blocking.
- **Stargazer counts:** 10 repos at 0 stars, 1 repo (ai-dev-operating-system) at 1 star. The series launch should drive the first wave of stars.

---

## Per-Repo Current State

| # | Repo | Stars | Issues | PRs | Releases | README | License | Description | Topics | Default Branch | Last Commit | Days Since |
|---|---|---:|---:|---:|---:|:--:|:--:|:--:|:--:|:--:|---|---:|
| 1 | `agentic-development-guide` | 0 | 0 | 0 | 0 | yes | MIT | yes | none | `main` | 2026-03-06 | 43 |
| 2 | `multi-agent-consensus` | 0 | 0 | 0 | 0 | yes | MIT | yes | none | `master` | 2026-03-01 | 48 |
| 3 | `functional-validation-framework` | 0 | 0 | 0 | 0 | yes | MIT | yes | none | `master` | 2026-03-01 | 48 |
| 4 | `claude-ios-streaming-bridge` | 0 | 0 | 0 | 0 | yes | MIT | yes | none | `master` | 2026-03-01 | 48 |
| 5 | `claude-sdk-bridge` | 0 | 0 | 0 | 0 | yes | MIT | yes | none | `master` | 2026-03-01 | 48 |
| 6 | `auto-claude-worktrees` | 0 | 0 | 0 | 0 | yes | MIT | yes | none | `master` | 2026-03-01 | 48 |
| 7 | `claude-prompt-stack` | 0 | 0 | 0 | 0 | yes | MIT | yes | none | `master` | 2026-03-01 | 48 |
| 8 | `ralph-orchestrator-guide` | 0 | 0 | 0 | 0 | yes | MIT | yes | none | `master` | 2026-03-01 | 48 |
| 9 | `code-tales` | 0 | 0 | 0 | 0 | yes | MIT | yes | none | `master` | 2026-03-01 | 48 |
| 10 | `stitch-design-to-code` | 0 | 0 | 0 | 0 | yes | MIT | yes | none | `main` | 2026-03-01 | 48 |
| 11 | `ai-dev-operating-system` | 1 | 0 | 0 | 0 | yes | MIT | yes | none | `master` | 2026-03-01 | 48 |

### Current one-line descriptions (already set, read for tone)

| # | Repo | Description |
|---|---|---|
| 1 | `agentic-development-guide` | "10 deeply technical blog posts on agentic development patterns — from 8,481 AI coding sessions over 90 days. Real code, real diagrams, real lessons." |
| 2 | `multi-agent-consensus` | "Framework for 3-agent consensus validation with hard gates for Claude Code" |
| 3 | `functional-validation-framework` | "Validation framework for AI-assisted development — browser + iOS automation + gate system. No mocks, no stubs." |
| 4 | `claude-ios-streaming-bridge` | "Reusable Swift Package + Python bridge for connecting iOS/macOS apps to Claude Code via SSE streaming" |
| 5 | `claude-sdk-bridge` | "Reference implementation of the 5-layer bridge pattern with documented failure cases" |
| 6 | `auto-claude-worktrees` | "CLI tool for automated parallel AI development using git worktrees" |
| 7 | `claude-prompt-stack` | "Template repository for the 7-layer defense-in-depth prompt engineering system for Claude Code" |
| 8 | `ralph-orchestrator-guide` | "Getting started guide and example configurations for Ralph Orchestrator" |
| 9 | `code-tales` | "Transform GitHub repositories into narrated audio stories with 9 narrative styles" |
| 10 | `stitch-design-to-code` | "Workflow template for Stitch MCP + AI design-to-code with Puppeteer validation" |
| 11 | `ai-dev-operating-system` | "Complete starter kit for building your own AI development operating system" |

Verdict on descriptions: all 11 are already serviceable. #1 mentions "10 posts" but the series is now 11+; recommend bumping to "11 posts" (or "ongoing series"). #5 and #8 are vague — both should mention what the bridge/orchestrator actually does so a stranger landing on the repo from LinkedIn understands it in 5 seconds.

---

## Risk Flags (urgent attention)

These items will hurt the launch unless fixed before each post's send date.

### R1. Zero topic tags across all 11 repos (HIGH)

Without `claude-code`, `agentic-development`, `ai`, etc. as topics, the repos are invisible to GitHub search and category browse. This is a 5-minute fix per repo and the highest-leverage polish task. Add topics to every repo.

### R2. All repos will be "dormant" by their post send date (HIGH)

Last commits range 2026-03-01 → 2026-03-06. Today is 2026-04-18 (43-48 days post-commit). The earliest blog post (Post 2) sends 2026-05-18 — by then those repos will be 78 days dormant. Every repo needs at least a refresh commit (badge + Related Post link counts) ≥7 days before its post sends, which conveniently dovetails with the per-repo prep checklist.

### R3. Two repos have weak/vague descriptions (MEDIUM)

- `claude-sdk-bridge` — "Reference implementation of the 5-layer bridge pattern with documented failure cases" reads as in-jokes; a stranger doesn't know what's bridged. Recommend: "Reference implementation showing 5 ways to call the Anthropic SDK from a real iOS app — and the 4 that fail in production."
- `ralph-orchestrator-guide` — "Getting started guide and example configurations for Ralph Orchestrator" doesn't say what Ralph is. Recommend: "Getting-started guide for the Ralph self-referential AI agent loop pattern — examples, configs, and battle-tested setups."

### R4. Default-branch inconsistency (LOW)

9 of 11 repos use `master`; 2 use `main`. Not a launch blocker but worth standardizing. If renaming, do it ≥10 days before the post send date so any external links/badges/CI catch up.

### R5. No releases anywhere (LOW)

No tagged versions on any repo. For most of these (template repos, guides) that's fine. For `auto-claude-worktrees`, `code-tales`, and `claude-ios-streaming-bridge` (which contain installable tooling), tagging a `v0.1.0` release at launch gives commenters something concrete to link to ("install with v0.1.0").

### R6. No homepage URL set (LOW)

Once each blog post is live, set `homepageUrl` on the repo to the canonical blog URL. One `gh repo edit` call per repo.

---

## Quick Wins (≤30 minutes total per repo)

For every repo on this list, the launch-ready polish path is:

1. Add 5-7 topic tags (1 min)
2. Add the "Featured in Agentic Development Blog — Post #N" badge to README (3 min)
3. Add a "Related Post" section with the LinkedIn + canonical blog URL (3 min)
4. Push the polish commit (refreshes "last commit" date) (1 min)
5. Set `homepageUrl` to the blog post URL (1 min)
6. Verify install command on a fresh terminal (5-15 min)

Total per repo: ~15-25 minutes. Total across 11 repos: ~3-4 hours of focused work, batchable in two evenings.

### Quick-win ranking (best ROI first)

| Rank | Repo | Why |
|---|---|---|
| 1 | `multi-agent-consensus` (Post 2) | First post to send (May 18). Highest-importance post (10/10). Already polished description. Just needs topics + badge. |
| 2 | `functional-validation-framework` (Post 3) | Sends May 21. Already strong description. Direct VF tie-in. |
| 3 | `agentic-development-guide` (Post 1) | Series overview — gets pinned as the hub repo. Already on `main` branch. |
| 4 | `claude-prompt-stack` (Post 7) | "Most actionable" post per calendar. Stack-pattern audience loves topics. |
| 5 | `auto-claude-worktrees` (Post 6) | Scale-demo post; tag a v0.1.0 release for the HN crowd. |
| 6 | `code-tales` (Post 9) | Product showcase. Tag a release; install command must work end-to-end. |
| 7 | `ai-dev-operating-system` (Post 11) | Capstone post. Already has 1 star. Needs the most thorough README polish. |
| 8 | `claude-sdk-bridge` (Post 5) | Description rewrite first, then standard polish. |
| 9 | `stitch-design-to-code` (Post 10) | On `main` branch; visual post means README needs screenshots. |
| 10 | `ralph-orchestrator-guide` (Post 8) | Description rewrite + standard polish. |
| 11 | `claude-ios-streaming-bridge` (Post 4) | Niche post (7/10 importance). Standard polish + verify Swift Package builds. |

---

## Summary Table (sorted by repo health, best first)

Health score = description quality (3 pts) + topics set (2 pts) + recency<60d (2 pts) + license (1 pt) + README (1 pt) + branch=main (1 pt) = max 10.

| Rank | Repo | Health | Notes |
|---|---|---:|---|
| 1 | `agentic-development-guide` | 7/10 | Best description; on `main`; needs topics. |
| 2 | `stitch-design-to-code` | 7/10 | On `main`; needs topics. |
| 3 | `functional-validation-framework` | 7/10 | Strong description; on `master`. |
| 4 | `multi-agent-consensus` | 7/10 | Strong description; on `master`. |
| 5 | `claude-ios-streaming-bridge` | 7/10 | Strong description; on `master`. |
| 6 | `claude-prompt-stack` | 7/10 | Strong description; on `master`. |
| 7 | `code-tales` | 7/10 | Strong description; on `master`. |
| 8 | `ai-dev-operating-system` | 7/10 | Generic but adequate description; on `master`; 1 star. |
| 9 | `auto-claude-worktrees` | 7/10 | Adequate description; on `master`. |
| 10 | `claude-sdk-bridge` | 6/10 | Weak description (rewrite recommended). |
| 11 | `ralph-orchestrator-guide` | 6/10 | Weak description (rewrite recommended). |

All 11 are within ~1 health point of each other. None are in crisis. The whole portfolio sits at "needs polish, no fires."

---

## Final Health Verdict

| Bucket | Count | Repos |
|---|---:|---|
| Healthy (launch-ready with quick wins) | **9** | agentic-development-guide, stitch-design-to-code, functional-validation-framework, multi-agent-consensus, claude-ios-streaming-bridge, claude-prompt-stack, code-tales, ai-dev-operating-system, auto-claude-worktrees |
| Needs polish (description rewrite + standard polish) | **2** | claude-sdk-bridge, ralph-orchestrator-guide |
| Urgent attention (private/missing/broken) | **0** | none |

No audit failures. Every repo is reachable, public, MIT-licensed, and has a README. The work is uniform polish, not triage.

---

## Open Questions

1. Should we standardize all repos onto `main` before launch, or accept the `master`/`main` split? (Recommendation: standardize, but in a single batch ≥10 days before the first send date so links don't break.)
2. Do we want a shared org-level GitHub Pages site for the series (e.g. `agentic-development-guide` as the hub), or just rely on per-repo `homepageUrl` pointing to the blog?
3. Are there cross-repo links to add inside each README (e.g. "See also: companion repos for posts 1-11")?
4. Should we add a `SECURITY.md` and `CODE_OF_CONDUCT.md` to each repo, or skip until traffic justifies it? (YAGNI says skip.)
