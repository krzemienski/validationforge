---
name: research-validation
description: "Use at Phase 0 before validation planning, or when entering an unfamiliar domain (healthcare, payments, a11y-regulated, new framework) where the applicable standards aren't already known. Researches what standards apply (WCAG 2.1 AA? PCI-DSS? SOC 2? GDPR?), what validation tools are industry-standard, and maps each to the ValidationForge skills that implement them. Output informs create-validation-plan by establishing the starting rubric. Reach for it on phrases like 'what standards apply', 'how should we validate X', 'research before validation', 'new domain entry', 'regulatory validation', or when the team isn't yet aligned on what 'thorough' means for this project."
triggers:
  - "research validation"
  - "validation research"
  - "what standards apply"
  - "how should we validate"
  - "research before validation"
  - "new domain entry"
  - "regulatory validation"
  - "what does thorough mean"
context_priority: reference
---

# Research Validation

Research applicable standards, best practices, and available tools before designing a validation strategy. This is Phase 0 — the intelligence-gathering step that informs `create-validation-plan`.

## When to Use

- Before validating a system you haven't worked with before
- When entering a new domain (healthcare, fintech, e-commerce, etc.)
- When standards have changed or new tools are available
- When deciding what validation coverage is appropriate
- When building the case for validation investment

## Five-Phase Research Process

```
Phase 1: SCOPE    Phase 2: STANDARDS   Phase 3: TOOLS    Phase 4: MAP    Phase 5: REPORT
What are we       What rules apply?    What can we       Match tools     Document for
validating?                            use?              to standards    plan creation
```

## Phase 1: Scope the Validation Domain

Identify what you're validating and classify it.

### Domain Classification

| Domain | Key Standards | Primary Risks |
|--------|--------------|---------------|
| Web Application | WCAG 2.1, OWASP Top 10, Core Web Vitals | Accessibility, security, performance |
| iOS Application | Apple HIG, App Store Review Guidelines | Rejection, usability, performance |
| API Service | OpenAPI spec, REST conventions, OAuth 2.0 | Breaking changes, auth bypass, rate limits |
| E-commerce | PCI DSS, GDPR, accessibility laws | Payment fraud, data breach, legal compliance |
| Healthcare | HIPAA, FDA 21 CFR Part 11 | Data exposure, audit trail gaps |
| Financial | SOX, PSD2, accessibility regulations | Regulatory violation, fraud |

```bash
mkdir -p e2e-evidence/research
```

Document scope in `e2e-evidence/research/step-01-scope.md`:
```markdown
## Validation Scope

**System:** {name and description}
**Domain:** {classification from table above}
**Platforms:** {web, iOS, API, CLI, etc.}
**User types:** {roles and access levels}
**Critical paths:** {revenue, auth, data integrity}
**Compliance requirements:** {applicable regulations}
```

## Phase 2: Research Applicable Standards

For each identified domain, research current standards.

### Research Sources

| Source Type | How to Access | What to Extract |
|-------------|--------------|-----------------|
| Web standards | WebSearch + WebFetch | WCAG criteria, browser support |
| Platform guidelines | Context7 MCP | HIG requirements, review guidelines |
| Security standards | OWASP website | Top 10 vulnerabilities, checklists |
| Performance benchmarks | Google Web Vitals docs | LCP, INP, CLS thresholds |
| Regulatory requirements | Government websites | Compliance checklists |
| Industry best practices | Technical blogs, conference talks | Patterns and anti-patterns |

### Research Protocol

1. **Search broadly** — 3-5 web searches per domain area
2. **Fetch documentation** — Read primary sources, not summaries
3. **Extract criteria** — Pull specific, measurable requirements
4. **Cross-reference** — Verify claims across 2+ sources
5. **Date-check** — Ensure standards are current (within 12 months)

Save findings to `e2e-evidence/research/step-02-standards.md`.

## Phase 3: Inventory Available Tools

Identify which validation tools are available in the current environment.

### Tool Categories

| Category | Tools to Check | How to Detect |
|----------|---------------|---------------|
| Browser automation | Playwright MCP, Chrome DevTools MCP | Check MCP server list |
| iOS automation | xcrun simctl, idb | `which xcrun`, `which idb` |
| API validation | curl, httpie, Postman | `which curl` |
| Accessibility | Lighthouse, axe-core | Via Chrome DevTools MCP |
| Performance | Lighthouse, WebPageTest | Via Chrome DevTools MCP |
| Design | Stitch MCP | Check MCP server list |
| Code analysis | ESLint, TypeScript, grep | Package.json, tsconfig |

### Environment Check

```bash
# Check available MCP tools
# (done by examining available tool list in Claude Code)

# Check CLI tools
for tool in xcrun idb curl node npm npx python3; do
  echo "$tool: $(which $tool 2>/dev/null || echo 'NOT FOUND')"
done > e2e-evidence/research/step-03-tools.txt
```

## Phase 4: Map Standards to Validation Skills

Create a mapping matrix connecting standards to ValidationForge skills.

```markdown
## Validation Mapping

| Standard/Requirement | Validation Skill | Evidence Type |
|---------------------|-----------------|---------------|
| WCAG 2.1 AA contrast | accessibility-audit | Lighthouse report |
| OWASP injection | api-validation | Request/response logs |
| Core Web Vitals LCP | chrome-devtools | Performance trace |
| Apple HIG touch targets | ios-validation | Screenshot + measurements |
| Design fidelity | design-validation | Side-by-side comparison |
| Responsive behavior | responsive-validation | Multi-viewport screenshots |
```

Save to `e2e-evidence/research/step-04-mapping.md`.

## Phase 5: Produce Research Report

```markdown
# Validation Research Report

**System:** {name}
**Date:** YYYY-MM-DD
**Researcher:** ValidationForge

## Executive Summary
{2-3 sentences: what we're validating, key risks, recommended approach}

## Applicable Standards
1. {Standard} — {specific criteria} — Source: {URL}
2. ...

## Available Tools
{list of tools available in this environment}

## Coverage Strategy
| Risk Area | Priority | Skill | Estimated Effort |
|-----------|----------|-------|-----------------|
| {area} | P0/P1/P2/P3 | {skill name} | {low/medium/high} |

## Recommended Validation Plan Inputs
- Journeys to validate: {list}
- Platforms to cover: {list}
- Standards to verify: {list}
- Tools to use: {list}

## Sources
1. {URL} — {what was extracted}
2. ...
```

Save to `e2e-evidence/research/report.md`.

## Integration with ValidationForge

- This skill is Phase 0 — run BEFORE `create-validation-plan`
- Research output feeds directly into `create-validation-plan` as input
- Standards catalog informs which validation skills to invoke
- Tool inventory determines which platform skills are available
- The `brainstorm-validation-strategy` use case is covered by Phase 1 (Scope) + Phase 4 (Map)
- Evidence goes to `e2e-evidence/research/`
