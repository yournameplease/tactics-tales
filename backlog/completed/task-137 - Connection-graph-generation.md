---
id: TASK-137
title: Connection graph generation
status: Done
assignee: []
created_date: '2026-05-17 00:40'
updated_date: '2026-05-17 01:19'
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
- [x] #1 `generate(theme, W, H, rng) → {edges, adjacency}` returns a connected graph.
- [x] #2 Bridge detection returns the set of edges whose removal disconnects the graph.
- [x] #3 Spec covers connectivity for all valid (W,H) up to 3×3 with deterministic seeds.
<!-- AC:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Added `src/tactics/battle/map/procgen/graph.lua`:
- `graph.generate(theme, w, h, rng) → ConnectionGraph`: Kruskal on a Fisher-Yates-shuffled list of all grid adjacencies builds the random spanning tree; remaining edges are rolled in at `theme.extra_edge_probability` (resolved via `rng:rndi(1000) < p*1000`). Returns `{ edges, adjacency }` with edges as sorted `{a,b}` pairs (1-based cell indices, row-major).
- `graph.bridges(g) → integer[][]`: naive bridge detection — for each edge, BFS from cell 1 with that edge masked and flag it if any cell becomes unreachable. Simple and fine for ≤9-cell graphs.

Spec at `src/spec/battle/map/procgen/graph_spec.lua` (7 tests) covers connectivity across every shape up to 3×3 and 10 seeds each, spanning-tree edge count (W·H−1), full-cycle edge count at p=1, edge ordering invariant, all-edges-bridges for trees, and zero-bridges for a 2×2 cycle. Full suite (1136) passes.
<!-- SECTION:FINAL_SUMMARY:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [x] #1 All acceptance criteria met
- [x] #2 make test passes
<!-- DOD:END -->
