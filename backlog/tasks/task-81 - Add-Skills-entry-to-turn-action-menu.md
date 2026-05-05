---
id: TASK-81
title: Add Skills entry to turn action menu
status: Done
assignee: []
created_date: '2026-05-04 22:28'
updated_date: '2026-05-05 00:13'
labels: []
milestone: m-13
dependencies:
  - TASK-79
references:
  - docs/adr/skill-system.md
  - src/tactics/battle/battle_menu_manager.lua
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Add a "Skills" option to the `SELECT_ACTION` menu step in `battle_menu_manager.lua`.

The entry is **hidden entirely** (not greyed) when the acting unit has no skills (`#unit.character.skill_loadout == 0`). When visible, selecting it navigates to a new `SELECT_SKILL` menu step (to be implemented in TASK-82).

This task only covers adding the conditional menu entry and the navigation target — the sub-menu content itself is a separate task.

File to modify: `src/tactics/battle/battle_menu_manager.lua`
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Acting unit with skills shows a Skills option in the action menu
- [ ] #2 Acting unit with no skills shows no Skills option
- [ ] #3 Selecting Skills navigates to the SELECT_SKILL step
- [ ] #4 Attack and Wait entries are unaffected
- [ ] #5 make test passes
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
