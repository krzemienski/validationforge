# ValidationForge Ecosystem Integration Guides

ValidationForge is a **complementary** plugin, not a replacement. It works alongside orchestration, quality, and testing frameworks to ensure validation is grounded in real-system execution instead of mocks.

> Orchestrate with OMC. Build with Superpowers. Enforce quality with ECC. **Validate with VF.**

## Guides

- **[VF + OMC](./vf-with-omc.md)** — pair with Oh-My-Claudecode for multi-agent orchestration + real-system validation
- **[VF + Superpowers](./vf-with-superpowers.md)** — pair with Superpowers TDD methodology to validate that tests mirror real system behavior
- **[VF + ECC](./vf-with-ecc.md)** — pair with Everything Claude Code for code quality + validation discipline

## Why Complementary Positioning

Each plugin covers a distinct slice of the engineering lifecycle:

| Plugin | Covers | Does NOT cover |
|---|---|---|
| **OMC** | Multi-agent planning, task dispatch, execution loops | Mock-free validation, evidence capture |
| **Superpowers** | TDD discipline, brainstorming, systematic debugging | Real-system end-to-end validation |
| **ECC** | Code quality, craft standards, engineering rigor | Functional validation through user interfaces |
| **VF** | Real-system validation, evidence-based verdicts, no-mock enforcement | Code generation, TDD coaching, quality review |

Running them together gives you:
1. **OMC plans and dispatches** the work
2. **Superpowers enforces TDD** during implementation
3. **ECC reviews code quality** before merge
4. **VF validates the running system** captures evidence, writes verdicts

Each layer catches bugs the others cannot. Mocks lie — VF makes sure no plugin in the stack gets away with pretending.

## How to Run All Four Together

1. Install each plugin following its own install guide
2. Restart Claude Code
3. Verify each plugin loaded: `node ~/.claude/plugins/validationforge/scripts/verify-plugin-structure.js`
4. In a new project, run `bash ~/.claude/plugins/validationforge/scripts/vf-setup.sh --standard`
5. Start work — each plugin's hooks and skills fire as their triggers match

See the individual guides for per-integration configuration snippets.
