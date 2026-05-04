---
id: TASK-83
title: Add skill target selection step
status: To Do
assignee: []
created_date: '2026-05-04 22:28'
labels: []
milestone: m-13
dependencies:
  - TASK-82
references:
  - docs/adr/skill-system.md
  - src/tactics/battle/battle_menu_manager.lua
  - src/tactics/constants.lua
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Implement the `SELECT_SKILL_TARGET` menu step: tile-based target selection using the chosen skill's targeting functions.

On entry:
1. Call `skill.targeting.get_selection_tiles(unit_position, map)` to get candidate tiles
2. Highlight them using the existing `HIGHLIGHT` bitmask (reuse `IS_VALID` or `CAN_ATTACK` as appropriate)
3. Allow cursor navigation among highlighted tiles
4. Enforce `skill.targeting.is_target_valid` on confirmation

Confirming a valid tile stores the target and triggers skill execution (TASK-84). Back returns to `SELECT_SKILL`.

Files to modify: `src/tactics/battle/battle_menu_manager.lua`, possibly `src/tactics/battle/battle_ui_context.lua` if tile highlight helpers need extending.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Only tiles returned by get_selection_tiles are highlighted and selectable
- [ ] #2 is_target_valid is enforced at confirmation
- [ ] #3 Cursor navigates among valid tiles only
- [ ] #4 Back returns to SELECT_SKILL with the same skill selected
- [ ] #5 Confirming a target triggers skill execution
- [ ] #6 make test passes
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
