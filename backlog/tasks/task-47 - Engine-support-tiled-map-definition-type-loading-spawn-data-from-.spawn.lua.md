---
id: TASK-47
title: 'Engine: support tiled map definition type loading spawn data from .spawn.lua'
status: To Do
assignee: []
created_date: '2026-04-28 03:10'
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
Extend `src/tactics/battle/map/map_generator.lua` to support a new `"tiled"` map definition type that populates `BattleMap.tile_labels` from a `.spawn.lua` file instead of the metatile layer. The existing `"static"` type and all existing tests must remain unaffected.

**New map definition type:**
```lua
---@class TiledMapDefinition : MapDefinition
---@field type "tiled"
---@field file string       -- path to Picotron .map file (tile graphics)
---@field spawn_file string -- path to .spawn.lua
```

**New BattleDefinition field:**
```lua
---@field active_variants? table<string, string>
-- set_name → selected variant layer name
-- e.g. { corner = "corner_horde" }
```

**Loading behaviour for `type = "tiled"`:**
1. Load tile layers from `.map` file (same as static — no metatile layer needed)
2. Load `.spawn.lua`
3. Populate `BattleMap.tile_labels` from `spawn_data.labels` (always-active)
4. For each `active_variants` entry, merge the selected variant's `labels` into `tile_labels`
5. Expose the active variant metadata (e.g. `turncoat_eligible`) — either on `BattleMap` or via a helper accessible from battle scripts/factories

`BattleDefinition.tile_labels` is ignored for `tiled` maps (it's only used by the metatile path).

**Spawn point coordinate format:** `{x, y, slot?, facing?, ai_hint?}` — these extra fields must be accessible from the `tile_labels` points so battle definitions can read `slot` and `ai_hint` when building `UnitSpawnData`.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 map_generator.load_map handles type="tiled" map definitions
- [ ] #2 Always-active labels from .spawn.lua labels table are available in BattleMap.tile_labels after load
- [ ] #3 active_variants selection merges the correct variant labels into BattleMap.tile_labels
- [ ] #4 Spawn point entries carry slot, facing, and ai_hint fields through to tile_labels so battle factories can read them
- [ ] #5 Active variant metadata (e.g. turncoat_eligible) is accessible from battle factory functions
- [ ] #6 The existing static/metatile path is unchanged and all existing tests pass
- [ ] #7 make test passes
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
