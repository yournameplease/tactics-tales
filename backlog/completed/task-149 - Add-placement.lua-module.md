---
id: TASK-149
title: Add placement.lua module
status: Done
assignee: []
created_date: '2026-05-18 14:16'
updated_date: '2026-05-19 00:23'
labels: []
milestone: m-22
dependencies:
  - TASK-146
references:
  - src/tactics/battle/map/procgen/placement.lua
  - src/spec/battle/map/procgen/placement_spec.lua
  - src/tactics/battle/map/procgen/graph.lua
  - docs/superpowers/plans/2026-05-18-procgen-objective-placement.md
ordinal: 2000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Create `src/tactics/battle/map/procgen/placement.lua` with a `placement.select(g, objective, rng)` function returning a `ProcgenPlacement` (`{deployment_cell, boss_cell?, escape_cell?}`). kill_boss/escape use double-BFS poles; rout/defend use min-eccentricity + max-degree center node. Errors on unknown objective.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 placement.select returns correct poles for kill_boss and escape on a chain graph
- [x] #2 placement.select returns hub for rout and defend on a star graph
- [x] #3 boss_cell and escape_cell are mutually exclusive; absent for rout/defend
- [x] #4 Falls back to all nodes when no candidate has degree >= 2
- [x] #5 Errors on unknown objective string
- [x] #6 make test passes
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [x] #1 All acceptance criteria met
- [x] #2 make test passes
<!-- DOD:END -->
