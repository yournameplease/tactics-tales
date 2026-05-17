---
id: TASK-138
title: Chunk selection with exit-overlap retry
status: To Do
assignee: []
created_date: '2026-05-17 00:40'
labels: []
milestone: m-21
dependencies: []
references:
  - docs/specs/procgen-map-spec.md
ordinal: 4000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Per spec §8 steps 5–7: choose one deployment cell at random, then select a chunk for each cell from the theme pool filtered by dimensions (and `deployment` tag for the deployment cell). Reject chunks lacking exit zones on connected faces. After all cells are filled, validate exit-zone overlap (§5.1) in map coordinates for every graph edge. On overlap failure, retry the offending cells up to 10 times; on repeated failure, regenerate the connection graph.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Exactly one cell receives a deployment-tagged chunk per generation.
- [ ] #2 All graph edges have ≥1 overlapping exit-zone tile in map coordinates.
- [ ] #3 Retry budget enforced; emits a clear error if a theme cannot satisfy a graph after retries.
- [ ] #4 Spec uses synthetic chunk pools to exercise retry and graph-regen paths.
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
