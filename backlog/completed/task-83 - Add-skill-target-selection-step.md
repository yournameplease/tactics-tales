---
id: TASK-83
title: Add skill target selection step
status: Done
assignee: []
created_date: '2026-05-04 22:28'
updated_date: '2026-05-05 00:43'
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
- [x] #1 Only tiles returned by get_selection_tiles are highlighted and selectable
- [x] #2 is_target_valid is enforced at confirmation
- [x] #3 Cursor navigates among valid tiles only
- [x] #4 Back returns to SELECT_SKILL with the same skill selected
- [x] #5 Confirming a target triggers skill execution
- [x] #6 make test passes
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [x] #1 All acceptance criteria met
- [x] #2 make test passes
<!-- DOD:END -->
