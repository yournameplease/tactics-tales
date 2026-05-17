---
id: TASK-141
title: Wire procgen path into map_generator.load_map
status: Done
assignee: []
created_date: '2026-05-17 00:41'
updated_date: '2026-05-17 02:35'
labels: []
milestone: m-21
dependencies: []
references:
  - docs/specs/procgen-map-spec.md
  - src/tactics/battle/map/map_generator.lua
ordinal: 7000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Add `ProcgenMapDefinition` LuaCATS class and a `load_procgen` branch in `src/tactics/battle/map/map_generator.lua`. Wire the procgen module to be called by `load_map` when `definition.type == "procgen"`. Decide and document the seed-passing signature (either an added optional `seed` parameter or a thread-local context); update the existing static/tiled branches accordingly. Update the placeholder spec at `src/spec/battle/map/map_generator_spec.lua:616` to exercise the procgen path.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 `map_generator.load_map({type="procgen", theme="castle"}, labels, gfx_registry, seed)` returns a BattleMap.
- [ ] #2 Same seed + theme + chunk pool yields a byte-identical BattleMap (deterministic).
- [ ] #3 Existing static/tiled load_map callers continue to work unchanged.
- [ ] #4 map_generator_spec covers procgen path with a fixture theme + chunk pool.
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
