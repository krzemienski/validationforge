#!/usr/bin/env python3
"""
Apply trimmed descriptions to SKILL.md files.
Unlike the prior apply.py, this one:
1. Reads proposals from JSON
2. Verifies each proposal is ≤210 chars BEFORE touching a file
3. Only replaces the description line — does NOT re-emit entire frontmatter
4. Preserves YAML style (no block-scalar → quoted churn)
5. Verifies the edit happened (read back and check)
"""

import json
import re
from pathlib import Path
import sys

ROOT = Path("/Users/nick/Desktop/validationforge")
SKILLS_DIR = ROOT / "skills"
PROPOSALS = ROOT / ".vf/skill-optimization/trim-proposals.json"
MAX_LEN = 210


def replace_description(skill_md: Path, new_desc: str) -> tuple[bool, str]:
    """Replace the description in frontmatter with a single-line quoted version.
    Returns (changed, message)."""
    content = skill_md.read_text()
    lines = content.split("\n")

    # Find frontmatter bounds
    if not lines or lines[0].strip() != "---":
        return False, "no frontmatter"

    fm_end = None
    for i in range(1, len(lines)):
        if lines[i].strip() == "---":
            fm_end = i
            break
    if fm_end is None:
        return False, "unclosed frontmatter"

    # Find description line(s) — could be single-line or block-scalar (> or |)
    desc_start = None
    desc_end = None
    for i in range(1, fm_end):
        line = lines[i]
        if line.startswith("description:"):
            desc_start = i
            rest = line[12:].strip()
            if rest.startswith(">") or rest.startswith("|"):
                # Block scalar — find where it ends (next key at col 0)
                for j in range(i + 1, fm_end):
                    nl = lines[j]
                    if nl and not nl.startswith(" ") and not nl.startswith("\t"):
                        desc_end = j - 1
                        break
                else:
                    desc_end = fm_end - 1
            else:
                desc_end = i
            break

    if desc_start is None:
        return False, "no description line"

    # Escape the new desc for single-line quoted YAML
    safe = new_desc.replace("\\", "\\\\").replace('"', '\\"')
    new_line = f'description: "{safe}"'

    new_lines = lines[:desc_start] + [new_line] + lines[desc_end + 1 :]
    new_content = "\n".join(new_lines)

    skill_md.write_text(new_content)
    return True, f"desc line {desc_start + 1}, was {desc_end - desc_start + 1} lines"


def main():
    proposals = json.loads(PROPOSALS.read_text())

    # Pre-flight: verify every proposal is ≤MAX_LEN
    over = [(n, len(d)) for n, d in proposals.items() if len(d) > MAX_LEN]
    if over:
        print(f"ABORT: {len(over)} proposals over {MAX_LEN} chars:")
        for n, l in over:
            print(f"  {n}: {l}")
        sys.exit(1)

    print(f"Pre-flight PASS: all 48 proposals ≤{MAX_LEN} chars")
    print(f"Total: {sum(len(d) for d in proposals.values())} chars")
    print()

    applied = 0
    for name, new_desc in sorted(proposals.items()):
        skill_md = SKILLS_DIR / name / "SKILL.md"
        if not skill_md.exists():
            print(f"  SKIP {name}: no SKILL.md")
            continue

        changed, msg = replace_description(skill_md, new_desc)
        if changed:
            applied += 1
        print(f"  {'OK' if changed else 'FAIL'} {name}: {msg}")

    print(f"\nApplied: {applied}/48")

    # Post-flight verification
    print("\nPost-flight verification:")
    import yaml

    all_ok = True
    total_len = 0
    for name in sorted(proposals.keys()):
        skill_md = SKILLS_DIR / name / "SKILL.md"
        parts = skill_md.read_text().split("---", 2)
        fm = yaml.safe_load(parts[1])
        desc = fm.get("description", "")
        total_len += len(desc)
        expected = proposals[name]
        if desc != expected:
            print(f"  MISMATCH {name}: expected {len(expected)}, got {len(desc)}")
            all_ok = False

    print(f"\nPost-flight: {'all match' if all_ok else 'MISMATCHES FOUND'}")
    print(f"Total description chars after: {total_len}")
    print(
        f"Baseline: 12384, After: {total_len}, Reduction: {12384 - total_len} chars ({(12384 - total_len) * 100 // 12384}%)"
    )


if __name__ == "__main__":
    main()
