#!/usr/bin/env python3
"""
Generate 20-query eval sets for all VF skills using claude -p.
Processes skills in parallel batches to speed up generation.
"""

import json
import os
import re
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

SKILLS_DIR = Path("/Users/nick/Desktop/validationforge/skills")
OUTPUT_DIR = Path(
    "/Users/nick/Desktop/validationforge/.vf/skill-optimization/eval-sets"
)
MODEL = "claude-sonnet-4-6"
MAX_WORKERS = 5  # parallel claude -p calls


def get_skill_info(skill_dir: Path) -> dict | None:
    skill_md = skill_dir / "SKILL.md"
    if not skill_md.exists():
        return None

    content = skill_md.read_text()
    lines = content.split("\n")

    name = skill_dir.name
    description = ""
    triggers = []
    in_frontmatter = False
    capturing_desc = False
    capturing_triggers = False

    for line in lines:
        if line.strip() == "---":
            if in_frontmatter:
                break
            in_frontmatter = True
            continue
        if not in_frontmatter:
            continue

        if line.startswith("name:"):
            name = line[5:].strip().strip("\"'")
        elif line.startswith("description:"):
            rest = line[12:].strip()
            if rest.startswith(">") or rest.startswith("|"):
                capturing_desc = True
            elif rest.startswith('"') or rest.startswith("'"):
                description = rest.strip("\"'")
            else:
                description = rest
        elif capturing_desc:
            if line and (line[0] == " " or line[0] == "\t"):
                description += " " + line.strip()
            else:
                capturing_desc = False
        elif line.startswith("triggers:"):
            capturing_triggers = True
        elif capturing_triggers:
            if line.strip().startswith("- "):
                triggers.append(line.strip()[2:].strip("\"'"))
            elif not line.strip():
                continue
            else:
                capturing_triggers = False

    return {
        "name": name,
        "description": description.strip(),
        "triggers": triggers,
    }


def generate_eval_set(skill_info: dict) -> list[dict] | None:
    name = skill_info["name"]
    desc = skill_info["description"]
    triggers = ", ".join(skill_info["triggers"][:5])

    prompt = f"""Generate exactly 20 eval queries for a Claude Code skill called "{name}".

Skill description: {desc}
Known triggers: {triggers}

Output a JSON array. Each item must have:
- "query": a realistic, detailed user prompt (2-4 sentences with specific context like file paths, company names, tech details)
- "should_trigger": true (10 queries) or false (10 queries)

Rules for should_trigger=true queries:
- Use different phrasings: formal, casual, with typos, abbreviated
- Include cases where the user needs this skill but doesn't name it explicitly
- Include uncommon/edge-case uses of the skill

Rules for should_trigger=false queries:
- Near-misses that share keywords but need a different skill/approach
- Adjacent domains that could confuse a naive keyword matcher
- Do NOT use obviously irrelevant queries like "write hello world"

Output ONLY the JSON array, no markdown fences, no explanation."""

    cmd = [
        "claude",
        "-p",
        prompt,
        "--output-format",
        "json",
        "--model",
        MODEL,
    ]

    env = {k: v for k, v in os.environ.items() if k != "CLAUDECODE"}

    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=120,
            env=env,
        )
        output = result.stdout.strip()

        # Parse the JSON response - might be wrapped in {"result": "..."}
        try:
            parsed = json.loads(output)
            if isinstance(parsed, dict) and "result" in parsed:
                # claude --output-format json wraps in {"result": "..."}
                inner = parsed["result"]
                # Try to extract JSON array from the text
                match = re.search(r"\[.*\]", inner, re.DOTALL)
                if match:
                    return json.loads(match.group())
            elif isinstance(parsed, list):
                return parsed
        except json.JSONDecodeError:
            # Try to find array in raw output
            match = re.search(r"\[.*\]", output, re.DOTALL)
            if match:
                return json.loads(match.group())

        print(f"  Could not parse output for {name}", file=sys.stderr)
        return None

    except subprocess.TimeoutExpired:
        print(f"  Timeout generating eval set for {name}", file=sys.stderr)
        return None
    except Exception as e:
        print(f"  Error for {name}: {e}", file=sys.stderr)
        return None


def process_skill(skill_dir: Path) -> tuple[str, bool]:
    name = skill_dir.name
    output_path = OUTPUT_DIR / f"{name}.json"

    if output_path.exists():
        return name, True  # already done

    info = get_skill_info(skill_dir)
    if not info or not info["description"]:
        return name, False

    eval_set = generate_eval_set(info)
    if eval_set and len(eval_set) >= 10:
        output_path.write_text(json.dumps(eval_set, indent=2))
        return name, True
    return name, False


def main():
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    skills = sorted(
        d for d in SKILLS_DIR.iterdir() if d.is_dir() and (d / "SKILL.md").exists()
    )
    print(
        f"Generating eval sets for {len(skills)} skills (max {MAX_WORKERS} parallel)..."
    )

    success = 0
    failed = 0

    with ThreadPoolExecutor(max_workers=MAX_WORKERS) as pool:
        futures = {pool.submit(process_skill, s): s.name for s in skills}
        for future in as_completed(futures):
            name = futures[future]
            try:
                _, ok = future.result()
                if ok:
                    success += 1
                    print(f"  OK: {name}")
                else:
                    failed += 1
                    print(f"  FAIL: {name}")
            except Exception as e:
                failed += 1
                print(f"  ERROR: {name} — {e}")

    print(f"\nDone. {success} succeeded, {failed} failed.")


if __name__ == "__main__":
    main()
