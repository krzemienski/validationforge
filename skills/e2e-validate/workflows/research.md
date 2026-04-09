# Workflow: Research

**Objective:** Gather applicable standards, best practices, and validation criteria before planning journeys. This is Phase 0 — the intelligence-gathering step that informs all downstream phases.

## Prerequisites

- Access to project root directory
- Internet access for standards research (optional but recommended)
- No running services required (research is pre-execution)

## Process

### Step 1: Scope the Validation Domain

Identify what you're validating and classify it by domain.

| Domain | Key Standards | Primary Risks |
|--------|--------------|---------------|
| Web Application | WCAG 2.1, OWASP Top 10, Core Web Vitals | Accessibility, security, performance |
| iOS Application | Apple HIG, App Store Review Guidelines | Rejection, usability, performance |
| API Service | OpenAPI spec, REST conventions, OAuth 2.0 | Breaking changes, auth bypass, rate limits |
| E-commerce | PCI DSS, GDPR, accessibility laws | Payment fraud, data breach, legal compliance |
| CLI Tool | POSIX conventions, man page standards | Usability, error messaging, exit codes |
| Fullstack | All of the above | Combined risks across all layers |

Create the research directory and document the scope:

```bash
mkdir -p e2e-evidence/research
```

Write `e2e-evidence/research/step-01-scope.md`:

```markdown
## Validation Scope

**System:** {name and description}
**Domain:** {classification from table above}
**Platforms:** {web, iOS, API, CLI, etc.}
**User types:** {roles and access levels}
**Critical paths:** {revenue, auth, data integrity}
**Compliance requirements:** {applicable regulations}
```

### Step 2: Research Applicable Standards

For each identified domain, gather current standards and best practices.

| Source Type | How to Access | What to Extract |
|-------------|--------------|-----------------|
| Web standards | WebSearch + WebFetch | WCAG criteria, browser support |
| Platform guidelines | Context7 MCP | HIG requirements, review guidelines |
| Security standards | OWASP website | Top 10 vulnerabilities, checklists |
| Performance benchmarks | Google Web Vitals docs | LCP, INP, CLS thresholds |
| Regulatory requirements | Government websites | Compliance checklists |
| Industry best practices | Technical blogs, conference talks | Patterns and anti-patterns |

Research protocol per domain area:

1. **Search broadly** — 3–5 searches per domain area
2. **Fetch primary sources** — Read official docs, not summaries
3. **Extract measurable criteria** — Pull specific, testable requirements
4. **Cross-reference** — Verify claims across 2+ sources
5. **Date-check** — Ensure standards are current (within 12 months)

Save findings to `e2e-evidence/research/step-02-standards.md`.

### Step 3: Inventory Available Validation Tools

Check which tools are available in the current environment.

```bash
# Check CLI tools
for tool in xcrun idb curl node npm npx python3 playwright; do
  echo "$tool: $(which $tool 2>/dev/null || echo 'NOT FOUND')"
done > e2e-evidence/research/step-03-tools.txt

# Check for platform indicators
ls *.xcodeproj *.xcworkspace Package.swift 2>/dev/null && echo "iOS project detected"
ls Cargo.toml go.mod 2>/dev/null && echo "CLI project detected"
grep -rl "app.listen\|uvicorn\|gin.Default" src/ server/ api/ 2>/dev/null | head -3
ls src/components src/pages public/index.html 2>/dev/null && echo "Web project detected"
```

| Category | Tools to Check | How to Detect |
|----------|---------------|---------------|
| Browser automation | Playwright MCP, Chrome DevTools MCP | Check MCP server list |
| iOS automation | xcrun simctl, idb | `which xcrun`, `which idb` |
| API validation | curl, httpie | `which curl` |
| Accessibility | Lighthouse, axe-core | Via Chrome DevTools MCP |
| Performance | Lighthouse, WebPageTest | Via Chrome DevTools MCP |
| Code analysis | ESLint, TypeScript, grep | Package.json, tsconfig |

### Step 4: Map Standards to Validation Skills

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

### Step 5: Produce Research Report

Compile all findings into a structured report.

```markdown
# Validation Research Report

**System:** {name}
**Date:** YYYY-MM-DD
**Phase:** 0 — Research

## Executive Summary
{2–3 sentences: what we're validating, key risks, recommended approach}

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

## Output

- `e2e-evidence/research/step-01-scope.md` — Domain classification and compliance requirements
- `e2e-evidence/research/step-02-standards.md` — Applicable standards with measurable criteria
- `e2e-evidence/research/step-03-tools.txt` — Available tool inventory
- `e2e-evidence/research/step-04-mapping.md` — Standards-to-skills mapping matrix
- `e2e-evidence/research/report.md` — Final research report with coverage strategy

## Next Step

Feed the research report into `workflows/plan.md` to generate PASS criteria for each journey. The standards catalog determines which validation skills to invoke and the tool inventory determines which platform skills are available.
