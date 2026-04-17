# ValidationForge Ecosystem Integrations

ValidationForge is a specialized validation layer, not a replacement for the orchestration, TDD, or code-quality plugins you already use. VF validates the output of plugins that build, orchestrate, or refactor — turning "it compiled" into "here is the evidence it actually works." These integration guides document how to combine VF with the most common ecosystem plugins so that each tool keeps its strengths and VF provides the evidence-based verdict at the end of the loop.

## When to use which plugin

| Plugin | Primary Role | Pair with VF when you want to... | Guide |
|--------|--------------|----------------------------------|-------|
| [oh-my-claudecode (OMC)](https://github.com/oh-my-claudecode) | Multi-agent orchestration and execution loops (ralph, autopilot, team) | Let OMC build or ship a feature, then have VF prove the shipped code actually behaves correctly against the real system. | [vf-with-omc.md](./vf-with-omc.md) |
| [everything-claude-code (ECC)](https://github.com/everything-claude-code) | Language-specific code quality, security review, and TDD rule sets | Use ECC to enforce TypeScript/Python/Go/Swift/Java rules and security review, then have VF validate the running application with evidence. | [vf-with-ecc.md](./vf-with-ecc.md) |
| [Superpowers](https://github.com/obra/superpowers) | Plan-and-execute TDD methodology with subagent-driven red/green/refactor cycles | Run Superpowers' TDD loop to produce passing unit tests, then have VF validate the assembled system end-to-end so you know the tests weren't just passing against mocks. | [vf-with-superpowers.md](./vf-with-superpowers.md) |

## How these guides are structured

Each integration guide follows the same 8-section template so you can skim or deep-read consistently:

1. **Title + Intro** — Why the pairing exists and what complementary frame it occupies.
2. **Quick Reference** — One-line answer for "which command do I run when."
3. **Combined Workflow** — Mermaid diagram showing the build/orchestrate/TDD → validate handoff.
4. **Installation + Config** — Side-by-side setup so both plugins coexist without clashing.
5. **Worked Example** — A concrete feature taken from "intent" to "SHIP" using both plugins.
6. **Evidence of Coexistence** — What the filesystem, hooks, and evidence directory look like after the combined run.
7. **Troubleshooting** — The small number of real conflicts (hook ordering, rule precedence, evidence vs. test-file gates) and how to resolve them.
8. **Related Resources** — Upstream docs, competitive analysis, and deeper VF references.

## Guiding principles

- **Complement, don't replace.** VF does not try to take over orchestration (OMC's job), code-quality enforcement (ECC's job), or TDD discipline (Superpowers' job). It validates their output.
- **No-mock still applies.** When VF enters the loop, the Iron Rules in the main [README](../README.md#iron-rules) take over for the validation phase. Test files produced by Superpowers or ECC remain in their own directories; VF never runs against mocks.
- **Evidence is the contract.** Regardless of which plugin produced the code, VF's verdict is backed by `e2e-evidence/` citations. If an upstream plugin claims "done," VF's job is to prove or disprove that claim with evidence.
- **High-stakes features get CONSENSUS.** For changes where a single validator's verdict isn't enough (auth, payments, data migrations), pair any upstream plugin with VF's `/validate-consensus` command — it spawns N independent validators, synthesizes their verdicts, and attaches a confidence score to the final PASS/FAIL.
- **Every run produces a dashboard.** VF's `evidence-dashboard` skill (invoked via `/validate-dashboard`) renders the per-journey evidence tree into an HTML + markdown summary so reviewers of the upstream plugin's PR can see the verdict at a glance.

## Related reading

- [Competitive Analysis](../competitive-analysis.md) — Market positioning and feature comparison against OMC and ECC.
- [Main README](../README.md) — Full command, skill, agent, hook, and rule inventory.
- [Architecture](../ARCHITECTURE.md) — How VF's pipeline, hooks, and evidence system work under the hood.
