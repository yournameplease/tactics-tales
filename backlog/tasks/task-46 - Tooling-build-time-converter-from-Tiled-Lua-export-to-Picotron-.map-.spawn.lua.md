---
id: TASK-46
title: >-
  Tooling: build-time converter from Tiled Lua export to Picotron .map +
  .spawn.lua
status: To Do
assignee: []
created_date: '2026-04-28 03:09'
labels: []
milestone: m-9
dependencies:
  - TASK-45
priority: high
ordinal: 2000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
A Picotron utility cart at `tools/tiled_convert.p64` that reads a Tiled Lua export and a `_meta.lua` sidecar and writes a Picotron `.map` file and a `.spawn.lua` coordinate table. Running inside Picotron gives native access to the `.map` binary format.

**Inputs:**
- Tiled Lua export (e.g. `playground.lua`) — produced by Tiled's "Export As > Lua" option
- `playground_meta.lua` sidecar — declares variant sets and per-variant flags

**Outputs:**
1. `playground.map` — Picotron map file with tile layers
2. `playground.spawn.lua` — spawn coordinate table

**`.spawn.lua` format:**
```lua
return {
    labels = {
        -- always-active groups (not in any variant_set)
        player_deployment = { {x=1,y=7}, {x=2,y=7} },
        enemy_cmdr        = { {x=12,y=4}, slot="enemy_commander", ai_hint="stationary" },
    },
    variant_sets = {
        corner = {
            corner_strong = {
                turncoat_eligible = false,
                labels = { corner_heavy = { {x=15,y=3, ai_hint="stationary"} } },
            },
            corner_horde = {
                turncoat_eligible = true,
                labels = { corner_light = { {x=14,y=3}, {x=15,y=3} } },
                from = "west",
            },
        }
    }
}
```

**Coordinate conversion:** pixel position from Tiled object ÷ tile size = tile-grid position.

**Property forwarding:**
- Per-object: `slot`, `facing`, `ai_hint` copied onto each coordinate entry
- Per-layer: `from` copied onto the group entry in `.spawn.lua`
- Object layers listed under a variant set in `_meta.lua` go under `variant_sets`; all others go under `labels`
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Converter reads tile layers from Tiled Lua export and writes them to a Picotron .map with correct layer names
- [ ] #2 Converter reads object layer point objects and resolves pixel coordinates to tile-grid {x,y} positions
- [ ] #3 Per-object properties (slot, facing, ai_hint) are preserved on each coordinate entry in .spawn.lua
- [ ] #4 Per-layer property `from` is preserved on group entries in .spawn.lua
- [ ] #5 Object layers declared in _meta.lua variant_sets appear under variant_sets in .spawn.lua; all others appear under labels
- [ ] #6 Per-variant flags (e.g. turncoat_eligible) from _meta.lua are preserved in .spawn.lua variant_sets
- [ ] #7 Running the converter on the playground sample produces a .map and .spawn.lua that match the original map's visual layout and spawn positions
- [ ] #8 make test passes
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
