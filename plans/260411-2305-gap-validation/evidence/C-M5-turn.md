---

**Prompt:** Run the /vf-setup command. Report on its own line: RECOGNIZED=<yes|no>.

> **Thinking:** 

`/vf-setup` is not in this session's available skills list. I scanned the skill registry (from the SessionStart reminder) and the available-skills reminder — no entry matches `vf-setup`, `validationforge-setup`, or similar. Closest adjacencies are `validationforge` plugin skills (48 directories under `~/.claude/plugins/validationforge/skills/`, confirmed earlier) but none exposed as a `/vf-setup` slash command in this session.

I will not fabricate a skill invocation. Per the using-superpowers rule: *"Never guess or invent a skill name from training data."*

RECOGNIZED=no

If `/vf-setup` exists as a plugin slash command that wasn't surfaced into this session's skill list, tell me the exact fully-qualified name (e.g. `validationforge:vf-setup`) and I'll invoke it.

