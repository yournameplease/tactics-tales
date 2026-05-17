# Tactics Tales — Procedural Map Generation Spec

## 1. Overview

This spec defines the procedural map generation system for Tactics Tales battle maps. The system produces grid-based tactical maps suitable for Fire Emblem-style combat on a 16x16 tile canvas (Picotron: 480x270, 32-color palette).

The approach uses a **macro grid** of authored **chunks** connected by a generated **connection graph**. High-level structure (which cells connect to which) is determined procedurally; low-level tile layout within each cell is authored by a designer. This gives predictable tactical quality while maintaining meaningful variation across runs.

**In scope:** macro grid generation, chunk selection and placement, connection construction, spawn point output, theme parameterization, chunk file format.

**Out of scope (noted as extension points):** autotiling, enemy population logic, campaign integration, shift/jitter (future), split exits (future), bent/diagonal connections (future).

---

## 2. Concepts & Terminology

**Macro Grid**
The top-level W×H array of cells that structures the map. Each cell is filled by one chunk. Typical sizes are 2×2 and 3×3; any W×H is valid as long as the size budget fits (see Section 3).

**Cell**
One slot in the macro grid. Has a column width and row height determined by the grid's size distribution. Contains one chunk.

**Chunk**
An authored tile template that fills a cell. Defined in a `.chunks` file. Includes a tile grid (interior plus border ring), exit zone markers, and spawn point markers.

**Cell Interior**
The tiles inside a chunk excluding the 1-tile border ring. This is the playable area of the cell.

**Border Ring**
The outermost 1-tile-wide perimeter of a chunk grid. Contains exit zone markers (`^v<>`) and wall markers (`#`). Not placed directly into the map — used to derive connection positions and wall edges.

**Wall Gap**
The space between two adjacent cell interiors in the assembled map. Derived from the grid's wall thickness setting. Filled with wall tiles by default; carved to form connections where the graph specifies.

**Connection**
A passable link between two adjacent cells. Represented as a carved opening through the wall gap at a specific position and width.

**Exit Zone**
A contiguous run of directional markers (`^`, `v`, `<`, `>`) on one face of a chunk's border ring. Defines the tiles on that face eligible to participate in a connection. A chunk face may have zero exit zones (always wall) or one exit zone. Split exits are deferred to a future version.

**Connection Graph**
The set of connections between cells, generated from theme parameters. Determines which adjacent cell pairs are connected and with what topology (branching factor, loop frequency).

**Spawn Point**
A tile within a chunk interior marked with a spawn character (`i`, `r`, `t`, `c`). Passed to the population pass after map generation.

**Theme**
A named parameter bundle controlling grid dimensions, wall thickness, border margin, exit width distribution, and connection graph topology. Defined in code/data, not in chunk files.

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
| Castle 3×3 | `[4, 4, 4]` | 2 | 1 | 12 + 4 + 2 = 16 ✓ |
| Cave 3×3 | `[3, 4, 3]` | 2 | 1 | 10 + 4 + 2 = 16 ✓ |
| Cave 3×3 (thick) | `[3, 3, 3]` | 3 | 1 | 9 + 6 + 2 = 17 ✗ |
| Boss 2×2 | `[6, 6]` | 2 | 1 | 12 + 2 + 2 = 16 ✓ |

Distributions may be fixed per theme or rolled from a small table of valid options at generation time.

**Minimum cell dimension:** No cell width or height may be less than 3 tiles (interior too small to be tactically meaningful or author usefully).

### 3.3 Connection Graph Generation

The connection graph is generated on the macro grid before chunk selection. It determines which adjacent cell pairs have a connection (passable) vs. a wall (impassable).

Parameters (per theme):

- **Connectivity:** The graph must always be fully connected — every cell reachable from every other cell. This is enforced by generating a random spanning tree first, then adding additional edges.
- **Extra edges:** Additional connections beyond the spanning tree, rolled per adjacent pair at a per-theme probability. Controls loop frequency (how often paths rejoin).
- **Map-edge connections:** Whether connections can exist on the map border (cells on the edge connecting outward, for escape/entry points). Off by default; enabled for specific mission types.

The spanning tree is generated by a simple random walk (or Kruskal's algorithm on shuffled edges) over the cell graph.

### 3.4 Future: Grid Shifts

Row and column offsets to reduce grid regularity are planned as a future extension. Not in scope for v1.

---

## 4. Chunks

### 4.1 Chunk Dimensions

A chunk is a rectangular tile grid of width `W_chunk` and height `H_chunk`. These dimensions include the 1-tile border ring, so the cell interior is `(W_chunk - 2) × (H_chunk - 2)`.

A chunk is valid for a cell if:
```
W_chunk - 2 == cell_col_width
H_chunk - 2 == cell_row_height
```

Chunks are selected from the theme's chunk pool filtered to those matching the target cell dimensions.

### 4.2 Border Ring

The border ring is the outermost 1-tile perimeter of the chunk grid. It is used during generation to derive exit zones and wall placement. It is **not** written directly to the map.

**Corner tiles:** Always `#`. Corners are never exit-eligible. The parser enforces this and rejects malformed chunks.

**Non-corner border tiles:**
- `#` — wall; this face position is not eligible for a connection opening
- `^` — exit-eligible on the north face
- `v` — exit-eligible on the south face
- `<` — exit-eligible on the west face
- `>` — exit-eligible on the east face

A contiguous run of directional markers on one face forms one **exit zone**. A `#` within a run breaks it; since split exits are deferred, a chunk face should have at most one contiguous exit zone in v1.

### 4.3 Interior Tiles

The interior (border ring excluded) uses the following tile vocabulary:

| Character | Meaning |
|-----------|---------|
| `#` | Wall |
| `.` | Ground |
| `?` | Optional ground (autotiler may treat as ground or wall) |
| `i` | Spawn: `enemy_infantry` |
| `r` | Spawn: `enemy_ranged` |
| `t` | Spawn: `enemy_tank` |
| `c` | Spawn: `enemy_commander` |

Spawn characters imply the unit spawns at that tile. A chunk with no spawn characters is valid — the population pass may place no enemies in that cell.

### 4.4 Exit Zone Derivation

After parsing, exit zones are stored as tile ranges (1-indexed, inclusive) on each face:

- **North/South face:** column indices 2 through `W_chunk - 1` (excluding corners)
- **East/West face:** row indices 2 through `H_chunk - 1` (excluding corners)

A zone is the contiguous run of directional markers. Example: `#^^^#` on a 5-wide north face produces exit zone `[2, 4]`.

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

A connection requires `overlap_width >= 1`. If the connection graph specifies a connection but no overlap exists, chunk selection for one or both cells must be retried (see Section 8).

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

The passage connects the two cell interiors with a clean rectangular cut at this stage.

### 5.4 Theme Modification Passes

After carving, theme-specific passes modify the opening:

**Cave erosion:** For each tile on the left and right edges of the carved opening, roll to retain or remove it, weighted toward the center. This produces a ragged, organic-looking entrance. Wider openings erode more visibly.

**Castle pass:** None defined in v1. Reserved for future architectural detailing (archway corners, etc.).

### 5.5 Guard Spawn Points

After connection construction, each connection is evaluated for guard placement:

- **Bottleneck check:** Remove this connection from the graph and check if the graph remains connected. If not, this is a bridge connection — flag it as a high-value guard position.
- **Width check:** If the carved width is 1, the connection is eligible for a guard spawn point.
- If both conditions are met, a guard spawn point is placed at the center tile of the passage. The population pass decides whether to fill it, based on mission parameters.

---

## 6. Themes

A theme is a named parameter bundle. Two themes are defined in v1.

### 6.1 Castle

| Parameter | Value |
|-----------|-------|
| Wall thickness | 2 |
| Border margin | 1 |
| Col/row distributions | `[4, 4, 4]` (3×3), `[6, 6]` (2×2) |
| Exit width | 1–2, weighted toward 1 |
| Extra edge probability | 0.2 (low loops — more linear) |
| Cave erosion | No |

### 6.2 Cave

| Parameter | Value |
|-----------|-------|
| Wall thickness | 2 |
| Border margin | 1 |
| Col/row distributions | `[3, 4, 3]` (3×3), `[6, 6]` (2×2) |
| Exit width | 1–4, weighted toward 2–3 |
| Extra edge probability | 0.35 (moderate loops) |
| Cave erosion | Yes |

---

## 7. Chunk File Format

### 7.1 File Naming

One file per theme: `<theme>.chunks` (e.g. `castle.chunks`, `cave.chunks`). The filename implicitly defines the theme for all chunks within. Chunk files are part of a mod's data directory.

### 7.2 File Structure

A chunk file contains one or more chunk definitions separated by blank lines. Each chunk definition consists of:

1. A **label line**: `[chunk_name]` — a unique name within the file, used for debugging and future filtering.
2. A **dimension line**: `W H` — two integers separated by a space. `W` and `H` include the border ring.
3. Exactly `H` **tile rows**, each exactly `W` characters wide.

Comments may appear as lines beginning with `--` and are ignored by the parser.

### 7.3 Example

```
-- castle.chunks
-- Castle theme chunk definitions

[gatehouse]
5 5
#^^##
<....#
<.i..#
<....#
##vv#

[corridor_ns]
5 5
#^^##
#....#
#.i..#
#....#
##vv#

[corner_room]
5 5
#^^##
<....#
<....#
<....#
#####

[wide_hall]
7 5
##^^^##
<.....#
<..i..#
<.....#
##vvv##

-- Cave theme chunk definitions would go in cave.chunks
```

### 7.4 Parser Rules

- Corners (four corner characters of the tile grid) must be `#`. Reject otherwise.
- Non-corner border characters must be one of `# ^ v < >`. Reject other characters in the border ring.
- Interior characters must be one of `# . ? i r t c`. Reject other characters.
- Directional markers must face the correct edge (`^` only on row 0, `v` only on row H-1, `<` only on col 0, `>` only on col W-1). Reject mismatched markers.
- A face may have at most one contiguous run of directional markers in v1. A `#` breaking a directional run is valid (produces a wall column within the border) but results in zero or one zone depending on position — the larger contiguous run is used, or the face has no exit zone if no run exists.
- Chunk names must be unique within a file.
- Blank lines between chunks are required as delimiters. Trailing whitespace is ignored.

---

## 8. Generation Sequence

The full generation procedure in order:

1. **Select theme.** Determined by campaign/mission parameters.
2. **Roll grid shape.** Select W×H from theme's valid configurations.
3. **Roll size distributions.** Select col widths and row heights from theme's distribution table. Validate budget constraint.
4. **Generate connection graph.** Random spanning tree over the cell grid, then roll extra edges per theme probability.
5. **Select chunks.** For each cell, filter the theme's chunk pool to chunks matching the cell's dimensions. From the filtered set, select randomly. Chunks with exit zones on connected faces are preferred; chunks with no exit zone on a connected face are rejected.
6. **Validate exit overlaps.** For each connection in the graph, compute the exit zone overlap in map coordinates. If overlap is insufficient for minimum width 1, reject one or both chunks and retry from step 5. If retry budget is exceeded, regenerate the connection graph (step 4).
7. **Roll exit widths and positions.** For each connection, roll width from theme distribution clamped to overlap. Roll position within overlap.
8. **Assemble tile map.** Place all cell interiors at their computed map positions. Fill wall gaps with wall tiles. Fill border margin with wall tiles.
9. **Carve connections.** For each connection, carve the opening through the wall gap. Apply theme modification passes (erosion, etc.).
10. **Flag bottleneck connections.** Run bridge detection on the connection graph. Flag bridge connections with width 1 as guard spawn candidates.
11. **Collect spawn points.** Gather all spawn characters from all chunk interiors, translated to map coordinates. Include guard spawn candidates. Pass to population pass.
12. **Hand off.** Emit the tile map (for autotiling) and spawn point list (for population pass).

---

## 9. Validation & Rejection

| Check | When | Action on failure |
|-------|------|------------------|
| Budget constraint | Theme definition | Hard error — fix theme data |
| Corner tiles are `#` | Chunk parse | Reject chunk file |
| Valid border characters | Chunk parse | Reject chunk file |
| Valid interior characters | Chunk parse | Reject chunk file |
| Directional markers on correct face | Chunk parse | Reject chunk file |
| Unique chunk names | Chunk parse | Reject chunk file |
| Minimum cell dimension ≥ 3 | Grid roll | Reroll distribution |
| Graph fully connected | Graph generation | Regenerate graph |
| Exit overlap ≥ 1 | Post-chunk-selection | Retry chunk selection (max 10 attempts per cell, then regenerate graph) |

---

## 10. Extension Points

The following are out of scope for v1 but the system is designed to accommodate them:

**Grid shifts (jitter).** Row and column offsets applied after size distribution to reduce grid regularity. Requires exit overlap validation to account for shifted positions.

**Additional themes.** Village, forest, open terrain. Village requires thin-wall border style (1-tile fences) as a theme parameter. Forest requires open/no-wall border style with interior obstacle clusters.

**Multi-cell chunks.** A chunk spanning two adjacent cells. Requires the chunk selection step to treat two cells as a unit and skip connection construction on their shared face.

**Variable macro grid shape per campaign position.** The campaign layer selects grid shape based on battle index or narrative context (e.g., boss battles always use 2×2).

**Autotiling interface.** This system outputs a tile map using the generation vocabulary (`# . ?`). The autotiler consumes this and produces the final themed tile indices. Autotiling rules are theme-specific and defined separately.

**Population interface.** This system outputs a spawn point list with role tags and guard flags. The population pass consumes this and selects specific units from the active enemy faction.
