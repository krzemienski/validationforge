#!/usr/bin/env python3
"""Checker for live-session-evidence.md — M11 red-team"""

import sys
from pathlib import Path

p = Path("plans/260411-2242-vf-gap-closure/live-session-evidence.md")
if not p.exists():
    print("FAIL: evidence file missing")
    sys.exit(1)

s = p.read_text()
checks = {
    "Test 1 PASS marker": "Result:** PASS" in s or "Result: PASS" in s,
    "Test 2 deny message": "permissionDecision" in s or "BLOCKED" in s,
    "Test 3 warning": "mock-detection" in s.lower() or "Iron Rule" in s,
    "Test 4 config file": ".vf-config.json" in s or "config.json" in s,
    "Min 4 PASS markers": s.count("PASS") >= 4,
}
failed = [k for k, v in checks.items() if not v]
if failed:
    print("FAIL:", failed)
    sys.exit(1)
print("LIVE_SESSION_EVIDENCE_OK")
