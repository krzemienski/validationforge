# Evidence Management

## Directory Structure

```
e2e-evidence/
  {journey-slug}/
    step-01-{action}-{result}.png
    step-02-{action}-{result}.json
    step-03-{action}-{result}.txt
    evidence-inventory.txt
  report.md
```

## Naming Convention

Files: `step-{NN}-{action}-{result}.{ext}`
- `step-01-navigate-to-login.png`
- `step-02-submit-credentials.json`
- `step-03-dashboard-loaded.png`
- `step-04-console-errors.txt`

## Evidence Types

| Type | When to Capture | Format |
|------|----------------|--------|
| Screenshots | Every state transition | PNG |
| DOM snapshots | Initial load + after interactions | HTML/JSON |
| Console logs | Always | TXT |
| Network logs | API integration debugging | JSON |
| API responses | Endpoint validation | JSON |
| CLI output | Command validation | TXT |

## Evidence Quality Rules

1. Screenshots must show the RELEVANT content, not just a blank page
2. API responses must include headers AND body
3. Console logs must include timestamps
4. Every evidence file must be >0 bytes (empty files are invalid evidence)
5. Evidence inventory must list all files with byte counts

## Retention

### Lifecycle Policy

Evidence follows a structured lifecycle tied to validation runs and configurable retention:

| Phase | Action |
|-------|--------|
| During validation | All evidence preserved; no cleanup permitted |
| After PASS | Keep entry + final state screenshots; prune intermediates |
| After FAIL | Keep ALL evidence indefinitely until explicit cleanup |
| Beyond retention period | Eligible for automatic or manual cleanup |

### Configuration

Retention period is configured via `.vf-config.json` (default: 30 days):

```json
{
  "evidence_retention_days": 30
}
```

`evidence_retention_days` controls how long evidence directories are kept before becoming
eligible for cleanup. Set to `0` to disable automatic expiry (keep forever).

### Automatic Cleanup

The `/validate --clean` flag removes evidence older than `evidence_retention_days` before
starting a new validation run:

```bash
/validate --clean          # Purge evidence older than configured retention period
/validate --clean --days 7 # Override: purge evidence older than 7 days
```

Cleanup rules:
- Evidence from **in-progress** validations is **never** deleted
- FAIL evidence is flagged but still subject to the retention policy unless pinned
- Cleanup writes a removal log to `e2e-evidence/.cleanup-log.txt` for audit

### Source Control

Add `e2e-evidence/` to `.gitignore` to prevent committing evidence to source control:

```
# Evidence directories — managed by ValidationForge retention policy
e2e-evidence/
```

Exception: commit `e2e-evidence/report.md` if the team requires verdicts in source control.

### Lock File Protocol

Active validation sessions write a lock file to prevent cleanup from interfering with
in-progress runs:

```
e2e-evidence/validation-in-progress.lock
```

**Lock file lifecycle:**

| Event | Action |
|-------|--------|
| Validation starts | Write `validation-in-progress.lock` with PID and start timestamp |
| Validation ends (PASS or FAIL) | Remove `validation-in-progress.lock` |
| Cleanup triggered | Check for lock file; abort if present |
| Stale lock detected | Lock older than 24 hours is treated as orphaned and ignored |

**Lock file contents:**

```json
{
  "pid": 12345,
  "started_at": "2024-01-15T10:30:00Z",
  "run_id": "run-20240115-103000"
}
```

**Cleanup behavior when lock is present:**

```
⚠️  Validation in progress (PID 12345, started 2024-01-15T10:30:00Z).
    Cleanup aborted. Re-run after validation completes.
```

Cleanup never removes `validation-in-progress.lock` itself — only the validation
process that created it may remove it. If a lock is stale (process no longer running),
cleanup logs a warning and proceeds after the 24-hour grace period.

### Archive Before Purge

Before any cleanup, create a compressed archive for offline retention:

```bash
tar -czf e2e-evidence-$(date +%Y%m%d).tar.gz e2e-evidence/
```
