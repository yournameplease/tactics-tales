---
id: TASK-137
title: Connection graph generation
status: To Do
assignee: []
created_date: '2026-05-17 00:40'
labels: []
milestone: m-21
dependencies: []
references:
  - docs/specs/procgen-map-spec.md
ordinal: 3000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Generate the connection graph over a W×H cell grid per spec §3.3: a random spanning tree (Kruskal on shuffled edges) ensuring full connectivity, plus extra edges rolled at the theme's `extra_edge_probability` per adjacent pair. Also implement bridge detection (§5.5) for use by the bottleneck flag in step 11.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 `generate(theme, W, H, rng) → {edges, adjacency}` returns a connected graph.
- [ ] #2 Bridge detection returns the set of edges whose removal disconnects the graph.
- [ ] #3 Spec covers connectivity for all valid (W,H) up to 3×3 with deterministic seeds.
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
