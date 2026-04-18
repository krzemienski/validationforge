# Visual Content Spec — All Platforms

**Companion to:** `execution/social-calendar-unified.md` and every file in `copy/`.
**Purpose:** define exactly what visual asset each post needs, in what dimensions, in what style, and where to source it.
**Iron rule:** real terminal output > marketing screenshots. No stock photos. No AI-generated illustrations. No mockups. The visual is the evidence.

---

## Style Guide (applies everywhere)

| Lever | Rule |
|---|---|
| Source material | Real terminal output, real `e2e-evidence/` files, real Claude Code session captures. Not staged. |
| Color palette | Terminal greens (`#22c55e` PASS), reds (`#ef4444` FAIL), Claude orange `#cc785c` reserved for primary CTA accent only |
| Typography in overlays | Monospace (JetBrains Mono, Menlo, Fira Code). Never sans-serif marketing fonts overlaid on code |
| Backgrounds | Black/very-dark (`#0a0a0a`) for terminal screenshots. Off-white (`#fafafa`) for diagrams |
| Cursor | Visible in terminal screenshots. Implies "this is real, not a mockup" |
| Watermark | None. The repo URL belongs in the post text, not burned into the image |
| Stock imagery | Forbidden |
| AI-generated illustrations | Forbidden for this campaign (would undermine the "receipts > rhetoric" thesis) |
| Faces / headshots | Only the founder's actual headshot, only when the post is explicitly authored. Never stock person |

---

## Per-Platform Specifications

### LinkedIn

**Post hero image (every long-form post):**
- Dimensions: **1200 × 627 px** (1.91:1)
- Format: PNG or JPG, < 5 MB
- Content: full-bleed dark terminal screenshot with one PASS verdict line highlighted in green. NO text overlay. The terminal IS the image.
- Filename convention: `{post-slug}-hero.png`
- Why these dimensions: LinkedIn crops to 1.91:1 in the feed; anything taller gets clipped. 1200×627 is the safe maximum that fills the feed card without crop.

**Inline screenshots (mid-post):**
- Dimensions: **1200 × variable** (max 1200 wide, height as needed)
- Format: PNG (preserves crispness on monospaced text)
- Use case: when the post says "here is the actual verdict file," embed the verdict file. When it says "the e2e-evidence directory listing looks like this," embed the `tree e2e-evidence/` output as a real screenshot
- Quantity per post: 2-4 max. More than that, the post becomes a gallery and engagement drops

**Carousel (skip for this campaign):**
- LinkedIn carousels (10-page PDFs in 1080×1080) get 3× the impressions of text posts in some niches. Skip them here. The dev/eng leadership audience reads long-form text and finds carousels childish

**Native video:**
- Dimensions: **1080 × 1080 px (square)** OR **1080 × 1920 (vertical)** depending on intent
- Length: 60-90 seconds for hero posts; 15-30 seconds for daily nudges
- Caption: required, burned in (LinkedIn auto-plays muted)
- Use case: ONE founder talking-head per launch (Day 12 hero post). Don't over-do video — your text is doing the work
- Bitrate: 8 Mbps minimum so the terminal text in screen-recordings stays crisp

**Thumbnail for video:**
- Same dimensions as video. Single-frame still showing terminal output mid-PASS-verdict, NOT founder face
- Why not the founder face: the audience converts on the artifact, not on the personality. Save face shots for posts where the personal-brand authority IS the message

---

### X / Twitter

**Single-image post:**
- Dimensions: **1600 × 900 px** (16:9). X crops to 16:9 in the timeline regardless of original aspect; build to that ratio
- Format: PNG for code/text content, JPG for photographs (none here)
- File size: < 5 MB
- Content rule: real terminal output, single moment of clarity (one PASS verdict, one error line, one diff hunk). No collages

**Image-quote (text on image, e.g., for the manifesto tweet):**
- Dimensions: **1600 × 900 px**
- Background: `#0a0a0a` solid OR a faint terminal screenshot backdrop with 70% darken layer
- Foreground: white text in JetBrains Mono, max 12 words, single statement
- Use sparingly: 1-2 image-quotes per week max. They are eye-catching but feel "designed" — counter to receipts ethos
- Example payloads:
  - `Compilation isn't validation.`
  - `PASS without citation isn't PASS.`
  - `Receipts > rhetoric.`

**GIFs (thread anchors):**
- Dimensions: **1200 × 675 px** (16:9)
- Length: **8-12 seconds**, 30 fps, looping
- File size: < 15 MB (X limit)
- Content: real `/validate` run captured live. Show the command, the spinner, the captured screenshots flying past, the final verdict. NO music. NO talking. NO text overlay
- Tools: `asciinema` for terminal capture → convert to GIF via `agg` or `gifski`. Or QuickTime → ScreenRecorder → ffmpeg downscale
- One GIF per launch tweet (T1 of the personal-brand thread, T1 of the project drumbeat thread)

**Native video (X video, NOT YouTube embed):**
- Dimensions: **1280 × 720 px** OR **1080 × 1920 vertical**
- Length: 30-60 seconds (X auto-plays first 30s muted; the hook has to land in 5)
- Caption: burned in
- Use case: rare. Only for the Show HN day amplification thread
- Storage limit: < 512 MB

---

### Hacker News

**Visual content:** ZERO. HN does not render images in posts. The Show HN body is text-only.

**The exception:** the linked repo's README must have the demo GIF embedded above the fold. That GIF carries the visual weight of the entire HN landing.

**README hero GIF spec:**
- Dimensions: **800 × 450 px** (16:9 — large enough to be readable in the README, small enough to load fast)
- Length: 10-15 seconds, looping
- Content: full `/validate` run from command to verdict. Same content as the X anchor GIF, slightly compressed
- File size: < 8 MB (GitHub renders inline up to ~10 MB cleanly)
- Filename: `demo/vf-demo.gif` (already exists per README; verify the file is the latest version)

---

### Reddit

**r/ClaudeAI, r/LocalLLaMA:** images allowed and expected. Lead with a GIF.

**r/programming:** stricter. Images are tolerated but the rule of thumb is "if the post needs an image to make the argument, the post is too thin." Lead with text. Embed at most one screenshot deep in the body for evidence.

**r/ClaudeAI specific:**
- Cover GIF: same as X anchor GIF (800 × 450)
- Optional inline: terminal screenshot of an interesting verdict (1200 × variable)

**r/LocalLLaMA specific:**
- Lead with the `e2e-evidence/` directory tree screenshot rather than a GIF — this audience cares about structure
- Filename: `evidence-tree.png`, 1200 × variable

**r/programming specific:**
- One inline image MAX, deep in the body, used to support a specific technical claim (e.g., the table of bug categories)
- Avoid: animated GIFs (read as flashy in this sub)

---

### Discord

**Anthropic Discord, OMC server, Superpowers, plugin-dev:**
- Embedded image: ONE per drop, the demo GIF
- Dimensions: same 800 × 450 GIF used everywhere
- File size: discord allows up to 25 MB free, 50 MB with Nitro — keep under 8 MB to be safe across servers
- Custom emoji: don't add. Custom emoji on someone else's server reads as taking liberties

---

### Personal Blog (Canonical)

- Hero image: same 1200 × 627 PNG used on LinkedIn (so LinkedIn's preview card matches the canonical)
- Inline screenshots: full-resolution PNG (no width cap; let the blog's CSS handle responsive sizing)
- Open Graph image: must be set explicitly, 1200 × 627, same as hero
- Twitter Card image: same hero, listed as `twitter:image` in `<head>`
- Favicon: terminal-style monospace V (use existing `ck-logo.png` if it works, else design an 'V' rendered in JetBrains Mono on transparent bg)

---

## Asset Production Checklist (Per Post)

For each post drafted in `copy/`, this is what to produce alongside it:

### `personal-brand-launch-post.md` (LinkedIn hero, Day 12)
- [ ] **Hero PNG** (1200×627): real terminal showing `Verdict: PASS — 6/6 journeys, 13/13 criteria, 0 fix attempts` in green, file path visible underneath
- [ ] **Inline screenshot 1** (1200×variable): the actual `e2e-evidence/self-validation/journey-3/step-04-curl-response.json` content, syntax-highlighted
- [ ] **Inline screenshot 2** (1200×variable): the `tree e2e-evidence/self-validation/` output showing the directory structure
- [ ] **Inline screenshot 3** (1200×variable): a 5-row table of the 5 bug categories rendered as terminal output (NOT as a designed graphic)
- [ ] **Founder headshot** (400×400 circular, your existing LinkedIn photo): goes inline once, near the consulting CTA section
- [ ] **OG image** for the personal blog version: same as Hero PNG

### `linkedin-blog-series.md → Part 1` (Day 5)
- [ ] **Hero PNG** (1200×627): terminal showing one of the 5 bug-category headers (e.g., "Pattern 1: API field rename — mock returned old field; real returned new")
- [ ] **Inline screenshot**: the actual diff of a renamed API field that broke a frontend (anonymized)

### `linkedin-blog-series.md → Part 2` (Day 8)
- [ ] **Hero PNG** (1200×627): real metrics from the launch (X impressions, Reddit upvotes, GitHub stars). Use a real screenshot from your X analytics or GitHub insights. NOT a designed dashboard
- [ ] **Inline screenshot**: a real DM you got during launch (with sender info redacted), if you have one worth quoting

### `linkedin-blog-series.md → Part 3` (Day 13)
- [ ] **Hero PNG** (1200×627): final scoreboard (the table from the post) rendered as terminal output
- [ ] **Inline screenshot**: GitHub Insights → Traffic chart for the 14-day window
- [ ] **Optional video** (60-90s): founder talking head with terminal screenshare overlay, walking through one specific bug VF caught during launch

### `x-thread-launch-hero.md` (5-tweet thread, Day 12 evening)
- [ ] **T1 attachment**: the demo GIF (800×450, 10-15s loop)
- [ ] **T2 attachment**: image-quote with text "Five patterns. Mocks drift from reality." over a faint terminal backdrop (1600×900)
- [ ] **T3 attachment**: terminal screenshot of `vf-setup` running and `/validate` completing (1600×900)
- [ ] **T4 attachment**: image-quote with text "Compilation is necessary. It is not sufficient." (1600×900)
- [ ] **T5 attachment**: NO image. The CTA tweet should be text-only so the link preview to the repo dominates the visual

### `x-threads.md → D3 big thread` (Day 3)
- [ ] **T1 attachment**: demo GIF (same as personal-brand thread, reuse)
- [ ] Each numbered bug-pattern tweet (T2-T6): static terminal screenshot of that specific bug pattern in action — different image per tweet
- [ ] **T7 (the build moment)**: terminal screenshot of `block-test-files.js` hook output denying a Write tool call
- [ ] **T8 (CTA)**: no image, link preview only

### `reddit-posts.md → r/ClaudeAI` (Day 4)
- [ ] **Cover GIF**: the demo GIF (800×450)
- [ ] **Inline image (optional)**: 5-row bug pattern table as terminal screenshot

### `discord-announcements.md` (Day 3)
- [ ] **Embedded GIF**: the demo GIF (800×450)
- [ ] No additional images per server

### `show-hn-drafts.md` (Day 11)
- [ ] **No images on HN itself.** The README's hero GIF carries the weight
- [ ] Verify `demo/vf-demo.gif` in repo is the latest 10-15s loop before posting

---

## Production Workflow

### For terminal screenshots
1. Open Terminal (or iTerm2) at 14pt JetBrains Mono / 14pt Menlo
2. Set background `#0a0a0a`, foreground `#e5e5e5`
3. Resize window to ~120 columns wide (matches both LinkedIn 1200px and X 1600px when scaled)
4. Run the actual command
5. macOS: `Cmd+Shift+4`, drag to select window, save to `creatives/screenshots/`
6. Filename: `{post-slug}-{description}.png` (kebab-case)

### For terminal GIFs
1. Use **asciinema** to record terminal session: `asciinema rec demo.cast`
2. Convert with **agg**: `agg --theme one-dark --font-family "JetBrains Mono" --speed 1.2 demo.cast demo.gif`
3. OR record with QuickTime → export → convert with ffmpeg:
   ```
   ffmpeg -i screen.mov -vf "fps=20,scale=800:-1:flags=lanczos" -c:v gif demo.gif
   ```
4. Optimize with **gifski** for size: `gifski -o demo.gif --quality 80 frames/*.png`
5. Target: 8 MB or less

### For image-quotes (text on image)
1. Open Figma or Sketch (NOT a designed marketing tool — keep it simple)
2. Canvas: 1600 × 900 px
3. Background: `#0a0a0a` solid OR faint terminal backdrop (40% opacity)
4. Text: JetBrains Mono Bold 96pt, white `#fafafa`, centered
5. Max 12 words. Less is more. "Compilation isn't validation" beats "Why compilation is necessary but not sufficient"
6. Export as PNG

### For video screencasts
1. Record actual `/validate` run via QuickTime → New Screen Recording
2. Edit in Final Cut, Premiere, or DaVinci Resolve free
3. Add captions (LinkedIn auto-plays muted)
4. NO music. NO logo intro. NO transitions. Cut hard between sections
5. Export H.264 MP4, 8 Mbps, 1080p

---

## Asset Storage Convention

```
assets/campaigns/260418-validationforge-launch/creatives/
├── screenshots/
│   ├── personal-brand-launch-hero.png
│   ├── personal-brand-launch-evidence-curl.png
│   ├── personal-brand-launch-evidence-tree.png
│   ├── linkedin-part-1-hero.png
│   ├── linkedin-part-2-hero.png
│   ├── linkedin-part-3-hero.png
│   ├── x-d3-pattern-1-api-rename.png
│   ├── x-d3-pattern-2-jwt-expiry.png
│   ├── ... (one per pattern tweet)
├── gifs/
│   ├── vf-demo-hero.gif (the canonical demo, 800×450, 10-15s)
│   ├── vf-validate-pass.gif (focused on the verdict moment, 600×400, 5s)
├── image-quotes/
│   ├── compilation-isnt-validation.png
│   ├── pass-without-citation.png
│   ├── receipts-over-rhetoric.png
├── video/
│   ├── linkedin-part-3-talkinghead-90s.mp4
│   └── og-thumbnail-talkinghead.png
└── og-images/
    ├── personal-brand-launch.png (same as hero, 1200×627)
    ├── linkedin-part-1.png
    └── ... (one per long-form post)
```

---

## What I Have NOT Specified (and why)

- **Brand identity / logo design.** ValidationForge already has a brand context (terminal-native, "receipts > rhetoric"). Designing a new logo specifically for this launch would distract from the receipt-driven messaging. The repo can use the text wordmark `ValidationForge` in JetBrains Mono and call it done.
- **Marketing-style infographics.** Designed infographics signal "marketing budget." The whole campaign is anti-marketing-budget. Skip.
- **Stock photography.** Forbidden by style guide.
- **AI-generated illustrations.** Forbidden — would undermine the thesis.
- **Founder headshot for every post.** The face appears once per long-form post (near the CTA), and in the personal blog's About page. Otherwise the artifact is the visual.

---

## Production Priority (what to make first)

If you only have time to produce three visual assets before launch Day 1, make these:

1. **`vf-demo-hero.gif`** (800×450, 10-15s) — used everywhere: README, X threads, Reddit, Discord
2. **`personal-brand-launch-hero.png`** (1200×627) — used for the LinkedIn hero post + personal blog OG
3. **`compilation-isnt-validation.png`** image-quote (1600×900) — used for X T4 + can be reused as a Reddit thumbnail

Everything else can be produced rolling as posts go live. Daily X receipts can be produced same-day in 5 minutes each (run command, screenshot, post).

---

## Open Items

1. Decide if you want me to write a **shell script** (`creatives/scripts/capture-terminal.sh`) that auto-takes the standard terminal screenshot at the right dimensions with the right theme, so production doesn't depend on remembering settings every time.
2. Confirm whether the founder headshot you want to use is the one currently on your LinkedIn, or if a fresh one should be shot. Affects when the personal-brand assets can be finalized.
3. The Day 11 Show HN day has NO image requirements (HN strips them). Confirm you don't want me to over-engineer that.
4. Whether to produce a 60-second talking-head video for LinkedIn Part 3 (end of week 2) or skip and stay text-only. Text-only is the safer bet; video is higher-ceiling.
