# Companion Repo Pre-Launch Prep — Execution Results

**Run date:** 2026-04-18
**Operator:** general-purpose subagent (`gh` CLI under user `krzemienski`)
**Scope:** 11 companion repos for Posts #1-11 of the Agentic Development Blog series.
**Source docs:** `companion-repo-audit-report.md`, `companion-repo-prep-checklist.md` (both in this directory).

> **Repo correction:** Per the launch task, Post #3's companion repo is **`claude-code-skills-factory`** (NOT `functional-validation-framework` as listed in the original audit). Post #11's capstone repo is **`validationforge`** itself (NOT `ai-dev-operating-system`). Both corrections were applied during this run; the legacy `functional-validation-framework` and `ai-dev-operating-system` repos were left untouched.

---

## TL;DR

- **Topics:** Set on **11 of 11** repos (all started with zero).
- **Descriptions:** **3 of 11** updated (`claude-sdk-bridge`, `ralph-orchestrator-guide`, `claude-code-skills-factory` — the last was null). The other 8 already had serviceable descriptions per the audit and were left alone.
- **READMEs:** Patched READMEs for **11 of 11** staged to `staged-readme-patches/` for user review. **No auto-push performed** (per task rules).
- **Licenses:** Verified MIT on **11 of 11**. No action required.
- **Default branch:** Left as-is (2 on `main`, 8 on `master`, 1 on `dev` — `claude-code-skills-factory`). **Flagged for user.**
- **Refresh commits:** **NOT pushed.** Flagged for user judgment per task rules — the README patches in `staged-readme-patches/` are the natural vehicle for the launch refresh commit.

---

## Per-Repo Results

| # | Repo | Topics | Description | README staged | License | Notes |
|---|---|:---:|:---:|:---:|:---:|---|
| 1 | `agentic-development-guide` | OK | unchanged | OK | MIT | Already strong; on `main`. |
| 2 | `multi-agent-consensus` | OK | unchanged | OK | MIT | Already strong. |
| 3 | `claude-code-skills-factory` | OK | NEW (was null) | OK | MIT | Default branch is `dev` — see flag. |
| 4 | `claude-ios-streaming-bridge` | OK | unchanged | OK | MIT | Already strong. |
| 5 | `claude-sdk-bridge` | OK | REWRITTEN | OK | MIT | Vague description replaced. |
| 6 | `auto-claude-worktrees` | OK | unchanged | OK | MIT | Adequate description. |
| 7 | `claude-prompt-stack` | OK | unchanged | OK | MIT | Already strong. |
| 8 | `ralph-orchestrator-guide` | OK | REWRITTEN | OK | MIT | Vague description replaced. |
| 9 | `code-tales` | OK | unchanged | OK | MIT | Already strong. |
| 10 | `stitch-design-to-code` | OK | unchanged | OK | MIT | Already on `main`. |
| 11 | `validationforge` (flagship) | OK | unchanged | OK | MIT | Description is intentionally long-form. |

---

## Commands Run

### A. Topic tags (`gh repo edit --add-topic ...`)

All 11 commands succeeded with no error output. Spot-check (returned via `gh api repos/krzemienski/{repo} --jq .topics`):

```
agentic-development-guide:    [agentic-development, ai, blog-series, claude-code, meta-repo]
multi-agent-consensus:        [agentic-development, ai, claude-code, code-review, consensus, multi-agent]
claude-code-skills-factory:   [agentic-development, ai, claude-code, evidence-based, skills, validation]
claude-ios-streaming-bridge:  [agentic-development, ai, claude-code, ios, sse, streaming, swift]
claude-sdk-bridge:            [agentic-development, ai, bridge, claude-code, polyglot, python, sdk]
auto-claude-worktrees:        [agentic-development, ai, automation, claude-code, git-worktrees, parallel]
claude-prompt-stack:          [agentic-development, ai, claude-code, defense-in-depth, hooks, prompt-engineering]
ralph-orchestrator-guide:     [agentic-development, agents, ai, claude-code, orchestration, rust]
code-tales:                   [agentic-development, ai, audio, claude-code, elevenlabs, narration]
stitch-design-to-code:        [agentic-development, ai, claude-code, design-tokens, react, stitch-mcp, tailwind]
validationforge:              [agentic-development, ai, claude-code, evidence-based, mcp-plugin, plugin, validation]
```

### B. Description rewrites (`gh repo edit --description ...`)

```
claude-sdk-bridge → "Polyglot SDK bridge — call the Anthropic Claude SDK from iOS, Python, and Node clients
                     through one unified bridge layer with documented failure modes."

ralph-orchestrator-guide → "Getting-started guide for Ralph — a Rust agent fleet platform implementing the
                            self-referential AI loop pattern with examples, configs, and battle-tested setups."

claude-code-skills-factory → "Author, evaluate, and ship Claude Code skills — a factory pattern for building
                              evidence-based agent skills with no mocks." (was null)
```

All 8 remaining repos already had serviceable descriptions per the audit and were left untouched. The audit's request to bump `agentic-development-guide` from "10 posts" → "11 posts" is **deferred** to the user — the existing description still reads accurately as historical framing.

### C. README patches (staged, NOT pushed)

For each repo, the current README was fetched via `gh api repos/krzemienski/{repo}/readme` (base64-decoded), then patched by inserting:

1. A shields.io badge linking to `agentic-development-guide` (the series hub) immediately below the H1.
2. A `## Related Post` section with: post number, post title, send date, LinkedIn placeholder, canonical-blog-URL placeholder, and a series-hub backlink.

Output: 11 files in `staged-readme-patches/{repo}-README.md`. User should review each, fill in the LinkedIn + canonical blog URLs as those become available, and push as a single commit per repo (which also satisfies the "refresh last-commit date" requirement — see Flag F2 below).

### D. License check

```
$ for r in <11 repos>; do gh api repos/krzemienski/$r --jq .license.spdx_id; done
MIT × 11
```

No action needed.

---

## Flags for User Judgment

### F1. Default-branch standardization (LOW — deferred per task rules)

| Branch | Count | Repos |
|---|---:|---|
| `main` | 3 | agentic-development-guide, stitch-design-to-code, validationforge |
| `master` | 7 | multi-agent-consensus, claude-ios-streaming-bridge, claude-sdk-bridge, auto-claude-worktrees, claude-prompt-stack, ralph-orchestrator-guide, code-tales |
| `dev` | 1 | claude-code-skills-factory |

**Note vs original audit:** Audit lists `claude-code-skills-factory` as `master`; current default is actually `dev`. This is a third inconsistency the audit missed. Recommend: when standardizing, also rename `claude-code-skills-factory`'s default from `dev` → `main`.

Per task rules, no migration was performed on this run. If standardizing, do it ≥10 days before each post's send date (i.e. before May 8 for the earliest post).

### F2. Dormancy refresh — repos crossing the 60-day threshold before send date (HIGH)

Today is 2026-04-18. Days-since-last-commit per repo, with the date each will cross 60 days dormant:

| Repo | Last commit | Crosses 60d on | Send date | Buffer |
|---|---|---|---|---|
| `claude-code-skills-factory` | 2025-12-08 | 2026-02-06 (already past) | Thu May 21 | **Already 131 days dormant — urgent** |
| All other 9 series repos | 2026-03-01 | 2026-04-30 | varies May 18 → Jun 22 | Crosses dormancy in 12 days |
| `agentic-development-guide` | 2026-03-06 | 2026-05-05 | Mon May 26 | Crosses dormancy in 17 days |
| `validationforge` | 2026-04-18 | 2026-06-17 | Mon Jun 22 | OK — recently active |

**Recommendation:** When the user pushes the staged README patches, that single commit per repo refreshes the last-commit date and resets the dormancy clock. Doing so on the 7-day-pre-send polish deadline naturally puts every repo well inside the 60-day window for its post. **No fake refresh commits required** — the README patch IS the meaningful change.

### F3. Homepage URL (LOW)

All 11 repos still have `homepageUrl: null`. Setting this requires the canonical blog URLs, which the user noted are TBD. Once each post is live, run:

```
gh repo edit krzemienski/{repo} --homepage "https://blog.url/post-N"
```

Skipped this run.

### F4. `template` flag for `claude-prompt-stack` (LOW)

The checklist asks to enable the "Use this template" button on `claude-prompt-stack`. The `gh repo edit --template true` flag would apply, but this is a one-time toggle that should happen alongside the README push so users hitting the repo at launch see the template button. Deferred to the README push.

### F5. Releases (LOW)

The checklist suggests tagging `v0.1.0` on `auto-claude-worktrees`, `code-tales`, and `claude-ios-streaming-bridge`, plus `v1.0.0` on `validationforge` (the capstone). All deferred — releases require human judgment about what's actually shippable, and tagging an empty release for SEO is bad practice.

### F6. Repo 11 ambiguity resolved

The original audit and checklist both listed `ai-dev-operating-system` as the Post #11 capstone repo. The launch task explicitly overrides this: **`validationforge` is the Post #11 repo.** This run treated `validationforge` as repo 11 and added the capstone-tier badge and Related Post block to its README. `ai-dev-operating-system` was **NOT** modified.

Likewise, the audit listed `functional-validation-framework` for Post #3, but the launch task corrected this to `claude-code-skills-factory`. This run treated `claude-code-skills-factory` as repo 3 and left `functional-validation-framework` untouched.

**Action for user:** confirm `functional-validation-framework` and `ai-dev-operating-system` should be archived, sunsetted, or repurposed — they're now orphaned from the launch series.

---

## Verification

```
$ ls /Users/nick/Desktop/validationforge/assets/campaigns/260418-validationforge-launch/execution/staged-readme-patches/ | wc -l
11

$ gh api repos/krzemienski/multi-agent-consensus --jq .topics
["agentic-development","ai","claude-code","code-review","consensus","multi-agent"]

$ gh api repos/krzemienski/claude-sdk-bridge --jq .topics
["agentic-development","ai","bridge","claude-code","polyglot","python","sdk"]
```

All three checks pass.

---

## What's Left for the User

1. **Review** each of the 11 patched READMEs in `staged-readme-patches/`.
2. **Fill in** the `LinkedIn:` and `Canonical blog post:` placeholders as those URLs become available (the patches use `_link added on send day_` as the placeholder text).
3. **Push** each patched README to its repo on or before the per-post polish deadline (see `companion-repo-prep-checklist.md` master deadline table). Suggested commit message: `docs: add launch badge + Related Post link for blog series Post #N`.
4. **(Optional)** Standardize default branches to `main` in a single batch ≥10 days before May 8.
5. **(Optional)** Set `homepageUrl` per repo once canonical blog URLs are minted.
6. **(Optional)** Tag `v0.1.0` releases on the three installable repos and `v1.0.0` on `validationforge`.
7. **Decide** what to do with the orphaned `functional-validation-framework` and `ai-dev-operating-system` repos.
