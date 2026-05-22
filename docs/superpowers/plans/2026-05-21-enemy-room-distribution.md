# Enemy Room Distribution Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Randomly designate non-special rooms as enemy or non-enemy rooms during procgen placement, and enforce that designation during chunk selection.

**Architecture:** `themes.lua` adds `enemy_room_probability`; `placement.select()` rolls each non-special cell and stores results in `enemy_cells` on `ProcgenPlacement`; `chunk_selector.filter_candidates()` receives a `has_enemies` flag and filters accordingly.

**Tech Stack:** Lua, Busted (test runner — `make test` or `busted build/spec/path/to/file_spec.lua`)

---

### Task 1: Add `enemy_room_probability` to themes

**Files:**
- Modify: `src/tactics/battle/map/procgen/themes.lua`
- Test: `src/spec/battle/map/procgen/themes_spec.lua`

- [ ] **Step 1: Write the failing test**

In `themes_spec.lua`, add inside the `describe("validate"` block:

```lua
it("rejects enemy_room_probability outside [0, 1]", function()
    luassert.has_error(function()
        themes.validate(make_theme({ enemy_room_probability = 1.5 }))
    end)
    luassert.has_error(function()
        themes.validate(make_theme({ enemy_room_probability = -0.1 }))
    end)
end)

it("accepts enemy_room_probability of 0 and 1", function()
    luassert.has_no.errors(function()
        themes.validate(make_theme({ enemy_room_probability = 0 }))
    end)
    luassert.has_no.errors(function()
        themes.validate(make_theme({ enemy_room_probability = 1 }))
    end)
end)
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
busted build/spec/battle/map/procgen/themes_spec.lua
```

Expected: failures on the new tests (enemy_room_probability not validated yet).

- [ ] **Step 3: Add the field annotation to `ProcgenTheme` in `themes.lua`**

In the `---@class ProcgenTheme` block, add after `target_deployment_distance`:

```lua
---@field enemy_room_probability number  Per-cell probability a non-special room gets enemies. Range [0, 1].
```

- [ ] **Step 4: Add validation in `themes.validate()`**

After the `off_screen_edge_probability` assertion in `themes.validate()`:

```lua
assert(
    theme.enemy_room_probability >= 0 and theme.enemy_room_probability <= 1,
    "enemy_room_probability must be in [0, 1]"
)
```

- [ ] **Step 5: Set the value on both themes**

In `themes.castle`, add after `off_screen_edge_probability`:
```lua
enemy_room_probability = 0.4,
```

In `themes.cave`, add after `off_screen_edge_probability`:
```lua
enemy_room_probability = 0.4,
```

- [ ] **Step 6: Run tests to verify they pass**

```bash
busted build/spec/battle/map/procgen/themes_spec.lua
```

Expected: all pass.

- [ ] **Step 7: Commit**

```bash
git add src/tactics/battle/map/procgen/themes.lua src/spec/battle/map/procgen/themes_spec.lua
git commit -m "feat: add enemy_room_probability to ProcgenTheme"
```

---

### Task 2: Roll `enemy_cells` in `placement.select()`

**Files:**
- Modify: `src/tactics/battle/map/procgen/placement.lua`
- Test: `src/spec/battle/map/procgen/placement_spec.lua`

- [ ] **Step 1: Write the failing tests**

In `placement_spec.lua`, add a new `describe` block at the end (before the final `end)`):

```lua
describe("enemy_cells", function()
    it("marks all non-special cells as enemy when probability = 1.0", function()
        -- chain4: kill_boss places deployment at one pole, boss at the other.
        -- The two middle cells (2 and 3) are non-special.
        local g = chain4()
        local theme = { target_deployment_distance = nil, enemy_room_probability = 1.0 }
        local result = placement.select(g, "kill_boss", random.new(1), theme)
        local specials = { [result.deployment_cell] = true, [result.boss_cell] = true }
        for node in pairs(g.adjacency) do
            if not specials[node] then
                luassert.is_true(result.enemy_cells[node] == true,
                    "expected node " .. node .. " to be in enemy_cells")
            end
        end
    end)

    it("marks no cells as enemy when probability = 0.0", function()
        local g = chain4()
        local theme = { target_deployment_distance = nil, enemy_room_probability = 0.0 }
        local result = placement.select(g, "kill_boss", random.new(1), theme)
        local count = 0
        for _ in pairs(result.enemy_cells) do count = count + 1 end
        luassert.are_equal(0, count)
    end)

    it("never marks special cells as enemy", function()
        local g = chain4()
        local theme = { target_deployment_distance = nil, enemy_room_probability = 1.0 }
        local result = placement.select(g, "kill_boss", random.new(1), theme)
        luassert.is_nil(result.enemy_cells[result.deployment_cell])
        luassert.is_nil(result.enemy_cells[result.boss_cell])
    end)

    it("returns empty enemy_cells when theme is nil", function()
        local result = placement.select(chain4(), "kill_boss", random.new(1), nil)
        local count = 0
        for _ in pairs(result.enemy_cells) do count = count + 1 end
        luassert.are_equal(0, count)
    end)

    it("returns empty enemy_cells when theme has no enemy_room_probability", function()
        local theme = { target_deployment_distance = nil }
        local result = placement.select(chain4(), "kill_boss", random.new(1), theme)
        local count = 0
        for _ in pairs(result.enemy_cells) do count = count + 1 end
        luassert.are_equal(0, count)
    end)
end)
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
busted build/spec/battle/map/procgen/placement_spec.lua
```

Expected: failures (enemy_cells not yet on the return value).

- [ ] **Step 3: Add `enemy_cells` to the `ProcgenPlacement` annotation in `placement.lua`**

In the `---@class ProcgenPlacement` block, add:

```lua
---@field enemy_cells table<integer, true>  non-special cells designated as enemy rooms
```

- [ ] **Step 4: Extract a shared helper and roll enemy_cells in `placement.select()`**

Add a local helper before `placement.select`:

```lua
--- Roll enemy_cells for all nodes in g that are not in `specials`.
---@param g ConnectionGraph
---@param specials table<integer, true>
---@param prob number
---@param rng RngInstance
---@return table<integer, true>
local function roll_enemy_cells(g, specials, prob, rng)
    local enemy_cells = {}
    for node in pairs(g.adjacency) do
        if not specials[node] and rng:rndf() < prob then
            enemy_cells[node] = true
        end
    end
    return enemy_cells
end
```

Then in `placement.select()`, after each return point, add the `enemy_cells` field. The pattern is:

After computing `deployment_cell`, `boss_cell`/`escape_cell`, collect specials and roll:

```lua
local prob = theme and theme.enemy_room_probability or 0
```

For the `kill_boss` branch, replace the return:

```lua
local specials = { [deployment_cell] = true, [end_cell] = true }
local enemy_cells = roll_enemy_cells(g, specials, prob, rng)
return { deployment_cell = deployment_cell, boss_cell = end_cell, enemy_cells = enemy_cells }
```

For the `escape` branch, replace the return:

```lua
local specials = { [deployment_cell] = true, [end_cell] = true }
local enemy_cells = roll_enemy_cells(g, specials, prob, rng)
return { deployment_cell = deployment_cell, escape_cell = end_cell, enemy_cells = enemy_cells }
```

For the `rout`/`defend` branch, replace the return:

```lua
local specials = { [deployment_cell] = true }
local enemy_cells = roll_enemy_cells(g, specials, prob, rng)
return { deployment_cell = deployment_cell, enemy_cells = enemy_cells }
```

The `prob` variable must be computed before the `if objective ==` branching. Add this line immediately after the function signature (before the first `if`):

```lua
local prob = theme and theme.enemy_room_probability or 0
```

- [ ] **Step 5: Run tests to verify they pass**

```bash
busted build/spec/battle/map/procgen/placement_spec.lua
```

Expected: all pass.

- [ ] **Step 6: Run the full suite to check for regressions**

```bash
make test
```

Expected: all pass.

- [ ] **Step 7: Commit**

```bash
git add src/tactics/battle/map/procgen/placement.lua src/spec/battle/map/procgen/placement_spec.lua
git commit -m "feat: roll enemy_cells in placement.select()"
```

---

### Task 3: Enforce `has_enemies` in `chunk_selector`

**Files:**
- Modify: `src/tactics/battle/map/procgen/chunk_selector.lua`
- Test: `src/spec/battle/map/procgen/chunk_selector_spec.lua`

- [ ] **Step 1: Write the failing tests**

In `chunk_selector_spec.lua`, add a helper and new tests. Add the helper after the existing helpers (after `north_last_chunk`):

```lua
--- Chunk with exits on all four faces and the "has_enemies" tag.
---@param name string
---@return ChunkRecord
local function enemy_chunk(name)
    return {
        name = name, width = 3, height = 3,
        tags = { "has_enemies" },
        rows = { "#^^^#", "<...>", "<...>", "<...>", "#vvv#" },
        exits = {
            north = { min = 2, max = 4 }, south = { min = 2, max = 4 },
            east  = { min = 2, max = 4 }, west  = { min = 2, max = 4 },
        },
    }
end
```

Then add a new `describe` block inside the outer `describe("tactics.battle.map.procgen.chunk_selector"`:

```lua
describe("select with enemy_cells", function()
    it("assigns enemy chunks to enemy cells and non-enemy chunks to non-enemy cells", function()
        -- 2x2 grid. Cell 1 = deployment (special, unconstrained). Cells 2,3,4 = regular.
        -- Cell 2 marked enemy; cells 3,4 non-enemy.
        -- Pool: one deployment chunk, one enemy chunk, one non-enemy chunk.
        local pool = {
            all_exits_chunk("deploy", true),
            enemy_chunk("enemy"),
            all_exits_chunk("plain"),
        }
        local g = make_2x2_graph()
        local placement = {
            deployment_cell = 1,
            enemy_cells     = { [2] = true },
        }
        local rng = random.new(1)
        local result = chunk_selector.select(make_2x2_grid(), g, pool, rng, nil, placement)

        luassert.is_not_nil(result)
        -- Cell 2 must be the enemy_chunk.
        local has_enemies_tag = false
        for _, t in ipairs(result.assignment[2].tags) do
            if t == "has_enemies" then has_enemies_tag = true end
        end
        luassert.is_true(has_enemies_tag, "cell 2 (enemy) should have has_enemies tag")
        -- Cells 3 and 4 must NOT be the enemy_chunk.
        for _, idx in ipairs({ 3, 4 }) do
            for _, t in ipairs(result.assignment[idx].tags) do
                luassert.are_not_equal("has_enemies", t,
                    "cell " .. idx .. " (non-enemy) should not have has_enemies tag")
            end
        end
    end)

    it("returns nil when no non-enemy chunk is available for a non-enemy cell", function()
        -- Pool only has enemy chunks (and the deployment chunk).
        -- Non-enemy cells cannot be satisfied.
        local pool = {
            all_exits_chunk("deploy", true),
            enemy_chunk("enemy_1"),
            enemy_chunk("enemy_2"),
        }
        local placement = {
            deployment_cell = 1,
            enemy_cells     = {},  -- no enemy cells — all regular cells are non-enemy
        }
        local rng = random.new(1)
        local result, err = chunk_selector.select(make_2x2_grid(), make_2x2_graph(), pool, rng, nil, placement)

        luassert.is_nil(result)
        luassert.is_not_nil(err)
    end)

    it("does not constrain special cells on has_enemies", function()
        -- Deployment cell can use a non-enemy chunk even if enemy_cells is all non-specials.
        local pool = {
            all_exits_chunk("deploy", true),
            enemy_chunk("enemy"),
        }
        local g = make_2x2_graph()
        -- All non-special cells are enemy cells.
        local n = #g.adjacency
        local enemy_cells = {}
        for i = 2, n do enemy_cells[i] = true end
        local placement = { deployment_cell = 1, enemy_cells = enemy_cells }
        local rng = random.new(1)
        local result = chunk_selector.select(make_2x2_grid(), g, pool, rng, nil, placement)

        luassert.is_not_nil(result)
        -- Deployment cell has deployment tag, not has_enemies.
        local has_deploy = false
        for _, t in ipairs(result.assignment[1].tags) do
            if t == "deployment" then has_deploy = true end
        end
        luassert.is_true(has_deploy)
    end)
end)
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
busted build/spec/battle/map/procgen/chunk_selector_spec.lua
```

Expected: the new tests fail.

- [ ] **Step 3: Add a helper to check for the `has_enemies` tag in `chunk_selector.lua`**

Add after `get_special_tag`:

```lua
---@param chunk ChunkRecord
---@return boolean
local function chunk_has_enemies(chunk)
    for _, t in ipairs(chunk.tags) do
        if t == "has_enemies" then return true end
    end
    return false
end
```

- [ ] **Step 4: Add `has_enemies` parameter to `filter_candidates`**

Change the signature and add filtering inside the loop. The complete updated function:

```lua
---@param chunks ChunkRecord[]
---@param cw integer
---@param ch integer
---@param required_tag string?
---@param faces table<string, true>
---@param has_enemies boolean?
---@return ChunkRecord[]
local function filter_candidates(chunks, cw, ch, required_tag, faces, has_enemies)
    local result = {}
    for _, chunk in ipairs(chunks) do
        if chunk.width == cw and chunk.height == ch then
            if get_special_tag(chunk) == required_tag then
                local ok = true
                for face in pairs(faces) do
                    if not chunk.exits[face] then ok = false; break end
                end
                if ok and has_enemies ~= nil then
                    if chunk_has_enemies(chunk) ~= has_enemies then ok = false end
                end
                if ok then table.insert(result, chunk) end
            end
        end
    end
    return result
end
```

- [ ] **Step 5: Compute `has_enemies` per cell in `chunk_selector.select()` and pass to `filter_candidates`**

In `chunk_selector.select()`, the initial selection loop currently reads:

```lua
local required_tag = cell_required_tag(idx, placement)
local candidates = filter_candidates(
    chunks,
    grid.col_widths[col],
    grid.row_heights[row],
    required_tag,
    all_faces(idx)
)
```

Replace with:

```lua
local required_tag = cell_required_tag(idx, placement)
local has_enemies_flag
if required_tag == nil then
    has_enemies_flag = placement.enemy_cells ~= nil and placement.enemy_cells[idx] == true
end
local candidates = filter_candidates(
    chunks,
    grid.col_widths[col],
    grid.row_heights[row],
    required_tag,
    all_faces(idx),
    has_enemies_flag
)
```

Do the same replacement in the retry loop (the second call to `filter_candidates`):

```lua
local candidates = filter_candidates(
    chunks,
    grid.col_widths[col],
    grid.row_heights[row],
    cell_required_tag(idx, placement),
    all_faces(idx)
)
```

Replace with:

```lua
local rt = cell_required_tag(idx, placement)
local hef
if rt == nil then
    hef = placement.enemy_cells ~= nil and placement.enemy_cells[idx] == true
end
local candidates = filter_candidates(
    chunks,
    grid.col_widths[col],
    grid.row_heights[row],
    rt,
    all_faces(idx),
    hef
)
```

- [ ] **Step 6: Run tests to verify they pass**

```bash
busted build/spec/battle/map/procgen/chunk_selector_spec.lua
```

Expected: all pass.

- [ ] **Step 7: Run the full suite**

```bash
make test
```

Expected: all pass.

- [ ] **Step 8: Commit**

```bash
git add src/tactics/battle/map/procgen/chunk_selector.lua src/spec/battle/map/procgen/chunk_selector_spec.lua
git commit -m "feat: enforce has_enemies tag per cell during chunk selection"
```
