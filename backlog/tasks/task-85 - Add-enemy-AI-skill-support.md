---
id: TASK-85
title: Add enemy AI skill support
status: To Do
assignee: []
created_date: '2026-05-04 22:29'
labels: []
milestone: m-13
dependencies:
  - TASK-79
  - TASK-84
references:
  - docs/adr/skill-system.md
  - src/tactics/battle/unit/unit_ai.lua
  - src/tactics/battle/tactics/ai_engine.lua
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Extend the AI system so enemy units with skills can use them on their turns.

**UnitAI type** (`src/tactics/battle/unit/unit_ai.lua`):
Add `skill_priority?: "prefer" | "fallback"`. When nil, AI ignores skills entirely (existing behavior preserved).

**AI engine** (`src/tactics/battle/tactics/ai_engine.lua`):
In `compute_unit_ai()`, when `unit_ai.skill_priority` is set, evaluate available skills alongside attack options:
- Find all reachable tiles (existing movement logic)
- For each reachable tile, check each available skill's `get_selection_tiles` for valid targets
- `"prefer"`: if any skill has a valid target, use the skill; else fall back to attack
- `"fallback"`: if an attack is possible, attack; else use skill if a valid target exists
- When using a skill, dispatch to `handle_skill()` (TASK-84)

"Available" means: `cooldown_remaining == 0`, `uses_remaining ~= 0`, `hp_current >= hp_cost`.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Enemy unit with skill_priority=nil behaves identically to current AI (no regression)
- [ ] #2 Enemy with skill_priority="prefer" uses skill when a valid target is reachable, else attacks
- [ ] #3 Enemy with skill_priority="fallback" attacks when possible, uses skill only when no attack target exists
- [ ] #4 make test passes
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
