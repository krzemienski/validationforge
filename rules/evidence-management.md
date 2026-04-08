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

- Keep ALL evidence for FAIL journeys
- Keep key evidence for PASS journeys (entry + final state)
- Archive after validation: `tar -czf e2e-evidence-$(date +%Y%m%d).tar.gz e2e-evidence/`
