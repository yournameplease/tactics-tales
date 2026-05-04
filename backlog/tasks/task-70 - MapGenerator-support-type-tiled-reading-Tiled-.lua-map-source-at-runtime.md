---
id: TASK-70
title: 'MapGenerator: support type="tiled" reading Tiled .lua map source at runtime'
status: To Do
assignee: []
created_date: '2026-05-04 04:33'
labels: []
milestone: m-9
dependencies:
  - TASK-69
priority: high
ordinal: 6000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Add a `type = "tiled"` branch to `map_generator.lua` that reads a Tiled `.lua` export directly at runtime and produces the same `MapLayers` struct as the existing static path. This supersedes the tile-layer portion of TASK-47 (spawn data handling remains in TASK-47).

**Files to modify:**
- `src/tactics/battle/map/map_generator.lua`

**New map definition type:**
```lua
---@class TiledMapDefinition : MapDefinition
---@field type "tiled"
---@field file string  -- path to Tiled .lua file (no extension), relative to mod root
```

**Loading behaviour:**
1. `include` the Tiled `.lua` file
2. Build `tileset_bases`: for each tileset entry, strip extension from `filename` to get the stem, look up `gfx_registry[stem]` to get the base sprite index
3. For each tile layer, convert tile IDs: `sprite = base + (tile_id - firstgid)` where `base` comes from whichever tileset owns that tile ID
4. Tile dimensions come from the Tiled source's `tilewidth` / `tileheight` (not STATIC_CONFIG)
5. Layer names match the existing renderer: `ground` is required; `front_walls`, `mid_walls`, `back_walls`, `metatiles`, `ceiling` are optional (nil if absent)
6. Return the same `MapLayers` struct used by the static path

`gfx_registry` must be passed into the load function alongside the map definition (threaded from `game_data`).

The existing `static` path and all existing tests must remain unaffected.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 map_generator handles type="tiled" map definitions
- [ ] #2 Tile IDs are converted to Picotron sprite indices using: base + (tile_id - firstgid)
- [ ] #3 Tileset base index is looked up from gfx_registry by filename stem
- [ ] #4 Tile dimensions are read from tilewidth/tileheight in the Tiled source
- [ ] #5 ground layer is required; missing optional layers produce nil in MapLayers without error
- [ ] #6 The returned MapLayers struct is compatible with the existing BattleMap/renderer
- [ ] #7 The existing static path is unchanged and all existing tests pass
- [ ] #8 make test passes
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
