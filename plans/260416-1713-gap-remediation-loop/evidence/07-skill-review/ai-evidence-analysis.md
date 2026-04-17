---
skill: ai-evidence-analysis
reviewer: R1
date: 2026-04-16
verdict: PASS
---

# ai-evidence-analysis review

## Frontmatter check
- name: `ai-evidence-analysis`
- description: `"AI-augmented evidence review: vision models analyze screenshots, LLMs check API/CLI output. Produces 0-100 confidence scores and findings. Optional in offline mode."` (168 chars)
- description_well_formed: yes
- yaml_parses: yes

## Trigger realism
Would invoke on: `"analyze evidence"`, `"evidence confidence score"`, `"analyze screenshot"`, `"analyze API response"`.
Realism score: 5/5. Triggers are clear, match skill scope exactly. Technical terminology used correctly.

## Body-description alignment
PASS. Body fully realizes the description:
- Vision model analysis of screenshots with confidence scores ✓
- LLM analysis of API/CLI output ✓
- 0-100 confidence score assignment ✓
- Offline/disabled mode handling ✓
- Findings with severity labels ✓

Analysis output schema is explicit. Disabling logic included. Anti-patterns table helps avoid misuse.

## MCP tool existence
- Vision model (`claude-sonnet` with vision) — referenced for screenshot analysis
  - Confirmed available? Yes, inline model calls documented
- LLM (implicit claude model) — referenced for API/CLI analysis
  - Confirmed available? Yes, implied in all skills

No external MCP servers required for core functionality; skill is self-contained via model API calls.

## Example invocation proof
User: `"Analyze this screenshot for rendering defects"`
Would trigger Phase 2 (Classify), Phase 3 (Analyze by Type), Phase 4 (Save Results).

## Verdict
**PASS**

Well-structured skill with clear offline/disabled handling. Output schema is explicit and falsifiable. Analysis protocol is detailed. No blocking dependencies.
