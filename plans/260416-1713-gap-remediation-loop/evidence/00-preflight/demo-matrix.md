# P05 Demo Matrix: Benchmark Scenarios

**Date:** 2026-04-16  
**Source:** P00 preflight scan of `benchmark/scaffolds/` + demo dirs  
**Status:** Baseline identified; 5 canonical scenarios TBD (P05 will discover)

---

## Existing Scaffolds (8 total)

Location: `benchmark/scaffolds/`

| # | Scaffold | Platform | Language | Framework | In Scope Today? | Oracle File? | Notes |
|---|----------|----------|----------|-----------|-----------------|--------------|-------|
| 1 | node-cli | CLI | JavaScript | Node.js | TBD | ? | Command-line app; args + exit codes |
| 2 | node-express | API | JavaScript | Express | TBD | ? | REST API server; port binding + routes |
| 3 | node-fullstack | Fullstack | JavaScript | Node+HTML | TBD | ? | Web server + static assets |
| 4 | node-nextjs | Web | JavaScript | Next.js | TBD | ? | React SSR; page rendering + client nav |
| 5 | node-react | Web | JavaScript | React | TBD | ? | SPA; component rendering + state |
| 6 | python-cli | CLI | Python | standard lib | TBD | ? | CLI args; stdout capture |
| 7 | python-flask | API | Python | Flask | TBD | ? | HTTP server; response validation |
| 8 | swift-ios | iOS | Swift | native | TBD | ? | Xcode project; simulator launch |

---

## Demo Directory

Location: `/Users/nick/Desktop/validationforge/demo/` (exists but contents not scanned in P00)

Status: Defer to P05 (executor will walk demo/ and select 5 canonical scenarios for final validation matrix).

---

## Missing Information (Flagged)

| Item | Status | Next Action |
|------|--------|-------------|
| 5 canonical scenarios | UNRESOLVED | P05 executor discovery |
| Oracle files (pre-existing?) | UNRESOLVED | P05 will match scaffolds to oracle specs |
| Platform coverage (which 5 of 8?) | UNRESOLVED | P05 to select based on gap closure targets |
| Demo-to-scaffold mapping | UNRESOLVED | P05 discovery phase |

---

## Notes for P05 Executor

1. Walk `benchmark/scaffolds/` and `demo/` to identify the 5 scenarios matching your closure targets
2. For each scenario: determine if pre-existing oracle spec exists (yes/no)
3. Fill in "In Scope Today?" based on campaign priorities (P05 phase file will specify)
4. Update this matrix with final selections before Phase 05 validation begins

This is a baseline snapshot. P05 will refine and finalize.
