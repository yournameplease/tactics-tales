---
id: TASK-79
title: Add skill state to BattleUnit
status: Done
assignee: []
created_date: '2026-05-04 22:28'
updated_date: '2026-05-04 23:29'
labels: []
milestone: m-13
dependencies:
  - TASK-76
  - TASK-77
  - TASK-78
references:
  - docs/adr/skill-system.md
  - src/tactics/battle/tactics/battle_unit.lua
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Add per-skill battle-instance state to `BattleUnit` so cooldown and uses can be tracked during a battle.

File to modify: `src/tactics/battle/tactics/battle_unit.lua`

Add field `skill_states: table<string, SkillState>` to `BattleUnit`. Initialize in `spawn_unit()` by iterating `permanent_unit.character.skill_loadout`:
- Each skill_id gets `cooldown_remaining = 0`, `uses_remaining = game_data.skills[skill_id].uses_per_battle` (nil if `uses_per_battle` is nil).

`spawn_unit` will need access to `game_data` (or the skill definitions) to read `uses_per_battle`. Check whether game_data is already threaded through the spawn path or needs to be passed in.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Spawned BattleUnit has skill_states table keyed by skill_id for every skill in its character's skill_loadout
- [x] #2 Initial cooldown_remaining is 0 for all skills
- [x] #3 Initial uses_remaining matches uses_per_battle from skill definition (nil if unlimited)
- [x] #4 Unit with no skill_loadout has empty skill_states table
- [x] #5 make test passes
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [x] #1 All acceptance criteria met
- [x] #2 make test passes
<!-- DOD:END -->
