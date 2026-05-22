# Enemy Distribution Modes — Design Spec

**Date:** 2026-05-22

## Overview

Extend procgen maps with a second enemy distribution strategy alongside the existing room-based approach. `ProcgenMapDefinition` gains an `enemy_distribution` field that selects between two modes:

- **`"room_based"`** (default) — existing behaviour: `placement.select` rolls `enemy_cells`; `chunk_selector` enforces `has_enemies` tag per cell.
- **`"scatter"`** — enemies are not assigned at the chunk level. After glyph-grid assembly, a post-processing pass randomly replaces floor (`.`) glyphs with enemy-infantry (`i`) glyphs at a configurable per-tile probability (default 2%). Chunk selection forces non-enemy chunks for regular cells, matching `room_based` at probability 0.

## Data Model

### `ProcgenMapDefinition` (map_generator.lua)

Two new optional fields:

```lua
---@field enemy_distribution "room_based"|"scatter"?  default "room_based"
---@field scatter_probability number?                 default 0.02, only used when enemy_distribution="scatter"
```

Nothing is added to `ProcgenTheme`.

## Pipeline Changes

### 1. `placement.select` (placement.lua)

Gains a 5th parameter `enemy_distribution: string?`.

- When `"scatter"`: skip `roll_enemy_cells`; return `enemy_cells = nil`.
- When `"room_based"` or nil: existing behaviour unchanged.

`enemy_cells = nil` is already handled correctly by `cell_has_enemies_flag` in `chunk_selector`: it returns `false` for all regular cells, which forces non-enemy chunks — exactly the desired scatter-mode behaviour.

### 2. `chunk_selector.generate` (chunk_selector.lua)

Gains a 6th parameter `enemy_distribution: string?`. Passes it through to `placement_mod.select`. No other changes.

### 3. `glyph_grid.scatter_enemies` (glyph_grid.lua)

New public function:

```lua
---@param rows string[]          16-element array of 16-char glyph strings (entries replaced in-place)
---@param gen_result ChunkGenerationResult
---@param grid ProcgenGrid
---@param prob number            per-tile probability of placing an infantry glyph
---@param rng RngInstance
function glyph_grid.scatter_enemies(rows, gen_result, grid, prob, rng)
```

Algorithm:

1. Identify special cell indices: `deployment_cell`, `boss_cell`, `escape_cell` from `gen_result.placement`.
2. For each cell index 1..n:
   - Skip if the cell is a special cell.
   - Compute the cell's interior tile bounds using `grid_layout.cell_x_start` / `cell_y_start` and the cell's `col_width` / `row_height`.
   - For each interior tile (x, y): convert `rows[y]` to a char array, replace `.` with `i` on a successful roll, rebuild the string, and write it back to `rows[y]`.

Non-`.` glyphs (walls `#`, existing spawn glyphs `d`, `I`, etc.) are never replaced.

### 4. `load_procgen` (map_generator.lua)

After `glyph_grid.assemble`:

```lua
if definition.enemy_distribution == "scatter" then
    local prob = definition.scatter_probability or 0.02
    glyph_grid.scatter_enemies(assembled.rows, gen_result, grid, prob, rng)
end
```

Also passes `definition.enemy_distribution` to `chunk_selector.generate`.

## Testing

### `placement_spec.lua`

- `placement.select` with `enemy_distribution="scatter"` returns `enemy_cells = nil` for `kill_boss`, `escape`, `rout`, and `defend` objectives.

### `chunk_selector_spec.lua`

- `generate` with `enemy_distribution="scatter"`: regular cells receive only non-`has_enemies` chunks (same as room_based at probability 0).

### `glyph_grid_spec.lua` (new file or extend existing)

- `scatter_enemies` with a deterministic RNG (always returns 0) replaces all `.` glyphs in non-special cells with `i`.
- `scatter_enemies` with prob=0 leaves all rows unchanged.
- `scatter_enemies` leaves special cells (deployment, boss, escape) untouched.
- `scatter_enemies` does not replace non-`.` glyphs (`#`, `d`, `I`, etc.).
