---
id: TASK-80
title: Tick skill cooldowns at start of unit's turn
status: To Do
assignee: []
created_date: '2026-05-04 22:28'
labels: []
milestone: m-13
dependencies:
  - TASK-79
references:
  - docs/adr/skill-system.md
  - src/tactics/battle/tactics/tactics_engine.lua
  - src/tactics/battle/turn_manager.lua
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Decrement `cooldown_remaining` by 1 for each skill (where > 0) at the start of the acting unit's own turn.

Find the correct hook — likely in `src/tactics/battle/tactics/tactics_engine.lua` where a unit's turn begins, or in `src/tactics/battle/turn_manager.lua`. The decrement should happen before the player sees the action menu so the menu reflects updated availability.

Per the spec: a skill used on turn 1 with `cooldown = 2` sets `cooldown_remaining = 2`. On turn 2 the counter becomes 1 (unavailable). On turn 3 it becomes 0 (available again).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Skill with cooldown=2 has cooldown_remaining=2 immediately after use, 1 on the caster's next turn, 0 on the turn after that
- [ ] #2 Skills with cooldown_remaining=0 are not decremented below 0
- [ ] #3 Cooldown ticks only on the owning unit's turn, not on enemy turns
- [ ] #4 make test passes
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
