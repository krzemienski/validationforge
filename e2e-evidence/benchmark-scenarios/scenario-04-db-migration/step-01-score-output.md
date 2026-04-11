=== ValidationForge 4-Dimension Benchmark Scorer ===
Project: /Users/nick/Desktop/validationforge/scripts/benchmark/fixtures/scenario-04-db-migration

[enforcement] +20: hooks infrastructure found
[enforcement] +20: no test/spec files in src/ or lib/
[enforcement] +20: no mock/stub patterns in src/
[enforcement] +20: .claude/rules/ has 1 markdown rule file(s)
[enforcement] +10: e2e-evidence/ directory exists
[enforcement] +10: .vf/config.json exists

Enforcement score: 100 / 100

[evidence] total files: 6
[evidence] non-empty (>10 bytes): 6
[evidence] verdict/report files: 2
Evidence Quality score: 100 / 100

[coverage] evidence journey subdirs: 1
[coverage] +10: plans/ has 2 markdown plan file(s)
Coverage score: 60 / 100

[speed] no .vf/last-run.json — using default speed score
Speed score: 80 / 100

=== BENCHMARK RESULTS ===

| Dimension        | Weight | Score |
|------------------|--------|-------|
| Coverage         |   35%  |  60  |
| Evidence Quality |   30%  |  100  |
| Enforcement      |   25%  |  100  |
| Speed            |   10%  |  80  |

Aggregate: 84 / 100
Grade: B

Benchmark saved to /Users/nick/Desktop/validationforge/scripts/benchmark/fixtures/scenario-04-db-migration/.vf/benchmarks/benchmark-2026-04-11.json
{"coverage":60,"evidence":100,"enforcement":100,"speed":80,"aggregate":84,"grade":"B"}
