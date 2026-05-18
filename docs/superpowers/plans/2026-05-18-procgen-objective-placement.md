# Procgen Objective-Aware Placement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Place player deployment and objective targets (boss room, escape zone) at graph-aware positions based on the battle objective type.

**Architecture:** A new `placement.lua` module selects cells using `graph.node_depths` (for polar kill_boss/escape objectives) or `graph.node_eccentricities` (for central rout/defend objectives). `chunk_selector.generate` calls `placement.select` on each generated graph, passing the result through as a `ProcgenPlacement` attached to the returned `BattleMap`.

**Tech Stack:** Lua, Busted (`make test`), LuaCATS annotations.

**Spec:** `docs/superpowers/specs/2026-05-18-procgen-objective-placement-design.md`

---

## File Map

| Action | Path |
|--------|------|
| Modify | `src/tactics/battle/map/procgen/graph.lua` |
| Modify | `src/spec/battle/map/procgen/graph_spec.lua` |
| Create | `src/tactics/battle/map/procgen/placement.lua` |
| Create | `src/spec/battle/map/procgen/placement_spec.lua` |
| Modify | `src/tactics/battle/map/procgen/chunk_parser.lua` |
| Modify | `src/tactics/battle/map/procgen/chunk_selector.lua` |
| Modify | `src/spec/battle/map/procgen/chunk_selector_spec.lua` |
| Modify | `src/tactics/battle/map/map_generator.lua` |
| Modify | `src/spec/battle/map/map_generator_spec.lua` |

---

## Task 1: `graph.node_eccentricities`

**Files:**
- Modify: `src/tactics/battle/map/procgen/graph.lua`
- Test: `src/spec/battle/map/procgen/graph_spec.lua`

- [ ] **Step 1: Write the failing tests**

Add a new `describe("node_eccentricities", ...)` block inside the top-level `describe` in `src/spec/battle/map/procgen/graph_spec.lua`. The `make_graph` helper already exists in the `node_depths` describe block — duplicate it locally here (copy-paste it at the start of this block).

```lua
describe("node_eccentricities", function()
    local function make_graph(adj)
        local edges = {}
        for a, neighbors in ipairs(adj) do
            for _, b in ipairs(neighbors) do
                if a < b then table.insert(edges, { a, b }) end
            end
        end
        return { edges = edges, adjacency = adj }
    end

    it("returns eccentricity 0 for a single-node graph", function()
        local g = make_graph({ {} })
        local ecc = graph.node_eccentricities(g)
        luassert.are_equal(0, ecc[1])
    end)

    it("center of a 3-node chain has lower eccentricity than endpoints", function()
        -- Chain: 1-2-3. ecc[1]=2, ecc[2]=1 (center), ecc[3]=2
        local g = make_graph({ { 2 }, { 1, 3 }, { 2 } })
        local ecc = graph.node_eccentricities(g)
        luassert.are_equal(2, ecc[1])
        luassert.are_equal(1, ecc[2])
        luassert.are_equal(2, ecc[3])
    end)

    it("hub of a star graph has lower eccentricity than spokes", function()
        -- Star: hub=1 connected to 2,3,4. ecc[1]=1, ecc[2..4]=2
        local g = make_graph({ { 2, 3, 4 }, { 1 }, { 1 }, { 1 } })
        local ecc = graph.node_eccentricities(g)
        luassert.are_equal(1, ecc[1])
        luassert.are_equal(2, ecc[2])
        luassert.are_equal(2, ecc[3])
        luassert.are_equal(2, ecc[4])
    end)

    it("both nodes in a 2-node graph have eccentricity 1", function()
        local g = make_graph({ { 2 }, { 1 } })
        local ecc = graph.node_eccentricities(g)
        luassert.are_equal(1, ecc[1])
        luassert.are_equal(1, ecc[2])
    end)
end)
```

- [ ] **Step 2: Run tests to confirm they fail**

```bash
busted build/spec/battle/map/procgen/graph_spec.lua
```

Expected: failures mentioning `node_eccentricities` is nil.

- [ ] **Step 3: Implement `graph.node_eccentricities`**

Add this function to `src/tactics/battle/map/procgen/graph.lua` after `graph.node_depths` (before `graph.bridges`):

```lua
--- Compute the eccentricity of each node: max BFS distance to any other node.
--- A node with low eccentricity can reach all others in few hops (graph center).
---@param g ConnectionGraph
---@return table<integer, integer>  keyed by 1-based cell index
function graph.node_eccentricities(g)
    local n = 0
    for k in pairs(g.adjacency) do
        if k > n then n = k end
    end
    local ecc = {}
    for i = 1, n do
        local dist = bfs_distances(g, i)
        local max_d = 0
        for _, d in pairs(dist) do
            if d > max_d then max_d = d end
        end
        ecc[i] = max_d
    end
    return ecc
end
```

- [ ] **Step 4: Run tests to confirm they pass**

```bash
busted build/spec/battle/map/procgen/graph_spec.lua
```

Expected: all tests pass.

- [ ] **Step 5: Commit**

```bash
git add src/tactics/battle/map/procgen/graph.lua src/spec/battle/map/procgen/graph_spec.lua
git commit -m "feat: add graph.node_eccentricities for center-node placement"
```

---

## Task 2: `placement.lua` module

**Files:**
- Create: `src/tactics/battle/map/procgen/placement.lua`
- Create: `src/spec/battle/map/procgen/placement_spec.lua`

- [ ] **Step 1: Write the failing tests**

Create `src/spec/battle/map/procgen/placement_spec.lua`:

```lua
require("src.spec.picotron_shim")

local luassert = require("luassert")
local placement = require("src.tactics.battle.map.procgen.placement")
local random    = require("src.tactics.util.random")

local function make_graph(adj)
    local edges = {}
    for a, neighbors in ipairs(adj) do
        for _, b in ipairs(neighbors) do
            if a < b then table.insert(edges, { a, b }) end
        end
    end
    return { edges = edges, adjacency = adj }
end

-- Linear chain 1-2-3-4. Graph poles are nodes 1 and 4.
local function chain4()
    return make_graph({ { 2 }, { 1, 3 }, { 2, 4 }, { 3 } })
end

-- Star: hub=1 connected to 2, 3, 4.
local function star4()
    return make_graph({ { 2, 3, 4 }, { 1 }, { 1 }, { 1 } })
end

describe("tactics.battle.map.procgen.placement", function()
    describe("select (kill_boss)", function()
        it("places deployment and boss at opposite poles", function()
            local g = chain4()
            local result = placement.select(g, "kill_boss", random.new(1))
            luassert.is_true(result.deployment_cell == 1 or result.deployment_cell == 4)
            luassert.is_true(result.boss_cell == 1 or result.boss_cell == 4)
            luassert.are_not_equal(result.deployment_cell, result.boss_cell)
        end)

        it("has no escape_cell", function()
            local result = placement.select(chain4(), "kill_boss", random.new(1))
            luassert.is_nil(result.escape_cell)
        end)
    end)

    describe("select (escape)", function()
        it("places deployment and escape_cell at opposite poles", function()
            local g = chain4()
            local result = placement.select(g, "escape", random.new(1))
            luassert.is_true(result.deployment_cell == 1 or result.deployment_cell == 4)
            luassert.is_true(result.escape_cell == 1 or result.escape_cell == 4)
            luassert.are_not_equal(result.deployment_cell, result.escape_cell)
        end)

        it("has no boss_cell", function()
            local result = placement.select(chain4(), "escape", random.new(1))
            luassert.is_nil(result.boss_cell)
        end)
    end)

    describe("select (rout)", function()
        it("places deployment at the hub of a star (min eccentricity, max degree)", function()
            -- Hub=1 has eccentricity 1 and degree 3; all spokes have eccentricity 2 and degree 1.
            local result = placement.select(star4(), "rout", random.new(1))
            luassert.are_equal(1, result.deployment_cell)
        end)

        it("returns no boss_cell or escape_cell", function()
            local result = placement.select(star4(), "rout", random.new(1))
            luassert.is_nil(result.boss_cell)
            luassert.is_nil(result.escape_cell)
        end)

        it("falls back to all nodes when no candidate has degree >= 2", function()
            -- Chain 1-2: both nodes have degree 1. Should still return a result.
            local g = make_graph({ { 2 }, { 1 } })
            local result = placement.select(g, "rout", random.new(1))
            luassert.is_not_nil(result.deployment_cell)
        end)
    end)

    describe("select (defend)", function()
        it("places deployment at the hub of a star (same logic as rout)", function()
            local result = placement.select(star4(), "defend", random.new(1))
            luassert.are_equal(1, result.deployment_cell)
        end)
    end)

    it("errors on unknown objective", function()
        luassert.has_error(function()
            placement.select(chain4(), "unknown", random.new(1))
        end)
    end)
end)
```

- [ ] **Step 2: Run tests to confirm they fail**

```bash
busted build/spec/battle/map/procgen/placement_spec.lua
```

Expected: error that `placement` module cannot be found.

- [ ] **Step 3: Implement `placement.lua`**

Create `src/tactics/battle/map/procgen/placement.lua`:

```lua
---@brief
--- Objective-aware cell placement for procgen maps.
--- See docs/superpowers/specs/2026-05-18-procgen-objective-placement-design.md

local graph_mod = require("src.tactics.battle.map.procgen.graph")

---@class ProcgenPlacement
---@field deployment_cell integer  1-based macro-grid cell index
---@field boss_cell integer?       present for kill_boss only
---@field escape_cell integer?     present for escape only

local placement = {}

--- Select deployment and objective cells based on the given objective.
---@param g ConnectionGraph
---@param objective string  One of "kill_boss", "escape", "rout", "defend"
---@param rng RngInstance
---@return ProcgenPlacement
function placement.select(g, objective, rng)
    if objective == "kill_boss" or objective == "escape" then
        -- Double-BFS finds the two graph poles.
        -- depth 0 = far pole (objective target); max depth = near pole (deployment).
        local depths = graph_mod.node_depths(g, 1)
        local far_cell = nil
        local max_d = -1
        for node, d in pairs(depths) do
            if d == 0 then far_cell = node end
            if d > max_d then max_d = d end
        end
        local candidates = {}
        for node, d in pairs(depths) do
            if d == max_d then table.insert(candidates, node) end
        end
        table.sort(candidates)
        local deployment_cell = candidates[rng:rndi(#candidates) + 1]
        if objective == "kill_boss" then
            return { deployment_cell = deployment_cell, boss_cell = far_cell }
        else
            return { deployment_cell = deployment_cell, escape_cell = far_cell }
        end

    elseif objective == "rout" or objective == "defend" then
        -- Place deployment at the graph center: min eccentricity, prefer higher degree.
        local ecc = graph_mod.node_eccentricities(g)
        local candidates = {}
        for node, e in pairs(ecc) do
            if #(g.adjacency[node] or {}) >= 2 then
                table.insert(candidates, { node = node, ecc = e, degree = #g.adjacency[node] })
            end
        end
        if #candidates == 0 then
            for node, e in pairs(ecc) do
                table.insert(candidates, { node = node, ecc = e, degree = #g.adjacency[node] })
            end
        end
        table.sort(candidates, function(a, b)
            if a.ecc ~= b.ecc then return a.ecc < b.ecc end
            if a.degree ~= b.degree then return a.degree > b.degree end
            return a.node < b.node
        end)
        local min_ecc  = candidates[1].ecc
        local max_deg  = candidates[1].degree
        local top = {}
        for _, c in ipairs(candidates) do
            if c.ecc == min_ecc and c.degree == max_deg then
                table.insert(top, c.node)
            end
        end
        local deployment_cell = top[rng:rndi(#top) + 1]
        return { deployment_cell = deployment_cell }

    else
        error("placement.select: unknown objective '" .. tostring(objective) .. "'")
    end
end

return placement
```

- [ ] **Step 4: Run tests to confirm they pass**

```bash
busted build/spec/battle/map/procgen/placement_spec.lua
```

Expected: all tests pass.

- [ ] **Step 5: Commit**

```bash
git add src/tactics/battle/map/procgen/placement.lua src/spec/battle/map/procgen/placement_spec.lua
git commit -m "feat: add placement module for objective-aware cell selection"
```

---

## Task 3: Extend `chunk_selector` for boss/escape constraints

**Files:**
- Modify: `src/tactics/battle/map/procgen/chunk_parser.lua`
- Modify: `src/tactics/battle/map/procgen/chunk_selector.lua`
- Modify: `src/spec/battle/map/procgen/chunk_selector_spec.lua`

- [ ] **Step 1: Register the new tags in `chunk_parser.lua`**

In `src/tactics/battle/map/procgen/chunk_parser.lua`, find `KNOWN_TAGS` (around line 158) and add `boss_room` and `escape_zone`:

```lua
local KNOWN_TAGS = {
    deployment  = true,
    boss_room   = true,
    escape_zone = true,
    rotate_90   = true,
    rotate_180  = true,
    flip_v      = true,
    flip_h      = true,
}
```

- [ ] **Step 2: Write failing tests for new chunk_selector behaviour**

Add the following at the end of the `describe("select", ...)` block in `src/spec/battle/map/procgen/chunk_selector_spec.lua`.

First, add two new chunk helpers near the top of the file (after `north_last_chunk`):

```lua
--- Chunk tagged "boss_room" with exits on all four faces.
---@param name string
---@return ChunkRecord
local function boss_chunk(name)
    return {
        name = name, width = 3, height = 3,
        tags = { "boss_room" },
        rows = { "#^^^#", "<...>", "<...>", "<...>", "#vvv#" },
        exits = {
            north = { min = 2, max = 4 }, south = { min = 2, max = 4 },
            east  = { min = 2, max = 4 }, west  = { min = 2, max = 4 },
        },
    }
end

--- Chunk tagged "escape_zone" with exits on all four faces.
---@param name string
---@return ChunkRecord
local function escape_chunk(name)
    return {
        name = name, width = 3, height = 3,
        tags = { "escape_zone" },
        rows = { "#^^^#", "<...>", "<...>", "<...>", "#vvv#" },
        exits = {
            north = { min = 2, max = 4 }, south = { min = 2, max = 4 },
            east  = { min = 2, max = 4 }, west  = { min = 2, max = 4 },
        },
    }
end
```

Then add these tests inside the `describe("select", ...)` block. All existing calls to `chunk_selector.select` must be updated to pass a sixth `placement` argument; add `{ deployment_cell = 1 }` to every existing call that currently omits it. Then add:

```lua
it("places boss_room chunk at the boss_cell from placement", function()
    local pool = {
        all_exits_chunk("deploy", true),
        all_exits_chunk("normal"),
        boss_chunk("boss"),
    }
    local g = make_2x2_graph()
    local rng = random.new(1)
    -- deployment=1, boss=2 (arbitrary valid cells for a 2x2 graph)
    local p = { deployment_cell = 1, boss_cell = 2 }
    local result = chunk_selector.select(make_2x2_grid(), g, pool, rng, nil, p)

    luassert.is_not_nil(result)
    local boss_chunk_assigned = result.assignment[2]
    local has_boss = false
    for _, t in ipairs(boss_chunk_assigned.tags) do
        if t == "boss_room" then has_boss = true end
    end
    luassert.is_true(has_boss)
end)

it("places escape_zone chunk at the escape_cell from placement", function()
    local pool = {
        all_exits_chunk("deploy", true),
        all_exits_chunk("normal"),
        escape_chunk("escape"),
    }
    local g = make_2x2_graph()
    local rng = random.new(1)
    local p = { deployment_cell = 1, escape_cell = 3 }
    local result = chunk_selector.select(make_2x2_grid(), g, pool, rng, nil, p)

    luassert.is_not_nil(result)
    local esc_chunk_assigned = result.assignment[3]
    local has_escape = false
    for _, t in ipairs(esc_chunk_assigned.tags) do
        if t == "escape_zone" then has_escape = true end
    end
    luassert.is_true(has_escape)
end)

it("returns nil when no boss_room chunk exists for a boss_cell constraint", function()
    -- Pool has no boss_room chunk; should fail to select for cell 2.
    local pool = {
        all_exits_chunk("deploy", true),
        all_exits_chunk("normal_1"),
        all_exits_chunk("normal_2"),
    }
    local g = make_2x2_graph()
    local rng = random.new(1)
    local p = { deployment_cell = 1, boss_cell = 2 }
    local result, err = chunk_selector.select(make_2x2_grid(), g, pool, rng, nil, p)
    luassert.is_nil(result)
    luassert.is_not_nil(err)
end)
```

- [ ] **Step 3: Run tests to confirm new tests fail and existing tests still pass**

```bash
busted build/spec/battle/map/procgen/chunk_selector_spec.lua
```

Expected: the three new tests fail; existing tests may also fail due to missing `placement` argument.

- [ ] **Step 4: Update `chunk_selector.lua`**

**4a.** Replace `has_deployment_tag` and the `need_deployment` parameter with a tag-based approach.

Remove the existing `has_deployment_tag` function entirely. Add these in its place, after the `---Candidate filtering---` comment:

```lua
local SPECIAL_TAGS = { deployment = true, boss_room = true, escape_zone = true }

---@param chunk ChunkRecord
---@return string? first special tag found, or nil
local function get_special_tag(chunk)
    for _, t in ipairs(chunk.tags) do
        if SPECIAL_TAGS[t] then return t end
    end
    return nil
end
```

**4b.** Replace the `filter_candidates` signature and body.

Old signature: `local function filter_candidates(chunks, cw, ch, need_deployment, faces)`

Change to: `local function filter_candidates(chunks, cw, ch, required_tag, faces)`

Inside the function, replace:
```lua
local is_dep = has_deployment_tag(chunk)
if is_dep == need_deployment then
```
with:
```lua
if get_special_tag(chunk) == required_tag then
```

(`required_tag` is `"deployment"`, `"boss_room"`, `"escape_zone"`, or `nil` for regular cells.)

**4c.** Add a helper to resolve the required tag for a cell index from a placement:

```lua
---@param idx integer
---@param p ProcgenPlacement
---@return string?
local function cell_required_tag(idx, p)
    if idx == p.deployment_cell then return "deployment" end
    if idx == p.boss_cell       then return "boss_room"  end
    if idx == p.escape_cell     then return "escape_zone" end
    return nil
end
```

**4d.** Update `chunk_selector.select` signature to accept `placement` instead of rolling randomly.

Old: `function chunk_selector.select(grid, g, chunks, rng, offscreen_edges)`
New: `function chunk_selector.select(grid, g, chunks, rng, offscreen_edges, placement)`

Remove: `local deployment_cell = rng:rndi(n) + 1`

In the initial assignment loop and the retry loop, replace every call:
```lua
idx == deployment_cell,
```
with:
```lua
cell_required_tag(idx, placement),
```

(The `filter_candidates` call becomes `filter_candidates(chunks, ..., cell_required_tag(idx, placement), all_faces(idx))`.)

Update the return at the end of `chunk_selector.select`:
```lua
return { assignment = assignment, deployment_cell = placement.deployment_cell }
```

**4e.** Update `chunk_selector.generate` to require `placement_mod` and accept `objective`.

At the top of the file, add:
```lua
local placement_mod = require("src.tactics.battle.map.procgen.placement")
```

Change the signature:
Old: `function chunk_selector.generate(theme, grid, chunks, rng, offscreen_edges)`
New: `function chunk_selector.generate(theme, grid, chunks, rng, offscreen_edges, objective)`

Inside the retry loop, after `local g = graph_mod.generate(...)`, add:
```lua
local p = placement_mod.select(g, objective, rng)
```

Pass `p` to `chunk_selector.select`:
```lua
local result = chunk_selector.select(grid, g, chunks, rng, offscreen_edges, p)
```

Update the success return:
```lua
return {
    assignment      = result.assignment,
    deployment_cell = p.deployment_cell,
    placement       = p,
    graph           = g,
}
```

Also update the `ChunkGenerationResult` annotation at the top of the file:
```lua
---@class ChunkGenerationResult : ChunkSelection
---@field graph ConnectionGraph
---@field placement ProcgenPlacement
```

- [ ] **Step 5: Run tests to confirm all pass**

```bash
busted build/spec/battle/map/procgen/chunk_selector_spec.lua
```

Expected: all tests pass.

- [ ] **Step 6: Commit**

```bash
git add src/tactics/battle/map/procgen/chunk_parser.lua \
        src/tactics/battle/map/procgen/chunk_selector.lua \
        src/spec/battle/map/procgen/chunk_selector_spec.lua
git commit -m "feat: extend chunk_selector with objective-aware placement constraints"
```

---

## Task 4: Wire `map_generator` and integration test

**Files:**
- Modify: `src/tactics/battle/map/map_generator.lua`
- Modify: `src/spec/battle/map/map_generator_spec.lua`

- [ ] **Step 1: Write failing integration tests**

In `src/spec/battle/map/map_generator_spec.lua`, extend `FIXTURE_CHUNKS` (around line 629) to include boss and escape chunks. Add `boss_room` and `escape_zone` chunks for each needed size. For the castle theme (3×3 grid), add:

```lua
"[boss_3x3]", "boss_room", "5 5",
"#^^^#", "<...>", "<...>", "<...>", "#vvv#", "",
"[boss_4x3]", "boss_room", "6 5",
"#^^^^#", "<....>", "<....>", "<....>", "#vvvv#", "",
"[boss_3x4]", "boss_room", "5 6",
"#^^^#", "<...>", "<...>", "<...>", "<...>", "#vvv#", "",
"[boss_4x4]", "boss_room", "6 6",
"#^^^^#", "<....>", "<....>", "<....>", "<....>", "#vvvv#", "",
"[escape_3x3]", "escape_zone", "5 5",
"#^^^#", "<...>", "<...>", "<...>", "#vvv#", "",
"[escape_4x3]", "escape_zone", "6 5",
"#^^^^#", "<....>", "<....>", "<....>", "#vvvv#", "",
"[escape_3x4]", "escape_zone", "5 6",
"#^^^#", "<...>", "<...>", "<...>", "<...>", "#vvv#", "",
"[escape_4x4]", "escape_zone", "6 6",
"#^^^^#", "<....>", "<....>", "<....>", "<....>", "#vvvv#", "",
```

Update `DEF` to include an objective, and add new tests at the end of the `describe("load_map (procgen type)", ...)` block:

```lua
local DEF = { type = "procgen", theme = "castle", chunks = "fixture.chunks", objective = "rout" }
```

```lua
it("returns a map with procgen_placement for kill_boss objective", function()
    local restore = stub_fetch_chunks()
    local def = { type = "procgen", theme = "castle", chunks = "fixture.chunks", objective = "kill_boss" }
    local map = map_generator.load_map(def, {}, {}, 1)
    restore()
    luassert.is_not_nil(map.procgen_placement)
    luassert.is_not_nil(map.procgen_placement.deployment_cell)
    luassert.is_not_nil(map.procgen_placement.boss_cell)
    luassert.are_not_equal(map.procgen_placement.deployment_cell, map.procgen_placement.boss_cell)
end)

it("returns a map with procgen_placement for escape objective", function()
    local restore = stub_fetch_chunks()
    local def = { type = "procgen", theme = "castle", chunks = "fixture.chunks", objective = "escape" }
    local map = map_generator.load_map(def, {}, {}, 1)
    restore()
    luassert.is_not_nil(map.procgen_placement)
    luassert.is_not_nil(map.procgen_placement.deployment_cell)
    luassert.is_not_nil(map.procgen_placement.escape_cell)
    luassert.are_not_equal(map.procgen_placement.deployment_cell, map.procgen_placement.escape_cell)
end)

it("returns a map with procgen_placement.deployment_cell for rout objective", function()
    local restore = stub_fetch_chunks()
    local def = { type = "procgen", theme = "castle", chunks = "fixture.chunks", objective = "rout" }
    local map = map_generator.load_map(def, {}, {}, 1)
    restore()
    luassert.is_not_nil(map.procgen_placement)
    luassert.is_not_nil(map.procgen_placement.deployment_cell)
    luassert.is_nil(map.procgen_placement.boss_cell)
    luassert.is_nil(map.procgen_placement.escape_cell)
end)
```

- [ ] **Step 2: Run tests to confirm new tests fail**

```bash
busted build/spec/battle/map/map_generator_spec.lua
```

Expected: new tests fail; existing procgen tests may also fail since `DEF` now has `objective = "rout"` but `chunk_selector.generate` doesn't receive it yet.

- [ ] **Step 3: Update `map_generator.lua`**

**3a.** Update the `ProcgenMapDefinition` annotation (around line 17):

```lua
---@class ProcgenMapDefinition : MapDefinition
---@field type "procgen"
---@field theme string Theme name (key in the themes table, e.g. "castle").
---@field chunks string Path to the .chunks file (passed to chunk_parser.load_theme).
---@field tileset_name string? Tileset stem for gfx_registry lookup (e.g. "paper_tileset").
---@field objective string Battle objective type: "kill_boss", "escape", "rout", or "defend".
```

**3b.** In `load_procgen`, update the `chunk_selector.generate` call to pass `definition.objective`:

Old:
```lua
local gen_result = chunk_selector.generate(theme, grid, chunks, rng, offscreen_edges)
```

New:
```lua
local gen_result = chunk_selector.generate(theme, grid, chunks, rng, offscreen_edges, definition.objective)
```

**3c.** After `map.offscreen_exits = assembled.offscreen_exits`, add:

```lua
map.procgen_placement = gen_result.placement
```

- [ ] **Step 4: Run all tests to confirm they pass**

```bash
make test
```

Expected: all tests pass.

- [ ] **Step 5: Commit**

```bash
git add src/tactics/battle/map/map_generator.lua src/spec/battle/map/map_generator_spec.lua
git commit -m "feat: wire objective placement into procgen pipeline and expose procgen_placement on BattleMap"
```
