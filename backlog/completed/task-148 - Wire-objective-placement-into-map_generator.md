---
id: TASK-148
title: Wire objective placement into map_generator
status: Done
assignee: []
created_date: '2026-05-18 14:15'
updated_date: '2026-05-19 12:47'
labels: []
milestone: m-22
dependencies: []
references:
  - src/tactics/battle/map/map_generator.lua
  - src/spec/battle/map/map_generator_spec.lua
  - docs/superpowers/plans/2026-05-18-procgen-objective-placement.md
ordinal: 4000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Add `objective: string` to ProcgenMapDefinition. Pass it to chunk_selector.generate in load_procgen. Attach gen_result.placement to the returned BattleMap as map.procgen_placement. Add integration tests for kill_boss, escape, and rout objectives that verify procgen_placement fields are present and correct.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 ProcgenMapDefinition has an objective field (LuaCATS annotation)
- [x] #2 load_procgen passes definition.objective to chunk_selector.generate
- [x] #3 map.procgen_placement is set from gen_result.placement
- [x] #4 Integration test: kill_boss map has deployment_cell != boss_cell, no escape_cell
- [x] #5 Integration test: escape map has deployment_cell != escape_cell, no boss_cell
- [x] #6 Integration test: rout map has deployment_cell, no boss_cell or escape_cell
- [x] #7 All existing map_generator_spec tests still pass
- [x] #8 make test passes
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
