---
id: TASK-105
title: >-
  Extend MissionFactory to receive MapContext and merge point_labels after map
  load
status: To Do
assignee: []
created_date: '2026-05-09 17:00'
labels: []
milestone: m-16
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The mission factory (`MissionFactory` alias in `src/tactics/battle/definition.lua:7`) currently receives only `(CampaignConfig, CampaignRngContext)`. To let factories expand rect zones into tile positions, they need access to the rect zones parsed from the map (TASK-103).

Changes needed:

**Types** (`src/tactics/battle/definition.lua`, `mods/types.d.lua`):
- New type `MapContext { rect_zones: table<string, RectZone> }`.
- Update `MissionFactory` alias to `fun(CampaignConfig, CampaignRngContext, MapContext): MissionDefinition`.
- Add optional field `point_labels table<TileLabel, Point[]>` to `MissionDefinition` (parallel to the existing `tile_labels` which carries metatile indices).

**Load order in `src/tactics/battle/battle_manager.lua` (around line 84)**:
Current order: call factory → load map.
New order:
1. Load map → `battle_map` (unchanged, uses `battle_def.tile_labels` metatile indices).
2. Build `map_context = { rect_zones = battle_map.rect_zones }`.
3. Call factory with `(campaign_config, rng_context, map_context)` → `battle_def`.
4. Merge `battle_def.point_labels` into `battle_map.tile_labels` (simple table merge).

Wait — the factory needs rect_zones before the map loads, but rect_zones come from the map. Resolution: add a lightweight `map_generator.extract_rect_zones(map_id) → table<string, RectZone>` that reads only the object layer (no full map load), called before the factory, then the full `load_map` proceeds as normal.

All existing factories that accept two args remain valid (Lua ignores extra args).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 MissionFactory type annotation reflects three-arg signature.
- [ ] #2 battle_manager passes a populated map_context to the factory.
- [ ] #3 point_labels returned by the factory are merged into BattleMap.tile_labels before battle start.
- [ ] #4 Existing missions (skirmish, abandoned_fortress_seize) work unchanged — make test green.
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
