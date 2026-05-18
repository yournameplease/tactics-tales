# Procgen Objective-Aware Placement

**Date:** 2026-05-18
**Branch:** additional-procgen-map-content

## Overview

Procedurally generated maps need to place the player deployment zone and objective targets (boss room, escape zone) in positions that match the battle objective. This spec covers four objectives: `kill_boss`, `escape`, `rout`, and `defend`.

---

## Architecture

Five changes across the pipeline:

1. **`graph.lua`** — add `graph.node_eccentricities(g)`: runs BFS from every node, returns `node → max_distance_to_any_other_node`.
2. **`procgen/placement.lua`** (new) — takes `(g, objective, rng)`, returns a `ProcgenPlacement`. Hard-errors on unknown objective.
3. **`chunk_selector`** — remove internal `deployment_cell` random roll; accept a `PlacementResult` and treat its fields as fixed constraints when filtering chunks (extending the existing `need_deployment` tag-filter pattern).
4. **`ProcgenMapDefinition`** — gains `objective: string` field.
5. **`map_generator.load_procgen`** — calls `placement.select` after `graph.generate`, passes result into `chunk_selector.generate`, attaches it to the returned map as `map.procgen_placement`.

---

## Placement Logic

### `kill_boss` and `escape`

Run `graph.node_depths(g, 1)` (double-BFS; arbitrary start finds the true graph poles regardless).

- `boss_cell` / `escape_cell` = depth-0 node (the far pole)
- `deployment_cell` = max-depth node (the opposite pole)
- Ties broken by `rng`

### `rout` and `defend`

Run `graph.node_eccentricities(g)`. Filter candidates to nodes with `#adjacency >= 2`; fall back to all nodes if none qualify.

- `deployment_cell` = minimum-eccentricity node among candidates
- Tie-break: higher edge count first, then `rng`
- No `boss_cell` or `escape_cell` returned

---

## New Chunk Tags

| Tag | Used by |
|-----|---------|
| `boss_room` | `kill_boss` |
| `escape_zone` | `escape` |

Both follow the same filtering pattern as the existing `deployment` tag in `chunk_selector`.

---

## Hard-Error Conditions

- `kill_boss` selected but no `boss_room`-tagged chunks exist → error at chunk_selector filter time ("no valid chunk for cell N")
- `escape` selected but no `escape_zone`-tagged chunks exist → same
- Unknown objective string → error in `placement.select`

---

## Return Shape

```lua
---@class ProcgenPlacement
---@field deployment_cell integer  1-based macro-grid cell index
---@field boss_cell integer?       present for kill_boss only
---@field escape_cell integer?     present for escape only
```

Attached to the returned `BattleMap` as `map.procgen_placement`. Mission resolvers translate cell indices to tile coordinates as needed.

---

## Testing

| Spec file | Coverage |
|-----------|----------|
| `graph_spec.lua` | `node_eccentricities` — linear chain, grid, star graphs |
| `placement_spec.lua` (new) | Each objective on a small fixed graph; correct cell selections |
| `chunk_selector_spec.lua` | boss/escape cell constraints honoured during chunk filtering |
| `map_generator_spec.lua` | Integration: each objective type produces correct `procgen_placement` fields |
