---
id: TASK-46
title: >-
  Tiled map: extract object layers as spawn labels and update battle_manager
  spawn interface
status: Done
assignee: []
created_date: '2026-04-28 03:09'
updated_date: '2026-05-04 14:51'
labels: []
milestone: m-9
dependencies:
  - TASK-45
priority: high
ordinal: 2000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Extend `load_tiled` in `map_generator.lua` to read Tiled object layers and expose them as named spawn label groups on the BattleMap. Update `battle_manager` to support the new squad/slot unit entry format. Existing static maps (metatile approach) are untouched.

**Object layer → spawn label mapping:**
- Each Tiled `objectgroup` layer becomes a named group keyed by layer name.
- Point object pixel coordinates are divided by tile size to produce tile-grid `{x, y}` positions.
- Per-object property `slot` (string) is attached to each point entry if present.
- Per-object property `ai_hint` (string) is attached to each point entry if present; per-layer `ai_hint` sets a default that per-object values override.
- Per-layer property `from` (string, e.g. `"west"`) is attached to the group entry (not to individual points) for reinforcement waves.

**BattleMap spawn groups structure:**
```lua
map.spawn_groups = {
    enemy_squad_nw = {
        from = nil,  -- or "west" etc.
        points = {
            { x=5, y=3, slot="squad_leader", ai_hint="stationary" },
            { x=4, y=3, slot="squad_unit" },
            { x=6, y=3, slot="squad_unit" },
        }
    },
    deployment_defense = {
        points = { {x=9,y=2}, {x=11,y=2} }
    },
}
```

**New mission unit entry format (squad/slot style):**
```lua
{
    side = "enemy",
    layer = "enemy_squad_nw",
    slots = {
        squad_leader = { character_source = character_source.template("cmdr"), ai = ai.stationary },
        squad_unit   = { character_source = character_source.template("inf"),  ai = ai.move_two },
    }
}
```
The battle manager places each point in the layer's group, resolving the point's `slot` to the matching sub-entry. Points with no `slot` property use a `"default"` slot key.

**Out of scope:** variant_sets, `facing`, file-based `.map`/`.spawn.lua` output, `tiled_convert.p64`.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 load_tiled populates map.spawn_groups from Tiled objectgroup layers, converting pixel coords to tile-grid positions
- [x] #2 Per-object 'slot' property is attached to each point entry when present
- [x] #3 Per-object 'ai_hint' overrides per-layer 'ai_hint' default on individual point entries
- [x] #4 Per-layer 'from' property is attached to the group entry (not individual points)
- [x] #5 battle_manager handles the new layer/slots unit entry format, placing each point's unit using its slot sub-entry
- [x] #6 Points with no slot property use the 'default' slot key
- [x] #7 Existing static map loading (metatile approach) is unchanged
- [x] #8 abandoned_fortress spawn groups load correctly from its object layers
- [x] #9 make test passes
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [x] #1 All acceptance criteria met
- [x] #2 make test passes
<!-- DOD:END -->
