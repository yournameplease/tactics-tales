---
id: TASK-15
title: Fix battle_menu_manager grid cursor bounds to use live map dimensions
status: To Do
assignee: []
created_date: '2026-04-25 21:34'
labels: []
milestone: m-2
dependencies:
  - TASK-10
priority: high
ordinal: 6000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
In `src/tactics/battle/battle_menu_manager.lua`, all `grid.grid(id, MAP_WIDTH, MAP_HEIGHT)` calls use the old static constants. Replace each with `grid.grid(id, battle_map.width, battle_map.height)` so the cursor is clamped to the actual map dimensions.

`battle_menu_manager` already has access to `battle_map` — confirm the exact reference path and use it at the call sites on lines ~372, ~407, ~458, ~501, ~597.

Also remove the `local MAP_WIDTH`/`local MAP_HEIGHT` locals at the top of the file.

Files to modify:
- `src/tactics/battle/battle_menu_manager.lua`
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 No references to STATIC_CONFIG.MAP_WIDTH or MAP_HEIGHT remain in battle_menu_manager.lua
- [ ] #2 Cursor movement is clamped to battle_map.width / battle_map.height on all menu steps
- [ ] #3 make test passes
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
