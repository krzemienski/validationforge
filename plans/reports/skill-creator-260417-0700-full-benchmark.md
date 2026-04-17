# ValidationForge Skills Full Benchmark Report

**Session**: 2026-04-17 06:46–07:00 ET
**Skills benchmarked**: 48 / 48 (across 8 batches of 6)
**Method**: compressed skill-creator loop — first eval from each skill's `evals.json`, 4 assertions derived from expected_output, graded against snapshot (pre-pass-1) and current (post-pass-3)

## Headline

| Config | Mean pass rate | Skills at 100% | Skills with regression |
|---|---|---|---|
| snapshot (pre-improvement) | 0.73 | 17 / 48 | — |
| current (post-improvement) | 0.95 | **42 / 48** | 2 |

**Mean delta: +0.22 per skill** (`(0.95 − 0.73) * 100 = +22pp`).

## Per-batch roll-up

| Batch | Skills | Scope | Aggregate delta |
|---|---|---|---|
| 1 | api-validation, ai-evidence-analysis, e2e-validate, forge-setup, ios-validation, no-mocking-validation-gates | Stage 1+2 targets | **+0.17** |
| 2 | web-validation, forge-plan, fullstack-validation, coordinated-validation, react-native-validation, django-validation | Stage 2+3 targets | **+0.13** |
| 3 | flutter-validation, accessibility-audit, baseline-quality-assessment, build-quality-gates, chrome-devtools, cli-validation | Stage 3 + desc-only | **−0.04** |
| 4 | condition-based-waiting, create-validation-plan, design-token-audit, design-validation, e2e-testing, error-recovery | Third-pass polish + desc-only | **+0.58** |
| 5 | forge-execute, forge-team, full-functional-audit, functional-validation, gate-validation-discipline, ios-simulator-control | Desc-only + structural | **+0.08** |
| 6 | ios-validation-gate, ios-validation-runner, parallel-validation, playwright-validation, preflight, production-readiness-audit | Mixed | **+0.13** |
| 7 | research-validation, responsive-validation, retrospective-validation, rust-cli-validation, sequential-analysis, stitch-integration | Desc-only (biggest gains) | **+0.63** |
| 8 | team-validation-dashboard, validate-audit-benchmarks, verification-before-completion, visual-inspection, web-testing, forge-benchmark | Stage 4 polish targets | **+0.08** |

## Ceiling snapshot

**42 of 48 skills at 4/4 (100%) with the current version.** Remaining six:

| Skill | Pass rate | Gap |
|---|---|---|
| ios-validation | 3/4 (0.75) | Missing Xcode Product→Scheme→Edit UI path in both versions |
| no-mocking-validation-gates | 3/4 (0.75) | Missing concrete fix menu (caching, production-like data) for slow/flaky deps |
| baseline-quality-assessment | 3/4 (0.75) | Login-specific capture lives in refs, not inline |
| coordinated-validation | 3/4 (0.75) | **FIXED this session** — timing formula inlined |
| flutter-validation | 3/4 (0.75) | **FIXED this session** — iOS DiagnosticReports path inlined |
| full-functional-audit | 2/4 (0.50) | Missing Phase 2 feature inventory guidance (route scanning, OpenAPI parsing, ~20-feature scoping heuristic) |

## Regressions (caught by benchmark, fixed in this session)

Two progressive-disclosure side effects from Stage 3 body restructuring:

1. **coordinated-validation** (-0.25 in batch 2) — the wall-clock timing formula
   `DB + API + max(Web, iOS)` was offloaded to `references/troubleshooting.md`, but
   the eval specifically expected it inline. Fixed by re-inlining the formula with a
   concrete example (`≈ 5.5min` for a typical fullstack stack).
2. **flutter-validation** (-0.25 in batch 3) — the iOS `~/Library/Logs/DiagnosticReports/Runner*.ips`
   crash-log check was offloaded to `references/flutter-logs-crashes.md`, but the
   eval expected it inline for release-build triage. Fixed by splitting Step 7 into
   "Dart-side check" (inline) and "Native-layer checks" (inline for iOS + Android with
   reference pointer retained for deeper variants).

## Biggest wins

| Skill | Delta | Why |
|---|---|---|
| research-validation | **+0.75** | 5-phase structure + domain table (PCI/HIPAA) the snapshot lacked entirely |
| retrospective-validation | **+0.75** | COLLECT→ANALYZE→CORRELATE→CONCLUDE phases + Detection×Accuracy×Longevity formula |
| stitch-integration | **+0.75** | stitch.json persistence + canonical bridge protocol |
| design-token-audit | **+0.75** | 4-phase EXTRACT→SCAN→COMPARE→REPORT + HIGH/LOW severity + % threshold |
| error-recovery | **+0.75** | 3-strike taxonomy (snapshot baseline was "retry and hope") |

Skills with meaningful (+0.25–+0.50) gains: ai-evidence-analysis, e2e-validate,
web-validation, forge-plan, fullstack-validation, condition-based-waiting,
create-validation-plan, design-validation, e2e-testing, responsive-validation,
rust-cli-validation, sequential-analysis, forge-execute, gate-validation-discipline,
ios-validation-runner, parallel-validation, preflight, validate-audit-benchmarks,
forge-benchmark.

## Where snapshot was already strong

17 skills scored 1.00 on the snapshot — the baseline SKILL.md already contained the
full rubric needed for eval-1. Their pass-1/2/3 improvements are additive (better
descriptions, more triggers, bundled scripts, sharper examples) but the first-eval
assertion set was already satisfied. These include forge-team, ios-simulator-control,
functional-validation, playwright-validation, production-readiness-audit,
ios-validation-gate, team-validation-dashboard, verification-before-completion,
visual-inspection, web-testing, and others. Additional improvement signal would show
up on harder or more adversarial evals.

## Mechanics caveat

Compressed benchmark — one eval per skill, not two; runs inline within a single batch
meta-agent (one agent sees both snapshot and current, separates its reads). Not
identical to the forge-benchmark demo's fully-isolated subagent-per-config setup, but
cheap enough to cover all 48 skills in 8 waves (~80 minutes wall clock). The forge-benchmark
demo remains the reference implementation for rigorous per-skill benchmarking if a skill's
delta warrants it.

## Files

- Per-batch JSON: `skill-audit-workspace/_benchmark-batch{1..8}.json`
- forge-benchmark iteration-1 reference demo: `skill-audit-workspace/forge-benchmark/iteration-1/{review.html,benchmark.json,benchmark.md}`
- Improvement logs per skill: `skill-audit-workspace/<skill>/improvement-log-pass2.json` or `restructure-log-pass2.json`

## Unresolved questions

1. Run **eval #2** on the 4 skills at 0.75 ceiling (ios-validation, no-mocks, baseline-quality-assessment,
   full-functional-audit)? Their pass-1 edits may show as gains there even when eval #1
   floored.
2. full-functional-audit at 0.50 is the lowest — worth a targeted pass-4 edit adding
   a "Phase 2: Feature Inventory Techniques" subsection with routing-table extraction,
   OpenAPI parsing, and the >20-feature scoping heuristic?
3. Should the regressions (coordinated-validation, flutter-validation) be re-benchmarked
   now that they're fixed, to confirm the fix closes the delta?
