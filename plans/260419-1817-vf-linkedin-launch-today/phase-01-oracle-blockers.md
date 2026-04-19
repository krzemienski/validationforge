# Phase 01 — Close remaining Oracle gaps

## 1. Repo topics (Oracle A.1 remainder)

Add missing topics to `krzemienski/validationforge`:
- `no-mock`
- `functional-testing`
- `quality-assurance`

```bash
gh repo edit krzemienski/validationforge \
  --add-topic no-mock \
  --add-topic functional-testing \
  --add-topic quality-assurance
```

Verify with `gh repo view krzemienski/validationforge --json repositoryTopics`.

## 2. README purge (Oracle A.2)

**Line 3** (badge): currently points to future Post #11. Replace with launch-week badge.

**Lines 5-12** (Related Post block): currently references:
- Send date: Mon Jun 22, 2026
- LinkedIn: _link added on send day_
- Canonical blog post: https://ai.hack.ski/blog/the-ai-development-operating-system
- Series hub: agentic-development-guide

Replace with launch-week content per Oracle:

```markdown
[![Launch week — Apr 20–30, 2026](https://img.shields.io/badge/launch-week-green)](https://github.com/krzemienski/validationforge)

## Related Post

Soft-launch week for ValidationForge is in progress.

- GitHub repo: https://github.com/krzemienski/validationforge
- Self-validation evidence: ./e2e-evidence/self-validation/report.md
- Long-form essay: _publishes Wed Apr 22, 2026_
- Series hub: https://github.com/krzemienski/agentic-development-guide
```

## Verification

```bash
rg -n 'slug-set-on-send-day|Mon Jun 22, 2026|link added on send day' README.md
# → no output expected
```
