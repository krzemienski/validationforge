#!/usr/bin/env python3
"""Scaffold per-skill workspaces from audit JSON reports.

For each audit JSON, creates:
  <plugin-root>/skill-audit-workspace/<skill-name>/
    ├── skill-snapshot/           (copy of current skill dir)
    ├── evals/
    │   └── evals.json            (top 2 test prompts from audit)
    └── iteration-1/
        ├── eval-0-<slug>/
        │   ├── eval_metadata.json
        │   ├── with_skill/outputs/
        │   └── old_skill/outputs/
        └── eval-1-<slug>/
            ├── eval_metadata.json
            ├── with_skill/outputs/
            └── old_skill/outputs/

Idempotent: safe to re-run. Will not overwrite snapshot if it exists.
"""

import json
import os
import re
import shutil
import sys
from pathlib import Path

ROOT = Path("/Users/nick/Desktop/validationforge")
SKILLS_DIR = ROOT / "skills"
REPORTS_DIR = ROOT / "skill-audit-workspace" / "_reports"
WORKSPACE_ROOT = ROOT / "skill-audit-workspace"


def slugify(text: str, max_len: int = 40) -> str:
    s = re.sub(r"[^a-z0-9]+", "-", text.lower())[:max_len].strip("-")
    return s or "eval"


def scaffold_skill(audit_path: Path) -> dict:
    with audit_path.open() as f:
        audit = json.load(f)
    skill_name = audit["skill_name"]
    skill_dir = SKILLS_DIR / skill_name
    if not skill_dir.exists():
        return {"skill": skill_name, "status": "missing_source", "path": str(skill_dir)}

    ws = WORKSPACE_ROOT / skill_name
    ws.mkdir(exist_ok=True)

    snap = ws / "skill-snapshot"
    if not snap.exists():
        shutil.copytree(skill_dir, snap)

    prompts = audit.get("test_prompts", [])[:2]
    if len(prompts) < 2:
        return {
            "skill": skill_name,
            "status": "insufficient_prompts",
            "have": len(prompts),
        }

    evals_dir = ws / "evals"
    evals_dir.mkdir(exist_ok=True)
    evals_obj = {
        "skill_name": skill_name,
        "evals": [
            {
                "id": p["id"],
                "prompt": p["prompt"],
                "expected_output": p.get("expected_output", ""),
                "files": [],
            }
            for p in prompts
        ],
    }
    (evals_dir / "evals.json").write_text(json.dumps(evals_obj, indent=2))

    iter_dir = ws / "iteration-1"
    iter_dir.mkdir(exist_ok=True)
    eval_names = []
    for idx, p in enumerate(prompts):
        basis = p.get("expected_output") or p["prompt"]
        first_words = " ".join(basis.split()[:6])
        eval_name = slugify(first_words)
        eval_dir = iter_dir / f"eval-{idx}-{eval_name}"
        (eval_dir / "with_skill" / "outputs").mkdir(parents=True, exist_ok=True)
        (eval_dir / "old_skill" / "outputs").mkdir(parents=True, exist_ok=True)
        meta = {
            "eval_id": idx,
            "eval_name": eval_name,
            "prompt": p["prompt"],
            "expected_output": p.get("expected_output", ""),
            "assertions": [],
        }
        (eval_dir / "eval_metadata.json").write_text(json.dumps(meta, indent=2))
        eval_names.append(eval_dir.name)

    return {
        "skill": skill_name,
        "status": "ok",
        "workspace": str(ws),
        "evals": eval_names,
        "priority": audit.get("priority", "unknown"),
    }


def main():
    results = []
    audits = sorted(REPORTS_DIR.glob("*.audit.json"))
    for a in audits:
        results.append(scaffold_skill(a))

    summary_path = WORKSPACE_ROOT / "_pipeline" / "scaffold-summary.json"
    summary_path.write_text(json.dumps(results, indent=2))
    ok = sum(1 for r in results if r["status"] == "ok")
    print(f"Scaffolded {ok}/{len(results)} skills. Summary: {summary_path}")
    bad = [r for r in results if r["status"] != "ok"]
    if bad:
        print("Issues:")
        for r in bad:
            print(" ", r)


if __name__ == "__main__":
    main()
