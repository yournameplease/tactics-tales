---
id: TASK-13
title: Update tactics_map renderer for camera offset and viewport culling
status: To Do
assignee: []
created_date: '2026-04-25 21:34'
labels: []
milestone: m-2
dependencies:
  - TASK-11
priority: high
ordinal: 4000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Rework `src/tactics/ui/panels/tactics_map.lua` to render only the visible viewport using the camera offset from `BattleUIContext`.

**Ground/highlight/path layers:** Replace full-map `map()` calls with tile-offset + sub-tile draw-target shift:
- Compute `tile_ox = flr(camera_x / TILE_WIDTH)`, `tile_oy = flr(camera_y / TILE_HEIGHT)`
- Compute sub-tile pixel shift `px = -(camera_x % TILE_WIDTH)`, `py = -(camera_y % TILE_HEIGHT)`
- Call `map(layer, tile_ox, tile_oy, px, py, VIEWPORT_WIDTH + 1, VIEWPORT_HEIGHT + 1, ...)` (one extra tile for overdraw)
- Adjust draw target offset accordingly

**Unit culling:** After computing animated positions, discard units whose pixel position falls outside `[camera_x - TILE_WIDTH, camera_x + VIEWPORT_WIDTH * TILE_WIDTH + TILE_WIDTH]` (and same for y) before building sorted_units userdata.

**Unit draw positions:** Subtract `camera_x`/`camera_y` from each unit's world pixel position before drawing.

**Wall decorations:** Clamp `draw_map_decorations` z-range to `[camera_y, camera_y + VIEWPORT_HEIGHT * TILE_HEIGHT]`; subtract `camera_y` from draw y offsets. Replace hardcoded `MAP_HEIGHT * TILE_SIZE.y` sentinel with `battle_map.height * TILE_HEIGHT`.

**Panel size:** `tactics_map.new` should use `VIEWPORT_WIDTH`/`VIEWPORT_HEIGHT` instead of `map_width`/`map_height` for computing panel pixel dimensions.

Replace all remaining references to `MAP_WIDTH`/`MAP_HEIGHT` locals with `VIEWPORT_WIDTH`/`VIEWPORT_HEIGHT` or `battle_map.width`/`battle_map.height` as appropriate.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 A 16x16 map renders identically to before (no visual regression)
- [ ] #2 On a larger map, only tiles within the viewport are drawn
- [ ] #3 Units outside the viewport are not rendered
- [ ] #4 Wall decorations render correctly at all camera positions
- [ ] #5 Panel pixel dimensions are unchanged (still 16x16 tiles)
- [ ] #6 make test passes
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
