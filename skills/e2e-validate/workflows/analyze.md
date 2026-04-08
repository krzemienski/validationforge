# Workflow: Analyze

**Objective:** Scan the codebase, detect the project platform, and produce a complete inventory of user journeys that require validation.

## Prerequisites

- Access to project root directory
- No running services required (static analysis only)

## Process

### Step 1: Detect Platform

Run the `detect_platform()` function from SKILL.md or manually check file indicators:

```bash
# Quick manual check
ls *.xcodeproj *.xcworkspace Package.swift 2>/dev/null  # iOS?
ls Cargo.toml go.mod 2>/dev/null                        # CLI?
grep -rl "app.listen\|uvicorn\|gin.Default" src/ server/ api/ 2>/dev/null  # API?
ls src/components src/pages public/index.html 2>/dev/null  # Web?
```

Record the detected platform. If ambiguous, choose the HIGHEST priority match from the platform table.

### Step 2: Identify Entry Points

Scan for all user-facing entry points based on platform:

| Platform | What to Scan | Tool |
|----------|-------------|------|
| iOS | Storyboard scenes, SwiftUI views, `@main` App struct | Grep for `NavigationView`, `TabView`, `WindowGroup` |
| Web | Route definitions, page components, navigation menus | Grep for `<Route`, `pages/`, `app/` directory structure |
| API | Route registrations, endpoint handlers, OpenAPI spec | Grep for `app.get`, `@router`, `r.GET`, `paths:` in YAML |
| CLI | Subcommands, flag definitions, help text | Grep for `cobra.Command`, `argparse`, `clap::Arg`, `yargs` |
| Fullstack | All of the above | Combine results |

### Step 3: Map User Journeys

For each entry point, trace the complete user journey:

1. **Entry** — How does the user arrive? (URL, command, tap, deep link)
2. **Action** — What does the user do? (fill form, click button, pass args)
3. **Expectation** — What should happen? (data appears, file created, response returned)
4. **Exit** — How does the journey end? (success message, redirect, output)

### Step 4: Classify Journey Priority

| Priority | Criteria | Example |
|----------|----------|---------|
| P0 — Critical | Core business function, blocking if broken | Login, checkout, main command |
| P1 — High | Important feature, workaround exists | Search, filtering, export |
| P2 — Medium | Enhancement, not blocking | Sorting, preferences, help text |
| P3 — Low | Edge case, cosmetic | Empty state, animation, tooltip |

### Step 5: Output Journey Inventory

Write the inventory in this format:

```markdown
## Journey Inventory

**Platform:** {detected_platform}
**Entry Points Found:** {count}
**Journeys Mapped:** {count}

### P0 — Critical
- [ ] J1: {Journey Name} — Entry: {entry_point} → Expected: {outcome}
- [ ] J2: ...

### P1 — High
- [ ] J3: ...

### P2 — Medium
- [ ] J4: ...
```

Save to `e2e-evidence/analysis.md`.

## Output

- `e2e-evidence/analysis.md` — Journey inventory with priorities
- Detected platform type (passed to subsequent workflows)
- Count of journeys per priority level

## Next Step

Feed the analysis output into `workflows/plan.md` to generate PASS criteria for each journey.
