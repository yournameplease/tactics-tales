# Tactics Tales — Procedural Map Generation Spec

## 1. Overview

This spec defines the procedural map generation system for Tactics Tales battle maps. The system produces grid-based tactical maps suitable for Fire Emblem-style combat on a hard **16×16 tile** canvas (Picotron: 480×270, 32-color palette).

The approach uses a **macro grid** of authored **chunks** connected by a generated **connection graph**. High-level structure (which cells connect to which) is determined procedurally; low-level tile layout within each cell is authored by a designer. This gives predictable tactical quality while maintaining meaningful variation across runs.

**In scope (v1):**
- Macro grid generation, chunk selection and placement, connection construction.
- Trivial 1:1 autotiling into a single `ground` sprite layer.
- Player deployment via a tagged entry chunk.
- Spawn point output as tile labels consumed by the existing faction system in `tt_procedural_campaign`.
- Two themes (Castle, Cave) differing in size distribution and exit width.

**Out of scope (deferred to later specs):**
- Cave erosion and other theme modification passes (§5.4).
- The `?` optional-ground glyph and any non-trivial autotiling.
- `p` (player) and `a` (ally) spawn glyphs — reserved in the vocabulary, no behavior in v1.
- Grid shifts/jitter, split exits, bent/diagonal connections, multi-cell chunks.
- Map-edge connections (escape/entry through map border).

---

## 2. Concepts & Terminology

**Macro Grid**
The top-level W×H array of cells that structures the map. Each cell is filled by one chunk. Typical sizes are 2×2 and 3×3.

**Cell**
One slot in the macro grid. Has a column width and row height determined by the grid's size distribution. Contains one chunk.

**Chunk**
An authored tile template that fills a cell. Defined in a `.chunks` file. Includes optional tags, a tile grid (interior plus border ring), exit zone markers, and spawn point markers.

**Cell Interior**
The tiles inside a chunk excluding the 1-tile border ring. This is the playable area of the cell.

**Border Ring**
The outermost 1-tile-wide perimeter of a chunk grid. Contains exit zone markers (`^v<>`) and wall markers (`#`). Not placed directly into the map — used to derive connection positions and wall edges.

**Wall Gap**
The space between two adjacent cell interiors in the assembled map. Derived from the grid's wall thickness setting. Filled with wall tiles by default; carved to form connections where the graph specifies.

**Connection**
A passable link between two adjacent cells. Represented as a carved opening through the wall gap at a specific position and width.

**Exit Zone**
A contiguous run of directional markers (`^`, `v`, `<`, `>`) on one face of a chunk's border ring. Defines the tiles on that face eligible to participate in a connection. A chunk face may have zero or one exit zones. Split exits (two zones on one face) are rejected by the parser in v1.

**Connection Graph**
The set of connections between cells, generated from theme parameters. Determines which adjacent cell pairs are connected and with what topology (branching factor, loop frequency).

**Spawn Point**
A tile within a chunk interior marked with a spawn glyph (see §4.3). Each spawn glyph maps to a tile label (e.g. `enemy_infantry`, `player_deployment`) on the resulting BattleMap.

**Chunk Tag**
A keyword on a chunk's optional tags line that signals selection intent or permits transformations. v1 defines: `deployment` (the chunk hosts player deployment); `rotate_90`, `rotate_180`, `flip_h`, `flip_v` (transformation permissions — see §4.6). Future tags: `boss`, `no_enemy`, etc.

**Variant**
A transformed copy of an authored chunk produced by applying a rotation or reflection permitted by its tags. Variants are first-class members of the chunk pool — chunk selection treats them identically to authored chunks.

**Theme**
A named parameter bundle controlling grid dimensions, wall thickness, border margin, exit width distribution, and connection graph topology. Defined in code, not in chunk files.

---

## 3. Macro Grid

### 3.1 Grid Shape

The macro grid is defined by width `W` and height `H` (in cells). Any positive integer W and H are valid subject to the size budget constraint below. Standard configurations:

| Config | Use case |
|--------|----------|
| 2×2 | Boss rooms, set-piece missions, large open maps |
| 3×3 | Standard generated missions |
| 2×3 / 3×2 | Asymmetric missions (escort, siege) |

### 3.2 Size Distributions

Each axis (columns, rows) has an independent size distribution — a list of integer tile widths, one per cell, that must satisfy:

```
sum(col_widths) + (W - 1) * wall_thickness + 2 * border_margin == 16
sum(row_heights) + (H - 1) * wall_thickness + 2 * border_margin == 16
```

Where:
- `wall_thickness` is the target thickness of the wall gap between cells (theme parameter, minimum 1)
- `border_margin` is the thickness of the map edge wall (theme parameter, minimum 0)

The system validates this constraint at theme definition time. Generation fails fast if the budget doesn't balance.

**Example distributions (16-tile axis):**

| Theme | Distribution | Wall | Border | Check |
|-------|-------------|------|--------|-------|
| Castle 3×3 | `[4, 4, 4]` | 2 | 1 | 12 + 4 + 2 = 18 ✗ ⟵ adjust |
| Castle 3×3 | `[3, 4, 3]` | 2 | 1 | 10 + 4 + 2 = 16 ✓ |
| Cave 3×3 | `[3, 4, 3]` | 2 | 1 | 10 + 4 + 2 = 16 ✓ |
| Boss 2×2 | `[6, 6]` | 2 | 1 | 12 + 2 + 2 = 16 ✓ |

> Distributions in the table above are illustrative. Final per-theme distributions are defined in code and validated at load time.

**Minimum cell dimension:** No cell width or height may be less than 3 tiles (interior too small to be tactically meaningful or author usefully).

### 3.3 Connection Graph Generation

The connection graph is generated on the macro grid before chunk selection. It determines which adjacent cell pairs have a connection (passable) vs. a wall (impassable).

Parameters (per theme):

- **Connectivity:** The graph must always be fully connected — every cell reachable from every other cell. Enforced by generating a random spanning tree first, then adding additional edges.
- **Extra edges:** Additional connections beyond the spanning tree, rolled per adjacent pair at a per-theme probability. Controls loop frequency (how often paths rejoin).
- **Map-edge connections:** Deferred to a future spec. v1 has no openings through the border margin.

The spanning tree is generated by Kruskal's algorithm on shuffled edges (or an equivalent random spanning tree algorithm).

### 3.4 Future: Grid Shifts

Row and column offsets to reduce grid regularity are planned as a future extension. Not in scope for v1.

---

## 4. Chunks

### 4.1 Chunk Dimensions

A chunk's **logical dimensions** are its interior: width × height of the playable area, not including the border ring. The border ring exists only to derive connectivity (exit zones) and is not placed into the map.

In the chunk file format (§7.2) the dimension line declares the **outer grid** (`W H`, including the border ring) because the rows beneath it physically need to be that wide. The parser converts to interior dimensions when building the in-memory record: `width = W - 2`, `height = H - 2`.

A chunk is valid for a cell if `chunk.width == cell_col_width` and `chunk.height == cell_row_height`. Chunks are selected from the theme's chunk pool filtered to those matching the target cell dimensions.

### 4.2 Border Ring

The border ring is the outermost 1-tile perimeter of the chunk grid. It is used during generation to derive exit zones and wall placement. It is **not** written directly to the map.

**Corner tiles:** Always `#`. Corners are never exit-eligible. The parser enforces this and rejects malformed chunks.

**Non-corner border tiles:**
- `#` — wall; this face position is not eligible for a connection opening
- `^` — exit-eligible on the north face (row 0 only)
- `v` — exit-eligible on the south face (row H-1 only)
- `<` — exit-eligible on the west face (col 0 only)
- `>` — exit-eligible on the east face (col W-1 only)

A contiguous run of directional markers on one face forms one **exit zone**. A `#` within a run breaks it; a face must have **at most one** contiguous run of directional markers in v1. The parser hard-rejects chunks with split exits (two or more runs on a single face).

### 4.3 Interior Tiles

The interior (border ring excluded) uses the following tile vocabulary:

| Character | Meaning | Tile label on BattleMap |
|-----------|---------|-------------------------|
| `#` | Wall | — (rendered as solid tile in ground layer) |
| `.` | Ground | — |
| `d` | Player deployment | `player_deployment` |
| `i` | Enemy spawn (infantry) | `enemy_infantry` |
| `r` | Enemy spawn (ranged) | `enemy_ranged` |
| `t` | Enemy spawn (tank) | `enemy_tank` |
| `c` | Enemy spawn (commander) | `enemy_commander` |
| `p` | (reserved) Player special | — (parser accepts; no behavior in v1) |
| `a` | (reserved) Ally | — (parser accepts; no behavior in v1) |

Spawn glyphs imply a unit spawns at that tile. A spawn glyph also functions as a passable ground tile. A chunk with no spawn glyphs is valid.

`d` glyphs are only meaningful in chunks tagged `deployment` (§4.5).

### 4.4 Exit Zone Derivation

After parsing, exit zones are stored as tile ranges (1-indexed, inclusive) on each face:

- **North/South face:** column indices 2 through `W_chunk - 1` (excluding corners)
- **East/West face:** row indices 2 through `H_chunk - 1` (excluding corners)

A zone is the contiguous run of directional markers. Example: `#^^^#` on a 5-wide north face produces exit zone `[2, 4]`.

### 4.5 Chunk Tags

A chunk may declare zero or more tags on an optional tags line (§7.2). v1 defines:

- `deployment` — this chunk hosts the player deployment cell. Its `d` glyphs produce `player_deployment` tile labels.
- `rotate_90`, `rotate_180`, `flip_h`, `flip_v` — permit the corresponding transformation when expanding the chunk into variants. See §4.6.

Generation requires **exactly one** cell on the map to be filled with a `deployment`-tagged chunk (or any of its variants, if transformation tags are also present). The deployment cell does not need to be a graph leaf. If no chunk in the theme's pool with `deployment` and the right dimensions exists for any cell, generation fails.

Future tags (placeholders, parser accepts unknown tags as a warning rather than error): `boss`, `no_enemy`.

### 4.6 Variants (Rotations and Reflections)

By default a chunk appears in the pool exactly as authored. Transformation tags expand a chunk into additional **variants** — rotated or reflected copies — that join the same pool. Variants are indistinguishable from authored chunks during selection.

Tags:

- `rotate_90` — permits 0°, 90°, 180°, and 270° rotations (4 orientations).
- `rotate_180` — permits 0° and 180° rotation (2 orientations). Subsumed by `rotate_90`.
- `flip_h` — permits a horizontal reflection (mirror across the vertical axis).
- `flip_v` — permits a vertical reflection (mirror across the horizontal axis).

Tags compose. A chunk with `rotate_90 flip_h` produces up to 8 variants (the dihedral group D₄). Variants that are tile-identical to another variant after transformation should be deduplicated (e.g. a fully symmetric chunk under `rotate_90` collapses to one variant).

**Dimensions.** A 90°/270° rotation swaps the chunk's interior width and height. Other transforms preserve dimensions. Chunk selection therefore treats a `rotate_90`-tagged chunk authored as `W×H` as fitting cells of either `(W, H)` or `(H, W)` dimensions.

**Exit zones transform with their face.** Under a 90° CW rotation, `north → east`, `east → south`, `south → west`, `west → north`, and the zone's range maps to the new face's coordinate. Under `flip_h`, `east ↔ west` swap; `north` and `south` zones reverse their range (`[a, b]` on a face of width `W` becomes `[W - b + 1, W - a + 1]`). `flip_v` is symmetric.

**Spawn glyphs and `d` markers** are repositioned by the same transform that produces the variant. Deployment intent is preserved (the `deployment` tag carries over to every variant).

**Variant identity.** A variant has a derived name `<base>|<op1>|<op2>|...` (e.g. `gatehouse|rot90`, `corridor_ns|flip_h`) used in logs and rejection messages. Variants share the base chunk's tags except for the transformation tags themselves (a variant is not re-expanded).

---

## 5. Connection Construction

### 5.1 Exit Overlap Check

For two adjacent cells A and B sharing a face, a connection is only possible if their exit zones on that shared face overlap sufficiently. The overlap is computed in map coordinates (accounting for each cell's position on the axis).

Let A's exit zone on the shared face be `[a_min, a_max]` and B's be `[b_min, b_max]` (both in map tile coordinates). The overlap is:

```
overlap_min = max(a_min, b_min)
overlap_max = min(a_max, b_max)
overlap_width = overlap_max - overlap_min + 1
```

A connection requires `overlap_width >= 1`. If the connection graph specifies a connection but no overlap exists, chunk selection for one or both cells must be retried (see §8).

### 5.2 Exit Width Selection

The connection width `w` is rolled from the theme's exit width distribution, clamped to `[1, overlap_width]`. The exit position within the overlap is chosen randomly (uniform, subject to fitting width `w`).

**Theme exit width distributions:**

| Theme | Width range | Notes |
|-------|-------------|-------|
| Castle | 1–2 | Prefers 1 (tight corridors) |
| Cave | 1–4 | Higher widths more common |

Distributions are defined as weighted tables, not uniform ranges.

### 5.3 Carving the Opening

Given the exit position and width in map coordinates, the wall gap between the two cell interiors is carved:

1. Fill the entire wall gap strip with wall tiles (`#`) — this is the default state.
2. Erase wall tiles at the exit position for the full depth of the wall gap, producing a rectangular passage.

The passage connects the two cell interiors with a clean rectangular cut. v1 has no further modification passes.

### 5.4 Theme Modification Passes (Deferred)

Cave erosion and architectural detailing are deferred to a future spec. v1 carved openings are always clean rectangles.

### 5.5 Guard Spawn Points

After connection construction, each connection is evaluated for guard placement:

- **Bottleneck check:** Remove this connection from the graph and check if the graph remains connected. If not, this is a bridge connection — flag it as a high-value guard position.
- **Width check:** If the carved width is 1, the connection is eligible for a guard spawn point.
- If both conditions are met, a guard spawn point is placed at the center tile of the passage and contributes to the `enemy_commander` tile label.

The mission resolver decides whether to actually fill the slot.

---

## 6. Themes

A theme is a named parameter bundle. Two themes are defined in v1.

### 6.1 Castle

| Parameter | Value |
|-----------|-------|
| Wall thickness | 2 |
| Border margin | 1 |
| Col/row distributions | `[3, 4, 3]` (3×3), `[6, 6]` (2×2) |
| Exit width | 1–2, weighted toward 1 |
| Extra edge probability | 0.2 (low loops — more linear) |

### 6.2 Cave

| Parameter | Value |
|-----------|-------|
| Wall thickness | 2 |
| Border margin | 1 |
| Col/row distributions | `[3, 4, 3]` (3×3), `[6, 6]` (2×2) |
| Exit width | 1–4, weighted toward 2–3 |
| Extra edge probability | 0.35 (moderate loops) |

In v1, Castle and Cave differ only by exit width distribution and extra-edge probability; visual differentiation is left to authored chunk content (different chunk pools per theme).

---

## 7. Chunk File Format

### 7.1 File Location & Registration

Chunk files live under each mod at `mods/<mod>/game_data/chunks/<theme>.chunks`. The filename stem is the theme name.

A mod's `mod.lua` registers the directory via a `chunks` entry in its `content` table, mirroring how `maps` and `missions` are registered:

```lua
content = {
    ...
    chunks = "game_data/chunks",
}
```

The mod loader scans the directory and merges all `*.chunks` files by theme name into a global registry. Multiple mods may contribute to the same theme; entries are merged by chunk name.

Chunk files are read via Picotron's `fetch()` and parsed by the procgen module.

### 7.2 File Structure

A chunk file contains one or more chunk definitions separated by blank lines. Each chunk definition consists of:

1. A **label line**: `[chunk_name]` — a unique name within the file, used for debugging and future filtering.
2. An **optional tags line**: space-separated tag keywords (e.g. `deployment`). If absent, the chunk has no tags. Identified by being non-empty and containing no spaces from the dimension grammar (i.e. not parseable as two integers).
3. A **dimension line**: `W H` — two integers separated by a space. `W` and `H` include the border ring.
4. Exactly `H` **tile rows**, each exactly `W` characters wide.

Comments may appear as lines beginning with `--` and are ignored by the parser.

### 7.3 Example

```
-- castle.chunks
-- Castle theme chunk definitions

[gatehouse]
deployment
6 5
#^^^^#
<d...>
<.d..>
<...d>
##vv##

[corridor_ns]
5 5
#^^^#
#...#
#.i.#
#...#
#vvv#

[corner_room]
5 5
#^^^#
<...#
<...#
<...#
#####

[wide_hall]
7 5
#^^^^^#
<.....>
<..i..>
<.....>
##vvv##
```

### 7.4 Parser Rules

- Corners (four corner characters of the tile grid) must be `#`. Reject otherwise.
- Non-corner border characters must be one of `# ^ v < >`. Reject other characters in the border ring.
- Interior characters must be one of `# . i r t c d p a`. Reject other characters.
- Directional markers must face the correct edge (`^` only on row 0, `v` only on row H-1, `<` only on col 0, `>` only on col W-1). Reject mismatched markers.
- A face may have at most one contiguous run of directional markers. A face with two or more runs is a **hard reject** in v1.
- A chunk containing `d` glyphs must declare the `deployment` tag (and vice versa: a chunk with the `deployment` tag must contain at least one `d` glyph).
- Chunk names must be unique within a file.
- Blank lines between chunks are required as delimiters. Trailing whitespace is ignored.
- Unknown tags emit a warning but do not fail parsing (forward compatibility).

---

## 8. Generation Sequence

The full generation procedure, in order:

1. **Receive inputs.** A `ProcgenMapDefinition` (`{type="procgen", theme=string}`) and a numeric `seed` from the caller. All RNG below is seeded deterministically from `seed`.
2. **Roll grid shape.** Select W×H from the theme's valid configurations.
3. **Roll size distributions.** Select col widths and row heights from the theme's distribution table. Validate budget constraint.
4. **Generate connection graph.** Random spanning tree over the cell grid, then roll extra edges per theme probability.
5. **Choose deployment cell.** Pick one cell uniformly at random; constrain chunk selection for that cell to chunks tagged `deployment`.
6. **Select chunks.** For each cell, filter the theme's chunk pool to chunks matching the cell's dimensions (and the deployment tag for the deployment cell). From the filtered set, select randomly. Chunks with exit zones on connected faces are preferred; chunks lacking an exit zone on a connected face are rejected.
7. **Validate exit overlaps.** For each connection in the graph, compute the exit zone overlap in map coordinates. If overlap is insufficient for minimum width 1, reject one or both chunks and retry from step 6. If retry budget is exceeded, regenerate the connection graph (step 4).
8. **Roll exit widths and positions.** For each connection, roll width from theme distribution clamped to overlap. Roll position within overlap.
9. **Assemble glyph grid.** Place all cell interiors at their computed map positions. Fill wall gaps with `#`. Fill border margin with `#`.
10. **Carve connections.** For each connection, carve the opening through the wall gap.
11. **Flag bottleneck connections.** Run bridge detection on the connection graph. Place a center-tile spawn marker on width-1 bridges (treated as `enemy_commander`).
12. **Autotile.** Walk the glyph grid; write tile id `1` (floor sprite) for `. d i r t c p a` and tile id `2` (wall sprite, solid via tile flag) for `#` into the `ground` layer of a fresh BattleMap. Other terrain layers (`front_wall`, `mid_wall`, `back_wall`, `ceiling`, `metatiles`) remain empty/nil.
13. **Collect tile labels.** Group spawn glyph positions into tile labels per the table in §4.3 and attach to the BattleMap as `tile_labels`.
14. **Return BattleMap.** Width 16, height 16, with `ground` layer populated, `tile_labels` populated, `spawn_groups` empty, `rect_zones` empty.

---

## 9. Engine Integration

### 9.1 MapDefinition

```lua
---@class ProcgenMapDefinition : MapDefinition
---@field type "procgen"
---@field theme string  -- theme name; must match a registered chunk file stem
```

`map_generator.load_map(definition, labels, gfx_registry)` gains a third branch that calls into the procgen module. The procgen path additionally requires a seed; this is passed through a new optional parameter (or a thread-local context) — exact signature TBD by the implementing task.

### 9.2 Tile Sprite Resolution

The `ground` layer tile ids `1` and `2` index into the first registered tileset for the mission's mod (the same convention `load_tiled` uses). Mod authors are responsible for placing a passable floor sprite at index 1 and a wall sprite (with the solid tile flag set) at index 2 in their tileset.

### 9.3 Mission Resolver

A new mission resolver lives at `mods/tt_procedural_campaign/lib/procgen_mission_resolver.lua` (sibling of the existing `pod_mission_resolver.lua`). The pod resolver remains as reference until the procgen path is validated, then is removed.

The resolver:

1. Computes the seed deterministically from campaign state + battle index (no new save fields).
2. Loads the BattleMap via `map_generator.load_map(...)` with that seed.
3. Reads the active faction and tier from campaign state (existing `factions.lua` API: `resolve_slot`, `resolve_slot_cost`).
4. For each enemy spawn tile label (`enemy_infantry`, `enemy_ranged`, `enemy_tank`, `enemy_commander`), expands the tile-label point list into one `UnitSpawnData` per point with `character_source = template(resolve_slot(faction, tier, role))`.
5. Emits a single player `UnitSpawnData` with `tile = "player_deployment"` and `character_source = player_roster()`.

The resolver does **not** use the existing pod/budget/threat_mult system — every spawn glyph becomes exactly one unit.

---

## 10. Validation & Rejection

| Check | When | Action on failure |
|-------|------|------------------|
| Budget constraint | Theme definition | Hard error — fix theme data |
| Corner tiles are `#` | Chunk parse | Reject chunk file |
| Valid border characters | Chunk parse | Reject chunk file |
| Valid interior characters | Chunk parse | Reject chunk file |
| Directional markers on correct face | Chunk parse | Reject chunk file |
| Single contiguous exit run per face | Chunk parse | Reject chunk file |
| `d` glyph ↔ `deployment` tag consistency | Chunk parse | Reject chunk file |
| Unique chunk names | Chunk parse | Reject chunk file |
| Minimum cell dimension ≥ 3 | Grid roll | Reroll distribution |
| Graph fully connected | Graph generation | Regenerate graph |
| Deployment chunk exists for chosen cell | Chunk selection | Reroll deployment cell, then regenerate graph |
| Exit overlap ≥ 1 | Post-chunk-selection | Retry chunk selection (max 10 attempts per cell, then regenerate graph) |

---

## 11. Extension Points

Out of scope for v1; the system is designed to accommodate:

- **Cave erosion / theme passes.** Re-introduce §5.4 with per-theme edge erosion of carved openings.
- **`?` optional ground.** Requires a real autotiler that can resolve ambiguous tiles.
- **`p` / `a` glyphs.** Player special and ally spawn behavior.
- **Grid shifts (jitter).** Row/column offsets after size distribution. Requires exit overlap validation to account for shifted positions.
- **Additional themes.** Village (thin-wall borders), forest (open borders with interior clusters), open terrain.
- **Multi-cell chunks.** A chunk spanning two adjacent cells; chunk selection treats them as a unit and skips the shared-face connection.
- **Map-edge connections.** Openings through the border margin for escape/entry missions.
- **Split exits.** Multiple exit zones per face.
- **Variable macro grid per campaign position.** Campaign layer picks shape per battle (e.g. bosses always 2×2).
- **Proper autotiling.** Replace the 1:1 mapping with rule-based theming.
- **Future chunk tags.** `boss`, `no_enemy`, others as needed.
