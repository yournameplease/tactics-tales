# Enemy Room Distribution — Design Spec

**Date:** 2026-05-21

## Overview

Procgen maps should randomly designate some rooms as enemy rooms and some as empty. Chunk selection then enforces this: enemy rooms pick from chunks tagged `has_enemies`, non-enemy rooms pick from chunks without that tag. Special cells (deployment, boss, escape) are excluded from the roll.

## Data Flow

### 1. `themes.lua` — new field

Add `enemy_room_probability: number` (range [0, 1]) to `ProcgenTheme`. Set to `0.4` on both `castle` and `cave` themes.

### 2. `placement.select()` — roll enemy cells

After resolving `deployment_cell`, `boss_cell`, and `escape_cell`, iterate all `n` cells. For each cell that is not a special cell, roll `rng:rndf() < theme.enemy_room_probability`. Collect passing cells into `enemy_cells: table<integer, true>` (a sparse set).

Add `enemy_cells` to `ProcgenPlacement`:

```lua
---@field enemy_cells table<integer, true>  cells (non-special) designated as enemy rooms
```

When `theme` is nil, default to an empty set (no enemy rooms rolled).

### 3. `chunk_selector.filter_candidates()` — enforce has_enemies

Add a `has_enemies: boolean?` parameter. When not nil:
- `true` → only include chunks where `chunk.tags` contains `"has_enemies"`
- `false` → only include chunks where `chunk.tags` does not contain `"has_enemies"`
- `nil` → no filtering (existing behaviour for special cells)

### 4. `chunk_selector.select()` — compute flag per cell

Before calling `filter_candidates`, determine `has_enemies`:
- If `cell_required_tag(idx, placement)` is non-nil → pass `nil` (special cell, no constraint)
- Else if `placement.enemy_cells[idx]` → pass `true`
- Else → pass `false`

## Type Annotations

```lua
---@class ProcgenTheme
---@field enemy_room_probability number  Per-cell probability a non-special room has enemies. Range [0, 1].

---@class ProcgenPlacement
---@field enemy_cells table<integer, true>
```

## Testing

- `placement_spec`: given a known RNG and `enemy_room_probability = 1.0`, all non-special cells appear in `enemy_cells`; with `0.0`, none do; special cells never appear.
- `chunk_selector_spec`: enemy cell selects only `has_enemies` chunks; non-enemy cell selects only non-`has_enemies` chunks; special cell is unconstrained on `has_enemies`.
- `themes_spec`: validate that `enemy_room_probability` is in [0, 1].
