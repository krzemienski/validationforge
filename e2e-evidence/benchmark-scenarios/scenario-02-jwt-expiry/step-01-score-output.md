=== ValidationForge 4-Dimension Benchmark Scorer ===
Project: /Users/nick/Desktop/validationforge/.auto-claude/worktrees/tasks/018-verified-benchmark-scoring-system/scripts/benchmark/fixtures/scenario-02-jwt-expiry

[enforcement]  +0: no hooks/hooks.json or .claude/hooks/
[enforcement] +20: no test/spec files in src/ or lib/
[enforcement] +20: no mock/stub patterns in src/
[enforcement]  +0: no markdown files in .claude/rules/
[enforcement] +10: e2e-evidence/ directory exists
[enforcement]  +0: no .vf/config.json

Enforcement score: 50 / 100

[evidence] total files: 2
[evidence] non-empty (>10 bytes): 2
[evidence] verdict/report files: 0
Evidence Quality score: 70 / 100

[coverage] evidence journey subdirs: 1
[coverage]  +0: no markdown files in plans/
Coverage score: 50 / 100

[speed] no .vf/last-run.json — using default speed score
Speed score: 80 / 100

=== BENCHMARK RESULTS ===

| Dimension        | Weight | Score |
|------------------|--------|-------|
| Coverage         |   35%  |  50  |
| Evidence Quality |   30%  |  70  |
| Enforcement      |   25%  |  50  |
| Speed            |   10%  |  80  |

Aggregate: 59 / 100
Grade: F

Benchmark saved to /Users/nick/Desktop/validationforge/.auto-claude/worktrees/tasks/018-verified-benchmark-scoring-system/scripts/benchmark/fixtures/scenario-02-jwt-expiry/.vf/benchmarks/benchmark-2026-04-08.json
{"coverage":50,"evidence":70,"enforcement":50,"speed":80,"aggregate":59,"grade":"F"}
