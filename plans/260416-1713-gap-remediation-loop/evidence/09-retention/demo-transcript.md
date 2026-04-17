# P09 Cleanup Demo Transcript

## Dry-run
[evidence-clean] retention=30d (from standard.json) | root=/tmp/vf-cleanup-demo/e2e-evidence | dry-run=true
[evidence-clean] DRY-RUN would delete: /tmp/vf-cleanup-demo/e2e-evidence/fake-old-journey (mtime=2026-03-17T00:43:33.000Z)
[evidence-clean] dry-run complete. 1 dir(s) scanned, 1 eligible for removal.

## Real clean
[evidence-clean] retention=30d (from standard.json) | root=/tmp/vf-cleanup-demo/e2e-evidence | dry-run=false
[evidence-clean] deleted: /tmp/vf-cleanup-demo/e2e-evidence/fake-old-journey (mtime=2026-03-17T00:43:33.000Z)
[evidence-clean] done. removed=1 skipped=0

## cleanup.log entries
2026-04-17T00:43:39Z | /tmp/vf-cleanup-demo/e2e-evidence/fake-old-journey | 2026-03-17T00:43:33Z | dry-run
2026-04-17T00:43:39Z | SUMMARY | - | dry-run complete. 1 dir(s) scanned, 1 eligible for removal.
2026-04-17T00:43:47Z | /tmp/vf-cleanup-demo/e2e-evidence/fake-old-journey | 2026-03-17T00:43:33Z | deleted
2026-04-17T00:43:47Z | SUMMARY | - | done. removed=1 skipped=0
