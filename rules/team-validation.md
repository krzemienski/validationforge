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

1. Lead creates validation plan with journey assignments
2. Lead dispatches platform validators in parallel
3. Each validator captures evidence to its owned directory
4. Validators report completion to Lead
5. Lead invokes verdict-writer to synthesize all evidence
6. Lead reviews and approves final verdict

## Evidence Handoff

Validators produce evidence. The verdict-writer consumes it.
```
Validator → writes → e2e-evidence/{platform}/step-*.{png,json,txt}
Verdict Writer → reads → all e2e-evidence/*/step-*
Verdict Writer → writes → e2e-evidence/report.md
```

## Conflict Resolution

- If two validators need the same endpoint, coordinate through the Lead
- If evidence contradicts between platforms, document both in the verdict
- If a validator's journey depends on another platform, use sequential ordering
