# Phase 0: Research — Next.js Web Platform Validation

**System:** blog-series/site (Next.js 15, App Router, TypeScript, Tailwind v4)
**Date:** 2026-04-08
**Phase:** 0 — Research
**Validator:** ValidationForge research-validation protocol

---

## Step 1: Validation Scope

**System:** blog-series/site — a Next.js 15 App Router blog publishing 18 posts about agentic development workflows.
**Domain:** Web Application
**Platforms:** Web (Next.js 15, SSG/SSR, TypeScript, Tailwind v4)
**User types:**
- Anonymous readers (primary) — browse posts, read articles
- No authenticated users (public-facing blog, read-only)

**Critical paths:**
- Homepage renders all 18 posts (content index)
- Individual post pages render full article (markdown → HTML, Mermaid diagrams, code blocks)
- Post-to-post navigation works (Previous/Next links)
- Site navigation (Posts, About, GitHub links) functions correctly

**Compliance requirements:**
- WCAG 2.1 Level AA (web accessibility — mandatory for public-facing sites)
- Core Web Vitals (Google ranking signal — LCP < 2.5s, INP < 200ms, CLS < 0.1)
- Browser compatibility: modern evergreen browsers (Chrome, Firefox, Safari, Edge)
- No PII/GDPR concerns (no user data collected, no authentication)

---

## Step 2: Applicable Standards

### 2.1 Web Accessibility — WCAG 2.1 Level AA

**Applicable criteria for a content-heavy blog:**

| Criterion | Level | Requirement | How to Verify |
|-----------|-------|-------------|---------------|
| 1.1.1 Non-text content | A | All images have alt text | Inspect img elements |
| 1.4.3 Contrast | AA | Text contrast ratio ≥ 4.5:1 | Lighthouse accessibility audit |
| 2.1.1 Keyboard | A | All interactive elements keyboard-navigable | Tab through page |
| 2.4.1 Skip blocks | A | Skip navigation link present | Check page source |
| 2.4.6 Headings/Labels | AA | Headings describe topic/purpose | Verify heading hierarchy |
| 3.1.1 Language of Page | A | `<html lang>` attribute set | Inspect HTML root |
| 4.1.2 Name/Role/Value | A | Interactive elements have accessible names | Lighthouse audit |

**Source:** https://www.w3.org/WAI/WCAG21/quickref/

### 2.2 Core Web Vitals (Google, 2024)

| Metric | Good | Needs Improvement | Poor |
|--------|------|-------------------|------|
| LCP (Largest Contentful Paint) | < 2.5s | 2.5–4.0s | > 4.0s |
| INP (Interaction to Next Paint) | < 200ms | 200–500ms | > 500ms |
| CLS (Cumulative Layout Shift) | < 0.1 | 0.1–0.25 | > 0.25 |
| FCP (First Contentful Paint) | < 1.8s | 1.8–3.0s | > 3.0s |

**Source:** https://web.dev/articles/vitals

### 2.3 Next.js App Router — Platform-Specific Standards

| Requirement | Rationale | How to Verify |
|-------------|-----------|---------------|
| Build completes with zero errors | Production build is the golden artifact | `pnpm build` exit code 0 |
| Static pages generated correctly | SSG output validates template compilation | Build output: "Generating static pages (N/N)" |
| No hydration mismatch errors | Server HTML ≠ client HTML causes layout jumps | Browser console, no "Warning: Text content did not match" |
| Link components use client-side navigation | Next.js `<Link>` should intercept, not full reload | Network tab shows no full page reloads on navigation |
| Image Optimization | `next/image` serves WebP, correct sizes | Network tab: `Accept: image/webp` responses |

### 2.4 Security Standards (OWASP, baseline)

For a static/SSG blog with no user input or authentication, the attack surface is minimal:

| Risk | Mitigation | Verification |
|------|-----------|-------------|
| XSS | Next.js auto-escapes React output | No unescaped HTML in rendered output |
| Content Security Policy | CSP headers restrict resource loading | Check response headers |
| HTTPS enforcement | HTTPS-only in production | Out of scope for localhost; document for production |

**Source:** https://owasp.org/www-project-top-ten/

### 2.5 Browser Compatibility

**Target browsers (based on Next.js 15 browser targets):**

| Browser | Minimum Version | Market Share |
|---------|----------------|-------------|
| Chrome | 90+ | ~65% |
| Firefox | 88+ | ~4% |
| Safari | 14+ | ~19% |
| Edge | 90+ | ~5% |
| Mobile Safari | iOS 14+ | included |

**Validation approach:** Playwright covers Chrome (Chromium) and optionally Firefox/WebKit.

---

## Step 3: Available Validation Tools

Detected from environment:

| Category | Tool | Available | Version/Path |
|----------|------|-----------|-------------|
| HTTP client | curl | ✅ | /usr/bin/curl |
| Node.js runtime | node | ✅ | /opt/homebrew/bin/node |
| Package manager | npm | ✅ | /opt/homebrew/bin/npm |
| Package manager | pnpm | ✅ | /opt/homebrew/bin/pnpm |
| Script runner | npx | ✅ | /opt/homebrew/bin/npx |
| Browser automation | Playwright MCP | ✅ | MCP server active in Claude Code |
| Accessibility | Lighthouse (via Chrome DevTools MCP) | ✅ | Via Chrome DevTools MCP |
| iOS simulator | xcrun simctl | N/A | Not needed for web |
| Python | python3 | ✅ | /opt/homebrew/bin/python3 |
| API testing | curl | ✅ | Available for API endpoint testing |

**Platform indicators detected in blog-series/site:**
- `next.config.ts` → Next.js project
- `package.json` → `next: 15.1.6`, `react: 19.0.0`
- `tailwind.config.ts` → Tailwind v4
- `tsconfig.json` → TypeScript
- `app/` directory → App Router (not pages/)
- `pnpm-lock.yaml` → pnpm package manager

**Platform classification: Web Application (Next.js 15, App Router, SSG)**

---

## Step 4: Standards-to-Skills Mapping

| Standard / Requirement | ValidationForge Skill | Evidence Type |
|-----------------------|----------------------|---------------|
| Next.js build succeeds | build-quality-gates | Build log (exit code + output line) |
| Dev server starts and serves HTTP 200 | preflight | curl response |
| Homepage renders all posts | playwright-validation | Screenshot + accessibility snapshot |
| Individual post renders correctly | playwright-validation | Screenshot |
| Post-to-post navigation works | playwright-validation | Screenshot (before + after) |
| No JavaScript console errors | playwright-validation | Console log capture |
| WCAG 2.1 AA compliance | accessibility-audit | Lighthouse accessibility report |
| Core Web Vitals in "Good" range | chrome-devtools | Lighthouse performance report |
| Responsive layout (mobile viewport) | playwright-validation | Screenshot at 375px width |
| Static pages generated (SSG output) | build-quality-gates | Build output line count |
| No hydration errors | playwright-validation | Console error check |
| Link navigation (client-side routing) | playwright-validation | Network request intercept |

---

## Step 5: Research Report

### Executive Summary

We are validating `blog-series/site`, a Next.js 15 App Router blog with 18 static posts about agentic development. The primary risks are: rendering failures (Mermaid diagrams, code blocks, data tables), navigation breakage (Next.js Link routing), hydration mismatches, and accessibility violations. The recommended approach is a layered bottom-up validation: build verification → server health → homepage render → individual post rendering → navigation → console error check. Playwright MCP is available for browser automation; curl is available for HTTP-level verification.

### Applicable Standards (prioritized)

1. **Next.js Build** — Zero-error build with all N pages generated — Source: Next.js docs
2. **HTTP availability** — Server responds with 200 on primary routes — Source: RFC 9110
3. **Homepage content render** — All 18 post cards visible, stats correct — Observable from screenshot
4. **Individual post render** — Title, body, Mermaid diagrams, code blocks, navigation all visible — Observable from screenshot
5. **Navigation** — Previous/Next links advance to correct posts — Observable from URL + screenshot
6. **Console cleanliness** — No application-level JS errors — Browser console capture
7. **WCAG 2.1 AA** — Contrast, alt text, keyboard navigation, heading hierarchy — Lighthouse report
8. **Core Web Vitals** — LCP < 2.5s, INP < 200ms, CLS < 0.1 — Lighthouse performance report
9. **Responsive layout** — Layout intact at 375px mobile viewport — Mobile screenshot

### Coverage Strategy

| Risk Area | Priority | Skill | Estimated Effort |
|-----------|----------|-------|-----------------|
| Build compiles | P0 | build-quality-gates | Low |
| Server starts/responds | P0 | preflight | Low |
| Homepage renders all posts | P0 | playwright-validation | Low |
| Individual post renders | P0 | playwright-validation | Low |
| Post-to-post navigation | P1 | playwright-validation | Low |
| Console error detection | P1 | playwright-validation | Low |
| Accessibility audit | P2 | accessibility-audit | Medium |
| Core Web Vitals | P2 | chrome-devtools | Medium |
| Mobile responsive | P2 | playwright-validation | Low |
| Cross-browser (Firefox) | P3 | playwright-validation | Medium |

### Recommended Validation Plan Inputs

- **Journeys to validate:** 7 (Build, Server Health, Homepage, Post Detail, Navigation, Console Check, Mobile Responsive)
- **Platforms to cover:** Web (Next.js 15, Chromium via Playwright)
- **Standards to verify:** Next.js build standards, HTTP availability, WCAG 2.1 AA (P2), Core Web Vitals (P2)
- **Tools to use:** pnpm (build), curl (HTTP check), Playwright MCP (browser journeys)

### Sources

1. https://www.w3.org/WAI/WCAG21/quickref/ — WCAG 2.1 Level AA criteria (accessibility standards table)
2. https://web.dev/articles/vitals — Core Web Vitals thresholds (LCP, INP, CLS numbers)
3. https://nextjs.org/docs — Next.js 15 App Router build and SSG behavior
4. https://owasp.org/www-project-top-ten/ — OWASP Top 10 (baseline security requirements)
5. https://playwright.dev/ — Playwright browser automation API (screenshot, navigation, console capture)
