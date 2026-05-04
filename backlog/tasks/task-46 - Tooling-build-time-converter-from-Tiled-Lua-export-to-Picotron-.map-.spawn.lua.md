---
id: TASK-46
title: >-
  Tooling: build-time converter from Tiled Lua export to Picotron .map +
  .spawn.lua
status: To Do
assignee: []
created_date: '2026-04-28 03:09'
updated_date: '2026-05-04 02:12'
labels: []
milestone: m-9
dependencies:
  - TASK-45
priority: high
ordinal: 2000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
A Picotron utility cart at `tools/tiled_convert.p64` that reads a Tiled Lua export and a `_meta.lua` sidecar and writes a Picotron `.map` file and a `.spawn.lua` Spawn File. PNG→.gfx conversion is handled by a separate spike task.

**Inputs:**
- Tiled Lua export (e.g. `abandoned_fortress.lua`) — produced by Tiled's "Export As > Lua" option
- `abandoned_fortress_meta.lua` sidecar — declares variant sets

**Outputs (written into the mod's game_data/):**
1. `game_data/maps/<name>.map` — Picotron map file with tile layers
2. `game_data/maps/<name>.spawn.lua` — Spawn File with Spawn Groups

**`.spawn.lua` format:**
```lua
return {
    labels = {
        deployment_defense = { {x=9, y=2}, {x=11, y=2} },
        boss_seize         = { {x=10, y=2, slot="enemy_commander", ai_hint="stationary"} },
        reinforce_west     = { from="west", {x=0, y=18}, {x=0, y=19} },
    },
    variant_sets = {}
}
```

**Coordinate conversion:** pixel position from Tiled object ÷ tile size = tile-grid position.

**Property forwarding (precedence: per-object overrides layer default):**
- Per-layer properties set defaults for all objects in the layer: `slot`, `facing`, `ai_hint` are copied onto each coordinate entry unless overridden per-object
- Per-object properties override layer defaults: `slot`, `facing`, `ai_hint` copied individually
- Per-layer `from` copied onto the group entry (not onto individual points)
- Object layers listed under a variant set in `_meta.lua` go under `variant_sets`; all others go under `labels`

**Coordinate conversion:** pixel position from Tiled object ÷ tile size = tile-grid position.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Converter reads tile layers from Tiled Lua export and writes them to a Picotron .map with correct layer names
- [ ] #2 Converter reads object layer point objects and resolves pixel coordinates to tile-grid {x,y} positions
- [ ] #3 Per-layer properties (slot, facing, ai_hint) are applied as defaults to all objects in the layer
- [ ] #4 Per-object properties override layer defaults on individual coordinate entries
- [ ] #5 Per-layer property `from` is preserved on group entries in .spawn.lua (not on individual points)
- [ ] #6 Object layers in _meta.lua variant_sets appear under variant_sets; all others under labels
- [ ] #7 Per-variant flags from _meta.lua are preserved in .spawn.lua variant_sets
- [ ] #8 Running the converter on abandoned_fortress produces .map and .spawn.lua matching the map's visual layout and spawn positions
- [ ] #9 make test passes
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
