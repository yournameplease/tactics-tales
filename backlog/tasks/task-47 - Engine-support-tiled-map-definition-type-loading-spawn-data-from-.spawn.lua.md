---
id: TASK-47
title: 'Engine: support tiled map definition type loading spawn data from .spawn.lua'
status: To Do
assignee: []
created_date: '2026-04-28 03:10'
updated_date: '2026-05-04 02:12'
labels: []
milestone: m-9
dependencies:
  - TASK-45
  - TASK-46
priority: high
ordinal: 3000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Extend `src/tactics/battle/map/map_generator.lua` to support a new `"tiled"` map definition type that populates `BattleMap.tile_labels` from a Spawn File (`.spawn.lua`) instead of the metatile layer. The existing `"static"` type and all existing tests must remain unaffected.

**New map definition type:**
```lua
---@class TiledMapDefinition : MapDefinition
---@field type "tiled"
---@field file string       -- path to Picotron .map file (tile graphics)
---@field spawn_file string -- path to .spawn.lua Spawn File
```

**New MissionDefinition fields:**
```lua
---@field active_labels? string[]
-- Spawn Group names to load from spawn_file.labels
-- e.g. { "deployment_defense", "boss_seize", "reinforce_west" }
-- If nil, all labels are loaded.

---@field active_variants? table<string, string>
-- set_name → selected variant Spawn Group name
-- e.g. { corner = "corner_horde" }
```

**Loading behaviour for `type = "tiled"`:**
1. Load tile layers from `.map` file (same as static — no metatile layer needed)
2. Load `.spawn.lua` Spawn File
3. If `active_labels` is set, load only those named Spawn Groups from `spawn_data.labels`; otherwise load all
4. For each `active_variants` entry, merge the selected variant's Spawn Groups into `tile_labels`
5. Expose active variant metadata (e.g. `turncoat_eligible`) on `BattleMap` or via a helper accessible from battle scripts/factories

`BattleDefinition.tile_labels` is ignored for `tiled` maps (it is only used by the metatile path).

**Spawn point coordinate format:** `{x, y, slot?, facing?, ai_hint?}` — extra fields must be accessible from `tile_labels` points so battle factories can read `slot` and `ai_hint` when building `UnitSpawnData`.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 map_generator.load_map handles type="tiled" map definitions
- [ ] #2 active_labels filters which Spawn Groups are loaded from spawn_data.labels (nil loads all)
- [ ] #3 Always-active Spawn Groups from .spawn.lua are available in BattleMap.tile_labels after load
- [ ] #4 active_variants selection merges the correct variant Spawn Groups into BattleMap.tile_labels
- [ ] #5 Spawn point entries carry slot, facing, and ai_hint fields through to tile_labels
- [ ] #6 Active variant metadata (e.g. turncoat_eligible) is accessible from battle factory functions
- [ ] #7 The existing static/metatile path is unchanged and all existing tests pass
- [ ] #8 make test passes
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
