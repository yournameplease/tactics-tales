---
id: TASK-14
title: Fix mouse tile selection to account for camera offset
status: Done
assignee: []
created_date: '2026-04-25 21:34'
updated_date: '2026-04-25 23:55'
labels: []
milestone: m-2
dependencies:
  - TASK-13
priority: high
ordinal: 5000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The `get_selection_at` function in `src/tactics/ui/panels/tactics_map.lua` converts screen pixel position to tile coordinates. With a camera offset it must add `flr(camera_x / TILE_WIDTH)` and `flr(camera_y / TILE_HEIGHT)` to the computed tile, and clamp to `[0, battle_map.width)` / `[0, battle_map.height)` instead of the old `MAP_WIDTH`/`MAP_HEIGHT` constants.

`get_selection_at` needs access to `camera_x`/`camera_y` from `BattleUIContext` and the live map dimensions. Thread these through from `state.battle_context`.

Files to modify:
- `src/tactics/ui/panels/tactics_map.lua`
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Clicking a tile at the right edge of a scrolled viewport selects the correct map tile
- [x] #2 Clicking outside the map area returns nil
- [x] #3 make test passes
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
