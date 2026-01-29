---@brief service to listen for script triggers
--- and apply the battle events

local point = require("src/tactics/util/point")
local Point = point.Point
local id_generator = require("src/tactics/util/id_generator")
local battle_unit = require("src/tactics/battle/tactics/battle_unit")
local BattleUnit = battle_unit.BattleUnit
local event_bus = require("src/tactics/systems/event_bus")
local event_listener = require("src/tactics/systems/event_bus/event_listener")
local battle_script = require("src/tactics/battle/scripts/battle_script")
local bm = require("src/tactics/battle/battle_map")
local tactics_engine = require("src/tactics/battle/tactics/tactics_engine")
local TaskManager = require("src/tactics/systems/tasks").TaskManager

local record ScriptContext
	source_unit: BattleUnit
	target_unit: BattleUnit
	source_tile: Point
	target_tile: Point
	turn_number: integer
end

local interface ScriptManager
	teardown: function(self)
end

local script_manager = {
	ScriptManager = ScriptManager
}

local record TileInteractionMessage
    script_id: integer
    source_unit: BattleUnit
    source_tile: Point
    target_tile: Point
end

local record UnitInteractionMessage
    script_id: integer
    source_unit: BattleUnit
    source_tile: Point
    target_unit: BattleUnit
    target_tile: Point
end

local record ScriptManagerImpl
	battle_map: bm.BattleMap
	tactics_engine: tactics_engine.TacticsEngine
	event_listener: event_listener.EventListener
    task_manager: TaskManager
end

function ScriptManagerImpl:resolve_unit_specifier(
	selector: battle_script.selector.UnitSpecifier
): { BattleUnit }
	if selector is battle_script.selector.TagLookupUnitSelector then
		return self.battle_map:get_units(battle_unit.has_tag(selector.tag))
	else
		unexpected(selector.type)
	end
end

function ScriptManagerImpl:resolve_unit_selector(
	selector: battle_script.selector.UnitSelector,
	ctx: ScriptContext
): { BattleUnit }
	if
		selector is battle_script.selector.TagLookupUnitSelector
	then
		return self:resolve_unit_specifier(selector)
	elseif selector is battle_script.selector.TriggerSourceUnitSelector then
		assert(ctx.source_unit ~= nil)
		return { ctx.source_unit }
	elseif selector is battle_script.selector.TriggerTargetUnitSelector then
		assert(ctx.target_unit ~= nil)
		return { ctx.target_unit }
	else
		unexpected(selector.type)
	end
end

function ScriptManagerImpl:resolve_tile_specifier(
	selector: battle_script.selector.TileSpecifier
): { Point }
	if selector is battle_script.selector.TagLookupTileSpecifier then
		return self.battle_map:get_tiles_by_label(selector.tag)
	elseif selector is battle_script.selector.StaticPointTileSpecifier then
		return { point.of_record(selector.point) }
	else
		unexpected(selector.type)
	end
end

function ScriptManagerImpl:resolve_tile_selector(
	selector: battle_script.selector.TileSelector,
	ctx: ScriptContext
): { Point }
	if
		selector is battle_script.selector.StaticPointTileSpecifier
		or selector is battle_script.selector.TagLookupTileSpecifier
	then
		return self:resolve_tile_specifier(selector)
	elseif selector is battle_script.selector.TriggerSourceTileSelector then
		assert(ctx.source_tile ~= nil)
		return { ctx.source_tile }
	elseif selector is battle_script.selector.TriggerTargetTileSelector then
		assert(ctx.target_tile ~= nil)
		return { ctx.target_tile }
	else
		unexpected(selector.type)
	end
end

function ScriptManagerImpl:register_script(
	script: battle_script.BattleScript
)

	local event: event_bus.GameEvent
	local filter: function({string: any}): boolean, ScriptContext

	local trigger = script.trigger

	if trigger is battle_script.trigger.Turn then
		if trigger.phase == "before_player" then
			event = "TACTICS_BEGIN_PLAYER_TURN"
		elseif trigger.phase == "after_player" then
			event = "TACTICS_END_PLAYER_TURN"
		elseif trigger.phase == "before_enemy" then
			event = "TACTICS_BEGIN_ENEMY_TURN"
		elseif trigger.phase == "after_enemy" then
			event = "TACTICS_END_ENEMY_TURN"
		else
			unexpected(trigger.phase)	
		end

		if trigger.repeating == nil then
			filter = function(ctx: {string: any}): boolean, ScriptContext
				local turn = ctx.turn as integer
				return turn == trigger.turn,
					{
						turn_number = turn
					}
			end
		else
			-- this assert is unnessary, but the LSP complains without it
			assert(trigger is battle_script.trigger.Turn)
			filter = function(ctx: {string: any}): boolean, ScriptContext
				local turn = ctx.turn as integer
				return turn >= trigger.turn
					and (turn - trigger.turn) % trigger.repeating == 0,
					{
						turn_number = turn
					}
			end
		end
	elseif trigger is battle_script.trigger.UnitDeath then
		event = "TACTICS_UNIT_DEATH"
		filter = function(ctx: {string: any}): boolean, ScriptContext
			local defender = ctx.defender as BattleUnit
			local attacker = ctx.attacker as BattleUnit
			return
				defender.tags[trigger.unit_label],
				{
					source_unit = attacker,
					source_tile = attacker.tile,
					target_unit = defender,
					target_tile = defender.tile,
				}
		end
	elseif trigger is battle_script.trigger.UnitInteraction then
		event = "TACTICS_INTERACTION"
		filter = function(msg: UnitInteractionMessage): boolean, ScriptContext
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
	elseif trigger is battle_script.trigger.TileInteraction then
		event = "TACTICS_INTERACTION"
		filter = function(msg: TileInteractionMessage): boolean, ScriptContext
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
	
	local effects: {function(ScriptContext)} = {}

	for _,effect in ipairs(script.effects) do
		local fn: function(ScriptContext)
		if effect is battle_script.effect.SpawnUnits then
			fn = function(_: ScriptContext)
				log.debug("Handling SpawnUnits event")
			    self.tactics_engine:spawn_all(
			        effect.players,
			        effect.enemies,
			        effect.neutral,
					effect.animation
			    )
			end
		elseif effect is battle_script.effect.ModifyUnits then
			fn = function(ctx: ScriptContext)
				log.debug("Handling ModifyUnits event")
				local sel = effect.unit_selector
				self.tactics_engine:modify_units(
					self:resolve_unit_selector(effect.unit_selector, ctx),
					{
						new_side = effect.new_side,
						new_ai = effect.new_ai,
					}
				)
			end
		elseif effect is battle_script.effect.ModifyTerrain then
			fn = function(_ctx: ScriptContext)
				log.debug("Handling ModifyTerrain event")
				self.battle_map:update_terrain(
					effect.tile_label,
					effect.new_terrain
				)
			end
		elseif effect is battle_script.effect.Dialogue then
			fn = function(ctx: ScriptContext)
				log.debug("Handling Dialogue event")
				local units = self:resolve_unit_selector(effect.unit, ctx)
				assert(#units == 1, "Not implemented.")
				self.tactics_engine:start_dialogue(units[1], effect.text)
			end
		elseif effect is battle_script.effect.DespawnUnits then
			fn = function(ctx: ScriptContext)
				log.debug("Handling DespawnUnit event")
				local units = self:resolve_unit_selector(effect.units, ctx)
				self.tactics_engine:despawn_unit(units)
			end
		else
			unexpected(effect.type)
		end
		pt.add(effects, fn)
	end

	self.event_listener:on(
		event,
		function(args: {string: any})
			local triggered, ctx = filter(args)
			if triggered then
		        self.task_manager:start_routine(function()
					for _,effect in ipairs(effects) do
						effect(ctx)
						while self.tactics_engine:is_blocked() do
							pt.yield()
						end
					end
				end)
			end
		end
	)
end

function script_manager.new(
	scripts: { battle_script.BattleScript },
	bus: event_bus.EventBus,
	map: bm.BattleMap,
	tactics: tactics_engine.TacticsEngine,
    task_manager: TaskManager
): ScriptManager
	scripts = scripts or {}

	local self: ScriptManagerImpl = setmetatable({},{
		__index = ScriptManagerImpl	
	})

	self.event_listener = event_listener.new(bus)
	self.tactics_engine = tactics
	self.battle_map = map
	self.task_manager = task_manager

	local id_gen = id_generator.new()

	for _,script in ipairs(scripts) do
		script.id = id_gen:get_id()

		local trigger = script.trigger	
		if trigger is battle_script.trigger.UnitInteraction then
			local units = self:resolve_unit_specifier(trigger.unit_specifier)
			for _,unit in ipairs(units) do
				self.battle_map:register_unit_interaction(
					unit,
					script.id,
					trigger.interaction_text
				)
			end
		elseif trigger is battle_script.trigger.TileInteraction then
			local tiles = self:resolve_tile_specifier(trigger.tile_specifier)
			for _,tile in ipairs(tiles) do
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

	return self as ScriptManager
end

function ScriptManagerImpl:teardown()
    self.event_listener:teardown()
end

return script_manager
