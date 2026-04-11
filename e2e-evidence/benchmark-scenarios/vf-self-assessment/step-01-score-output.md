=== ValidationForge 4-Dimension Benchmark Scorer ===
Project: /Users/nick/Desktop/validationforge

[enforcement] +20: hooks infrastructure found
[enforcement] +20: no test/spec files in src/ or lib/
[enforcement] +20: no mock/stub patterns in src/
[enforcement]  +0: no markdown files in .claude/rules/
[enforcement] +10: e2e-evidence/ directory exists
[enforcement]  +0: no .vf/config.json

Enforcement score: 70 / 100

[evidence] total files: 85
[evidence] non-empty (>10 bytes): 85
[evidence] verdict/report files: 7
Evidence Quality score: 100 / 100

[coverage] evidence journey subdirs: 8
[coverage] +10: plans/ has 33 markdown plan file(s)
Coverage score: 95 / 100

[speed] no .vf/last-run.json — using default speed score
Speed score: 80 / 100

=== BENCHMARK RESULTS ===

| Dimension        | Weight | Score |
|------------------|--------|-------|
| Coverage         |   35%  |  95  |
| Evidence Quality |   30%  |  100  |
| Enforcement      |   25%  |  70  |
| Speed            |   10%  |  80  |

Aggregate: 88 / 100
Grade: B

Benchmark saved to /Users/nick/Desktop/validationforge/.vf/benchmarks/benchmark-2026-04-11.json
{"coverage":95,"evidence":100,"enforcement":70,"speed":80,"aggregate":88,"grade":"B"}
