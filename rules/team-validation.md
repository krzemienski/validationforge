# Team Validation

## Multi-Agent Validation Teams

ValidationForge supports coordinated multi-agent validation through the `parallel-validation` skill and agent dispatch patterns.

## Team Roles

| Role | Responsibility | Skills Used |
|------|---------------|-------------|
| **Lead** | Coordinates validation plan, assigns platforms | create-validation-plan, parallel-validation |
| **iOS Validator** | iOS app validation | ios-validation, ios-validation-gate, ios-simulator-control |
| **Web Validator** | Web app validation | playwright-validation, web-validation, chrome-devtools |
| **API Validator** | Backend API validation | api-validation |
| **Design Validator** | Design fidelity checking | design-validation, stitch-integration, design-token-audit |
| **Verdict Writer** | Synthesizes evidence into verdicts | verdict-writer agent |

## File Ownership

Each validator owns its evidence directory:
```
e2e-evidence/
  ios/         ← iOS Validator only
  web/         ← Web Validator only
  api/         ← API Validator only
  design/      ← Design Validator only
  report.md    ← Verdict Writer only
```

Never write to another validator's evidence directory.

## Coordination Protocol

Validators execute in **dependency-aware waves** — upstream platforms must PASS before downstream validators launch.

### Wave Structure

**Wave 1 — Foundation (no dependencies):**
- API Validator runs first; all other validators depend on a working API

**Wave 2 — Client Platforms (depend on Wave 1 PASS):**
- Web Validator and iOS Validator launch only after API Validator reports PASS
- Design Validator may run in parallel with Wave 2 (no API dependency)

**Wave 3 — Synthesis:**
- Verdict Writer aggregates all evidence after all platform validators complete

### Execution Steps

1. Lead creates validation plan with journey assignments and dependency graph
2. Lead dispatches Wave 1 validators (API)
3. Lead waits for Wave 1 PASS before launching Wave 2
4. If Wave 1 FAILs, Wave 2 validators are marked BLOCKED (see Conflict Resolution)
5. Lead dispatches Wave 2 validators in parallel once Wave 1 PASSes
6. Each validator captures evidence to its owned directory
7. Validators report completion to Lead
8. Lead invokes verdict-writer to synthesize all evidence
9. Lead reviews and approves final verdict

## Evidence Handoff

Validators produce evidence. The verdict-writer consumes it.
```
Validator → writes → e2e-evidence/{platform}/step-*.{png,json,txt}
Verdict Writer → reads → all e2e-evidence/*/step-*
Verdict Writer → writes → e2e-evidence/report.md
```

## Platform Dependencies

| Validator | Depends On | Launch Condition |
|-----------|-----------|-----------------|
| API Validator | — | Launches immediately (Wave 1) |
| Web Validator | API Validator | API must PASS before launch |
| iOS Validator | API Validator | API must PASS before launch |
| Design Validator | — | Launches immediately (no API dependency) |
| Verdict Writer | All validators | All waves must complete |

**Rule:** Never launch a dependent validator against a failing upstream. A Web or iOS validator running against a broken API produces meaningless results — mark them BLOCKED instead.

## Conflict Resolution

- If two validators need the same endpoint, coordinate through the Lead
- If evidence contradicts between platforms, document both in the verdict
- If a validator's journey depends on another platform, use sequential wave ordering
- **Dependency-blocked validator:** If an upstream platform FAILs, all dependent validators are reported as `BLOCKED` with the upstream FAIL cited as the reason. Do NOT attempt validation against a known-broken dependency. Example verdict entry:
  ```
  Web Validator: BLOCKED
  Reason: API Validator FAILED (see e2e-evidence/api/report.md)
  Action required: Fix API failures, then re-run Wave 2 validators
  ```
