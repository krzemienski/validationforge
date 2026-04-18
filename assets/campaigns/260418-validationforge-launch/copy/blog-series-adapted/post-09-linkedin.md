---
post_number: 9
title: "From GitHub Repos to Audio Stories: Building Code Tales with AI"
channels: LinkedIn (native long-form post) + personal blog (canonical)
word_count_target: 1600-2000
send_week: Week 8 — Mon Jun 8, 2026
companion_repo: https://github.com/krzemienski/code-tales
hero_image: assets/code-tales-hero.png (existing, 1200x627, ready)
rewrite_note: |
  REWRITE 2026-04-18 — calendar-framed adaptation, NOT source-faithful.
  The earlier draft pulled from a source post that had drifted toward
  session-mining framing. This rewrite restores the original calendar slot
  intent: a product showcase for Code Tales — a tool that converts a
  GitHub repo URL into a narrated audio experience using Claude for
  analysis + script generation and ElevenLabs for voice synthesis.
  Pull-quote selected: "What if I could listen to a codebase?"
---

# From GitHub Repos to Audio Stories: Building Code Tales with AI

I was stuck in traffic on the 405, listening to a podcast about a system I had never used, and realized I understood its architecture better in twenty minutes than I had understood the codebase I'd been reading for two days.

That bothered me enough to build something about it.

## The question I could not stop asking

What if I could listen to a codebase? Not read documentation. Not scan source files. Listen — like a podcast about FastAPI's architecture, or a documentary on how Redis handles persistence, or an executive briefing on what a new internal service does and why it exists.

The technology to do this existed. Large language models can read repositories and explain them in natural language. Speech synthesis has crossed the line where the output is pleasant to listen to for ten minutes at a stretch. The pieces were on the table. Nobody had assembled them in the shape I wanted.

So I assembled them. The result is Code Tales — a tool that takes a GitHub repository URL, analyzes the codebase with Claude, generates a narrative script in one of nine styles, then synthesizes spoken audio via ElevenLabs. You give it a URL. Twenty minutes later you have an mp3 you can listen to on a walk.

The repo is open: github.com/krzemienski/code-tales. The interesting engineering does not live where you'd expect.

## The four-stage pipeline

The system is conceptually simple. Four stages, each one with a clean handoff to the next.

**Stage 1: clone.** Pull the repo to a temporary directory. Walk the file tree. Build a manifest of files, languages, and rough size. Skip vendored directories, build artifacts, and anything bigger than a sane threshold. The output of this stage is a structured description of "what is in this repository" — file paths, line counts, language mix, a list of the entry points the build system declares.

**Stage 2: analyze.** Feed the manifest to Claude with a prompt asking specific questions. What does this codebase do, in one paragraph? What are the major architectural components? What's the data flow? What's the most interesting design decision? What's a reader new to this code likely to misunderstand? The output of this stage is a structured analysis document — JSON with named sections, not free-form prose.

**Stage 3: narrate.** Feed the analysis to Claude again, with a different prompt: rewrite this as a narrative script in style X, optimized for spoken delivery. Style X is the parameter that changes the entire experience. Documentary style. Podcast-with-two-hosts style. Interview style. Executive briefing. Fiction. Tutorial. Debate. Technical lecture. Storytelling. Each style has its own prompt template, its own pacing rules, its own conventions about how to handle technical jargon.

**Stage 4: synthesize.** Feed the script to ElevenLabs. Get back an audio file. For multi-voice styles (podcast, interview, debate), the script is segmented and each segment is rendered with the appropriate voice, then stitched together with a small amount of silence at the boundaries.

You can read the code in an afternoon. Each stage is a few hundred lines. The interesting engineering is not in the code. It is at the boundaries between the stages.

## Where the system actually got hard

The clone-to-manifest stage is mostly file-system work. The audio synthesis is mostly an API call. Those two ends are well-understood.

The middle two stages are where the system either produces something worth listening to or produces something that sounds like a robot reading a stack trace.

The hard problem in stage 2 is that "analyze this codebase" is not a single task. A documentary script needs different inputs than a podcast script. A documentary wants a clean architectural narrative with one or two major themes. A two-host podcast wants questions and answers, points where one host can challenge the other, places where the conversation can branch. The analysis stage has to produce a representation that is rich enough for any downstream style to draw from.

The solution I landed on is a structured analysis document with more sections than any single style needs. The narrate stage picks the sections it cares about and ignores the rest. This means stage 2 always does the same work, regardless of style — which makes the pipeline cacheable and reproducible. If you re-run a repo in a different style, you skip stage 2 entirely.

The hard problem in stage 3 is that LLMs are not good at writing for spoken delivery by default. They write for the page. Sentences are too long. Parentheticals nest. Numbers are spelled out in ways that sound wrong. Acronyms are read letter-by-letter when they should be read as words, or vice versa. The first generation of scripts I produced were unlistenable.

The fix was not a better model. The fix was constraints. Sentences capped at twenty-five words. No nested clauses. Numbers under one hundred written out as words. A list of acronyms with their pronunciation rules. Pacing markers — short sentences after long ones, deliberate paragraph breaks every few minutes. The model with constraints produced scripts that sounded human. The model without constraints produced scripts that sounded like LinkedIn.

## Same repository, different audio experiences

The most surprising thing about the system is what happens when you run the same repo through two different styles.

Take a small Python web framework. In documentary style, the output is a fifteen-minute narrative explaining the framework's design decisions, the tradeoffs the author made, the historical context for why certain patterns exist. It sounds like an episode of a podcast about software history. The narrator is calm, the pacing is deliberate, the structure is chronological-by-architectural-layer.

Same repository, podcast style. Two hosts, one slightly more skeptical than the other. The skeptic asks why a particular design was chosen. The other host explains. The skeptic pushes back. They disagree about something, then resolve. The output is twenty minutes long, has the energy of a real podcast, and covers about sixty percent of what the documentary covered — but the parts it covers, it covers more memorably because the disagreement makes you actually think about the tradeoffs.

Same repository, executive briefing style. Six minutes. The narrator is brisk. The structure is decision-oriented: what does this codebase do, what would adopting it cost, what are the integration points, what are the risks. No history, no anecdotes, no architectural deep dives. Just the answer to "should my team use this."

These are fundamentally different audio experiences from the same source data. The thing the system optimizes for — listenability for a specific use case — is determined entirely by the prompt template at stage 3. The repository did not change. The model did not change. The constraints changed, and the output became something else.

The lesson here is the one I keep relearning: AI-generated content quality depends not on the model but on the constraints and structure you give it. The model is the engine. The constraints are the steering wheel. Most projects I see fail because they have a fast engine and no steering wheel.

## What I had to throw away

The first version of this system did not have a structured analysis stage. It went directly from the cloned repo to the narrative script. The single-stage prompt was "read this repository and write a podcast script about it."

The output was occasionally brilliant and frequently incoherent. The model would forget halfway through what the codebase actually did. It would invent files that didn't exist. It would describe one design pattern in the introduction and a completely different one in the conclusion, with no acknowledgement that the two contradicted each other.

Adding the explicit analyze stage — making the model first produce a structured representation of what is in the repo, then write the script from the representation — fixed all three problems. The structured analysis is the model's anchor. When it later writes the script, it is writing about the analysis, not about the repo. The analysis is finite, consistent, and doesn't disappear from context.

I also threw away the first three voice-synthesis pipelines I tried. The early versions used a different provider with a flatter prosody model. The audio was technically correct and emotionally inert. ElevenLabs produced output that I would actually listen to for fifteen minutes voluntarily, which turned out to be the only metric that mattered. If you would not listen to it on a walk, the pipeline failed regardless of how clever the upstream stages were.

The honest version of "I built this in a weekend" is "I built three versions and threw two away." That is more interesting than the weekend story and more useful to anyone trying to build something similar.

## Why this is in my portfolio

Code Tales is not a startup. It is not a funded project. I am not selling subscriptions. I built it because I wanted to listen to codebases on walks, and now I do.

It is in my portfolio because it is the smallest end-to-end demonstration I can show of a pattern I now use everywhere. The pattern: take a multimodal task that nobody can do well in a single LLM call, decompose it into stages with clean handoffs, give each stage explicit constraints and structured output, and let the system compose into something that feels like a finished product.

This pattern shows up in every agentic system worth building. The four-stage shape of Code Tales is the same four-stage shape I used for an internal tool that turns Slack threads into incident postmortems, and the same four-stage shape I used for a different internal tool that turns design specs into runnable React components. The repos are different. The pipeline shape is the same.

When I am evaluating whether a new agentic project is going to work, the first question I now ask is "what are the stages, what does each stage produce, and what constraints does each stage need." If I can answer those three questions cleanly, the project is feasible. If I can't, I am about to build a single-stage prompt that will be occasionally brilliant and frequently incoherent.

## The bridge to the rest of the work

Code Tales was built during the same ninety-day period that produced ValidationForge. The two projects look unrelated on the surface — one is an audio-generation toy, one is a validation framework — but they came out of the same observation. AI-assisted systems work when you give them structure and fail when you don't. ValidationForge enforces structure on the verification side. Code Tales enforces structure on the generation side. The principle is identical.

If you are building agentic systems and you are seeing the symptom I saw early on — output is sometimes great, sometimes nonsense, can't predict which — the answer is almost always more stages and more constraints, not a better model. The model is fine. The pipeline around the model is the work.

## What I am open to

I have a small amount of capacity in Q3 for advisory work with engineering teams adopting agentic development at scale. The teams I am best-suited for are 50-500 person organizations that are shipping AI-assisted code, hitting the consistency problem, and starting to ask whether the answer is "better prompts" or "better systems." It is the second one. I help teams build the second one.

If that is where you are, a one-paragraph LinkedIn DM is the fastest way to start a conversation. I respond within two business days.

If you just want to listen to a codebase: github.com/krzemienski/code-tales. Plug in any public repo, pick a style, get an mp3. The defaults work. If they don't, file an issue and I will fix it.

The system is the contribution. The audio is the demo.

---

*Nick Krzemienski — building Code Tales, ValidationForge, and a handful of other small systems that come from one ninety-day stretch of agentic development. github.com/krzemienski*
