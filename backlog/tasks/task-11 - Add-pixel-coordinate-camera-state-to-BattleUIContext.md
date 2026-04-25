---
id: TASK-11
title: Add pixel-coordinate camera state to BattleUIContext
status: To Do
assignee: []
created_date: '2026-04-25 21:34'
labels: []
milestone: m-2
dependencies:
  - TASK-10
priority: high
ordinal: 2000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Add `camera_x` and `camera_y` (pixel coordinates, integers) to `BattleUIContext` in `src/tactics/battle/battle_ui_context.lua`. Initialize to `0, 0`.

Add a `move_camera(battle_map, target_tile, dead_zone)` helper that:
1. Converts `target_tile` to pixel center
2. Computes the desired camera position to keep target within dead zone (in tiles) from viewport edges
3. Clamps result to `[0, (map.width - VIEWPORT_WIDTH) * TILE_WIDTH]` and `[0, (map.height - VIEWPORT_HEIGHT) * TILE_HEIGHT]`
4. Snaps immediately (no interpolation — TODO comment for future smooth scrolling)

Also expose a `clamp_camera(battle_map)` utility that clamps the current camera to valid bounds (needed after map load).

Files to modify:
- `src/tactics/battle/battle_ui_context.lua`
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 BattleUIContext has camera_x and camera_y fields initialized to 0
- [ ] #2 move_camera correctly keeps a tile within the dead zone band
- [ ] #3 move_camera clamps to map boundaries (no overshoot)
- [ ] #4 clamp_camera enforces bounds without changing the tile target
- [ ] #5 make test passes
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
