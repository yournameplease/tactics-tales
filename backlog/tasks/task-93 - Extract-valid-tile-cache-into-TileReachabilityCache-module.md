---
id: TASK-93
title: Extract valid tile cache into TileReachabilityCache module
status: To Do
assignee: []
created_date: '2026-05-05 13:29'
labels: []
milestone: m-14
dependencies: []
references:
  - src/tactics/battle/tactics/tactics_engine.lua
  - src/tactics/battle/pathfinding.lua
  - src/tactics/battle/battle_map.lua
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Six methods in TacticsEngine form a cohesive subsystem for computing and caching which tiles a unit can reach or attack (tactics_engine.lua:879–1028): `tiles_with_distance_from_unit_attacks`, `tiles_in_movement_and_attack_range_for_unit`, `get_valid_tiles_for_unit`, `invalidate_tiles_for_unit`, `invalidate_tiles_for_point`, `recompute_marked_unit_tiles`. The cache state (`valid_tiles_by_unit`, `marked_unit_tiles`, `marked_unit_revision`) also belongs here.

Extract to `src/tactics/battle/tile_reachability_cache.lua`. Dependencies are `BattleMap` and `pathfinding` — both real modules that can be supplied in tests using small synthetic maps, with no full TacticsEngine needed.

The mark/unmark handlers (`handle_mark_unit`, `handle_mark_all_units`, `handle_unmark_all_units`) consume the cache; leave them in TacticsEngine but have them call into the new module.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 New module exports `TileReachabilityCache.new(battle_map)` with get/invalidate-by-unit and invalidate-by-point on its interface
- [ ] #2 TacticsEngine holds a TileReachabilityCache instance and removes the inlined implementations
- [ ] #3 Unit tests use a real (small) BattleMap: cache miss computes tiles; second call returns cached value; invalidate-by-point evicts units within movement range; dead unit evicted on next invalidation pass
- [ ] #4 make test passes
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
