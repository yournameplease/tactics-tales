# Enemy Distribution Modes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `enemy_distribution = "room_based" | "scatter"` to `ProcgenMapDefinition`; scatter mode randomly places `i` (enemy_infantry) glyphs on floor tiles after glyph-grid assembly instead of using chunk-level has_enemies filtering.

**Architecture:** Four-file change. (1) `placement.select` skips `roll_enemy_cells` in scatter mode, returning `enemy_cells = nil`. (2) `chunk_selector.generate` threads `enemy_distribution` through to placement. (3) New `glyph_grid.scatter_enemies` post-processes assembled rows. (4) `load_procgen` reads definition fields and calls the new function. `cell_has_enemies_flag` already returns `false` when `enemy_cells == nil`, so chunk selection automatically forces non-enemy chunks in scatter mode—no changes needed there.

**Tech Stack:** Lua 5.4, Busted test runner (`make test`), LuaCATS annotations.

---

### Task 1: `placement.select` — scatter mode returns `enemy_cells = nil`

**Files:**
- Modify: `src/tactics/battle/map/procgen/placement_spec.lua`
- Modify: `src/tactics/battle/map/procgen/placement.lua`

- [ ] **Step 1: Write the failing tests**

Add at the end of the `"enemy_cells"` describe block in `src/spec/battle/map/procgen/placement_spec.lua`:

```lua
describe("scatter mode", function()
    it("returns enemy_cells = nil for kill_boss", function()
        local g = chain4()
        local theme = { enemy_room_probability = 1.0 }
        local result = placement.select(g, "kill_boss", random.new(1), theme, "scatter")
        luassert.is_nil(result.enemy_cells)
    end)

    it("returns enemy_cells = nil for escape", function()
        local g = chain4()
        local theme = { enemy_room_probability = 1.0 }
        local result = placement.select(g, "escape", random.new(1), theme, "scatter")
        luassert.is_nil(result.enemy_cells)
    end)

    it("returns enemy_cells = nil for rout", function()
        local theme = { enemy_room_probability = 1.0 }
        local result = placement.select(star4(), "rout", random.new(1), theme, "scatter")
        luassert.is_nil(result.enemy_cells)
    end)

    it("returns enemy_cells = nil for defend", function()
        local theme = { enemy_room_probability = 1.0 }
        local result = placement.select(star4(), "defend", random.new(1), theme, "scatter")
        luassert.is_nil(result.enemy_cells)
    end)
end)
```

- [ ] **Step 2: Run tests to confirm they fail**

```bash
busted build/spec/battle/map/procgen/placement_spec.lua
```

Expected: 4 failures — "attempt to index nil value" or assertion error on `enemy_cells` being a table.

- [ ] **Step 3: Implement scatter mode in `placement.select`**

In `src/tactics/battle/map/procgen/placement.lua`, change the function signature and add a local `is_scatter` flag. Then replace each `roll_enemy_cells` call with a conditional:

```lua
function placement.select(g, objective, rng, theme, enemy_distribution)
    local is_scatter = enemy_distribution == "scatter"
    local prob = is_scatter and 0 or (theme and theme.enemy_room_probability or 0)
```

And in each return site, change:
```lua
local enemy_cells = roll_enemy_cells(g, specials, prob, rng)
```
to:
```lua
local enemy_cells = is_scatter and nil or roll_enemy_cells(g, specials, prob, rng)
```

There are three such sites (kill_boss branch, escape branch, rout/defend branch). The full updated function:

```lua
function placement.select(g, objective, rng, theme, enemy_distribution)
    local is_scatter = enemy_distribution == "scatter"
    local prob = is_scatter and 0 or (theme and theme.enemy_room_probability or 0)

    if objective == "kill_boss" or objective == "escape" then
        local d_from_start = graph_mod.bfs_distances(g, 1)
        local end_cell = 1
        for node, d in pairs(d_from_start) do
            if d > d_from_start[end_cell] then end_cell = node end
        end

        local d_from_end = graph_mod.bfs_distances(g, end_cell)
        local max_d = -1
        for _, d in pairs(d_from_end) do
            if d > max_d then max_d = d end
        end
        local target_d = (theme and theme.target_deployment_distance) or max_d
        local pick_d = target_d <= max_d and target_d or max_d
        local candidates = {}
        for node, d in pairs(d_from_end) do
            if d == pick_d then table.insert(candidates, node) end
        end
        sort.by(candidates)
        local deployment_cell = candidates[rng:rndi(#candidates) + 1]

        if objective == "kill_boss" then
            local specials = { [deployment_cell] = true, [end_cell] = true }
            local enemy_cells = is_scatter and nil or roll_enemy_cells(g, specials, prob, rng)
            return { deployment_cell = deployment_cell, boss_cell = end_cell, enemy_cells = enemy_cells }
        else
            local specials = { [deployment_cell] = true, [end_cell] = true }
            local enemy_cells = is_scatter and nil or roll_enemy_cells(g, specials, prob, rng)
            return { deployment_cell = deployment_cell, escape_cell = end_cell, enemy_cells = enemy_cells }
        end

    elseif objective == "rout" or objective == "defend" then
        local ecc = graph_mod.node_eccentricities(g)
        local candidates = {}
        for node, e in pairs(ecc) do
            if #(g.adjacency[node] or {}) >= 2 then
                table.insert(candidates, { node = node, ecc = e, degree = #g.adjacency[node] })
            end
        end
        if #candidates == 0 then
            for node, e in pairs(ecc) do
                table.insert(candidates, { node = node, ecc = e, degree = #(g.adjacency[node] or {}) })
            end
        end
        local min_ecc = math.huge
        for _, c in ipairs(candidates) do
            if c.ecc < min_ecc then min_ecc = c.ecc end
        end
        local max_deg = -1
        for _, c in ipairs(candidates) do
            if c.ecc == min_ecc and c.degree > max_deg then max_deg = c.degree end
        end
        local top = {}
        for _, c in ipairs(candidates) do
            if c.ecc == min_ecc and c.degree == max_deg then
                table.insert(top, c.node)
            end
        end
        sort.by(top)
        local deployment_cell = top[rng:rndi(#top) + 1]
        local specials = { [deployment_cell] = true }
        local enemy_cells = is_scatter and nil or roll_enemy_cells(g, specials, prob, rng)
        return { deployment_cell = deployment_cell, enemy_cells = enemy_cells }

    else
        error("placement.select: unknown objective '" .. tostring(objective) .. "'")
    end
end
```

- [ ] **Step 4: Run tests to confirm they pass**

```bash
busted build/spec/battle/map/procgen/placement_spec.lua
```

Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add src/tactics/battle/map/procgen/placement.lua src/spec/battle/map/procgen/placement_spec.lua
git commit -m "feat: placement.select skips enemy_cells in scatter distribution mode"
```

---

### Task 2: `chunk_selector.generate` — thread `enemy_distribution` to placement

**Files:**
- Modify: `src/spec/battle/map/procgen/chunk_selector_spec.lua`
- Modify: `src/tactics/battle/map/procgen/chunk_selector.lua`

- [ ] **Step 1: Write the failing test**

Add a new `describe` block after `"generate"` in `src/spec/battle/map/procgen/chunk_selector_spec.lua`:

```lua
describe("generate with scatter distribution", function()
    it("regular cells use non-enemy chunks when enemy_distribution = 'scatter'", function()
        -- Pool: deployment chunk + non-enemy chunk only.
        -- In scatter mode, regular cells must use non-enemy chunks (enemy_cells=nil
        -- → cell_has_enemies_flag returns false → filter excludes has_enemies chunks).
        -- If scatter mode mistakenly left enemy_cells as a table, the pool would still
        -- work here. So also test that an enemy-only pool fails.
        local pool = {
            all_exits_chunk("deploy", true),
            all_exits_chunk("plain"),
        }
        local rng = random.new(42)
        local result = chunk_selector.generate(make_theme(), make_2x2_grid(), pool, rng, "rout", "scatter")
        luassert.is_not_nil(result, "generate should succeed with non-enemy chunks in scatter mode")
        -- Verify no regular cell has has_enemies tag.
        for idx, chunk in ipairs(result.assignment) do
            if idx ~= result.deployment_cell then
                for _, t in ipairs(chunk.tags) do
                    luassert.are_not_equal("has_enemies", t,
                        "cell " .. idx .. " should not have has_enemies tag in scatter mode")
                end
            end
        end
    end)

    it("errors when pool only has enemy chunks for regular cells", function()
        -- enemy-only regular pool: no non-enemy chunk available for scatter mode
        local pool = {
            all_exits_chunk("deploy", true),
            enemy_chunk("enemy_1"),
            enemy_chunk("enemy_2"),
        }
        local rng = random.new(1)
        luassert.has_error(function()
            chunk_selector.generate(make_theme(), make_2x2_grid(), pool, rng, "rout", "scatter")
        end)
    end)
end)
```

- [ ] **Step 2: Run tests to confirm they fail**

```bash
busted build/spec/battle/map/procgen/chunk_selector_spec.lua
```

Expected: 2 failures — the scatter test either passes by accident (wrong) or fails with wrong behavior.

- [ ] **Step 3: Add `enemy_distribution` parameter to `chunk_selector.generate`**

In `src/tactics/battle/map/procgen/chunk_selector.lua`, update the `generate` function signature and the call to `placement_mod.select`:

Change:
```lua
function chunk_selector.generate(theme, grid, chunks, rng, objective)
    objective = objective or "rout"
```
to:
```lua
function chunk_selector.generate(theme, grid, chunks, rng, objective, enemy_distribution)
    objective = objective or "rout"
```

Change:
```lua
local p = placement_mod.select(g, objective, rng, theme)
```
to:
```lua
local p = placement_mod.select(g, objective, rng, theme, enemy_distribution)
```

Also update the LuaCATS annotation above the function:
```lua
---@param objective string?  Battle objective type passed to placement_mod.select
---@param enemy_distribution string?  "room_based" or "scatter"; nil defaults to "room_based"
```

- [ ] **Step 4: Run tests to confirm they pass**

```bash
busted build/spec/battle/map/procgen/chunk_selector_spec.lua
```

Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add src/tactics/battle/map/procgen/chunk_selector.lua src/spec/battle/map/procgen/chunk_selector_spec.lua
git commit -m "feat: chunk_selector.generate threads enemy_distribution to placement.select"
```

---

### Task 3: `glyph_grid.scatter_enemies` — post-assembly scatter pass

**Files:**
- Modify: `src/spec/battle/map/procgen/glyph_grid_spec.lua`
- Modify: `src/tactics/battle/map/procgen/glyph_grid.lua`

- [ ] **Step 1: Write the failing tests**

Add a new `describe("scatter_enemies", ...)` block at the end of the outer `describe` in `src/spec/battle/map/procgen/glyph_grid_spec.lua`, after the `assemble` block. The helpers `make_grid` and `make_chunk` are already defined at file scope.

Grid layout reference for tests (using `make_grid()` — 2×2, col_widths={7,7}, row_heights={7,7}, col_walls={2}, row_walls={2}, no borders):
- Cell 1 (col=1,row=1): interior x=[1..7], y=[1..7]
- Cell 2 (col=2,row=1): interior x=[10..16], y=[1..7]
- Cell 3 (col=1,row=2): interior x=[1..7], y=[10..16]
- Cell 4 (col=2,row=2): interior x=[10..16], y=[10..16]
- Wall columns x=8,9 and rows y=8,9 are not interior to any cell.

```lua
describe("scatter_enemies", function()
    --- 16×16 rows of all-floor glyphs.
    local function floor_rows()
        local rows = {}
        for i = 1, 16 do rows[i] = string.rep(".", 16) end
        return rows
    end

    --- RNG stub that always returns 0 from rndf() (every roll succeeds when prob > 0).
    local function always_hit_rng()
        return { rndf = function() return 0 end }
    end

    --- RNG stub that always returns 1 from rndf() (every roll fails).
    local function always_miss_rng()
        return { rndf = function() return 1 end }
    end

    it("replaces '.' with 'i' in non-special cell interiors at prob=1.0", function()
        local rows = floor_rows()
        local gen_result = { placement = { deployment_cell = 1 } }
        glyph_grid.scatter_enemies(rows, gen_result, make_grid(), 1.0, always_hit_rng())

        -- Cell 1 (special — deployment): interior must remain '.'.
        luassert.are_equal(".", rows[1]:sub(1, 1), "cell 1 interior x=1,y=1 should stay '.'")
        luassert.are_equal(".", rows[7]:sub(7, 7), "cell 1 interior x=7,y=7 should stay '.'")

        -- Cell 2 (non-special): interior must be 'i'.
        luassert.are_equal("i", rows[1]:sub(10, 10), "cell 2 interior x=10,y=1 should be 'i'")
        luassert.are_equal("i", rows[7]:sub(16, 16), "cell 2 interior x=16,y=7 should be 'i'")

        -- Cell 3 (non-special): interior must be 'i'.
        luassert.are_equal("i", rows[10]:sub(1, 1), "cell 3 interior x=1,y=10 should be 'i'")

        -- Cell 4 (non-special): interior must be 'i'.
        luassert.are_equal("i", rows[10]:sub(10, 10), "cell 4 interior x=10,y=10 should be 'i'")

        -- Wall gap tiles (not in any cell interior): must remain '.'.
        luassert.are_equal(".", rows[1]:sub(8, 8),  "wall gap x=8,y=1 should stay '.'")
        luassert.are_equal(".", rows[8]:sub(1, 1),  "wall gap x=1,y=8 should stay '.'")
    end)

    it("makes no changes at prob=0.0", function()
        local rows = floor_rows()
        local gen_result = { placement = { deployment_cell = 1 } }
        glyph_grid.scatter_enemies(rows, gen_result, make_grid(), 0.0, always_hit_rng())

        for y = 1, 16 do
            luassert.are_equal(string.rep(".", 16), rows[y], "row " .. y .. " should be unchanged")
        end
    end)

    it("makes no changes when rng always misses", function()
        local rows = floor_rows()
        local gen_result = { placement = { deployment_cell = 1 } }
        glyph_grid.scatter_enemies(rows, gen_result, make_grid(), 1.0, always_miss_rng())

        for y = 1, 16 do
            luassert.are_equal(string.rep(".", 16), rows[y], "row " .. y .. " should be unchanged")
        end
    end)

    it("does not replace non-'.' glyphs", function()
        local rows = floor_rows()
        -- Place a '#' and a 'd' inside cell 2's interior.
        local r2 = rows[2]
        rows[2] = r2:sub(1, 9) .. "#d" .. r2:sub(12)
        local gen_result = { placement = { deployment_cell = 1 } }
        glyph_grid.scatter_enemies(rows, gen_result, make_grid(), 1.0, always_hit_rng())

        luassert.are_equal("#", rows[2]:sub(10, 10), "# at x=10,y=2 must stay '#'")
        luassert.are_equal("d", rows[2]:sub(11, 11), "d at x=11,y=2 must stay 'd'")
    end)

    it("skips boss_cell and escape_cell as special cells", function()
        local rows = floor_rows()
        local gen_result = {
            placement = {
                deployment_cell = 1,
                boss_cell       = 2,
                escape_cell     = 3,
            }
        }
        glyph_grid.scatter_enemies(rows, gen_result, make_grid(), 1.0, always_hit_rng())

        -- Cells 1, 2, 3 are special: interior must remain '.'.
        luassert.are_equal(".", rows[1]:sub(10, 10), "boss cell 2 interior should stay '.'")
        luassert.are_equal(".", rows[10]:sub(1, 1),  "escape cell 3 interior should stay '.'")
        -- Cell 4 is non-special: must be 'i'.
        luassert.are_equal("i", rows[10]:sub(10, 10), "cell 4 interior should be 'i'")
    end)
end)
```

- [ ] **Step 2: Run tests to confirm they fail**

```bash
busted build/spec/battle/map/procgen/glyph_grid_spec.lua
```

Expected: 5 failures — `attempt to call a nil value (field 'scatter_enemies')`.

- [ ] **Step 3: Implement `glyph_grid.scatter_enemies`**

Add the following function to `src/tactics/battle/map/procgen/glyph_grid.lua`, before `return glyph_grid`:

```lua
--- Scatter enemy-infantry glyphs over floor tiles in non-special cells.
--- Modifies `rows` entries in-place (replaces string entries).
--- Skips deployment_cell, boss_cell, and escape_cell.
---@param rows string[]
---@param gen_result ChunkGenerationResult
---@param grid ProcgenGrid
---@param prob number  Per-tile probability of placing 'i' on a '.' tile.
---@param rng RngInstance
function glyph_grid.scatter_enemies(rows, gen_result, grid, prob, rng)
    local p = gen_result.placement
    local specials = { [p.deployment_cell] = true }
    if p.boss_cell   then specials[p.boss_cell]   = true end
    if p.escape_cell then specials[p.escape_cell] = true end

    local grid_w = #grid.col_widths
    local grid_h = #grid.row_heights
    local n = grid_w * grid_h

    for idx = 1, n do
        if not specials[idx] then
            local col = ((idx - 1) % grid_w) + 1
            local row = math.floor((idx - 1) / grid_w) + 1
            local x0 = grid_layout.cell_x_start(grid, col)
            local y0 = grid_layout.cell_y_start(grid, row)
            local w  = grid.col_widths[col]
            local h  = grid.row_heights[row]
            for cy = y0, y0 + h - 1 do
                local row_str = rows[cy]
                local chars = {}
                for i = 1, #row_str do chars[i] = row_str:sub(i, i) end
                local changed = false
                for cx = x0, x0 + w - 1 do
                    if chars[cx] == "." and rng:rndf() < prob then
                        chars[cx] = "i"
                        changed = true
                    end
                end
                if changed then
                    rows[cy] = table.concat(chars)
                end
            end
        end
    end
end
```

Note: `grid_layout` is already required at the top of `glyph_grid.lua`.

- [ ] **Step 4: Run tests to confirm they pass**

```bash
busted build/spec/battle/map/procgen/glyph_grid_spec.lua
```

Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add src/tactics/battle/map/procgen/glyph_grid.lua src/spec/battle/map/procgen/glyph_grid_spec.lua
git commit -m "feat: add glyph_grid.scatter_enemies for post-assembly infantry scatter"
```

---

### Task 4: Wire scatter into `load_procgen`

**Files:**
- Modify: `src/tactics/battle/map/map_generator.lua`
- Modify: `src/spec/battle/map/map_generator_spec.lua`

- [ ] **Step 1: Write the failing test**

In `src/spec/battle/map/map_generator_spec.lua`, add a new `it` block inside the `"load_map (procgen type)"` describe, after the existing rout placement test. This test uses the existing `FIXTURE_CHUNKS` and `stub_fetch_chunks` helpers already defined in that describe block:

```lua
it("scatter mode with prob=1.0 produces enemy_infantry tile labels", function()
    local restore = stub_fetch_chunks()
    local def = {
        type = "procgen",
        theme = "castle",
        chunks = "fixture.chunks",
        objective = "rout",
        enemy_distribution = "scatter",
        scatter_probability = 1.0,
    }
    local map = map_generator.load_map(def, {}, {}, 1)
    restore()
    luassert.is_not_nil(map.tile_labels, "expected tile_labels on map")
    luassert.is_not_nil(map.tile_labels.enemy_infantry,
        "expected enemy_infantry labels from scatter with prob=1.0")
    luassert.is_true(#map.tile_labels.enemy_infantry > 0,
        "expected at least one enemy_infantry spawn point")
end)
```

- [ ] **Step 2: Run test to confirm it fails**

```bash
busted build/spec/battle/map/map_generator_spec.lua
```

Expected: 1 failure — `nil` tile_labels or empty enemy_infantry (scatter not wired in yet).

- [ ] **Step 3: Add type annotations and wire scatter into `load_procgen`**

In `src/tactics/battle/map/map_generator.lua`:

**3a.** Update the `ProcgenMapDefinition` annotation (around line 19):

```lua
---@class ProcgenMapDefinition : MapDefinition
---@field type "procgen"
---@field theme string Theme name (key in the themes table, e.g. "castle").
---@field chunks string Path to the .chunks file (passed to chunk_parser.load_theme).
---@field tileset_name string? Tileset stem for gfx_registry lookup (e.g. "paper_tileset").
---@field objective string? Battle objective type ("kill_boss", "escape", "rout"). Defaults to "rout".
---@field enemy_distribution "room_based"|"scatter"? Defaults to "room_based".
---@field scatter_probability number? Per-tile infantry spawn probability for scatter mode. Defaults to 0.02.
```

**3b.** In `load_procgen`, change the `chunk_selector.generate` call and add the scatter pass:

Change:
```lua
local gen_result = chunk_selector.generate(theme, grid, chunks, rng, definition.objective)
local assembled = glyph_grid_mod.assemble(theme, grid, gen_result, gen_result.offscreen_edges, rng)
```
to:
```lua
local gen_result = chunk_selector.generate(theme, grid, chunks, rng, definition.objective, definition.enemy_distribution)
local assembled = glyph_grid_mod.assemble(theme, grid, gen_result, gen_result.offscreen_edges, rng)
if definition.enemy_distribution == "scatter" then
    local prob = definition.scatter_probability or 0.02
    glyph_grid_mod.scatter_enemies(assembled.rows, gen_result, grid, prob, rng)
end
```

- [ ] **Step 4: Run all tests to confirm everything passes**

```bash
make test
```

Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add src/tactics/battle/map/map_generator.lua src/spec/battle/map/map_generator_spec.lua
git commit -m "feat: wire enemy_distribution=scatter into load_procgen pipeline"
```
