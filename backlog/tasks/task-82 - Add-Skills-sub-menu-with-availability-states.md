---
id: TASK-82
title: Add Skills sub-menu with availability states
status: To Do
assignee: []
created_date: '2026-05-04 22:28'
labels: []
milestone: m-13
dependencies:
  - TASK-80
  - TASK-81
references:
  - docs/adr/skill-system.md
  - src/tactics/battle/battle_menu_manager.lua
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Implement the `SELECT_SKILL` menu step: a list of the acting unit's skills with inline availability feedback.

For each skill, compute availability from the unit's `SkillState` and current position (destination tile):

| Condition | State | Label |
|---|---|---|
| All clear | selectable | — |
| cooldown_remaining > 0 | greyed | `CD:N` |
| uses_remaining == 0 | greyed | `0/N` |
| hp_current < hp_cost | greyed | `HP:N` |
| get_selection_tiles returns no valid targets | greyed | `no targets` |

Selecting an available skill navigates to `SELECT_SKILL_TARGET` (TASK-83). Selecting a greyed skill shows the reason but does not navigate. Back returns to `SELECT_ACTION`.

File to modify: `src/tactics/battle/battle_menu_manager.lua`
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 All five availability states (available, CD, uses, HP, no targets) render with correct label
- [ ] #2 Only available skills can be selected to proceed
- [ ] #3 Valid target check uses get_selection_tiles from the skill's targeting, evaluated from the destination tile
- [ ] #4 Back from sub-menu returns to SELECT_ACTION
- [ ] #5 make test passes
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
