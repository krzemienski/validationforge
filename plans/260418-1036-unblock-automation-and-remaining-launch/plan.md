---
title: "Unblock automation + all remaining launch work"
description: "Full-campaign automation + site/infra gaps identified 2026-04-18 post-soft-launch"
status: partial-complete
priority: P0
effort: 40h
branch: main
tags: [linkedin, launch, ai-hack-ski, og-meta, ga, dns, automation]
created: 2026-04-18
updated: 2026-04-18
completed_in_session: phase-01, phase-05
deferred_out_of_repo: phase-02, phase-03, phase-04
partial: phase-06 (16/20 Mon+Thu slots queued; 4 off-cadence slots posted manually)
---

## Context

Soft-launch post went LIVE on Nick Personal feed on 2026-04-18 ~10:34 ET. URL:
`https://www.linkedin.com/feed/update/urn:li:share:7451276398083608577/`.

OAuth is now operational (`urn:li:person:VUL7zN-Xg2`, token valid through 2026-06-17,
refresh valid 365d). `src/publish.js` patched to default `Linkedin-Version: 202604`.

This plan captures everything else the user requested immediately after go-live, organized
into 6 phases. Written just before session context compaction — resume fresh.

## Phases

| # | Phase | Status | File |
|---|---|---|---|
| 1 | LinkedIn automation — queue + launchd Mon/Thu 08:30 ET | ✅ **COMPLETE** — queue subcommands shipped, 16 slots seeded, plist loaded | [phase-01](./phase-01-linkedin-queue-and-launchd.md) |
| 2 | ai.hack.ski OG metadata | 🚫 **DEFERRED OUT-OF-REPO** — ai.hack.ski is separate deployment; requires access to its repo | [phase-02](./phase-02-og-metadata-for-ai-hack-ski.md) |
| 3 | Google Analytics on ai.hack.ski | 🚫 **DEFERRED OUT-OF-REPO** — same | [phase-03](./phase-03-google-analytics-ai-hack-ski.md) |
| 4 | DDNS subdomain: `ai.hack.ski` → Vercel deployment | 🚫 **DEFERRED OUT-OF-REPO** — needs DNS provider + Vercel project info; work in `hack.ski` registrar account, not this repo | [phase-04](./phase-04-ddns-subdomain-point-to-vercel.md) |
| 5 | Product/marketing landing page | ✅ **COMPLETE** — existing `site/` Starlight at validationforge.dev confirmed as landing page (user decision 2026-04-18) | [phase-05](./phase-05-product-marketing-landing-page.md) |
| 6 | Wave 1-5 content execution | 🟡 **PARTIAL** — 16 Mon+Thu slots queued and launchd-driven; 4 off-cadence slots (Wed Apr 22, Sat Apr 25, Wed Apr 29, Thu Apr 30) posted manually via LinkedIn UI per user decision | [phase-06](./phase-06-content-execution-waves-1-5.md) |

## Session evidence
- Phase 1 evidence report: [plans/reports/cook-260418-1145-phase-01-linkedin-queue-launchd-evidence.md](../reports/cook-260418-1145-phase-01-linkedin-queue-launchd-evidence.md)
- First real publish: **Mon May 18 2026 08:30 EDT** (`post-02-linkedin.md` / multi-agent-consensus)

## Critical path

Phase 1 unblocks Phases 6 (every post ships through the queue).
Phase 4 unblocks Phase 2 (OG tags need stable URL) which unblocks Phase 6 (share previews).
Phase 3 runs parallel.
Phase 5 is highest-leverage inbound conversion; should land before Show HN (2026-04-28).

Suggested order: **4 → 2 → 3 → 5 → 1 → 6** (infra → presentation → measurement → landing → pipeline → content).

## Session handoff notes

- Current working token in `.env`: `LINKEDIN_ACCESS_TOKEN` (expires 2026-06-17).
- `LINKEDIN_API_VERSION=202604` now the default in `publish.js`; still honor env override.
- Client Secret WAS in chat transcript earlier today — user rotated it, that's what caused the first 401. New secret in `.env`.
- HAR corpus at `integrations/linkedin-publisher/.lp-har.json` has 15 requests seeded; POST-create voyager schema still unknown (blocker for iOS-parity scheduling, but OAuth path suffices for the campaign).
- launchd plist written at `integrations/linkedin-publisher/com.validationforge.linkedin-publisher.plist`, `plutil -lint` passes, not yet `launchctl load`ed.
