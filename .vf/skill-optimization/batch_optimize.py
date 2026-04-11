#!/usr/bin/env python3
"""
Batch skill description optimizer.
Runs scripts.run_loop on each VF skill sequentially with checkpointing.
"""

import json
import os
import subprocess
import sys
import time
from pathlib import Path

SKILLS_DIR = Path("/Users/nick/Desktop/validationforge/skills")
WORKSPACE = Path("/Users/nick/Desktop/validationforge/.vf/skill-optimization")
SKILL_CREATOR = Path("/Users/nick/.claude/skills/skill-creator")
PROJECT_ROOT = Path("/Users/nick/Desktop/validationforge")
MODEL = "claude-sonnet-4-6"
MAX_ITERATIONS = 5
RUNS_PER_QUERY = 3

CHECKPOINT = WORKSPACE / "checkpoint.json"
SUMMARY = WORKSPACE / "summary.json"


def load_checkpoint():
    if CHECKPOINT.exists():
        return json.loads(CHECKPOINT.read_text())
    return {"completed": [], "failed": [], "skipped": [], "improved": []}


def save_checkpoint(state):
    CHECKPOINT.write_text(json.dumps(state, indent=2))


def get_skill_description(skill_dir: Path) -> str | None:
    skill_md = skill_dir / "SKILL.md"
    if not skill_md.exists():
        return None
    lines = skill_md.read_text().split("\n")
    in_frontmatter = False
    desc_lines = []
    capturing_desc = False
    for line in lines:
        if line.strip() == "---":
            if in_frontmatter:
                break
            in_frontmatter = True
            continue
        if in_frontmatter:
            if line.startswith("description:"):
                rest = line[len("description:") :].strip()
                if rest.startswith(">") or rest.startswith("|"):
                    capturing_desc = True
                    continue
                elif rest.startswith('"') or rest.startswith("'"):
                    return rest.strip("\"'")
                else:
                    return rest
            elif capturing_desc:
                if line and (line[0] == " " or line[0] == "\t"):
                    desc_lines.append(line.strip())
                else:
                    capturing_desc = False
    return " ".join(desc_lines) if desc_lines else None


def update_skill_description(skill_dir: Path, new_desc: str):
    """Replace the description in SKILL.md frontmatter."""
    skill_md = skill_dir / "SKILL.md"
    content = skill_md.read_text()
    lines = content.split("\n")

    result = []
    in_frontmatter = False
    in_desc = False
    desc_replaced = False

    for i, line in enumerate(lines):
        if line.strip() == "---":
            if not in_frontmatter:
                in_frontmatter = True
                result.append(line)
                continue
            else:
                if in_desc:
                    in_desc = False
                in_frontmatter = False
                result.append(line)
                continue

        if in_frontmatter and not desc_replaced:
            if line.startswith("description:"):
                # Check if multiline
                rest = line[len("description:") :].strip()
                if rest.startswith(">") or rest.startswith("|"):
                    in_desc = True
                    # Replace with single-line
                    escaped = new_desc.replace('"', '\\"')
                    result.append(f'description: "{escaped}"')
                    desc_replaced = True
                    continue
                else:
                    escaped = new_desc.replace('"', '\\"')
                    result.append(f'description: "{escaped}"')
                    desc_replaced = True
                    continue
            elif in_desc:
                if line and (line[0] == " " or line[0] == "\t"):
                    continue  # skip old multiline desc
                else:
                    in_desc = False
                    desc_replaced = True
                    result.append(line)
                    continue

        result.append(line)

    skill_md.write_text("\n".join(result))


def run_optimization(
    skill_name: str, eval_set_path: Path, skill_path: Path, results_dir: Path
):
    """Run the optimization loop for a single skill."""
    cmd = [
        sys.executable,
        "-m",
        "scripts.run_loop",
        "--eval-set",
        str(eval_set_path),
        "--skill-path",
        str(skill_path),
        "--model",
        MODEL,
        "--max-iterations",
        str(MAX_ITERATIONS),
        "--runs-per-query",
        str(RUNS_PER_QUERY),
        "--verbose",
        "--report",
        "none",
        "--results-dir",
        str(results_dir),
    ]

    env = {k: v for k, v in os.environ.items() if k != "CLAUDECODE"}

    proc = subprocess.run(
        cmd,
        cwd=str(SKILL_CREATOR),
        capture_output=True,
        text=True,
        timeout=1800,  # 30 min max per skill
        env=env,
    )

    # Parse results from results_dir
    results_json = None
    if results_dir.exists():
        for d in sorted(results_dir.iterdir()):
            rj = d / "results.json"
            if rj.exists():
                results_json = json.loads(rj.read_text())

    return proc.returncode, proc.stdout, proc.stderr, results_json


def main():
    state = load_checkpoint()
    completed_set = set(state["completed"] + state["failed"] + state["skipped"])

    skills = sorted(
        d.name for d in SKILLS_DIR.iterdir() if d.is_dir() and (d / "SKILL.md").exists()
    )
    remaining = [s for s in skills if s not in completed_set]

    print(f"Total skills: {len(skills)}")
    print(f"Already done: {len(completed_set)}")
    print(f"Remaining: {len(remaining)}")
    print()

    for i, skill_name in enumerate(remaining):
        skill_path = SKILLS_DIR / skill_name
        eval_set_path = WORKSPACE / "eval-sets" / f"{skill_name}.json"
        results_dir = WORKSPACE / "results" / skill_name

        print(f"[{i + 1}/{len(remaining)}] {skill_name}")

        if not eval_set_path.exists():
            print(f"  SKIP: no eval set at {eval_set_path}")
            state["skipped"].append(skill_name)
            save_checkpoint(state)
            continue

        desc_before = get_skill_description(skill_path)
        if not desc_before:
            print(f"  SKIP: could not parse description")
            state["skipped"].append(skill_name)
            save_checkpoint(state)
            continue

        results_dir.mkdir(parents=True, exist_ok=True)

        try:
            returncode, stdout, stderr, results = run_optimization(
                skill_name, eval_set_path, skill_path, results_dir
            )
        except subprocess.TimeoutExpired:
            print(f"  TIMEOUT after 30min")
            state["failed"].append(skill_name)
            save_checkpoint(state)
            continue
        except Exception as e:
            print(f"  ERROR: {e}")
            state["failed"].append(skill_name)
            save_checkpoint(state)
            continue

        if results and results.get("best_description"):
            best = results["best_description"]
            test_score = results.get("test_score", 0)
            baseline_score = results.get("baseline_test_score", 0)

            if test_score > baseline_score:
                update_skill_description(skill_path, best)
                print(f"  IMPROVED: {baseline_score:.0%} → {test_score:.0%}")
                state["improved"].append(
                    {
                        "skill": skill_name,
                        "before": desc_before,
                        "after": best,
                        "baseline_score": baseline_score,
                        "new_score": test_score,
                    }
                )
            else:
                print(
                    f"  NO IMPROVEMENT: baseline={baseline_score:.0%}, new={test_score:.0%}"
                )
        else:
            print(f"  NO RESULT (returncode={returncode})")
            if stderr:
                # Save stderr for debugging
                (results_dir / "stderr.txt").write_text(stderr[-2000:])

        state["completed"].append(skill_name)
        save_checkpoint(state)
        print()

    # Write final summary
    summary = {
        "total": len(skills),
        "completed": len(state["completed"]),
        "improved": len(state["improved"]),
        "failed": len(state["failed"]),
        "skipped": len(state["skipped"]),
        "improvements": state["improved"],
    }
    SUMMARY.write_text(json.dumps(summary, indent=2))
    print(
        f"\nDone. {len(state['improved'])} skills improved out of {len(state['completed'])} completed."
    )
    print(f"Summary at {SUMMARY}")


if __name__ == "__main__":
    main()
