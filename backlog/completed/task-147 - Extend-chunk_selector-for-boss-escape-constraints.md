---
id: TASK-147
title: Extend chunk_selector for boss/escape constraints
status: Done
assignee: []
created_date: '2026-05-18 14:15'
updated_date: '2026-05-19 00:31'
labels: []
milestone: m-22
dependencies: []
references:
  - src/tactics/battle/map/procgen/chunk_selector.lua
  - src/tactics/battle/map/procgen/chunk_parser.lua
  - src/spec/battle/map/procgen/chunk_selector_spec.lua
  - docs/superpowers/plans/2026-05-18-procgen-objective-placement.md
ordinal: 3000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Wire placement into chunk_selector. (1) Add `boss_room` and `escape_zone` to KNOWN_TAGS in chunk_parser.lua. (2) Replace the random `deployment_cell` roll in chunk_selector with a `PlacementResult` parameter; extend filter_candidates to handle all three special tags. (3) chunk_selector.generate accepts `objective`, calls placement_mod.select on each generated graph, and includes `placement` in ChunkGenerationResult.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 boss_room and escape_zone are in chunk_parser KNOWN_TAGS
- [x] #2 chunk_selector.select accepts a placement argument instead of rolling deployment_cell randomly
- [x] #3 boss_cell constraint forces boss_room chunk at that cell
- [x] #4 escape_cell constraint forces escape_zone chunk at that cell
- [x] #5 Returns nil/error when required special chunk type is absent from the pool
- [x] #6 chunk_selector.generate accepts objective and propagates placement through the retry loop
- [x] #7 ChunkGenerationResult gains a placement field
- [x] #8 All existing chunk_selector_spec tests still pass
- [x] #9 make test passes
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [x] #1 All acceptance criteria met
- [x] #2 make test passes
<!-- DOD:END -->
