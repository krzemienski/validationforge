# Forge State Schema

Defines the structure of `.validationforge/forge-state.json` — the persistent state file that tracks every FORGE run, per-journey strike counts, per-attempt evidence paths, and lifecycle transitions.

## Root Object

```json
{
  "run_id": "forge-2026-04-08T14:23:00Z",
  "status": "idle",
  "journeys": [],
  "created_at": "2026-04-08T14:23:00Z",
  "updated_at": "2026-04-08T14:23:00Z"
}
```

| Field | Type | Description |
|-------|------|-------------|
| `run_id` | string | Unique identifier for this forge run (`forge-{ISO_TIMESTAMP}`) |
| `status` | enum | Lifecycle state: `idle`, `running`, `completed`, `aborted` |
| `journeys` | array | Ordered list of journey state objects (appended as discovered) |
| `created_at` | ISO 8601 | When `forge-init.sh` wrote this file |
| `updated_at` | ISO 8601 | Updated after every phase transition or attempt |

## Journey Entry

Each element of `journeys[]` represents one validation journey.

```json
{
  "journey_id": "user-login",
  "status": "running",
  "strikes": 1,
  "attempts": []
}
```

| Field | Type | Description |
|-------|------|-------------|
| `journey_id` | string | Journey slug (e.g., `user-login`, `checkout-flow`) |
| `status` | enum | `pending`, `running`, `passed`, `failed` |
| `strikes` | integer | Failed fix-and-retry count (0–3; aborts at 3) |
| `attempts` | array | Ordered list of attempt objects for this journey |

## Attempt Entry

Each element of a journey's `attempts[]` represents one build-validate-fix iteration.

```json
{
  "attempt_number": 1,
  "outcome": "fail",
  "evidence_path": "e2e-evidence/forge-attempt-1/user-login/",
  "fix_applied": "Added null guard to UserSession.init() at src/auth.ts:42",
  "timestamp": "2026-04-08T14:25:11Z"
}
```

| Field | Type | Description |
|-------|------|-------------|
| `attempt_number` | integer | 1-based attempt index |
| `outcome` | enum | `pass` or `fail` |
| `evidence_path` | string | Directory holding fresh evidence for this attempt |
| `fix_applied` | string\|null | Human-readable fix description with `file:line`; `null` on first attempt |
| `timestamp` | ISO 8601 | When this attempt concluded |

### Evidence Path Convention

```
e2e-evidence/forge-attempt-{N}/{journey-slug}/
```

Each attempt **must** use its own directory. Never reuse or overwrite a prior attempt's evidence.

## Lifecycle Transitions

```
idle ──start──► running ──all pass──► completed
                   │
                   └──3 strikes OR error──► aborted
```

| Transition | Trigger | `status` value |
|------------|---------|----------------|
| init | `forge-init.sh` runs | `idle` |
| start | `/forge-execute` begins phase 1 | `running` |
| success | All journeys reach `passed` | `completed` |
| strike limit | Any journey reaches `strikes == 3` | `aborted` |
| hard error | Unrecoverable build failure | `aborted` |

## Fully-Populated Example

```json
{
  "run_id": "forge-2026-04-08T14:23:00Z",
  "status": "completed",
  "journeys": [
    {
      "journey_id": "user-login",
      "status": "passed",
      "strikes": 1,
      "attempts": [
        {
          "attempt_number": 1,
          "outcome": "fail",
          "evidence_path": "e2e-evidence/forge-attempt-1/user-login/",
          "fix_applied": null,
          "timestamp": "2026-04-08T14:25:11Z"
        },
        {
          "attempt_number": 2,
          "outcome": "pass",
          "evidence_path": "e2e-evidence/forge-attempt-2/user-login/",
          "fix_applied": "Added null guard at src/auth.ts:42",
          "timestamp": "2026-04-08T14:31:04Z"
        }
      ]
    }
  ],
  "created_at": "2026-04-08T14:23:00Z",
  "updated_at": "2026-04-08T14:31:04Z"
}
```
