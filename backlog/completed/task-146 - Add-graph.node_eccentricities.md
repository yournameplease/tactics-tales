---
id: TASK-146
title: Add graph.node_eccentricities
status: Done
assignee: []
created_date: '2026-05-18 14:15'
updated_date: '2026-05-19 00:01'
labels: []
milestone: m-22
dependencies: []
references:
  - src/tactics/battle/map/procgen/graph.lua
  - src/spec/battle/map/procgen/graph_spec.lua
  - docs/superpowers/plans/2026-05-18-procgen-objective-placement.md
ordinal: 1000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Add `graph.node_eccentricities(g)` to `src/tactics/battle/map/procgen/graph.lua`. Runs BFS from every node and returns a table of `node → max_distance_to_any_other_node`. Used by the placement module to find the graph center for rout/defend objectives.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 graph.node_eccentricities is implemented in graph.lua after graph.node_depths
- [ ] #2 Tests cover: single-node graph, 3-node chain (center has lower eccentricity), star graph (hub lower than spokes), 2-node graph
- [ ] #3 All existing graph_spec tests still pass
- [ ] #4 make test passes
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
