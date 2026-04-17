#!/usr/bin/env python3
"""Consensus-mode plan merger for forge-plan.

Parses two markdown validation plans, unions journeys by case-insensitive
name, unions PASS criteria per journey, and flags conflicts on stderr.
See forge-plan-merge.sh for CLI contract.
"""
from __future__ import annotations
import argparse
import re
import sys
from pathlib import Path

JOURNEY_HDR = re.compile(r"^##\s+(?:Journey\s+\d+|J\d+)[:\s-]+(.+?)\s*$", re.IGNORECASE)
BULLET = re.compile(r"^\s*[-*]\s+(.+?)\s*$")


def parse_plan(text: str) -> dict[str, list[str]]:
    """Return {journey_name: [criteria...]} in source order."""
    journeys: dict[str, list[str]] = {}
    current: str | None = None
    for line in text.splitlines():
        m = JOURNEY_HDR.match(line)
        if m:
            current = m.group(1).strip()
            journeys.setdefault(current, [])
            continue
        if current is None:
            continue
        b = BULLET.match(line)
        if b:
            journeys[current].append(b.group(1).strip())
    return journeys


def criterion_subject(criterion: str) -> str:
    """Heuristic subject key used for conflict detection.

    Uses the first 3 words lowercased; criteria sharing the same subject but
    differing in the rest are treated as conflicting expectations.
    """
    words = re.findall(r"\w+", criterion.lower())
    return " ".join(words[:3])


def merge(a: dict[str, list[str]], b: dict[str, list[str]]):
    """Merge b into a copy of a. Returns (merged, conflicts)."""
    lower_to_canonical = {name.lower(): name for name in a}
    merged: dict[str, list[str]] = {name: list(crits) for name, crits in a.items()}
    conflicts: list[tuple[str, str, str]] = []  # (journey, a_text, b_text)

    for b_name, b_crits in b.items():
        key = b_name.lower()
        if key not in lower_to_canonical:
            lower_to_canonical[key] = b_name
            merged[b_name] = list(b_crits)
            continue
        canonical = lower_to_canonical[key]
        existing = merged[canonical]
        existing_subjects = {criterion_subject(c): c for c in existing}
        for bc in b_crits:
            if bc in existing:
                continue
            subj = criterion_subject(bc)
            if subj in existing_subjects and existing_subjects[subj] != bc:
                a_text = existing_subjects[subj]
                conflicts.append((canonical, a_text, bc))
                # Annotate the plan-A version with an HTML comment noting conflict.
                idx = existing.index(a_text)
                annotated = f"{a_text} <!-- conflict with plan-b: {bc!r} -->"
                existing[idx] = annotated
                existing_subjects[subj] = annotated
                continue
            existing.append(bc)
            existing_subjects[subj] = bc
    return merged, conflicts


def render(
    merged: dict[str, list[str]],
    plan_a_path: str,
    plan_b_path: str,
    a_journeys: set[str],
    b_journeys: set[str],
    conflict_count: int,
) -> str:
    a_lower = {n.lower() for n in a_journeys}
    b_lower = {n.lower() for n in b_journeys}
    only_a = sorted(n for n in a_journeys if n.lower() not in b_lower)
    only_b = sorted(n for n in b_journeys if n.lower() not in a_lower)
    overlap = sorted(n for n in merged if n.lower() in a_lower and n.lower() in b_lower)

    out: list[str] = [
        "# Merged Validation Plan",
        "",
        "## Merge Summary",
        "",
        f"- Source plan A: `{plan_a_path}`",
        f"- Source plan B: `{plan_b_path}`",
        f"- Total journeys in output: {len(merged)}",
        f"- Unique to plan A ({len(only_a)}): {', '.join(only_a) if only_a else 'none'}",
        f"- Unique to plan B ({len(only_b)}): {', '.join(only_b) if only_b else 'none'}",
        f"- Overlapping ({len(overlap)}): {', '.join(overlap) if overlap else 'none'}",
        f"- Conflicts detected: {conflict_count}",
        "",
        "## Journeys",
        "",
    ]
    for i, (name, crits) in enumerate(merged.items(), start=1):
        out.append(f"## Journey {i}: {name}")
        out.append("")
        out.append("**PASS criteria:**")
        out.append("")
        for c in crits:
            out.append(f"- {c}")
        out.append("")
    return "\n".join(out).rstrip() + "\n"


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--plan-a", required=True)
    ap.add_argument("--plan-b", required=True)
    ap.add_argument("--output", required=True)
    args = ap.parse_args()

    text_a = Path(args.plan_a).read_text(encoding="utf-8")
    text_b = Path(args.plan_b).read_text(encoding="utf-8")
    plan_a = parse_plan(text_a)
    plan_b = parse_plan(text_b)

    if not plan_a and not plan_b:
        print("forge-plan-merge: no journeys parsed from either plan", file=sys.stderr)
        return 2

    merged, conflicts = merge(plan_a, plan_b)

    for journey, a_text, b_text in conflicts:
        # Derive a short criterion label from the A text for the stderr line.
        label = a_text.split(".")[0].split("—")[0].strip()[:60]
        print(
            f'CONFLICT: {journey} / {label} — plan A says "{a_text}", '
            f'plan B says "{b_text}"',
            file=sys.stderr,
        )

    rendered = render(
        merged,
        args.plan_a,
        args.plan_b,
        set(plan_a.keys()),
        set(plan_b.keys()),
        len(conflicts),
    )
    Path(args.output).write_text(rendered, encoding="utf-8")
    return 0


if __name__ == "__main__":
    sys.exit(main())
