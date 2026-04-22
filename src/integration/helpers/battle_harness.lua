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

--- Set a value at a specific (x, y) position in a MockUserdata.
--- The shim's set(self, x, ...) writes varargs into data[0][x], data[1][x], ...
--- so to write data[target_y][x] = val we pad with zeros for rows 0..(target_y-1).
---@param ud userdata
---@param x integer  0-based column
---@param y integer  0-based row
---@param val number
local function set_at(ud, x, y, val)
    local args = {}
    for i = 1, y do
        args[i] = 0
    end
    args[y + 1] = val
    ud:set(x, table.unpack(args))
end

--- Build a mock fetch response for a static map.
--- The floor layer is filled with sprite_fixtures.FLOOR (passable, cost 1).
--- The metatile layer has BASE_METATILE + idx set at each labeled position.
--- All wall layers are zero (sprite 0 → impassable, but no unit enters a wall tile
--- in the open arena).
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
            set_at(floor, x, y, sprite_fixtures.FLOOR)
        end
    end

    for metatile_idx, positions in pairs(tile_positions) do
        for _, pos in ipairs(positions) do
            set_at(metatiles, pos.x, pos.y, BASE_METATILE + metatile_idx)
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
---@field _battle_result? string
---@field _battle_manager? BattleManager
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
---@param battle_id BattleId
---@param battle_config BattleConfig
function BattleHarness:start_battle(battle_id, battle_config)
    assert(not self._battle_manager, "start_battle() already called on this harness")
    local char_man = character_manager_mod.new(self._game_data)
    self._battle_manager = battle_manager_mod.new(
        1,
        battle_id,
        {},
        battle_config,
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
---@return string?
function BattleHarness:battle_result()
    return self._battle_result
end

--- Restore _G.fetch to its original value.
function BattleHarness:teardown()
    self._interceptor:teardown()
end

return battle_harness
