---
title: "21 AI-Generated Screens, Zero Figma Files"
channel: LinkedIn (long-form)
companion_blog_post: 10 of 18
companion_repo: github.com/krzemienski/stitch-design-to-code
target_word_count: 1600-2000
visual_assets_required: see "Posting Protocol" at bottom
voice_notes: Direct, technical, slightly contrarian. No emojis. Lead with the bug, then the system. Soft consulting CTA at the end.
---

# 21 AI-Generated Screens, Zero Figma Files

Screen 22 is where I noticed it. The header said "Awesome Video Dashboard." My prompt said "Awesome Lists." Eight screens were already wrong. The AI had been drifting for an hour and I hadn't caught it.

That branding bug is the most useful thing that happened to me in the six weeks I spent shipping a Figma-less design pipeline.

## What I was actually doing

I was building three products in parallel — an iOS app, a web dashboard, and the blog series site you'll see linked at the bottom — across roughly 23,479 Claude Code sessions in 42 days. That pace doesn't allow for a designer in the loop. Hiring one would have taken longer than building the products. Learning Figma well enough to produce production-grade comps myself? Not a defensible use of the time.

So I tried something different. I described screens in plain English, fed those descriptions into Google's Stitch MCP, and got rendered HTML back. Not wireframes. Not low-fidelity sketches. Real components with real colors and real typography. The handoff that usually eats two weeks of designer-developer ping-pong collapsed into a single conversion step.

The numbers from that experiment, across all three projects:

- 269 `generate_screen_from_text` calls
- 87 `list_screens` calls
- 20 `generate_variants` explorations
- 21 unique production screens shipped (multiple iteration rounds per screen)
- 0 Figma files opened
- 0 lines of CSS written by hand

I want to walk through how the pipeline works, where it breaks, and what the branding bug taught me about treating prompts as build artifacts rather than instructions.

## The Stitch loop

Three phases, tight cycle: prompt, generate, validate. A single screen goes from English description to a rendered React component in under fifteen minutes.

Every prompt follows the same four-part structure. Device type. Design system tokens, verbatim. Component primitives. Screen description with explicit layout details. That word "verbatim" is doing more work than it looks like it should.

Verbatim does not mean "use the same colors as before." It does not mean "see previous specs." It means the entire token set — every hex value, every spacing number, every typography spec — pasted into every single generation call. I learned this the hard way at screen 15.

## The branding bug that changed everything

By the fifteenth `generate_screen_from_text` call, Stitch started producing "Awesome Video Dashboard" instead of "Awesome Lists." The prompt clearly said "Awesome Lists." The generated screen said "Awesome Video Dashboard." Eight screens shipped with the wrong product name before I caught it on a visual review of screen 22.

Why did this happen? Each Stitch MCP call is stateless. The model has no memory of previous calls. By call 15, my prompt's design system description was competing with the model's training data about what "awesome" dashboards typically look like. "Awesome Video Dashboard" is a more common pattern in the model's training set than "Awesome Lists." So the model defaulted to what felt familiar. The branding I had assumed was being maintained was being silently overwritten.

The fix to the immediate damage was three lines of bash:

> `grep -r "Awesome Video" generated-screens/ | cut -d: -f1 | sort -u`

That found all eight contaminated screens in under a second. The deeper fix was a workflow rule I now treat as non-negotiable: the full design system, including the exact product name, goes in every prompt, every time. Not "see previous specs." Not "continue the design from screen 14." The entire token set, the exact product name, the component primitives — pasted into every generation call.

Here's the part I want to be honest about. This wasn't a Stitch defect. It was my fault. I had assumed the AI would maintain context across calls the way a human collaborator would. It can't. It won't. And the moment you stop expecting it to, you start designing systems that don't depend on it.

## The token file is the design

47 tokens across 7 categories. 18 colors including glows and subtle variants. 8 typography sizes. 5 font weights. 5 line heights. 15 spacing values. 8 border radii — all set to `0px`, more on that in a second. 8 shadow definitions. The token file is the single source of truth. Every other artifact in the pipeline (Tailwind utilities, React component styles, Stitch prompts) is generated from it.

About the border radii. Every single one is zero. None. Zip. This is the most distinctive design decision in the system and it serves a specific engineering purpose: it's an instant visual litmus test. If any component renders with rounded corners, the token pipeline is broken. You can spot the failure from across the room without zooming in.

The `tailwind-preset.js` file reads `tokens.json` and maps every value to a Tailwind utility. A developer writes `bg-background text-primary font-mono` and gets the exact design system colors without ever typing a hex code. Change `#e050b0` to `#00ff88` in `tokens.json` and every component switches from hot pink to neon green. One file change, 21 screens updated, zero manual edits.

Here's the experiment that proved the pipeline actually works. I swapped the primary color across the entire token file. 21 screens turned pink. But two components had hardcoded hex values that didn't change. The swap exposed token leaks — places where an agent had typed a color directly instead of referencing the token. I fixed those two references and ran a grep to confirm there were no other hardcoded colors hiding anywhere in the codebase. Any match outside the config files is a leak. Zero matches means the pipeline is clean.

## Prompt engineering for visual AI

Writing prompts for Stitch is nothing like writing prompts for text generation. Conversational tone produces garbage. Exact hex values produce consistency.

Four lessons from 269 generation calls.

**Describe, don't request.** "Make a login page" produces something generic. Describing a centered card with a max-width, a specific surface color, a 1px border, an email input, a password input with show/hide, and a CTA in the exact accent color produces something that matches the system on the first try.

**Hex values are non-negotiable.** "Dark gray" means different things to different models. `#111111` means exactly one thing.

**Specify interactive states or the AI will invent them.** And the ones it invents won't match. Hover, focus, loading, error — every state with exact style changes.

**Session length kills quality.** 21 screens in one session caused the later ones to degrade. Sweet spot: 5 to 7 screens per session, then a fresh start.

## Validation: proving tokens actually propagated

A screenshot proves the UI rendered. It does not prove the right colors were applied, the right fonts loaded, or the right spacing was used. That's why the validation suite runs 107 actions across all 21 screens, and why the important ones are programmatic.

The check that matters isn't "looks like the right gray." The check that matters is computationally verified to be exactly `rgb(17, 17, 17)` — the surface token from the file. Render checks, element presence, interaction checks, screenshot captures. The Admin Dashboard alone accounts for 25 of the 107 checks because the more complex the screen, the more the AI-to-code conversion introduces subtle errors.

The iron rule: if a value lives anywhere other than the token file, it doesn't get to ship.

## Prompts as build artifacts

Here's what's weird about this whole workflow. The single-source constraint that makes Figma-to-code handoffs tedious is exactly what makes AI-to-code handoffs reliable. A human designer holds the design system in their head, notices when a component deviates, fixes it intuitively. An AI cannot do any of that. It needs the exact tokens in the exact prompt on every call. The constraint that frustrated designers for a decade is the constraint that makes generative design pipelines work.

That realization shifted how I think about prompts. They aren't instructions. They're build artifacts. When the tokens change, the prompt changes. When the prompt changes, the next generation call produces screens that reflect the new tokens. The prompt is part of the build pipeline, no different from a Tailwind config or a webpack rule. The moment I started version-controlling the design system block, reviewing changes to it, and testing that changes propagated correctly — the consistency problems vanished.

This is also the period that produced ValidationForge, the open-source verification framework I shipped a few weeks before this post. Same underlying principle. AI-generated artifacts need machine-verifiable evidence that they actually match the spec, not the AI's confident assertion that they do. Token leaks in a design pipeline are the same class of bug as mock drift in a test suite. Both look fine until you check.

## What I'd do differently

Three things, briefly. I'd start with W3C Design Token Community Group format from day one — my custom JSON works, but every design tool that supports token import expects DTCG, and converting later costs more than starting right. I'd build the branding check into the prompt builder from the start, with `tokens.brand.name` interpolated automatically into every prompt rather than relying on my memory. And I'd validate font loading explicitly — JetBrains Mono doesn't load in headless Puppeteer by default, and my suite missed font rendering issues until I switched to non-headless mode.

## The receipts

The companion repo at **github.com/krzemienski/stitch-design-to-code** contains the full workflow. The 47-token source-of-truth file. The token-to-Tailwind preset. Structured prompt templates for all 21 screens. The five base shadcn/ui primitives with CVA variants. The 107-action Puppeteer validation suite. The branding bug case study and prevention doc.

Clone it, swap in your own design tokens, and run `generate_screen_from_text` against your own design system. Everything is designed to be forked and adapted.

Is the workflow flawless? No. The branding bug cost me an hour of rework. Font loading in headless browsers is still annoying. The A/B/C variation strategy produces more output than you actually need. But compared to the traditional two-week Figma-to-developer handoff cycle, describing screens in English and getting rendered components back in minutes is a fundamentally different speed. The flaws are worth fixing because the alternative is slower by an order of magnitude.

Design tools aren't going away. The handoff is. The gap between "what it should look like" and "what the code produces" used to be filled by screenshots, Zeplin exports, and meetings. Now it's a JSON file and a structured prompt. The token file is the design. The prompt is the spec. The validation suite is the acceptance test. Everything else is generated.

---

If you're a design or engineering leader trying to figure out how AI-generated UI fits into a real product workflow — particularly the verification side, where things quietly drift unless you build a gate — I'm taking on a small number of advisory engagements this quarter. The fastest way to reach me is a LinkedIn DM with a one-paragraph note on where you are now and where you'd like to be in 90 days.

The blog post this is adapted from is post 10 of 18 in a series on agentic development at scale. Repo and full post linked below.

---

*Nick Krzemienski — building ValidationForge. Six weeks, 23,479 sessions, 3.4M lines of AI code, and a stubborn opinion that AI-generated artifacts should ship with receipts. github.com/krzemienski/stitch-design-to-code*

---

## Visual Assets To Attach (do not design new ones)

Use existing screenshots from `~/Desktop/blog-series/posts/post-10-stitch-design-to-code/assets/`:

1. `stitch-hero.png` — primary feature image at top
2. `post10-stitch-workflow.svg` — pair with "Stitch loop" section
3. `post10-token-hierarchy.svg` — pair with "token file is the design"
4. `post10-generation-pipeline.svg` — pair with "prompts as build artifacts"
5. `post10-validation-loop.svg` — pair with "validation"
6. `linkedin-card.html` (or rendered PNG export) — closing card

If LinkedIn caps native attachments below 6, drop `post10-validation-loop.svg` first.
