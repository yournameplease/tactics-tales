---@brief
--- Test harness for campaign flow integration tests.
--- Wires up a system slice (Campaign + TaskManager + EventBus) and provides
--- a simple API for driving campaign flows and asserting on stable outcomes.

local tasks                 = require("src.tactics.systems.tasks")
local event_bus_mod         = require("src.tactics.systems.event_bus")
local animation             = require("src.tactics.animation")
local ui_ctx_mgr            = require("src.tactics.ui.ui_context_manager")
local music_player          = require("src.tactics.music.music_player")
local mod_loader_mod        = require("src.tactics.mods.mod_loader")
local campaign_mod          = require("src.tactics.campaign.campaign")
local input_helper          = require("src.spec.input.input_helper")
local sprite_fixtures       = require("src.integration.helpers.sprite_fixtures")
local map_fetch_interceptor = require("src.integration.helpers.map_fetch_interceptor")
local battle_harness        = require("src.integration.helpers.battle_harness")

local TICK_LIMIT            = 1000

---@class CampaignHarness
---@field _task_manager TaskManager
---@field _event_bus EventBus
---@field _animation_manager AnimationManager
---@field _ui_context UIContextManager
---@field _music_player MusicPlayer
---@field _game_data table
---@field _complete boolean
---@field _emitted table<string, table<string, any>[]>
---@field _campaign? table
---@field _interceptor MapFetchInterceptor
local CampaignHarness       = {}
CampaignHarness.__index     = CampaignHarness

local campaign_harness      = {}

--- Create a new CampaignHarness backed by the test_base mod.
--- Pass overrides.campaigns to merge inline campaign definitions on top of test_base.
---@param overrides? { campaigns?: table<string, any> }
---@return CampaignHarness
function campaign_harness.new(overrides)
    local self = setmetatable({}, CampaignHarness)

    sprite_fixtures.setup()

    -- Instant dialogue speed: one update() renders all chars and advances the row.
    DYNAMIC_CONFIG.dialogue_speed = "instant"

    self._task_manager            = tasks.task_manager()
    self._event_bus               = event_bus_mod.new()
    self._animation_manager       = animation.animation_manager()
    self._ui_context              = ui_ctx_mgr.new()
    self._music_player            = music_player.new()

    local loader                  = mod_loader_mod.new()
    loader:register_mod("base")
    loader:register_mod("test_base")
    self._game_data = loader:load_mod_data()

    if overrides and overrides.campaigns then
        for id, campaign_def in pairs(overrides.campaigns) do
            self._game_data.campaigns.data[id] = campaign_def
        end
    end

    self._complete       = false
    self._emitted        = {}

    -- Wrap emit to record all events by type.
    local original_emit  = self._event_bus.emit
    self._event_bus.emit = function(bus, event_type, args)
        if not self._emitted[event_type] then
            self._emitted[event_type] = {}
        end
        table.insert(self._emitted[event_type], args or {})
        if event_type == "GAME_EXIT_CAMPAIGN" then
            self._complete = true
        end
        return original_emit(bus, event_type, args)
    end

    self._campaign       = nil

    -- Install fetch interceptor so campaign nodes that start battles can load maps.
    self._interceptor    = map_fetch_interceptor.new()
    self._interceptor:register(
        "map/test_arena.map",
        battle_harness.build_map_fetch(16, 16, {
            [0x01] = { { x = 2, y = 7 } },
            [0x02] = { { x = 13, y = 7 } },
        })
    )
    self._interceptor:register(
        "map/test_close_arena.map",
        battle_harness.build_map_fetch(16, 16, {
            [0x01] = { { x = 7, y = 15 } },
            [0x02] = { { x = 8, y = 15 } },
        })
    )

    return self
end

--- Create and start the named campaign, then tick to idle.
---@param campaign_id string
---@param config? table
function CampaignHarness:start_campaign(campaign_id, config)
    assert(not self._campaign, "start_campaign() has already been called on this harness")
    self._campaign = campaign_mod.new(
        nil,
        campaign_id,
        config or {},
        self._game_data,
        self._task_manager,
        self._animation_manager,
        self._event_bus,
        self._music_player,
        self._ui_context,
        {
            current_input = "joypad",
            actions = {},
        }
    )
    self:tick_to_idle()
end

--- Loop update_tasks() until the task manager is idle.
--- Errors after 1000 iterations to catch infinite loops.
function CampaignHarness:tick_to_idle()
    local ticks = 0
    repeat
        self._animation_manager:tick()
        self._task_manager:update_tasks()
        ticks = ticks + 1
        if ticks >= TICK_LIMIT then
            error("tick_to_idle: exceeded " .. TICK_LIMIT .. " ticks — possible infinite loop")
        end
    until self._task_manager:is_idle()
end

--- Feed one BUTTON_A press frame to the campaign, then tick to idle.
function CampaignHarness:confirm()
    local input = input_helper.joypad({ a = true, ap = true })
    self._campaign:update(input)
    self:tick_to_idle()
end

--- Feed one directional input frame to the campaign, then tick to idle.
---@param dx integer Horizontal direction (-1, 0, or 1)
---@param dy integer Vertical direction (-1, 0, or 1)
function CampaignHarness:dpad(dx, dy)
    -- dxp/dyp mirror dx/dy: each dpad() call is a fresh pressed-this-frame signal.
    local input = input_helper.joypad({ dx = dx, dy = dy, dxp = dx, dyp = dy })
    self._campaign:update(input)
    self:tick_to_idle()
end

--- Return true if the campaign has reached exit_campaign.
---@return boolean
function CampaignHarness:is_complete()
    return self._complete
end

--- Return the node id the campaign is currently at.
---@return string
function CampaignHarness:current_node_id()
    assert(self._campaign, "start_campaign() has not been called")
    return self._campaign.current_node.node_id
end

--- Return the CampaignState entry for key, or nil if not set.
---@param key string
---@return table?
function CampaignHarness:memory(key)
    assert(self._campaign, "start_campaign() has not been called")
    return self._campaign.campaign_state:get(key)
end

--- Return all event payloads emitted for the given event type.
---@param event_type string
---@return table[]
function CampaignHarness:emitted(event_type)
    return self._emitted[event_type] or {}
end

--- Return the living characters in the player roster.
---@return Character[]
function CampaignHarness:player_roster()
    assert(self._campaign, "start_campaign() has not been called")
    return self._campaign.character_manager:get_player_roster()
end

--- Return the current CampaignResults from the campaign's stats service.
---@return CampaignResults
function CampaignHarness:campaign_results()
    assert(self._campaign, "start_campaign() has not been called")
    return self._campaign.stats_service.campaign_results
end

--- Return the topmost RenderedGameResults node, or nil if the top node is not game_results.
---@return RenderedGameResults?
function CampaignHarness:game_results_node()
    assert(self._campaign, "start_campaign() has not been called")
    local nodes = self._campaign.campaign_page.nodes
    local top = nodes[#nodes]
    if top and top.type == "game_results" then
        ---@cast top RenderedGameResults
        return top
    end
    return nil
end

--- Register a mock fetch response for a map path.
---@param path string
---@param fetch_data table
function CampaignHarness:register_map_fetch(path, fetch_data)
    self._interceptor:register(path, fetch_data)
end

--- Emit TACTICS_FINISH_SIDE_ACTIONS (end the player turn) and tick to idle.
--- Only meaningful when a battle is active within the campaign.
function CampaignHarness:finish_player_turn()
    self._event_bus:emit("TACTICS_FINISH_SIDE_ACTIONS", {})
    self:tick_to_idle()
end

--- Restore _G.fetch to its original value.
function CampaignHarness:teardown()
    self._interceptor:teardown()
end

return campaign_harness
