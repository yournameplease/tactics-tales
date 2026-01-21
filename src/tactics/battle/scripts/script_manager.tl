---@brief service to listen for script triggers
--- and apply the battle events

local point = require("src/tactics/util/point")
local Point = point.Point
local battle_unit = require("src/tactics/battle/tactics/battle_unit")
local BattleUnit = battle_unit.BattleUnit
local event_bus = require("src/tactics/systems/event_bus")
local event_listener = require("src/tactics/systems/event_bus/event_listener")
local battle_script = require("src/tactics/battle/scripts/battle_script")
local BattleMap = require("src/tactics/battle/battle_map").BattleMap
local tactics_engine = require("src/tactics/battle/tactics/tactics_engine")

local record ScriptContext
	initiator: BattleUnit
	receiver: BattleUnit
	tile: Point
	turn_number: integer
end

local interface ScriptManager
	teardown: function(self)
end

local script_manager = {
	ScriptManager = ScriptManager
}

local record ScriptManagerImpl
	battle_map: BattleMap
	tactics_engine: tactics_engine.TacticsEngine
	event_listener: event_listener.EventListener
end

function ScriptManagerImpl:resolve_unit_selector(
	selector: battle_script.UnitSelector,
	ctx: ScriptContext
): { BattleUnit }
	if selector is battle_script.selector.TagLookupSelector then
		return self.battle_map:get_units(battle_unit.has_tag(selector.tag))
	elseif selector is battle_script.selector.TriggerSourceSelector then
		assert(ctx.initiator ~= nil)
		return { ctx.initiator }
	elseif selector is battle_script.selector.TriggerTargetSelector then
		assert(ctx.receiver ~= nil)
		return { ctx.receiver }
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
					initiator = attacker,
					receiver = defender,
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
				self.tactics_engine:modify_units(
					self:resolve_unit_selector(effect.unit_selector, ctx),
					{
						new_side = effect.new_side,
						new_ai = effect.new_ai,
					}
				)
			end
		elseif effect is battle_script.effect.ModifyTerrain then
			fn = function(_: ScriptContext)
				log.debug("Handling ModifyTerrain event")
				self.battle_map:update_terrain(
					effect.tile_label,
					effect.new_terrain
				)
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
				for _,effect in ipairs(effects) do
					effect(ctx)
				end
			end
		end
	)
end

function script_manager.new(
	scripts: { battle_script.BattleScript },
	bus: event_bus.EventBus,
	map: BattleMap,
	tactics: tactics_engine.TacticsEngine
): ScriptManager
	scripts = scripts or {}

	local self: ScriptManagerImpl = setmetatable({},{
		__index = ScriptManagerImpl	
	})

	self.event_listener = event_listener.new(bus)
	self.tactics_engine = tactics
	self.battle_map = map

	for _,script in ipairs(scripts) do
		self:register_script(script)
	end

	return self as ScriptManager
end

function ScriptManagerImpl:teardown()
    self.event_listener:teardown()
end

return script_manager
