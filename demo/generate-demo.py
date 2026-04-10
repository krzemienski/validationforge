#!/usr/bin/env python3
"""
ValidationForge Demo GIF Generator

Generates a terminal-style animated GIF demonstrating the VF validation pipeline:
  - Platform detection
  - Hook firing (blocking test file)
  - Evidence capture (API + browser)
  - PASS verdict with cited proof

Output: demo/vf-demo.gif
Resolution: 900x540 (16:9)
Theme: Tokyo Night dark
"""

import os
import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

# ---------------------------------------------------------------------------
# Color palette — Tokyo Night dark
# ---------------------------------------------------------------------------
BG         = "#1a1b26"
PROMPT     = "#7aa2f7"   # blue
CMD        = "#c0caf5"   # white
SUCCESS    = "#9ece6a"   # green
ERROR      = "#f7768e"   # red
WARNING    = "#e0af68"   # yellow
INFO       = "#73daca"   # cyan
DIM        = "#565f89"   # gray
TITLE_FG   = "#bb9af7"   # purple/lavender for title
BORDER     = "#24283b"   # slightly lighter bg for header bar

# ---------------------------------------------------------------------------
# Dimensions & layout
# ---------------------------------------------------------------------------
WIDTH      = 900
HEIGHT     = 540
PADDING    = 28
LINE_H     = 22
HEADER_H   = 36

# ---------------------------------------------------------------------------
# Font loading
# ---------------------------------------------------------------------------
FONT_PATHS = [
    "/System/Library/Fonts/Supplemental/Courier New.ttf",
    "/System/Library/Fonts/Courier New.ttf",
    "/Library/Fonts/Courier New.ttf",
    "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf",
    "/usr/share/fonts/truetype/liberation/LiberationMono-Regular.ttf",
]


def load_font(size: int) -> ImageFont.FreeTypeFont:
    for path in FONT_PATHS:
        if os.path.exists(path):
            return ImageFont.truetype(path, size)
    return ImageFont.load_default(size=size)


FONT_NORMAL = load_font(15)
FONT_BOLD   = load_font(16)
FONT_SMALL  = load_font(13)
FONT_LARGE  = load_font(22)
FONT_TITLE  = load_font(32)

# ---------------------------------------------------------------------------
# Frame timing (GIF delay is in centiseconds, 1/100s)
# ---------------------------------------------------------------------------
DELAY_TITLE    = 300   # 3000ms
DELAY_READING  = 200   # 2000ms
DELAY_FAST     = 30    # 300ms
DELAY_HOOK     = 250   # 2500ms
DELAY_VERDICT  = 400   # 4000ms
DELAY_END      = 400   # 4000ms

# ---------------------------------------------------------------------------
# Low-level drawing helpers
# ---------------------------------------------------------------------------

def hex_to_rgb(hex_color: str):
    h = hex_color.lstrip("#")
    return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))


def new_frame() -> tuple[Image.Image, ImageDraw.ImageDraw]:
    img = Image.new("RGB", (WIDTH, HEIGHT), hex_to_rgb(BG))
    draw = ImageDraw.Draw(img)
    return img, draw


def draw_header(draw: ImageDraw.ImageDraw, title: str = "ValidationForge"):
    """Draw the terminal window chrome — colored top bar."""
    # Header bar background
    draw.rectangle([(0, 0), (WIDTH, HEADER_H)], fill=hex_to_rgb(BORDER))
    # Traffic-light circles
    for i, color in enumerate(["#f7768e", "#e0af68", "#9ece6a"]):
        cx = 18 + i * 22
        cy = HEADER_H // 2
        draw.ellipse([(cx-6, cy-6), (cx+6, cy+6)], fill=hex_to_rgb(color))
    # Title text centered
    bbox = draw.textbbox((0, 0), title, font=FONT_SMALL)
    tw = bbox[2] - bbox[0]
    tx = (WIDTH - tw) // 2
    draw.text((tx, 10), title, fill=hex_to_rgb(DIM), font=FONT_SMALL)


def draw_text_line(draw: ImageDraw.ImageDraw, y: int, text: str,
                   color: str = CMD, font=None, x: int = PADDING) -> int:
    """Draw a single line of text; return y position of next line."""
    if font is None:
        font = FONT_NORMAL
    draw.text((x, y), text, fill=hex_to_rgb(color), font=font)
    return y + LINE_H


def draw_multiline(draw: ImageDraw.ImageDraw, y: int,
                   lines: list[tuple[str, str]], font=None) -> int:
    """Draw multiple (text, color) tuples, one per line. Returns final y."""
    for text, color in lines:
        y = draw_text_line(draw, y, text, color=color, font=font)
    return y


def draw_box(draw: ImageDraw.ImageDraw, x1: int, y1: int, x2: int, y2: int,
             color: str = DIM):
    draw.rectangle([(x1, y1), (x2, y2)], outline=hex_to_rgb(color), width=1)


def to_palette(img: Image.Image, colors: int = 128) -> Image.Image:
    """Convert RGB image to palette mode for smaller GIF size."""
    return img.convert("P", palette=Image.ADAPTIVE, colors=colors)


# ---------------------------------------------------------------------------
# Individual frame builders
# ---------------------------------------------------------------------------

def frame_title_1() -> tuple[Image.Image, int]:
    """Frame 1: Title splash."""
    img, draw = new_frame()
    draw_header(draw, "ValidationForge  —  demo")

    cy = HEIGHT // 2 - 60

    # Logo-style ASCII top line
    logo = "  ✦  ValidationForge  ✦  "
    bbox = draw.textbbox((0, 0), logo, font=FONT_TITLE)
    tw = bbox[2] - bbox[0]
    draw.text(((WIDTH - tw) // 2, cy), logo, fill=hex_to_rgb(TITLE_FG), font=FONT_TITLE)

    tagline = "Ship verified code, not compiled code."
    bbox2 = draw.textbbox((0, 0), tagline, font=FONT_BOLD)
    tw2 = bbox2[2] - bbox2[0]
    draw.text(((WIDTH - tw2) // 2, cy + 50), tagline, fill=hex_to_rgb(CMD), font=FONT_BOLD)

    sub = "No-mock validation platform for Claude Code"
    bbox3 = draw.textbbox((0, 0), sub, font=FONT_SMALL)
    tw3 = bbox3[2] - bbox3[0]
    draw.text(((WIDTH - tw3) // 2, cy + 80), sub, fill=hex_to_rgb(DIM), font=FONT_SMALL)

    return img, DELAY_TITLE


def frame_title_2() -> tuple[Image.Image, int]:
    """Frame 2: Scenario intro."""
    img, draw = new_frame()
    draw_header(draw, "ValidationForge  —  demo")

    y = HEADER_H + PADDING
    y = draw_text_line(draw, y, "# The scenario", color=PROMPT, font=FONT_BOLD)
    y += 8

    lines = [
        ("A developer renames an API response field:", DIM),
        ("", DIM),
        ("  { users: [...] }  →  { data: [...] }", WARNING),
        ("", DIM),
        ("Unit tests:  4/4 passing ✓   (mocks not updated)", SUCCESS),
        ("Production:  💥 TypeError: Cannot read property 'length'", ERROR),
        ("             of undefined", ERROR),
        ("", DIM),
        ("Let's see what ValidationForge catches...", INFO),
    ]
    draw_multiline(draw, y, lines)

    return img, DELAY_READING


def frame_validate_invoke() -> tuple[Image.Image, int]:
    """Frame 3: Developer runs /validate."""
    img, draw = new_frame()
    draw_header(draw, "next-dashboard  —  zsh")

    y = HEADER_H + PADDING
    y = draw_text_line(draw, y, "~/next-dashboard", color=DIM)
    y = draw_text_line(draw, y, "❯ /validate", color=PROMPT, font=FONT_BOLD)
    y += 6
    y = draw_text_line(draw, y, "Starting ValidationForge pipeline...", color=INFO)

    return img, DELAY_FAST


def frame_platform_detect() -> tuple[Image.Image, int]:
    """Frame 4: Platform detection."""
    img, draw = new_frame()
    draw_header(draw, "next-dashboard  —  ValidationForge")

    y = HEADER_H + PADDING
    y = draw_text_line(draw, y, "❯ /validate", color=PROMPT)
    y += 4
    y = draw_text_line(draw, y, "[ PHASE 0 ] RESEARCH + PLATFORM DETECTION", color=WARNING, font=FONT_BOLD)
    y += 6

    lines = [
        ("  Scanning project structure...", DIM),
        ("  ✓ Found: package.json", SUCCESS),
        ("  ✓ Found: next.config.ts", SUCCESS),
        ("  ✓ Found: app/ directory (App Router)", SUCCESS),
        ("  ✓ Found: tailwind.config.ts", SUCCESS),
        ("", DIM),
        ("  Platform detected: Web — Next.js 15 + React 19", INFO),
        ("  Skills activated: playwright-validation, web-validation,", INFO),
        ("                    api-validation, fullstack-validation", INFO),
    ]
    draw_multiline(draw, y, lines)

    return img, DELAY_READING


def frame_platform_result() -> tuple[Image.Image, int]:
    """Frame 5: Platform detection result."""
    img, draw = new_frame()
    draw_header(draw, "next-dashboard  —  ValidationForge")

    y = HEADER_H + PADDING
    y = draw_text_line(draw, y, "[ PHASE 1 ] PLAN", color=WARNING, font=FONT_BOLD)
    y += 6

    lines = [
        ("  Journeys to validate:", DIM),
        ("    J1  GET /api/users      → returns user array", CMD),
        ("    J2  /dashboard          → renders user list", CMD),
        ("    J3  /dashboard          → handles API contract change", CMD),
        ("", DIM),
        ("  PASS criteria:", DIM),
        ("    • API returns 200 with user array in response body", CMD),
        ("    • Dashboard renders 'Users (N)' heading", CMD),
        ("    • Dashboard shows user cards, no console errors", CMD),
        ("", DIM),
        ("  Evidence required: screenshots + API response JSON", DIM),
    ]
    draw_multiline(draw, y, lines)

    return img, DELAY_READING


def frame_preflight_start() -> tuple[Image.Image, int]:
    """Frame 6: Preflight start."""
    img, draw = new_frame()
    draw_header(draw, "next-dashboard  —  ValidationForge")

    y = HEADER_H + PADDING
    y = draw_text_line(draw, y, "[ PHASE 2 ] PREFLIGHT", color=WARNING, font=FONT_BOLD)
    y += 6

    lines = [
        ("  Checking prerequisites...", DIM),
        ("", DIM),
        ("  ✓ Dev server running at http://localhost:3000 (200 OK)", SUCCESS),
        ("  ✓ Database seeded  (5 users)", SUCCESS),
        ("  ✓ Browser automation available (Playwright)", SUCCESS),
    ]
    draw_multiline(draw, y, lines)

    return img, DELAY_FAST


def frame_preflight_evidence() -> tuple[Image.Image, int]:
    """Frame 7: Preflight — evidence dir created."""
    img, draw = new_frame()
    draw_header(draw, "next-dashboard  —  ValidationForge")

    y = HEADER_H + PADDING
    y = draw_text_line(draw, y, "[ PHASE 2 ] PREFLIGHT", color=WARNING, font=FONT_BOLD)
    y += 6

    lines = [
        ("  ✓ Dev server running at http://localhost:3000 (200 OK)", SUCCESS),
        ("  ✓ Database seeded  (5 users)", SUCCESS),
        ("  ✓ Browser automation available (Playwright)", SUCCESS),
        ("  ✓ Evidence directory created: e2e-evidence/", SUCCESS),
        ("", DIM),
        ("  Preflight: ALL SYSTEMS GO", INFO),
        ("", DIM),
        ("  Proceeding to execution...", DIM),
    ]
    draw_multiline(draw, y, lines)

    return img, DELAY_READING


def frame_hook_attempt() -> tuple[Image.Image, int]:
    """Frame 8: Hook — attempt to create test file."""
    img, draw = new_frame()
    draw_header(draw, "next-dashboard  —  ValidationForge")

    y = HEADER_H + PADDING
    y = draw_text_line(draw, y, "[ HOOK SYSTEM ]  block-test-files", color=WARNING, font=FONT_BOLD)
    y += 6

    lines = [
        ("  Agent action detected:", DIM),
        ("  Write → app/api/__tests__/auth.test.ts", ERROR),
        ("", DIM),
        ("  Evaluating hook: block-test-files...", DIM),
    ]
    draw_multiline(draw, y, lines)

    return img, DELAY_FAST


def frame_hook_blocked() -> tuple[Image.Image, int]:
    """Frame 9: Hook fires — BLOCKED."""
    img, draw = new_frame()
    draw_header(draw, "next-dashboard  —  ValidationForge")

    y = HEADER_H + PADDING
    y = draw_text_line(draw, y, "[ HOOK SYSTEM ]  block-test-files", color=WARNING, font=FONT_BOLD)
    y += 6

    lines = [
        ("  Agent action detected:", DIM),
        ("  Write → app/api/__tests__/auth.test.ts", ERROR),
        ("", DIM),
        ("  Evaluating hook: block-test-files...", DIM),
        ("", DIM),
    ]
    y = draw_multiline(draw, y, lines)

    # Big BLOCKED banner
    draw_box(draw, PADDING, y, WIDTH - PADDING, y + 80, color=ERROR)
    y += 8
    blocked_text = "🚫  BLOCKED"
    bbox = draw.textbbox((0, 0), blocked_text, font=FONT_LARGE)
    tw = bbox[2] - bbox[0]
    draw.text(((WIDTH - tw) // 2, y + 6), blocked_text, fill=hex_to_rgb(ERROR), font=FONT_LARGE)
    y += 50

    y = draw_text_line(draw, y + 16, "  Reason: No test files, mocks, or stubs. Validate the", color=DIM)
    y = draw_text_line(draw, y, "          real system instead. [ValidationForge Rule #1]", color=DIM)

    return img, DELAY_HOOK


def frame_hook_rule() -> tuple[Image.Image, int]:
    """Frame 10: Iron rule reminder."""
    img, draw = new_frame()
    draw_header(draw, "next-dashboard  —  ValidationForge")

    y = HEADER_H + PADDING
    y = draw_text_line(draw, y, "[ IRON RULE #1 ]", color=ERROR, font=FONT_BOLD)
    y += 8

    rule_lines = [
        '  "Never create test files, mocks, stubs, or test doubles."',
        '  "Validate the real system — or fix the real system."',
    ]
    for line in rule_lines:
        y = draw_text_line(draw, y, line, color=WARNING, font=FONT_BOLD)

    y += 12
    lines = [
        ("  Why mocks lie:", DIM),
        ("    • Your Dashboard test mocked fetch() → { users: [...] }", CMD),
        ("    • Real API returns → { data: [...] }", CMD),
        ("    • Mock never saw the rename. Tests green. App broken.", ERROR),
        ("", DIM),
        ("  ValidationForge calls the real API. Always.", INFO),
    ]
    draw_multiline(draw, y, lines)

    return img, DELAY_READING


def frame_hook_resume() -> tuple[Image.Image, int]:
    """Frame 11: Resuming execution after hook."""
    img, draw = new_frame()
    draw_header(draw, "next-dashboard  —  ValidationForge")

    y = HEADER_H + PADDING
    y = draw_text_line(draw, y, "[ PHASE 3 ] EXECUTE", color=WARNING, font=FONT_BOLD)
    y += 6

    lines = [
        ("  Resuming validation plan...", DIM),
        ("", DIM),
        ("  Running: J1  GET /api/users", INFO),
    ]
    draw_multiline(draw, y, lines)

    return img, DELAY_FAST


def frame_api_curl() -> tuple[Image.Image, int]:
    """Frame 12: API curl command."""
    img, draw = new_frame()
    draw_header(draw, "next-dashboard  —  ValidationForge")

    y = HEADER_H + PADDING
    y = draw_text_line(draw, y, "[ J1 ]  API Validation", color=WARNING, font=FONT_BOLD)
    y += 6

    lines = [
        ("  $ curl -s http://localhost:3000/api/users \\", CMD),
        ("         | tee e2e-evidence/api-users/step-01-response.json", CMD),
        ("         | jq .", CMD),
        ("", DIM),
    ]
    draw_multiline(draw, y, lines, font=FONT_SMALL)

    return img, DELAY_FAST


def frame_api_response() -> tuple[Image.Image, int]:
    """Frame 13: API response shown."""
    img, draw = new_frame()
    draw_header(draw, "next-dashboard  —  ValidationForge")

    y = HEADER_H + PADDING
    y = draw_text_line(draw, y, "[ J1 ]  API Validation  — Response", color=WARNING, font=FONT_BOLD)
    y += 6

    lines = [
        ("  HTTP 200 OK", SUCCESS),
        ("  Content-Type: application/json", DIM),
        ("", DIM),
        ('  {', CMD),
        ('    "data": [', CMD),
        ('      { "id": 1, "name": "Alice", "email": "alice@example.com" },', CMD),
        ('      { "id": 2, "name": "Bob",   "email": "bob@example.com"   },', CMD),
        ('      { "id": 3, "name": "Carol", "email": "carol@example.com" },', CMD),
        ('      ...', DIM),
        ('    ]', CMD),
        ('  }', CMD),
        ("", DIM),
        ("  Evidence saved: e2e-evidence/api-users/step-01-response.json", SUCCESS),
    ]
    draw_multiline(draw, y, lines, font=FONT_SMALL)

    return img, DELAY_READING


def frame_api_verdict() -> tuple[Image.Image, int]:
    """Frame 14: API verdict."""
    img, draw = new_frame()
    draw_header(draw, "next-dashboard  —  ValidationForge")

    y = HEADER_H + PADDING
    y = draw_text_line(draw, y, "[ J1 ]  API Validation  — Verdict", color=WARNING, font=FONT_BOLD)
    y += 6

    lines = [
        ("  Observed: API returns { data: [...] }  (5 users)", CMD),
        ("  Status:   200 OK", CMD),
        ("  Evidence: e2e-evidence/api-users/step-01-response.json", DIM),
        ("", DIM),
        ("  Note: response key is 'data', not 'users'.", WARNING),
        ("        Checking if frontend reads the correct key...", WARNING),
        ("", DIM),
    ]
    y = draw_multiline(draw, y, lines)

    draw_box(draw, PADDING, y, WIDTH - PADDING, y + 30, color=SUCCESS)
    verdict = "  J1  GET /api/users    →   PASS"
    draw.text((PADDING + 10, y + 7), verdict, fill=hex_to_rgb(SUCCESS), font=FONT_BOLD)

    return img, DELAY_READING


def frame_browser_navigate() -> tuple[Image.Image, int]:
    """Frame 15: Playwright navigates to /dashboard."""
    img, draw = new_frame()
    draw_header(draw, "next-dashboard  —  ValidationForge")

    y = HEADER_H + PADDING
    y = draw_text_line(draw, y, "[ J2 ]  Browser Validation", color=WARNING, font=FONT_BOLD)
    y += 6

    lines = [
        ("  Running: J2  GET /dashboard  (browser)", INFO),
        ("", DIM),
        ("  Playwright: launching Chromium (headless)...", DIM),
        ("  Playwright: navigating to http://localhost:3000/dashboard", DIM),
        ("  Playwright: waiting for page load...", DIM),
    ]
    draw_multiline(draw, y, lines)

    return img, DELAY_FAST


def frame_browser_error() -> tuple[Image.Image, int]:
    """Frame 16: Dashboard crashes — TypeError in console."""
    img, draw = new_frame()
    draw_header(draw, "next-dashboard  —  ValidationForge")

    y = HEADER_H + PADDING
    y = draw_text_line(draw, y, "[ J2 ]  Browser Validation  — Console", color=WARNING, font=FONT_BOLD)
    y += 6

    lines = [
        ("  Page loaded. Capturing console output...", DIM),
        ("", DIM),
    ]
    y = draw_multiline(draw, y, lines)

    # Red error box
    draw_box(draw, PADDING, y, WIDTH - PADDING, y + 110, color=ERROR)
    inner_y = y + 10
    inner_y = draw_text_line(draw, inner_y, "  [console.error]  Unhandled Runtime Error", color=ERROR, font=FONT_BOLD, x=PADDING + 10)
    inner_y = draw_text_line(draw, inner_y, "  TypeError: Cannot read properties of", color=ERROR, x=PADDING + 10)
    inner_y = draw_text_line(draw, inner_y, "           undefined (reading 'length')", color=ERROR, x=PADDING + 10)
    inner_y = draw_text_line(draw, inner_y, "  at Dashboard  app/dashboard/page.tsx:6:32", color=DIM, x=PADDING + 10)
    y = inner_y + 12 + 10  # pad below box

    y += 10
    lines2 = [
        ("  Screenshot: e2e-evidence/web-dashboard/step-01-crash.png", DIM),
        ("  Observed:   Blank page with React error overlay", DIM),
    ]
    draw_multiline(draw, y, lines2)

    return img, DELAY_READING


def frame_browser_screenshot_sim() -> tuple[Image.Image, int]:
    """Frame 17: Simulated screenshot of the crashed dashboard."""
    img, draw = new_frame()
    draw_header(draw, "next-dashboard  —  ValidationForge")

    y = HEADER_H + PADDING
    y = draw_text_line(draw, y, "[ J2 ]  Evidence: step-01-crash.png", color=WARNING, font=FONT_BOLD)
    y += 6

    # Simulate browser window inside the terminal frame
    browser_top = y
    browser_h = 220
    browser_bg = (255, 255, 255)
    draw.rectangle([(PADDING, browser_top), (WIDTH - PADDING, browser_top + browser_h)], fill=browser_bg)

    # Browser address bar
    bar_y = browser_top + 6
    draw.rectangle([(PADDING + 4, bar_y), (WIDTH - PADDING - 4, bar_y + 20)], fill=(238, 238, 238))
    draw.text((PADDING + 12, bar_y + 2), "localhost:3000/dashboard", fill=(80, 80, 80), font=FONT_SMALL)

    # React error overlay
    overlay_top = browser_top + 32
    overlay_bg = (10, 10, 10)
    draw.rectangle([(PADDING, overlay_top), (WIDTH - PADDING, browser_top + browser_h)], fill=overlay_bg)

    ey = overlay_top + 12
    draw.text((PADDING + 16, ey), "Unhandled Runtime Error", fill=hex_to_rgb(ERROR), font=FONT_BOLD)
    ey += 22
    draw.text((PADDING + 16, ey), "TypeError: Cannot read properties of undefined (reading 'length')", fill=(200, 200, 200), font=FONT_SMALL)
    ey += 18
    draw.text((PADDING + 16, ey), "    at Dashboard  app/dashboard/page.tsx:6:32", fill=(120, 120, 120), font=FONT_SMALL)
    ey += 30
    draw.text((PADDING + 16, ey), "    5 │   const json = await res.json();", fill=(150, 150, 150), font=FONT_SMALL)
    ey += 18
    draw.text((PADDING + 14, ey), "> 6 │   const users = json.users;   // undefined!", fill=hex_to_rgb(ERROR), font=FONT_SMALL)
    ey += 18
    draw.text((PADDING + 16, ey), "    7 │   return (<div><h1>Users ({users.length})", fill=(150, 150, 150), font=FONT_SMALL)

    y = browser_top + browser_h + 12
    lines = [
        ("  ✗ Dashboard crashes on load. users is undefined.", ERROR),
    ]
    draw_multiline(draw, y, lines)

    return img, DELAY_READING


def frame_root_cause() -> tuple[Image.Image, int]:
    """Frame 18: Root cause analysis."""
    img, draw = new_frame()
    draw_header(draw, "next-dashboard  —  ValidationForge")

    y = HEADER_H + PADDING
    y = draw_text_line(draw, y, "[ PHASE 4 ] ANALYZE  — Root Cause", color=WARNING, font=FONT_BOLD)
    y += 8

    lines = [
        ("  Sequential analysis of J2 failure:", DIM),
        ("", DIM),
        ("  API returns:      { data: [...] }         ← key is 'data'", CMD),
        ("  Frontend reads:   json.users              ← reads 'users'", CMD),
        ("                    ─────────────────────", DIM),
        ("                    undefined               ← missing key!", ERROR),
        ("                    undefined.length        ← TypeError  💥", ERROR),
        ("", DIM),
        ("  Root cause: API renamed 'users' → 'data' (commit a3f9b2c)", WARNING),
        ("             Frontend still reads .users (not updated)", WARNING),
        ("", DIM),
        ("  Fix: app/dashboard/page.tsx line 6", INFO),
        ("       - const users = json.users;", ERROR),
        ("       + const users = json.data;", SUCCESS),
    ]
    draw_multiline(draw, y, lines)

    return img, DELAY_READING


def frame_fix_applied() -> tuple[Image.Image, int]:
    """Frame 19: Fix applied, re-validating."""
    img, draw = new_frame()
    draw_header(draw, "next-dashboard  —  ValidationForge")

    y = HEADER_H + PADDING
    y = draw_text_line(draw, y, "[ PHASE 4→3 ] FIX APPLIED  — Re-validating", color=WARNING, font=FONT_BOLD)
    y += 8

    lines = [
        ("  Applied fix: app/dashboard/page.tsx:6", SUCCESS),
        ("    - const users = json.users;", ERROR),
        ("    + const users = json.data;", SUCCESS),
        ("", DIM),
        ("  Re-running J2  /dashboard  (browser)...", INFO),
        ("", DIM),
        ("  Playwright: navigating to http://localhost:3000/dashboard", DIM),
        ("  Playwright: waiting for page load...", DIM),
        ("  Playwright: page loaded, no console errors ✓", SUCCESS),
        ("  Playwright: capturing screenshot...", DIM),
        ("  Screenshot: e2e-evidence/web-dashboard/step-02-fixed.png", SUCCESS),
    ]
    draw_multiline(draw, y, lines)

    return img, DELAY_READING


def frame_browser_fixed_screenshot() -> tuple[Image.Image, int]:
    """Frame 20: Simulated screenshot of fixed dashboard."""
    img, draw = new_frame()
    draw_header(draw, "next-dashboard  —  ValidationForge")

    y = HEADER_H + PADDING
    y = draw_text_line(draw, y, "[ J2 ]  Evidence: step-02-fixed.png", color=WARNING, font=FONT_BOLD)
    y += 6

    # Simulate browser window
    browser_top = y
    browser_h = 220
    browser_bg = (248, 250, 252)
    draw.rectangle([(PADDING, browser_top), (WIDTH - PADDING, browser_top + browser_h)], fill=browser_bg)

    # Address bar
    bar_y = browser_top + 6
    draw.rectangle([(PADDING + 4, bar_y), (WIDTH - PADDING - 4, bar_y + 20)], fill=(230, 230, 230))
    draw.text((PADDING + 12, bar_y + 2), "localhost:3000/dashboard", fill=(60, 60, 60), font=FONT_SMALL)

    # Dashboard content
    content_y = browser_top + 36
    draw.rectangle([(PADDING, content_y - 2), (WIDTH - PADDING, browser_top + browser_h)], fill=(255, 255, 255))

    # Nav bar
    draw.rectangle([(PADDING, content_y), (WIDTH - PADDING, content_y + 36)], fill=(15, 23, 42))
    draw.text((PADDING + 16, content_y + 10), "next-dashboard", fill=(255, 255, 255), font=FONT_BOLD)

    # Heading
    hy = content_y + 52
    draw.text((PADDING + 16, hy), "Users (5)", fill=(15, 23, 42), font=FONT_BOLD)

    # User cards row
    cy2 = hy + 30
    card_colors = [(241, 245, 249), (241, 245, 249), (241, 245, 249)]
    card_names = ["Alice", "Bob", "Carol", "Dave", "Eve"]
    for i, name in enumerate(card_names[:5]):
        cx = PADDING + 16 + i * 156
        if cx + 148 > WIDTH - PADDING:
            break
        draw.rectangle([(cx, cy2), (cx + 140, cy2 + 44)], fill=card_colors[0], outline=(203, 213, 225))
        draw.text((cx + 10, cy2 + 8), name, fill=(15, 23, 42), font=FONT_SMALL)
        draw.text((cx + 10, cy2 + 24), f"{name.lower()}@example.com", fill=(100, 116, 139), font=FONT_SMALL)

    y = browser_top + browser_h + 12
    y = draw_text_line(draw, y, "  ✓ Dashboard renders 'Users (5)' heading", color=SUCCESS)
    y = draw_text_line(draw, y, "  ✓ 5 user cards displayed, no errors", color=SUCCESS)

    return img, DELAY_READING


def frame_verdict() -> tuple[Image.Image, int]:
    """Frame 21: Final verdict."""
    img, draw = new_frame()
    draw_header(draw, "next-dashboard  —  ValidationForge")

    y = HEADER_H + PADDING
    y = draw_text_line(draw, y, "[ PHASE 5 ] VERDICT", color=WARNING, font=FONT_BOLD)
    y += 8

    lines = [
        ("  Journey results:", DIM),
        ("", DIM),
        ("  J1  GET /api/users         PASS  (200, data array present)", SUCCESS),
        ("  J2  /dashboard (initial)   FAIL  (TypeError: .users undef)", ERROR),
        ("  J2  /dashboard (post-fix)  PASS  (Users (5) rendered)", SUCCESS),
        ("  J3  Contract regression    PASS  (fix applied + verified)", SUCCESS),
        ("", DIM),
        ("  Evidence inventory:", DIM),
        ("    e2e-evidence/api-users/step-01-response.json", DIM),
        ("    e2e-evidence/web-dashboard/step-01-crash.png", DIM),
        ("    e2e-evidence/web-dashboard/step-02-fixed.png", DIM),
    ]
    draw_multiline(draw, y, lines)

    return img, DELAY_READING


def frame_verdict_pass() -> tuple[Image.Image, int]:
    """Frame 22: PASS banner."""
    img, draw = new_frame()
    draw_header(draw, "next-dashboard  —  ValidationForge  — PASS")

    y = HEADER_H + PADDING + 20

    # Big PASS banner
    banner_h = 100
    draw.rectangle([(PADDING, y), (WIDTH - PADDING, y + banner_h)], fill=hex_to_rgb("#1a2e1a"))
    draw_box(draw, PADDING, y, WIDTH - PADDING, y + banner_h, color=SUCCESS)

    pass_text = "✓  VALIDATION PASSED"
    bbox = draw.textbbox((0, 0), pass_text, font=FONT_LARGE)
    tw = bbox[2] - bbox[0]
    draw.text(((WIDTH - tw) // 2, y + 32), pass_text, fill=hex_to_rgb(SUCCESS), font=FONT_LARGE)

    y += banner_h + 20

    lines = [
        ("  3/3 journeys PASS  (1 FAIL caught, fixed, re-validated)", SUCCESS),
        ("  Bug found: API/frontend contract mismatch — json.users undef", WARNING),
        ("  Fix applied in: app/dashboard/page.tsx:6", CMD),
        ("  All evidence cited. Gate discipline maintained.", DIM),
        ("", DIM),
        ("  Unit tests saw: 4/4 PASS   ←  mocks don't lie, they hide", DIM),
        ("  ValidationForge saw: real crash → real fix → real PASS", INFO),
    ]
    draw_multiline(draw, y, lines)

    return img, DELAY_VERDICT


def frame_scorecard() -> tuple[Image.Image, int]:
    """Frame 23: Scorecard comparison."""
    img, draw = new_frame()
    draw_header(draw, "next-dashboard  —  ValidationForge")

    y = HEADER_H + PADDING
    y = draw_text_line(draw, y, "[ SCORECARD ]", color=WARNING, font=FONT_BOLD)
    y += 8

    # Table header
    col1, col2, col3 = PADDING + 4, 360, 620
    header_y = y
    draw.rectangle([(PADDING, header_y), (WIDTH - PADDING, header_y + 22)], fill=hex_to_rgb(BORDER))
    draw.text((col1 + 4, header_y + 4), "Check", fill=hex_to_rgb(DIM), font=FONT_SMALL)
    draw.text((col2 + 4, header_y + 4), "Unit Tests", fill=hex_to_rgb(DIM), font=FONT_SMALL)
    draw.text((col3 + 4, header_y + 4), "ValidationForge", fill=hex_to_rgb(DIM), font=FONT_SMALL)
    y = header_y + 28

    rows = [
        ("API returns 200",              "✓ PASS", SUCCESS, "✓ PASS",           SUCCESS),
        ("API returns user data",         "✓ PASS", SUCCESS, "✓ PASS",           SUCCESS),
        ("Frontend renders users",        "✓ PASS", SUCCESS, "✗ FAIL (crash)",   ERROR),
        ("End-to-end contract correct",   "✗ Not tested", DIM, "✓ PASS (fixed)", SUCCESS),
    ]
    for check, ut, ut_color, vf, vf_color in rows:
        draw.text((col1 + 4, y + 4), check, fill=hex_to_rgb(CMD), font=FONT_SMALL)
        draw.text((col2 + 4, y + 4), ut,    fill=hex_to_rgb(ut_color), font=FONT_SMALL)
        draw.text((col3 + 4, y + 4), vf,    fill=hex_to_rgb(vf_color), font=FONT_SMALL)
        y += LINE_H

    y += 12
    lines = [
        ("  Unit tests:        4/4 passing  →  App broken in production", DIM),
        ("  ValidationForge:  caught bug in 30s, fixed, verified  →  Ship!", SUCCESS),
    ]
    draw_multiline(draw, y, lines)

    return img, DELAY_READING


def frame_end_card() -> tuple[Image.Image, int]:
    """Frame 24: End card with repo link."""
    img, draw = new_frame()
    draw_header(draw, "ValidationForge  —  demo")

    cy = HEIGHT // 2 - 80

    logo = "  ✦  ValidationForge  ✦  "
    bbox = draw.textbbox((0, 0), logo, font=FONT_TITLE)
    tw = bbox[2] - bbox[0]
    draw.text(((WIDTH - tw) // 2, cy), logo, fill=hex_to_rgb(TITLE_FG), font=FONT_TITLE)

    cy += 60
    tag = "Ship verified code, not compiled code."
    bbox2 = draw.textbbox((0, 0), tag, font=FONT_BOLD)
    tw2 = bbox2[2] - bbox2[0]
    draw.text(((WIDTH - tw2) // 2, cy), tag, fill=hex_to_rgb(CMD), font=FONT_BOLD)

    cy += 36
    url = "github.com/krzemienski/validationforge"
    bbox3 = draw.textbbox((0, 0), url, font=FONT_NORMAL)
    tw3 = bbox3[2] - bbox3[0]
    draw.text(((WIDTH - tw3) // 2, cy), url, fill=hex_to_rgb(INFO), font=FONT_NORMAL)

    cy += 30
    install = "/validate — just invoke it."
    bbox4 = draw.textbbox((0, 0), install, font=FONT_SMALL)
    tw4 = bbox4[2] - bbox4[0]
    draw.text(((WIDTH - tw4) // 2, cy), install, fill=hex_to_rgb(PROMPT), font=FONT_SMALL)

    return img, DELAY_END


# ---------------------------------------------------------------------------
# Frame sequence definition
# ---------------------------------------------------------------------------

def build_frame_sequence() -> list[tuple[Image.Image, int]]:
    """Build ordered list of (image, delay_centiseconds) pairs."""
    builders = [
        frame_title_1,           # 1
        frame_title_2,           # 2
        frame_validate_invoke,   # 3
        frame_platform_detect,   # 4
        frame_platform_result,   # 5
        frame_preflight_start,   # 6
        frame_preflight_evidence,# 7
        frame_hook_attempt,      # 8
        frame_hook_blocked,      # 9
        frame_hook_rule,         # 10
        frame_hook_resume,       # 11
        frame_api_curl,          # 12
        frame_api_response,      # 13
        frame_api_verdict,       # 14
        frame_browser_navigate,  # 15
        frame_browser_error,     # 16
        frame_browser_screenshot_sim, # 17
        frame_root_cause,        # 18
        frame_fix_applied,       # 19
        frame_browser_fixed_screenshot, # 20
        frame_verdict,           # 21
        frame_verdict_pass,      # 22
        frame_scorecard,         # 23
        frame_end_card,          # 24
    ]

    frames = []
    for i, builder in enumerate(builders, start=1):
        print(f"  Rendering frame {i:02d}/{len(builders)}...", flush=True)
        img, delay = builder()
        frames.append((img, delay))

    return frames


# ---------------------------------------------------------------------------
# GIF assembly
# ---------------------------------------------------------------------------

def save_gif(frames: list[tuple[Image.Image, int]], output_path: str,
             n_colors: int = 128) -> None:
    """Convert RGB frames to palette mode and save as animated GIF."""
    palette_frames = []
    durations = []

    for img, delay_cs in frames:
        p = to_palette(img, colors=n_colors)
        palette_frames.append(p)
        durations.append(delay_cs * 10)  # GIF duration is in ms for Pillow

    first = palette_frames[0]
    rest  = palette_frames[1:]

    first.save(
        output_path,
        save_all=True,
        append_images=rest,
        loop=0,              # loop forever
        duration=durations,
        optimize=True,
    )


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> None:
    script_dir = Path(__file__).parent
    output_path = script_dir / "vf-demo.gif"

    print("ValidationForge Demo GIF Generator")
    print(f"  Output: {output_path}")
    print(f"  Resolution: {WIDTH}x{HEIGHT}")
    print(f"  Palette: 128 colors")
    print()

    print("Building frames...")
    frames = build_frame_sequence()
    print(f"  {len(frames)} frames built.")
    print()

    print("Assembling GIF...")
    save_gif(frames, str(output_path), n_colors=128)

    size_bytes = output_path.stat().st_size
    size_kb    = size_bytes // 1024
    size_mb    = size_bytes / (1024 * 1024)

    print(f"  Saved: {output_path}")
    print(f"  Size:  {size_kb} KB  ({size_mb:.2f} MB)")

    total_duration_ms = sum(delay * 10 for _, delay in frames)
    print(f"  Duration: {total_duration_ms / 1000:.1f} seconds  ({len(frames)} frames)")

    if size_bytes > 5 * 1024 * 1024:
        print()
        print("WARNING: GIF exceeds 5 MB target.")
        print("  Try re-running with reduced palette (64 colors) or lower resolution.")
        sys.exit(1)
    else:
        print()
        print("Done. ✓")


if __name__ == "__main__":
    main()
