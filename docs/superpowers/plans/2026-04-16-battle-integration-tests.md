# Battle Integration Tests Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a `BattleHarness` integration test helper and a suite of battle- and story-level integration tests covering turn flow, objective resolution, and BATTLE_END emission.

**Architecture:** A `MapFetchInterceptor` overrides `_G.fetch` to return real-looking mock map data (userdata layers), letting `map_generator.load_static` run unmodified. A `BattleHarness` wires all battle services (BattleManager, TurnManager, AIEngine, etc.) from the `test_base` mod and drives the battle by emitting events directly on the shared bus. Story-level battle tests extend the existing `StoryHarness` with the same fetch interception.

**Tech Stack:** Lua 5.4, Busted test runner, existing Picotron shim, `test_base` mod.

---

## File map

| File | Action | Purpose |
|------|--------|---------|
| `src/spec/picotron_shim.lua` | Modify | Replace stub `fget`/`fset` with live flag store; delete `fget_one` |
| `src/integration/helpers/sprite_fixtures.lua` | Create | Named sprite constants + `setup()` to wire flags via `fset` |
| `src/integration/helpers/map_fetch_interceptor.lua` | Create | Override/restore `_G.fetch` with a path-keyed mock registry |
| `src/integration/helpers/battle_harness.lua` | Create | Full BattleHarness: services, fetch interception, drive API |
| `src/integration/helpers/story_harness.lua` | Modify | Add interceptor wiring, `register_map_fetch`, `finish_player_turn` |
| `mods/test_base/game_data/characters.lua` | Modify | Add `default`, `test_fighter`, `test_enemy` templates |
| `mods/test_base/game_data/maps.lua` | Modify | Add `test_arena` map definition |
| `mods/test_base/game_data/battles.lua` | Modify | Add `rout_no_enemies`, `rout_with_player`, `turn_limit_defeat` |
| `mods/test_base/game_data/stories.lua` | Modify | Add `battle_and_exit` story |
| `src/integration/battle/simple_flow_spec.lua` | Create | Battle-level integration tests |
| `src/integration/story/battle_flow_spec.lua` | Create | Story-level battle integration tests |

---

### Task 1: Fix fget/fset in picotron_shim; remove fget_one

`fget_one` is only referenced in the shim itself. `fget` and `fset` are currently stubs that ignore
all arguments. This task makes them behave correctly and removes the legacy function.

**Files:**
- Modify: `src/spec/picotron_shim.lua`

- [ ] **Step 1: Verify fget_one has no callers outside the shim**

```bash
grep -rn "fget_one" /mnt/tactics/src/ /mnt/tactics/mods/
```

Expected: only one result — the definition line in `picotron_shim.lua`.

- [ ] **Step 2: Add `_sprite_flags` backing store before `pt_shim`**

In `src/spec/picotron_shim.lua`, find the line `local pt_shim = {` (around line 129). Insert
directly above it:

```lua
local _sprite_flags = {}
```

- [ ] **Step 3: Replace fget_one, fget, fset in pt_shim**

Find these three lines in `pt_shim` (around lines 175-177):

```lua
    fget_one       = function(_n, _f) return false end,
    fget           = function(_n) return 0 end,
    fset           = function(_n, _f, _val) end,
```

Replace with:

```lua
    fget           = function(n)
        return _sprite_flags[n] or 0
    end,
    fset           = function(n, f, val)
        local flags = _sprite_flags[n] or 0
        if val then
            _sprite_flags[n] = flags | (1 << f)
        else
            _sprite_flags[n] = flags & ~(1 << f)
        end
    end,
```

- [ ] **Step 4: Run the unit tests to verify nothing regressed**

```bash
busted src/ --exclude-tags='it'
```

Expected: all unit tests pass (same count as before). Any failure here means a test was relying on
`fget` always returning 0 or `fget_one` — investigate and fix before proceeding.

- [ ] **Step 5: Commit**

```bash
git add src/spec/picotron_shim.lua
git commit -m "fix: make fget/fset live; remove fget_one legacy stub"
```

---

### Task 2: Create sprite_fixtures module

Defines the two sprite constants used by test maps and exposes a `setup()` that installs their
flags via `fset`. `setup()` is idempotent.

**Files:**
- Create: `src/integration/helpers/sprite_fixtures.lua`

- [ ] **Step 1: Create the file**

```lua
---@brief
--- Canonical sprite indices and flag setup for integration test maps.
--- Call setup() once before constructing any mock map fetch response.

local sprite_fixtures = {}

--- Sprite index for a passable floor tile (no flags → movement cost 1, not solid).
sprite_fixtures.FLOOR = 1

--- Sprite index for a solid impassable tile (solid bit 0x01 set → movement cost 999).
sprite_fixtures.SOLID = 2

--- Install sprite flags via fset. Safe to call multiple times.
function sprite_fixtures.setup()
    fset(sprite_fixtures.FLOOR, 0, false)
    fset(sprite_fixtures.SOLID, 0, true)
end

return sprite_fixtures
```

- [ ] **Step 2: Smoke-check it loads without error**

```bash
busted src/ --exclude-tags='it'
```

Expected: still passes (new file has no tests, so no change in count).

- [ ] **Step 3: Commit**

```bash
git add src/integration/helpers/sprite_fixtures.lua
git commit -m "feat: add sprite_fixtures for integration test map setup"
```

---

### Task 3: Create map_fetch_interceptor module

Overrides `_G.fetch` for the lifetime of a harness and serves pre-registered mock responses by
path. Restores the original `fetch` on `teardown()`.

**Files:**
- Create: `src/integration/helpers/map_fetch_interceptor.lua`

- [ ] **Step 1: Create the file**

```lua
---@brief
--- Intercepts _G.fetch to serve mock map data during integration tests.
--- Create one per harness; call teardown() when the test is done.

---@class MapFetchInterceptor
---@field _mock_fetches table<string, table>
---@field _original_fetch function
local MapFetchInterceptor = {}
MapFetchInterceptor.__index = MapFetchInterceptor

local map_fetch_interceptor = {}

--- Create an interceptor and immediately override _G.fetch.
---@return MapFetchInterceptor
function map_fetch_interceptor.new()
    local self = setmetatable({}, MapFetchInterceptor)
    self._mock_fetches = {}
    self._original_fetch = _G.fetch
    _G.fetch = function(path)
        if self._mock_fetches[path] then
            return self._mock_fetches[path]
        end
        return self._original_fetch(path)
    end
    return self
end

--- Register a mock fetch response for the given file path.
---@param path string  The path that fetch() will be called with (e.g. "map/test_arena.map").
---@param data table   The list of {name, bmp} layer entries to return.
function MapFetchInterceptor:register(path, data)
    self._mock_fetches[path] = data
end

--- Restore the original _G.fetch.
function MapFetchInterceptor:teardown()
    _G.fetch = self._original_fetch
end

return map_fetch_interceptor
```

- [ ] **Step 2: Verify unit tests still pass**

```bash
busted src/ --exclude-tags='it'
```

Expected: passes.

- [ ] **Step 3: Commit**

```bash
git add src/integration/helpers/map_fetch_interceptor.lua
git commit -m "feat: add map_fetch_interceptor for test map loading"
```

---

### Task 4: Add test_base character templates

`character_generator` resolves a template chain up to `"default"`. `test_base` currently has no
characters, so any battle that spawns units will crash. This task adds a `default` template with
all required appearance fields, plus two lightweight test templates.

**Files:**
- Modify: `mods/test_base/game_data/characters.lua`

- [ ] **Step 1: Replace the file contents**

```lua
local options = {}

function options.list(opts)
    return { type = "list", options = opts }
end

function options.weighted(opts)
    return { type = "weighted", options = opts }
end

return {
    default = {
        movement = 3,
        hp_max   = 4,
        item_loadout = {},

        head_options_m = options.list{ "round", "strong_chin", "small_chin" },
        head_options_f = options.list{ "narrow_chin", "round", "small_chin" },
        headwear_options = options.weighted{ ["none"] = 1 },
        eyewear_options  = options.weighted{ ["none"] = 1 },
        body_options     = options.weighted{ ["default"] = 1 },
        gender_options   = options.list{ "male", "female" },
        skin_color_options = options.list{ "a", "b", "c", "d" },
        hair_color_options = options.list{
            "brown", "dark_grey", "light_grey", "orange", "yellow",
            "dark_brown", "darker_grey", "dark_red", "dark_orange",
            "medium_grey", "peach",
        },
        beard_options = options.weighted{ ["none"] = 1 },
        eye_options   = options.weighted{ ["a"] = 1 },
        hair_options_m = options.list{
            "bald", "pompadour", "short", "wavy", "afro_a",
            "buzz_a", "emo", "balding", "flat_top",
        },
        hair_options_f = options.list{
            "bald", "bob_bangs", "bob_a", "bob_b", "bob_c",
            "afro_b", "pigtails", "bun", "buzz_b",
        },
    },

    -- Strong unarmed player unit for battle tests.
    test_fighter = {
        parent_template = "default",
        hp_max   = 10,
        movement = 3,
    },

    -- Minimal unarmed enemy for battle tests.
    test_enemy = {
        parent_template = "default",
        hp_max   = 1,
        movement = 2,
    },
}
```

- [ ] **Step 2: Run unit tests**

```bash
busted src/ --exclude-tags='it'
```

Expected: passes.

- [ ] **Step 3: Commit**

```bash
git add mods/test_base/game_data/characters.lua
git commit -m "feat: add default, test_fighter, test_enemy templates to test_base"
```

---

### Task 5: Add test_base map and battle data

Adds the `test_arena` map definition and three battle definitions used by the battle integration
tests.

**Files:**
- Modify: `mods/test_base/game_data/maps.lua`
- Modify: `mods/test_base/game_data/battles.lua`

- [ ] **Step 1: Replace maps.lua**

```lua
return {
    -- 16×16 open arena used by battle integration tests.
    -- Tile labels encoded as metatile indices:
    --   0x01 → player_spawn at (2, 7)
    --   0x02 → enemy_spawn  at (13, 7)
    -- The BattleHarness pre-registers the fetch response for this path.
    test_arena = {
        type = "static",
        file = "map/test_arena.map",
    },
}
```

- [ ] **Step 2: Replace battles.lua**

```lua
return {
    -- No units. Rout victory fires on the first finish_player_turn()
    -- because zero enemies always satisfies the rout condition.
    rout_no_enemies = {
        map_id = "test_arena",
        tile_labels = {},
        victory_conditions = {
            { type = "rout" },
        },
        failure_conditions = {},
        units = {},
        scripts = {},
    },

    -- One player unit present, still zero enemies.
    -- Confirms rout with a player on the map behaves the same way.
    rout_with_player = {
        map_id = "test_arena",
        tile_labels = {
            player_spawn = { 0x01 },
        },
        victory_conditions = {
            { type = "rout" },
        },
        failure_conditions = {},
        units = {
            {
                side             = "player",
                character_source = { type = "template", template = "test_fighter" },
                tile             = "player_spawn",
            },
        },
        scripts = {},
    },

    -- One player unit, turn_limit = 1, turn_limit failure condition.
    -- Requires two finish_player_turn() calls:
    --   call 1: ends player phase → neutral (skip) → enemy (skip) →
    --           advance_turn(turn=1) → check: 1 > 1 = false → turn becomes 2
    --   call 2: ends player phase → … → advance_turn(turn=2) →
    --           check: 2 > 1 = true → DEFEAT
    turn_limit_defeat = {
        map_id = "test_arena",
        tile_labels = {
            player_spawn = { 0x01 },
        },
        turn_limit = 1,
        victory_conditions = {},
        failure_conditions = {
            { type = "turn_limit" },
        },
        units = {
            {
                side             = "player",
                character_source = { type = "template", template = "test_fighter" },
                tile             = "player_spawn",
            },
        },
        scripts = {},
    },
}
```

- [ ] **Step 3: Run unit tests**

```bash
busted src/ --exclude-tags='it'
```

Expected: passes.

- [ ] **Step 4: Commit**

```bash
git add mods/test_base/game_data/maps.lua mods/test_base/game_data/battles.lua
git commit -m "feat: add test_arena map and rout/turn_limit battle fixtures to test_base"
```

---

### Task 6: Add battle_and_exit story to test_base

Used by the story-level battle tests. The victory and defeat paths both immediately exit the story
so assertions can check `is_complete()` and `current_node_id()`.

**Files:**
- Modify: `mods/test_base/game_data/stories.lua`

- [ ] **Step 1: Add the battle story to the existing stories table**

Open `mods/test_base/game_data/stories.lua`. The file currently returns a table with a `data` key
and two other keys. Add `battle_and_exit` inside `data`:

```lua
        -- Story whose first node is a battle.
        -- Used by story-level battle integration tests.
        battle_and_exit = {
            starting_node = "the_battle",
            nodes = {
                the_battle = {
                    {
                        type              = "battle",
                        battle_id         = "rout_no_enemies",
                        next_node_victory = "after_victory",
                        next_node_failure = "after_defeat",
                    },
                },
                after_victory = {
                    { type = "exit_story" },
                },
                after_defeat = {
                    { type = "exit_story" },
                },
            },
        },
```

The full file should now look like:

```lua
return {
    data = {
        simple_exit = {
            starting_node = "exit",
            nodes = {
                exit = {
                    { type = "exit_story" },
                },
            },
        },

        linear_text = {
            starting_node = "main",
            nodes = {
                main = {
                    { type = "text", text = "First line." },
                    { type = "text", text = "Second line." },
                    { type = "exit_story" },
                },
            },
        },

        jump_flow = {
            starting_node = "start",
            nodes = {
                start = {
                    { type = "jump", next_node = "jump_target" },
                },
                jump_target = {
                    { type = "text", text = "You jumped here." },
                    { type = "exit_story" },
                },
            },
        },

        battle_and_exit = {
            starting_node = "the_battle",
            nodes = {
                the_battle = {
                    {
                        type              = "battle",
                        battle_id         = "rout_no_enemies",
                        next_node_victory = "after_victory",
                        next_node_failure = "after_defeat",
                    },
                },
                after_victory = {
                    { type = "exit_story" },
                },
                after_defeat = {
                    { type = "exit_story" },
                },
            },
        },
    },
    default_story = "simple_exit",
    story_select  = { "simple_exit", "linear_text", "jump_flow" },
}
```

- [ ] **Step 2: Run unit tests**

```bash
busted src/ --exclude-tags='it'
```

Expected: passes.

- [ ] **Step 3: Commit**

```bash
git add mods/test_base/game_data/stories.lua
git commit -m "feat: add battle_and_exit story to test_base"
```

---

### Task 7: Write failing battle integration tests

Write the spec file first. It will fail with "module 'src.integration.helpers.battle_harness' not
found" until Task 8 creates the harness.

**Files:**
- Create: `src/integration/battle/simple_flow_spec.lua`

- [ ] **Step 1: Create the spec file**

```lua
local luassert = require("luassert")
local battle_harness = require("src.integration.helpers.battle_harness")

describe("battle flow #it", function()
    local h

    after_each(function()
        if h then h:teardown() end
    end)

    describe("events on start", function()
        it("emits TACTICS_BEGIN_BATTLE", function()
            h = battle_harness.new()
            h:start_battle("rout_no_enemies")
            luassert.are_equal(1, #h:emitted("TACTICS_BEGIN_BATTLE"))
        end)

        it("emits TACTICS_BEGIN_TURN with turn 1", function()
            h = battle_harness.new()
            h:start_battle("rout_no_enemies")
            local turns = h:emitted("TACTICS_BEGIN_TURN")
            luassert.are_equal(1, #turns)
            luassert.are_equal(1, turns[1].turn)
        end)
    end)

    describe("rout_no_enemies", function()
        it("battle_result is VICTORY after finish_player_turn", function()
            h = battle_harness.new()
            h:start_battle("rout_no_enemies")
            h:finish_player_turn()
            luassert.are_equal("VICTORY", h:battle_result())
        end)

        it("emits BATTLE_END exactly once", function()
            h = battle_harness.new()
            h:start_battle("rout_no_enemies")
            h:finish_player_turn()
            luassert.are_equal(1, #h:emitted("BATTLE_END"))
        end)

        it("BATTLE_END payload has result VICTORY", function()
            h = battle_harness.new()
            h:start_battle("rout_no_enemies")
            h:finish_player_turn()
            luassert.are_equal("VICTORY", h:emitted("BATTLE_END")[1].result)
        end)
    end)

    describe("turn_limit_defeat", function()
        it("battle is not over after one finish_player_turn", function()
            h = battle_harness.new()
            h:start_battle("turn_limit_defeat")
            h:finish_player_turn()
            luassert.is_nil(h:battle_result())
        end)

        it("battle_result is DEFEAT after two finish_player_turns", function()
            h = battle_harness.new()
            h:start_battle("turn_limit_defeat")
            h:finish_player_turn()
            h:finish_player_turn()
            luassert.are_equal("DEFEAT", h:battle_result())
        end)

        it("BATTLE_END payload has result DEFEAT", function()
            h = battle_harness.new()
            h:start_battle("turn_limit_defeat")
            h:finish_player_turn()
            h:finish_player_turn()
            luassert.are_equal("DEFEAT", h:emitted("BATTLE_END")[1].result)
        end)

        it("emits TACTICS_BEGIN_TURN for turns 1 and 2 before defeat", function()
            h = battle_harness.new()
            h:start_battle("turn_limit_defeat")
            h:finish_player_turn()
            h:finish_player_turn()
            local turns = h:emitted("TACTICS_BEGIN_TURN")
            luassert.are_equal(2, #turns)
            luassert.are_equal(1, turns[1].turn)
            luassert.are_equal(2, turns[2].turn)
        end)
    end)
end)
```

- [ ] **Step 2: Run to confirm the expected failure**

```bash
busted src/integration/battle/simple_flow_spec.lua
```

Expected: error — `module 'src.integration.helpers.battle_harness' not found`.

- [ ] **Step 3: Commit the failing tests**

```bash
git add src/integration/battle/simple_flow_spec.lua
git commit -m "test: add failing battle integration tests"
```

---

### Task 8: Implement BattleHarness

Creates `battle_harness.lua`, which wires all battle services, overrides `fetch`, pre-registers the
`test_arena` mock response, and exposes the drive API. After this task all battle tests from
Task 7 should pass.

**Files:**
- Create: `src/integration/helpers/battle_harness.lua`

- [ ] **Step 1: Create the file**

```lua
---@brief
--- Test harness for battle flow integration tests.
--- Wires up a full battle service stack (BattleManager + TurnManager + AIEngine etc.)
--- and provides a simple API for driving battles and asserting on outcomes.

local tasks               = require("src.tactics.systems.tasks")
local event_bus_mod       = require("src.tactics.systems.event_bus")
local animation           = require("src.tactics.animation")
local ui_ctx_mgr          = require("src.tactics.ui.ui_context_manager")
local music_player_mod    = require("src.tactics.music.music_player")
local mod_loader_mod      = require("src.tactics.mods.mod_loader")
local character_manager_mod = require("src.tactics.character.character_manager")
local battle_manager_mod  = require("src.tactics.battle.battle_manager")
local sprite_fixtures     = require("src.integration.helpers.sprite_fixtures")
local map_fetch_interceptor = require("src.integration.helpers.map_fetch_interceptor")

local TICK_LIMIT    = 1000
local BASE_METATILE = 0x400
local ARENA_W       = 16
local ARENA_H       = 16

-- Metatile positions for the test_arena map.
-- 0x01 → player_spawn at (2, 7)
-- 0x02 → enemy_spawn  at (13, 7)
local ARENA_TILE_POSITIONS = {
    [0x01] = { { x = 2,  y = 7 } },
    [0x02] = { { x = 13, y = 7 } },
}

--- Build a mock fetch response for a static map.
--- The floor layer is filled with sprite_fixtures.FLOOR (passable, cost 1).
--- The metatile layer has BASE_METATILE + idx set at each labeled position.
--- All wall layers are zero (sprite 0 → get_terrain returns nil → impassable,
--- but no unit ever tries to enter a wall tile in the open arena).
---@param width integer
---@param height integer
---@param tile_positions table<integer, {x: integer, y: integer}[]>
---@return table
local function build_map_fetch(width, height, tile_positions)
    sprite_fixtures.setup()

    local metatiles = userdata("u8", width, height)
    local floor     = userdata("u8", width, height)
    local blank     = userdata("u8", width, height)

    for x = 0, width - 1 do
        for y = 0, height - 1 do
            floor:set(x, y, sprite_fixtures.FLOOR)
        end
    end

    for metatile_idx, positions in pairs(tile_positions) do
        for _, pos in ipairs(positions) do
            metatiles:set(pos.x, pos.y, BASE_METATILE + metatile_idx)
        end
    end

    return {
        { name = "metatiles",   bmp = metatiles },
        { name = "floor",       bmp = floor },
        { name = "front_walls", bmp = blank },
        { name = "mid_walls",   bmp = blank },
        { name = "back_walls",  bmp = blank },
    }
end

---@class BattleHarness
---@field _task_manager TaskManager
---@field _event_bus EventBus
---@field _animation_manager AnimationManager
---@field _ui_context UIContextManager
---@field _music_player MusicPlayer
---@field _game_data table
---@field _interceptor MapFetchInterceptor
---@field _emitted table<string, table[]>
---@field _battle_result string|nil
---@field _battle_manager BattleManager|nil
local BattleHarness = {}
BattleHarness.__index = BattleHarness

local battle_harness = {
    --- Expose build_map_fetch so tests can register custom maps via
    --- harness:register_map_fetch(path, battle_harness.build_map_fetch(...))
    build_map_fetch = build_map_fetch,
}

--- Create a new BattleHarness backed by the test_base mod.
--- Pass overrides.battles / overrides.maps to merge additional definitions.
---@param overrides? { battles?: table<string, any>, maps?: table<string, any> }
---@return BattleHarness
function battle_harness.new(overrides)
    local self = setmetatable({}, BattleHarness)

    -- Install fetch interceptor and pre-register test_arena.
    self._interceptor = map_fetch_interceptor.new()
    self._interceptor:register(
        "map/test_arena.map",
        build_map_fetch(ARENA_W, ARENA_H, ARENA_TILE_POSITIONS)
    )

    -- Wire services.
    self._task_manager      = tasks.task_manager()
    self._event_bus         = event_bus_mod.new()
    self._animation_manager = animation.animation_manager()
    self._ui_context        = ui_ctx_mgr.new()
    self._music_player      = music_player_mod.new()

    -- Load mod data.
    local loader = mod_loader_mod.new()
    loader:register_mod("test_base")
    self._game_data = loader:load_mod_data()

    if overrides and overrides.battles then
        for id, def in pairs(overrides.battles) do
            self._game_data.battles[id] = def
        end
    end
    if overrides and overrides.maps then
        for id, def in pairs(overrides.maps) do
            self._game_data.maps[id] = def
        end
    end

    -- Record all emitted events; capture BATTLE_END result.
    self._emitted        = {}
    self._battle_result  = nil
    local original_emit  = self._event_bus.emit
    self._event_bus.emit = function(bus, event_type, args)
        if not self._emitted[event_type] then
            self._emitted[event_type] = {}
        end
        table.insert(self._emitted[event_type], args or {})
        if event_type == "BATTLE_END" then
            self._battle_result = args and args.result
        end
        return original_emit(bus, event_type, args)
    end

    self._battle_manager = nil
    return self
end

--- Register a mock fetch response for a custom map path.
---@param path string
---@param fetch_data table
function BattleHarness:register_map_fetch(path, fetch_data)
    self._interceptor:register(path, fetch_data)
end

--- Create and start a BattleManager for the named battle, then tick to idle.
---@param battle_id string
function BattleHarness:start_battle(battle_id)
    assert(not self._battle_manager, "start_battle() already called on this harness")
    local char_man = character_manager_mod.new(self._game_data)
    self._battle_manager = battle_manager_mod.new(
        1,
        battle_id,
        self._game_data,
        char_man,
        self._task_manager,
        self._animation_manager,
        self._event_bus,
        self._music_player,
        self._ui_context
    )
    self:tick_to_idle()
end

--- Loop update_tasks() until the task manager is idle.
--- Errors after TICK_LIMIT iterations to catch infinite loops.
function BattleHarness:tick_to_idle()
    local ticks = 0
    repeat
        self._task_manager:update_tasks()
        ticks = ticks + 1
        if ticks >= TICK_LIMIT then
            error("tick_to_idle: exceeded " .. TICK_LIMIT .. " ticks — possible infinite loop")
        end
    until self._task_manager:is_idle()
end

--- Emit TACTICS_FINISH_SIDE_ACTIONS (end the player turn), then tick to idle.
function BattleHarness:finish_player_turn()
    self._event_bus:emit("TACTICS_FINISH_SIDE_ACTIONS", {})
    self:tick_to_idle()
end

--- Return all event payloads emitted for the given event type.
---@param event_type string
---@return table[]
function BattleHarness:emitted(event_type)
    return self._emitted[event_type] or {}
end

--- Return the battle result string ("VICTORY" or "DEFEAT"), or nil if battle is ongoing.
---@return string|nil
function BattleHarness:battle_result()
    return self._battle_result
end

--- Restore _G.fetch to its original value.
function BattleHarness:teardown()
    self._interceptor:teardown()
end

return battle_harness
```

- [ ] **Step 2: Run the battle tests**

```bash
busted src/integration/battle/simple_flow_spec.lua
```

Expected: all 8 tests pass.

- [ ] **Step 3: Run full integration suite to check for regressions**

```bash
busted src/ --tags='it'
```

Expected: all integration tests pass (existing story tests + new battle tests).

- [ ] **Step 4: Commit**

```bash
git add src/integration/helpers/battle_harness.lua
git commit -m "feat: implement BattleHarness integration test infrastructure"
```

---

### Task 9: Write failing story-level battle tests

Write the spec file before updating StoryHarness. It will fail because `StoryHarness` has no
`finish_player_turn` method yet.

**Files:**
- Create: `src/integration/story/battle_flow_spec.lua`

- [ ] **Step 1: Create the spec file**

```lua
local luassert = require("luassert")
local story_harness = require("src.integration.helpers.story_harness")

describe("story battle flow #it", function()
    local h

    after_each(function()
        if h then h:teardown() end
    end)

    describe("battle_and_exit story", function()
        it("story is not complete before finish_player_turn", function()
            h = story_harness.new()
            h:start_story("battle_and_exit")
            luassert.is_false(h:is_complete())
        end)

        it("story is complete after finish_player_turn (victory path)", function()
            h = story_harness.new()
            h:start_story("battle_and_exit")
            h:finish_player_turn()
            luassert.is_true(h:is_complete())
        end)

        it("emits GAME_EXIT_STORY after battle victory", function()
            h = story_harness.new()
            h:start_story("battle_and_exit")
            h:finish_player_turn()
            luassert.are_equal(1, #h:emitted("GAME_EXIT_STORY"))
        end)
    end)
end)
```

- [ ] **Step 2: Run to confirm the expected failure**

```bash
busted src/integration/story/battle_flow_spec.lua
```

Expected: error — attempt to call nil (finish_player_turn does not exist on StoryHarness), or a
fetch-related crash before that.

- [ ] **Step 3: Commit the failing tests**

```bash
git add src/integration/story/battle_flow_spec.lua
git commit -m "test: add failing story-level battle integration tests"
```

---

### Task 10: Update StoryHarness for battle support

Adds a `MapFetchInterceptor` (pre-registered with test_arena), `register_map_fetch`, and
`finish_player_turn` to the existing `StoryHarness`. Also adds a `teardown()` method to restore
`fetch`. After this task all story-level battle tests from Task 9 should pass.

**Files:**
- Modify: `src/integration/helpers/story_harness.lua`

- [ ] **Step 1: Add new requires at the top of the file**

Below the existing `require` lines (after `local input_helper = require(...)`), add:

```lua
local sprite_fixtures       = require("src.integration.helpers.sprite_fixtures")
local map_fetch_interceptor = require("src.integration.helpers.map_fetch_interceptor")
local battle_harness        = require("src.integration.helpers.battle_harness")
```

- [ ] **Step 2: Update `story_harness.new()` to set up the interceptor**

In `story_harness.new()`, after the line `self._story = nil`, add:

```lua
    -- Install fetch interceptor so story nodes that start battles can load maps.
    self._interceptor = map_fetch_interceptor.new()
    self._interceptor:register(
        "map/test_arena.map",
        battle_harness.build_map_fetch(16, 16, {
            [0x01] = { { x = 2,  y = 7 } },
            [0x02] = { { x = 13, y = 7 } },
        })
    )
```

Also add `sprite_fixtures.setup()` near the top of `new()`, before the services are wired (right
after `local self = setmetatable({}, StoryHarness)`):

```lua
    sprite_fixtures.setup()
```

- [ ] **Step 3: Add `register_map_fetch`, `finish_player_turn`, and `teardown` methods**

After the existing `StoryHarness:emitted()` method, add:

```lua
--- Register a mock fetch response for a map path.
---@param path string
---@param fetch_data table
function StoryHarness:register_map_fetch(path, fetch_data)
    self._interceptor:register(path, fetch_data)
end

--- Emit TACTICS_FINISH_SIDE_ACTIONS (end the player turn) and tick to idle.
--- Only meaningful when a battle is active within the story.
function StoryHarness:finish_player_turn()
    self._event_bus:emit("TACTICS_FINISH_SIDE_ACTIONS", {})
    self:tick_to_idle()
end

--- Restore _G.fetch to its original value.
function StoryHarness:teardown()
    self._interceptor:teardown()
end
```

- [ ] **Step 4: Run the story battle tests**

```bash
busted src/integration/story/battle_flow_spec.lua
```

Expected: all 3 tests pass.

- [ ] **Step 5: Run the full integration suite**

```bash
busted src/ --tags='it'
```

Expected: all integration tests pass — both existing story tests and all new battle and story-battle
tests.

- [ ] **Step 6: Run the full test suite**

```bash
busted src/
```

Expected: all tests pass.

- [ ] **Step 7: Commit**

```bash
git add src/integration/helpers/story_harness.lua
git commit -m "feat: add fetch interception and battle drive methods to StoryHarness"
```

---

## Self-review

### Spec coverage

| Spec requirement | Task |
|-----------------|------|
| fget/fset live backing store | Task 1 |
| fget_one removed | Task 1 |
| sprite_fixtures with FLOOR/SOLID | Task 2 |
| map_fetch_interceptor | Task 3 |
| test_base default/test_fighter/test_enemy templates | Task 4 |
| test_arena map + 3 battle definitions | Task 5 |
| battle_and_exit story | Task 6 |
| BattleHarness: start_battle, finish_player_turn, battle_result, emitted, teardown | Task 8 |
| BattleHarness: register_map_fetch, build_map_fetch | Task 8 |
| TACTICS_BEGIN_BATTLE / TACTICS_BEGIN_TURN emitted tests | Task 7 |
| rout_no_enemies VICTORY tests | Task 7 |
| turn_limit_defeat DEFEAT tests | Task 7 |
| turn 1 and 2 TACTICS_BEGIN_TURN test | Task 7 |
| StoryHarness: register_map_fetch, finish_player_turn, teardown | Task 10 |
| StoryHarness: fetch interception + sprite_fixtures.setup | Task 10 |
| story not complete before battle resolved | Task 9 |
| story complete after battle victory | Task 9 |
| GAME_EXIT_STORY emitted after battle | Task 9 |

All spec requirements covered.

### Type/name consistency

- `battle_harness.build_map_fetch` — defined in Task 8, referenced in Task 10. ✓
- `map_fetch_interceptor.new()` → returns `MapFetchInterceptor`; `interceptor:register(path, data)` and `interceptor:teardown()` — consistent across Tasks 3, 8, 10. ✓
- `sprite_fixtures.FLOOR`, `sprite_fixtures.SOLID`, `sprite_fixtures.setup()` — defined in Task 2, used in Task 8. ✓
- `BattleHarness:emitted(event_type)` returns `table[]` — same shape as `StoryHarness:emitted`. ✓
- `h:teardown()` added to both harnesses; both `after_each` blocks call it. ✓
