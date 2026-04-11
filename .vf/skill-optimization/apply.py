#!/usr/bin/env python3
"""
Apply optimized descriptions, missing triggers, and missing context_priority
to all 48 VF skills. Generates before/after report.
"""

import json
import re
from pathlib import Path

ROOT = Path("/Users/nick/Desktop/validationforge")
SKILLS_DIR = ROOT / "skills"
PROPOSALS_DIR = ROOT / ".vf/skill-optimization/proposals"
WORKSPACE = ROOT / ".vf/skill-optimization"


def load_all_proposals():
    proposals = {}
    for f in sorted(PROPOSALS_DIR.glob("batch-*.json")):
        data = json.loads(f.read_text())
        for item in data:
            proposals[item["name"]] = item
    return proposals


def split_frontmatter(content: str):
    """Return (fm_dict_preserving_order, body). fm is a list of (key, raw_value, multiline_lines)."""
    lines = content.split("\n")
    if not lines or lines[0].strip() != "---":
        return None, content

    end_idx = None
    for i in range(1, len(lines)):
        if lines[i].strip() == "---":
            end_idx = i
            break
    if end_idx is None:
        return None, content

    fm_lines = lines[1:end_idx]
    body = "\n".join(lines[end_idx + 1 :])
    return fm_lines, body


def rewrite_frontmatter(
    fm_lines: list[str],
    new_description: str,
    missing_triggers: list[str] | None,
    ensure_context_priority: str | None,
) -> list[str]:
    """Rewrite frontmatter lines preserving order and other keys."""
    # Parse top-level keys (keys at column 0 with a colon)
    # Collect sections: [(key, [lines...])]
    sections = []
    current_key = None
    current_lines = []
    for line in fm_lines:
        # Top-level key detection: starts at column 0, has "key:" pattern
        m = re.match(r"^([a-zA-Z_][a-zA-Z0-9_]*):(.*)$", line)
        if m and not line.startswith(" "):
            if current_key is not None:
                sections.append((current_key, current_lines))
            current_key = m.group(1)
            current_lines = [line]
        else:
            if current_key is not None:
                current_lines.append(line)
            else:
                # pre-key content (unlikely but safe)
                if sections and sections[-1][0] == "_preamble":
                    sections[-1][1].append(line)
                else:
                    sections.append(("_preamble", [line]))
    if current_key is not None:
        sections.append((current_key, current_lines))

    # Replace description
    new_sections = []
    desc_replaced = False
    triggers_added = False
    cp_added = False

    for key, lines in sections:
        if key == "description":
            # Emit as safe YAML single-line with quoting if needed
            safe = new_description.replace('"', '\\"')
            new_sections.append(("description", [f'description: "{safe}"']))
            desc_replaced = True
        elif key == "triggers":
            if missing_triggers:
                # Should never match since presence implies not missing, but be safe
                new_sections.append((key, lines))
                triggers_added = True
            else:
                new_sections.append((key, lines))
        elif key == "context_priority":
            new_sections.append((key, lines))
            cp_added = True
        else:
            new_sections.append((key, lines))

    # Add missing triggers after description if not present
    if missing_triggers and not any(k == "triggers" for k, _ in new_sections):
        trigger_lines = ["triggers:"]
        for t in missing_triggers:
            trigger_lines.append(f'  - "{t}"')
        # Insert after description
        final = []
        inserted = False
        for key, lines in new_sections:
            final.append((key, lines))
            if key == "description" and not inserted:
                final.append(("triggers", trigger_lines))
                inserted = True
        new_sections = final

    # Add missing context_priority if requested
    if ensure_context_priority and not cp_added:
        new_sections.append(
            ("context_priority", [f"context_priority: {ensure_context_priority}"])
        )

    # Rebuild
    out_lines = []
    for key, lines in new_sections:
        out_lines.extend(lines)
    return out_lines


def apply_proposal(skill_name: str, proposal: dict) -> dict:
    skill_md = SKILLS_DIR / skill_name / "SKILL.md"
    if not skill_md.exists():
        return {"status": "skipped", "reason": "no SKILL.md"}

    original_content = skill_md.read_text()
    fm_lines, body = split_frontmatter(original_content)
    if fm_lines is None:
        return {"status": "skipped", "reason": "no frontmatter"}

    # Capture original description
    orig_desc = None
    capturing = False
    desc_buf = []
    for line in fm_lines:
        if line.startswith("description:"):
            rest = line[12:].strip()
            if rest.startswith(">") or rest.startswith("|"):
                capturing = True
                continue
            else:
                orig_desc = rest.strip("\"'")
                break
        elif capturing:
            if line.startswith(" ") or line.startswith("\t"):
                desc_buf.append(line.strip())
            else:
                break
    if orig_desc is None and desc_buf:
        orig_desc = " ".join(desc_buf)

    new_desc = proposal.get("improved_description", "").strip()
    if not new_desc:
        return {"status": "skipped", "reason": "no improved_description"}

    missing_triggers = proposal.get("missing_triggers") or None
    ensure_cp = proposal.get("missing_context_priority") or None

    # Check if skill already has triggers - if so, don't add
    has_triggers = any(re.match(r"^triggers:", line) for line in fm_lines)
    if has_triggers:
        missing_triggers = None

    has_cp = any(re.match(r"^context_priority:", line) for line in fm_lines)
    if has_cp:
        ensure_cp = None

    new_fm = rewrite_frontmatter(fm_lines, new_desc, missing_triggers, ensure_cp)

    new_content = "---\n" + "\n".join(new_fm) + "\n---\n" + body
    skill_md.write_text(new_content)

    return {
        "status": "applied",
        "original_description": orig_desc,
        "new_description": new_desc,
        "triggers_added": missing_triggers or [],
        "context_priority_added": ensure_cp,
    }


def main():
    proposals = load_all_proposals()
    print(f"Loaded {len(proposals)} proposals")

    results = {}
    applied = 0
    skipped = 0
    for skill_dir in sorted(SKILLS_DIR.iterdir()):
        if not skill_dir.is_dir():
            continue
        name = skill_dir.name
        if name not in proposals:
            results[name] = {"status": "no_proposal"}
            skipped += 1
            continue
        try:
            r = apply_proposal(name, proposals[name])
            results[name] = r
            if r["status"] == "applied":
                applied += 1
            else:
                skipped += 1
        except Exception as e:
            results[name] = {"status": "error", "error": str(e)}
            skipped += 1
            print(f"  ERROR {name}: {e}")

    # Save report
    report = WORKSPACE / "report.json"
    report.write_text(json.dumps(results, indent=2))

    # Markdown report
    md = WORKSPACE / "report.md"
    lines = [
        "# Skill Optimization Report",
        "",
        f"**Scope:** 48 VF skills in `skills/`",
        f"**Applied:** {applied}",
        f"**Skipped:** {skipped}",
        "",
        "---",
        "",
    ]
    for name in sorted(results.keys()):
        r = results[name]
        if r["status"] != "applied":
            continue
        lines.append(f"## {name}")
        lines.append("")
        lines.append("**Before:**")
        lines.append("```")
        lines.append(r.get("original_description", "(empty)"))
        lines.append("```")
        lines.append("")
        lines.append("**After:**")
        lines.append("```")
        lines.append(r["new_description"])
        lines.append("```")
        lines.append("")
        if r.get("triggers_added"):
            lines.append(f"**Triggers added:** {', '.join(r['triggers_added'])}")
            lines.append("")
        if r.get("context_priority_added"):
            lines.append(f"**context_priority added:** `{r['context_priority_added']}`")
            lines.append("")
        lines.append("---")
        lines.append("")

    md.write_text("\n".join(lines))
    print(f"\nApplied: {applied}, Skipped: {skipped}")
    print(f"JSON report: {report}")
    print(f"Markdown report: {md}")


if __name__ == "__main__":
    main()
