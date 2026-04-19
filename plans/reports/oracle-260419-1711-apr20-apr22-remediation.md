# ORACLE — Apr 20 / Apr 22 Remediation Plan

## A. The 16-hour-window fixes (must be DONE before Apr 20 fires)

| Gap | Path(s) / lines | Before -> after | ETA | Verification | Depends on | Assignee |
|---|---|---|---:|---|---|---|
| Repo public + launch metadata verified | N/A (GitHub repo settings); source-of-truth strings already in [.claude-plugin/plugin.json](/Users/nick/Desktop/validationforge/.claude-plugin/plugin.json#L4) and [.claude-plugin/marketplace.json](/Users/nick/Desktop/validationforge/.claude-plugin/marketplace.json#L3) | Run: `gh repo edit krzemienski/validationforge --visibility public --description "No-mock functional validation for Claude Code. Ship verified code, not 'it compiled' code." --add-topic claude-code --add-topic validation --add-topic no-mock --add-topic functional-testing --add-topic evidence-based --add-topic quality-assurance` | 10 | `gh repo view krzemienski/validationforge --json isPrivate,description,homepageUrl,repositoryTopics,pushedAt,stargazerCount,defaultBranchRef` -> `"isPrivate":false`; description matches; topics populated; `pushedAt` recent | C.1 homepage choice optional; visibility required | user |
| README launch-week placeholder purge | [README.md:5-12](/Users/nick/Desktop/validationforge/README.md#L5) | Replace lines 5-12 with:<br>`## Related Post`<br>`Soft-launch week for ValidationForge is in progress.`<br>`- GitHub repo: https://github.com/krzemienski/validationforge`<br>`- Self-validation evidence: ./e2e-evidence/self-validation/report.md`<br>`- Long-form essay: _publishes Wed Apr 22, 2026_`<br>`- Series hub: https://github.com/krzemienski/agentic-development-guide` | 8 | `rg -n 'slug-set-on-send-day|Mon Jun 22, 2026|link added on send day' /Users/nick/Desktop/validationforge/README.md` -> no output | none | agent |

## B. The 72-hour-window fixes (must be DONE before Apr 22)

| Gap | Path(s) / lines | Before -> after | ETA | Verification | Depends on | Assignee |
|---|---|---|---:|---|---|---|
| Site GitHub/install URL drift | [site/src/pages/index.astro:335,366-367,705,713-714,723](/Users/nick/Desktop/validationforge/site/src/pages/index.astro#L335); [site/src/content/docs/installation.mdx:17-27](/Users/nick/Desktop/validationforge/site/src/content/docs/installation.mdx#L17); [site/src/content/docs/quickstart.mdx:10-12](/Users/nick/Desktop/validationforge/site/src/content/docs/quickstart.mdx#L10) | Replace all `github.com/krzemienski/validationforge` -> `github.com/krzemienski/validationforge`; replace all `raw.githubusercontent.com/krzemienski/validationforge/main/install.sh` -> `raw.githubusercontent.com/krzemienski/validationforge/main/install.sh`; replace Quickstart `curl -fsSL https://validationforge.dev/install | bash` -> `curl -fsSL https://raw.githubusercontent.com/krzemienski/validationforge/main/install.sh | bash` | 20 | `rg -n 'validationforge/validationforge|validationforge\.dev/install' /Users/nick/Desktop/validationforge/site` -> no output | A.1 complete if repo must be public for these URLs to work | agent |
| Remove stale “repo may not be public yet” note | [site/src/content/docs/getting-started.mdx:25-30](/Users/nick/Desktop/validationforge/site/src/content/docs/getting-started.mdx#L25) | Replace note block with:<br>`<Aside type="note" title="Fallback install path">`<br>`If GitHub is temporarily unavailable, use the local symlink method.`<br>`It installs from a local checkout and avoids network dependency.`<br>`</Aside>` | 6 | `sed -n '25,30p' /Users/nick/Desktop/validationforge/site/src/content/docs/getting-started.mdx` -> no `not be publicly published yet` / no `404` copy | A.1 | agent |
| Missing `CNAME` promised by site docs | New file: [/Users/nick/Desktop/validationforge/site/public/CNAME](/Users/nick/Desktop/validationforge/site/public/CNAME) | Create file with exact content:<br>`validationforge.dev` | 2 | `cat /Users/nick/Desktop/validationforge/site/public/CNAME` -> `validationforge.dev` | C.2 if domain/DNS target changes | agent |
| Lock Apr 22 canonical URL + publish state | [assets/.../blog-site-mdx/vf-validation-gap-essay.md:14](/Users/nick/Desktop/validationforge/assets/campaigns/260418-validationforge-launch/blog-site-mdx/vf-validation-gap-essay.md#L14); [README.md:9-11](/Users/nick/Desktop/validationforge/README.md#L9) | After canonical URL is chosen, change `published: false` -> `published: true`; replace README placeholders with actual LinkedIn URL and actual canonical URL | 10 | `rg -n 'published: false|slug-set-on-send-day' /Users/nick/Desktop/validationforge/assets/campaigns/260418-validationforge-launch/blog-site-mdx/vf-validation-gap-essay.md /Users/nick/Desktop/validationforge/README.md` -> no output | C.1 required | agent |

## C. Open decisions that block the plan

| ID | Question | Options | Tradeoff |
|---|---|---|---|
| C.1 | What is the canonical Apr 22 Part 1 URL? | A. `https://validationforge.dev/<slug>`; B. `https://ai.hack.ski/blog/<slug>`; C. no external canonical URL, use LinkedIn native + repo CTA only | A keeps everything on the product domain but needs site/blog publication plumbing in this repo. B is likely fastest if the personal-blog pipeline already works, but it creates a cross-repo dependency. C is fastest, but weakens the “long writeup” claim and leaves README/blog metadata awkward. |
| C.2 | Should GitHub `homepageUrl` point to the docs site now? | A. `https://validationforge.dev`; B. leave blank until externally verified; C. point to canonical Part 1 URL after Apr 22 | A improves launch credibility if the domain is live. B avoids a broken homepage on launch day. C is best long-term if the essay is the real conversion surface, but it cannot land until C.1 is decided and published. |

## Dependency order

1. User confirms C.2 enough to run A.1, then makes repo public and verifies `gh repo view`.
2. Agent lands A.2 immediately after A.1.
3. Agent lands B.1, B.2, B.3 as one docs/site scrub.
4. User decides C.1.
5. Agent lands B.4 and any final README canonical-link updates after the chosen URL is live.
