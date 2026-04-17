# Troubleshooting and Performance

Loaded by `coordinated-validation` when you hit a wave failure, cross-platform inconsistency, or want to understand timing/performance characteristics.

## Common Failures

| Symptom | Root cause | How to diagnose | Resolution |
|---------|-----------|-----------------|-----------|
| Web shows empty data after API PASS | Frontend fetching wrong endpoint or using cached/mock fetch | Curl the API endpoint manually, compare JSON; check Network tab in browser devtools | Fix fetch URL in web validator; remove mock fallback |
| iOS blocked despite API passing | Wave evaluator read wrong field in API report | Open the API wave report JSON, verify `verdict: "PASS"` is set | Fix the evaluator's field lookup; re-read the report; re-launch blocked wave |
| Cross-platform count mismatch (API returns 10, Web shows 8) | API pagination cutoff, or Web filtering client-side | Curl API with page/limit params; inspect Web's fetch params | Document as CONDITIONAL with the specific counts cited; decide whether to ship |
| Wave 2 agents launched before Wave 1 completed | Orchestrator didn't await all Wave 1 background tasks | Check orchestration log — did it wait on EACH task or just the last one spawned? | Always `await` all agent tasks (not just the last) before evaluating wave verdict |
| Two agents writing to the same evidence directory | Assignment error — same dir assigned twice in member assignment table | Compare Assignment Table against actual agent prompts | Reassign immediately; discard corrupted evidence; re-run those agents with fresh dirs |

## Performance Guidelines

The point of wave execution is to parallelize where dependencies allow, so total time follows this pattern:

```
Total time = sum of wave durations
Wave duration = max of platform durations within that wave (parallel)
```

| Configuration | Waves | Wall clock formula |
|--------------|-------|-------|
| API only | 1 | `time(API)` |
| DB + API | 2 | `time(DB) + time(API)` |
| DB + API + Web | 3 | `time(DB) + time(API) + time(Web)` |
| DB + API + Web + iOS | 3 | `time(DB) + time(API) + max(time(Web), time(iOS))` |
| DB + Design + API + Web + iOS | 3 | `max(time(DB), time(Design)) + time(API) + max(time(Web), time(iOS))` |

**Worked example:** DB=10s, API=15s, Web=20s, iOS=25s → total = 10 + 15 + max(20,25) = 50s. The sequential alternative (DB→API→Web→iOS) would be 10+15+20+25 = 70s. Parallel execution saves 20s.
