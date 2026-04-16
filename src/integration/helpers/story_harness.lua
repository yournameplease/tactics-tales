---@brief
--- Test harness for story flow integration tests.
--- Wires up a system slice (Story + TaskManager + EventBus) and provides
--- a simple API for driving story flows and asserting on stable outcomes.

local tasks            = require("src.tactics.systems.tasks")
local event_bus_mod    = require("src.tactics.systems.event_bus")
local animation        = require("src.tactics.animation")
local ui_ctx_mgr       = require("src.tactics.ui.ui_context_manager")
local music_player_mod = require("src.tactics.music.music_player")
local mod_loader_mod   = require("src.tactics.mods.mod_loader")
local story_mod        = require("src.tactics.story.story")
local input_helper     = require("src.spec.input.input_helper")

local TICK_LIMIT = 1000

---@class StoryHarness
local StoryHarness = {}
StoryHarness.__index = StoryHarness

local story_harness = {}

--- Create a new StoryHarness backed by the test_base mod.
--- Pass overrides.stories to merge inline story definitions on top of test_base.
---@param overrides? { stories?: table<string, any> }
---@return StoryHarness
function story_harness.new(overrides)
    local self = setmetatable({}, StoryHarness)

    -- Instant dialogue speed: one update() renders all chars and advances the row.
    DYNAMIC_CONFIG.dialogue_speed = "instant"

    self._task_manager      = tasks.task_manager()
    self._event_bus         = event_bus_mod.new()
    self._animation_manager = animation.animation_manager()
    self._ui_context        = ui_ctx_mgr.new()
    self._music_player      = music_player_mod.new()

    local loader = mod_loader_mod.new()
    loader:register_mod("test_base")
    self._game_data = loader:load_mod_data()

    if overrides and overrides.stories then
        for id, story_def in pairs(overrides.stories) do
            self._game_data.stories.data[id] = story_def
        end
    end

    self._complete = false
    self._emitted  = {}

    -- Wrap emit to record all events by type.
    local original_emit = self._event_bus.emit
    self._event_bus.emit = function(bus, event_type, args)
        if not self._emitted[event_type] then
            self._emitted[event_type] = {}
        end
        table.insert(self._emitted[event_type], args or {})
        if event_type == "GAME_EXIT_STORY" then
            self._complete = true
        end
        return original_emit(bus, event_type, args)
    end

    self._story = nil
    return self
end

--- Create and start the named story, then tick to idle.
---@param story_id string
function StoryHarness:start_story(story_id)
    self._story = story_mod.new(
        nil,
        story_id,
        self._game_data,
        self._task_manager,
        self._animation_manager,
        self._event_bus,
        self._music_player,
        self._ui_context
    )
    self:tick_to_idle()
end

--- Loop update_tasks() until the task manager is idle.
--- Errors after 1000 iterations to catch infinite loops.
function StoryHarness:tick_to_idle()
    local ticks = 0
    repeat
        self._task_manager:update_tasks()
        ticks = ticks + 1
        if ticks >= TICK_LIMIT then
            error("tick_to_idle: exceeded " .. TICK_LIMIT .. " ticks — possible infinite loop")
        end
    until self._task_manager:is_idle()
end

--- Feed one BUTTON_A press frame to the story, then tick to idle.
function StoryHarness:confirm()
    local input = input_helper.joypad({ a = true, ap = true })
    self._story:update(input)
    self:tick_to_idle()
end

--- Feed one directional input frame to the story, then tick to idle.
---@param dx integer Horizontal direction (-1, 0, or 1)
---@param dy integer Vertical direction (-1, 0, or 1)
function StoryHarness:dpad(dx, dy)
    local input = input_helper.joypad({ dx = dx, dy = dy, dxp = dx, dyp = dy })
    self._story:update(input)
    self:tick_to_idle()
end

--- Return true if the story has reached exit_story.
---@return boolean
function StoryHarness:is_complete()
    return self._complete
end

--- Return the node id the story is currently at.
---@return string
function StoryHarness:current_node_id()
    assert(self._story, "start_story() has not been called")
    return self._story.current_node.node_id
end

--- Return the StoryMemory entry for key, or nil if not set.
---@param key string
---@return table?
function StoryHarness:memory(key)
    assert(self._story, "start_story() has not been called")
    return self._story.story_memory:get(key)
end

--- Return all event payloads emitted for the given event type.
---@param event_type string
---@return table[]
function StoryHarness:emitted(event_type)
    return self._emitted[event_type] or {}
end

return story_harness
