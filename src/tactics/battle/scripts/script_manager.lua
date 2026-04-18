---@brief
--- Manages the execution of event-driven battle scripts.
--- Listens for triggers and applies corresponding script effects,
--- such as spawning units, modifying terrain, or initiating dialogue.

local point = require("src.tactics.util.point")
local id_generator = require("src.tactics.util.id_generator")
local event_listener = require("src.tactics.systems.event_bus.event_listener")
local lists = require("src.tactics.util.lists")

---@class ScriptContext
---@field source_unit BattleUnit
---@field target_unit BattleUnit
---@field source_tile Point
---@field target_tile Point
---@field turn_number integer
local ScriptContext = {}

---@class TileInteractionMessage
---@field script_id ScriptId
---@field source_unit BattleUnit
---@field source_tile Point
---@field target_tile Point
local TileInteractionMessage = {}

---@class UnitInteractionMessage
---@field script_id ScriptId
---@field source_unit BattleUnit
---@field source_tile Point
---@field target_unit BattleUnit
---@field target_tile Point
local UnitInteractionMessage = {}

---@class ScriptManager
---@field battle_map BattleMap
---@field tactics_engine TacticsEngine
---@field event_listener EventListener
---@field music_player MusicPlayer
---@field task_manager TaskManager
---@field active_scripts table<ScriptId, BattleScript>
---@field script_listeners table<ScriptId, ListenerId>
local ScriptManager = {}
ScriptManager.__index = ScriptManager

--- Return units matching the given specifier (no context required).
---@param selector table UnitSpecifier
---@return BattleUnit[]
function ScriptManager:resolve_unit_specifier(selector)
    if selector.type == "tag_lookup" then
        local battle_unit = require("src.tactics.battle.tactics.battle_unit")
        return self.battle_map:get_units(battle_unit.has_tag(selector.tag))
    else
        unexpected(selector.type)
        return {}
    end
end

--- Return units matching the given selector, possibly using the script context.
---@param selector table UnitSelector
---@param ctx ScriptContext
---@return BattleUnit[]
function ScriptManager:resolve_unit_selector(selector, ctx)
    if selector.type == "tag_lookup" then
        return self:resolve_unit_specifier(selector)
    elseif selector.type == "trigger_source" then
        assert(ctx.source_unit ~= nil)
        return { ctx.source_unit }
    elseif selector.type == "trigger_target" then
        assert(ctx.target_unit ~= nil)
        return { ctx.target_unit }
    else
        unexpected(selector.type)
        return {}
    end
end

--- Return tiles matching the given specifier (no context required).
---@param selector table TileSpecifier
---@return Point[]
function ScriptManager:resolve_tile_specifier(selector)
    if selector.type == "tag_lookup" then
        return self.battle_map:get_tiles_by_label(selector.tag)
    elseif selector.type == "static_point" then
        return { point.of_record(selector.point) }
    else
        unexpected(selector.type)
        return {}
    end
end

--- Return tiles matching the given selector, possibly using the script context.
---@param selector table TileSelector
---@param ctx ScriptContext
---@return Point[]
function ScriptManager:resolve_tile_selector(selector, ctx)
    if selector.type == "static_point" or selector.type == "tag_lookup" then
        return self:resolve_tile_specifier(selector)
    elseif selector.type == "trigger_source" then
        assert(ctx.source_tile ~= nil)
        return { ctx.source_tile }
    elseif selector.type == "trigger_target" then
        assert(ctx.target_tile ~= nil)
        return { ctx.target_tile }
    else
        unexpected(selector.type)
        return {}
    end
end

--- Deactivate a script and remove its event listener and interaction registration.
---@param script_id ScriptId
function ScriptManager:remove_script(script_id)
    if self.active_scripts[script_id] then
        self.event_listener:remove(self.script_listeners[script_id])
        self.battle_map:unregister_interaction(script_id)
        self.active_scripts[script_id] = nil
    else
        log.info("Attempt to remove a script which is no longer active.  Ignoring.  Id: " .. script_id)
    end
end

--- Register a script's trigger and build its effect callbacks.
---@param script BattleScript
function ScriptManager:register_script(script)
    local event
    local filter

    local trigger = script.trigger

    if trigger.type == "turn" then
        local event_by_offset = {
            ["before"] = "TACTICS_BEGIN_PHASE",
            ["after"] = "TACTICS_END_PHASE",
        }
        event = event_by_offset[trigger.phase.offset]

        if trigger.repeating == nil then
            filter = function(ctx)
                local turn = ctx.turn
                local side = ctx.side

                if side == trigger.phase.side and turn == trigger.turn then
                    return true, { turn_number = turn }
                end
                return false, nil
            end
        else
            filter = function(ctx)
                local turn = ctx.turn
                local side = ctx.side

                if side == trigger.phase.side
                    and turn >= trigger.turn
                    and (turn - trigger.turn) % trigger.repeating == 0
                then
                    return true, { turn_number = turn }
                end
                return false, nil
            end
        end
    elseif trigger.type == "unit_death" then
        event = "TACTICS_UNIT_DEATH"
        filter = function(ctx)
            local defender = ctx.defender
            local attacker = ctx.attacker
            return
                defender.tags[trigger.unit_label],
                {
                    source_unit = attacker,
                    source_tile = attacker.tile,
                    target_unit = defender,
                    target_tile = defender.tile,
                }
        end
    elseif trigger.type == "unit_interaction" then
        event = "TACTICS_INTERACTION"
        filter = function(msg)
            if msg.script_id ~= script.id then
                return false, nil
            end
            return
                true,
                {
                    source_unit = msg.source_unit,
                    source_tile = msg.source_tile,
                    target_unit = msg.target_unit,
                    target_tile = msg.target_tile,
                }
        end
    elseif trigger.type == "tile_interaction" then
        event = "TACTICS_INTERACTION"
        filter = function(msg)
            if msg.script_id ~= script.id then
                return false, nil
            end
            return
                true,
                {
                    source_unit = msg.source_unit,
                    source_tile = msg.source_tile,
                    target_tile = msg.target_tile,
                }
        end
    else
        unexpected(script.trigger.type)
    end

    local effects = {}

    for _, effect in ipairs(script.effects) do
        local fn
        if effect.type == "spawn_units" then
            fn = function(_ctx)
                log.debug("Handling SpawnUnits effect.")
                self.tactics_engine:spawn_all(
                    effect.units,
                    effect.animation,
                    effect.blocked_behavior
                )
            end
        elseif effect.type == "modify_units" then
            fn = function(ctx)
                log.debug("Handling ModifyUnits effect.")
                self.tactics_engine:modify_units(
                    self:resolve_unit_selector(effect.unit_selector, ctx),
                    {
                        new_side = effect.new_side,
                        new_ai = effect.new_ai,
                    }
                )
            end
        elseif effect.type == "recruit_units" then
            fn = function(ctx)
                log.debug("Handling RecruitUnits effect.")
                self.tactics_engine:recruit_units(
                    self:resolve_unit_selector(effect.unit_selector, ctx)
                )
            end
        elseif effect.type == "modify_terrain" then
            fn = function(_ctx)
                log.debug("Handling ModifyTerrain effect.")
                self.battle_map:update_terrain(
                    effect.tile_label,
                    effect.new_terrain
                )
            end
        elseif effect.type == "dialogue" then
            fn = function(ctx)
                log.debug("Handling Dialogue effect.")
                local units = self:resolve_unit_selector(effect.unit, ctx)
                assert(#units == 1, "Not implemented.")
                self.tactics_engine:start_dialogue(units[1], effect.text)
            end
        elseif effect.type == "despawn_units" then
            fn = function(ctx)
                log.debug("Handling DespawnUnit effect.")
                local units = self:resolve_unit_selector(effect.units, ctx)
                self.tactics_engine:despawn_unit(units)
            end
        elseif effect.type == "play_sound" then
            fn = function(_ctx)
                log.debug("Handling PlaySound effect.")
                local SFX_MAP = {
                    ["death"] = 0
                }
                local sound = SFX_MAP[effect.sound_id]
                if sound ~= nil then
                    sfx(sound)
                end
            end
        elseif effect.type == "remove_script" then
            fn = function(_ctx)
                log.debug("Handling RemoveScript effect.")
                for script_id, s in pairs(self.active_scripts) do
                    if s.tags and lists.contains(s.tags, effect.tag) then
                        self:remove_script(script_id)
                    end
                end
            end
        elseif effect.type == "play_music" then
            fn = function(_ctx)
                log.debug("Handling PlayMusic effect.")
                local MUSIC_MAP = {
                    ["recruit"] = { id = 8 },
                    ["recruit_short"] = { id = 8, offset = 50 * 16 },
                    ["death"] = { id = 9 },
                }

                if effect.music_id == nil then
                    self.music_player:resume_music(1000)
                else
                    local music = MUSIC_MAP[effect.music_id]
                    if music ~= nil then
                        if effect.music_type == "music" then
                            self.music_player:set_music(music.id, music.offset)
                        else
                            self.music_player:push_music(music.id, music.offset)
                        end
                    end
                end
            end
        else
            unexpected(effect.type)
        end
        table.insert(effects, fn)
    end

    local listener_id = self.event_listener:on(
        event,
        function(args)
            local triggered, ctx = filter(args)
            if triggered then
                local tactics_lock = self.tactics_engine:acquire_lock()
                if script.one_shot then
                    self:remove_script(script.id)
                end
                self.task_manager:start_routine(function()
                    for _, eff in ipairs(effects) do
                        eff(ctx)
                        while self.tactics_engine:is_blocked() do
                            yield()
                        end
                        log.debug("Handled script effect.")
                    end
                    self.tactics_engine:remove_lock(tactics_lock)
                end)
            end
        end
    )
    self.script_listeners[script.id] = listener_id
    self.active_scripts[script.id] = script
end

--- Tear down all event listeners.
function ScriptManager:teardown()
    self.event_listener:teardown()
end

local script_manager = {
    ScriptManager = ScriptManager
}

--- Create a new ScriptManager, registering all provided scripts.
---@param scripts BattleScript[] List of scripts to register on creation.
---@param bus EventBus
---@param music_player MusicPlayer
---@param map BattleMap
---@param tactics TacticsEngine
---@param task_manager TaskManager
---@return ScriptManager
function script_manager.new(scripts, bus, music_player, map, tactics, task_manager)
    scripts = scripts or {}

    ---@type ScriptManager
    local self = setmetatable({}, ScriptManager)

    self.event_listener = event_listener.new(bus)
    self.music_player = music_player
    self.tactics_engine = tactics
    self.battle_map = map
    self.task_manager = task_manager
    self.script_listeners = {}
    self.active_scripts = {}

    local id_gen = id_generator.new()

    for _, script in ipairs(scripts) do
        script.id = id_gen:get_id()

        local trigger = script.trigger
        if trigger.type == "unit_interaction" then
            local units = self:resolve_unit_specifier(trigger.unit_specifier)
            for _, unit in ipairs(units) do
                self.battle_map:register_unit_interaction(
                    unit,
                    script.id,
                    trigger.interaction_text
                )
            end
        elseif trigger.type == "tile_interaction" then
            local tiles = self:resolve_tile_specifier(trigger.tile_specifier)
            for _, tile in ipairs(tiles) do
                self.battle_map:register_tile_interaction(
                    tile,
                    script.id,
                    trigger.interaction_text,
                    trigger.interaction_distance
                )
            end
        end

        self:register_script(script)
    end

    return self
end

return script_manager
