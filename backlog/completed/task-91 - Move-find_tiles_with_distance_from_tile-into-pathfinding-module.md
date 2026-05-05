---
id: TASK-91
title: Move find_tiles_with_distance_from_tile into pathfinding module
status: Done
assignee: []
created_date: '2026-05-05 13:29'
updated_date: '2026-05-05 13:44'
labels: []
milestone: m-14
dependencies: []
references:
  - src/tactics/battle/tactics/tactics_engine.lua
  - src/tactics/battle/pathfinding.lua
  - src/spec/battle/pathfinding_spec.lua
priority: low
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The `find_tiles_with_distance_from_tile` method (tactics_engine.lua:916–947) is a pure function — given tile coords, a distance band, and map dimensions, it returns a 2D boolean array. It has no state dependency and belongs alongside the other distance/reachability functions in `pathfinding.lua`.

Also consider moving the `to_tile_path` local (tactics_engine.lua:141–149), which is similarly pure.

After extraction, `TacticsEngine` calls the public `pathfinding` function instead of its own method.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 pathfinding.lua exports a `tiles_with_distance_from_tile(tile_x, tile_y, min_distance, max_distance, map_w, map_h)` function
- [x] #2 TacticsEngine delegates to it rather than owning the implementation
- [x] #3 Unit tests cover: min==max (ring), min=0 (filled diamond), values clipped at map edges
- [x] #4 make test passes
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
