# Campaign Evidence Dir Preservation Check

After all P09 cleanup operations, the following plan evidence dirs still exist:

plans/260416-1713-gap-remediation-loop/evidence/00-preflight/
plans/260416-1713-gap-remediation-loop/evidence/01-active-plan/
plans/260416-1713-gap-remediation-loop/evidence/02-orphan-hooks/
plans/260416-1713-gap-remediation-loop/evidence/03-inventory/
plans/260416-1713-gap-remediation-loop/evidence/04-platform-detect/
plans/260416-1713-gap-remediation-loop/evidence/05-benchmark/
plans/260416-1713-gap-remediation-loop/evidence/06-skill-remed/
plans/260416-1713-gap-remediation-loop/evidence/07-skill-review/
plans/260416-1713-gap-remediation-loop/evidence/08-engines/
plans/260416-1713-gap-remediation-loop/evidence/09-retention/

Expected: 10 dirs (00..09 inclusive). Actual count:       10

scripts/evidence-clean.js only operates on $VF_EVIDENCE_ROOT (default ./e2e-evidence/) and does NOT traverse into plans/*/evidence/. Confirmed by reading scripts/evidence-clean.js.
