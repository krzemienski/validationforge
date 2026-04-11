=== ValidationForge 4-Dimension Benchmark Scorer ===
Project: /Users/nick/Desktop/validationforge/scripts/benchmark/fixtures/scenario-01-api-rename

[enforcement] +20: hooks infrastructure found
[enforcement] +20: no test/spec files in src/ or lib/
[enforcement] +20: no mock/stub patterns in src/
[enforcement] +20: .claude/rules/ has 1 markdown rule file(s)
[enforcement] +10: e2e-evidence/ directory exists
[enforcement]  +0: no .vf/config.json

Enforcement score: 90 / 100

[evidence] total files: 4
[evidence] non-empty (>10 bytes): 3
[evidence] verdict/report files: 1
Evidence Quality score: 82 / 100

[coverage] evidence journey subdirs: 1
[coverage] +10: plans/ has 1 markdown plan file(s)
Coverage score: 60 / 100

[speed] no .vf/last-run.json — using default speed score
Speed score: 80 / 100

=== BENCHMARK RESULTS ===

| Dimension        | Weight | Score |
|------------------|--------|-------|
| Coverage         |   35%  |  60  |
| Evidence Quality |   30%  |  82  |
| Enforcement      |   25%  |  90  |
| Speed            |   10%  |  80  |

Aggregate: 76 / 100
Grade: C

Benchmark saved to /Users/nick/Desktop/validationforge/scripts/benchmark/fixtures/scenario-01-api-rename/.vf/benchmarks/benchmark-2026-04-11.json
{"coverage":60,"evidence":82,"enforcement":90,"speed":80,"aggregate":76,"grade":"C"}
