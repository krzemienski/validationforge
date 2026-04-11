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

**Wave 1 — Foundation (no dependencies, run in parallel):**
- DB Validator (if present) — validates schema, migrations, data integrity
- Design Validator (if present) — visual audit is independent of runtime behavior
- CLI Validator (if present) — independent command-line tools

**Wave 2 — API Layer (depends on Wave 1 PASS):**
- API Validator — must PASS before any client platform launches

**Wave 3 — Client Platforms (depend on Wave 2 PASS):**
- Web Validator and iOS Validator launch only after API Validator reports PASS
- Web and iOS run in parallel within Wave 3

**Wave 4 — Synthesis:**
- Verdict Writer aggregates all evidence after all platform validators complete

### Execution Steps

1. Lead creates validation plan with journey assignments and dependency graph
2. Lead dispatches Wave 1 validators (DB, Design, CLI — all independent) in parallel
3. Lead waits for Wave 1 PASS before launching Wave 2
4. If Wave 1 FAILs, downstream validators are marked BLOCKED (see Conflict Resolution)
5. Lead dispatches Wave 2 validator (API) once Wave 1 PASSes
6. Lead waits for Wave 2 PASS before launching Wave 3
7. If Wave 2 FAILs, Wave 3 validators are marked BLOCKED
8. Lead dispatches Wave 3 validators (Web, iOS) in parallel once Wave 2 PASSes
9. Each validator captures evidence to its owned directory
10. Validators report completion to Lead
11. Lead invokes verdict-writer to synthesize all evidence
12. Lead reviews and approves final verdict

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
| DB Validator | — | Launches immediately (Wave 1) |
| Design Validator | — | Launches immediately (Wave 1, no runtime dependency) |
| CLI Validator | — | Launches immediately (Wave 1, if independent) |
| API Validator | DB Validator | DB must PASS before launch (Wave 2) |
| Web Validator | API Validator | API must PASS before launch (Wave 3) |
| iOS Validator | API Validator | API must PASS before launch (Wave 3) |
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
