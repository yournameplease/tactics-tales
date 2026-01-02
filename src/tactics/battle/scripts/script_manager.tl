---@brief service to listen for script triggers
--- and apply the battle events

local battle_unit = require("src/tactics/battle/tactics/battle_unit")
local BattleUnit = battle_unit.BattleUnit
local event_bus = require("src/tactics/systems/event_bus")
local event_listener = require("src/tactics/systems/event_bus/event_listener")
local battle_script = require("src/tactics/battle/scripts/battle_script")
local BattleMap = require("src/tactics/battle/battle_map").BattleMap
local tactics_engine = require("src/tactics/battle/tactics/tactics_engine")

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

function ScriptManagerImpl:register_script(
	script: battle_script.BattleScript
)

	local event: event_bus.GameEvent
	local filter: function({string: any}): boolean

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
			error()	
		end

		if trigger.repeating == nil then
			filter = function(ctx: {string: any}): boolean
				return ctx.turn == trigger.turn
			end
		else
			-- this assert is unnessary, but the LSP complains without it
			assert(trigger is battle_script.trigger.Turn)
			filter = function(ctx: {string: any}): boolean
				local turn = ctx.turn as integer
				return turn >= trigger.turn
					and (turn - trigger.turn) % trigger.repeating == 0 
			end
		end
	elseif trigger is battle_script.trigger.UnitDeath then
		event = "TACTICS_UNIT_DEATH"
		filter = function(ctx: {string: any}): boolean
			local defender = ctx.defender as BattleUnit
			return defender.labels[trigger.unit_label]
		end
	else
		error()
	end
	
	local effect: function

	if script is battle_script.script.SpawnUnits then
		effect = function()
			LOG.debug("Handling SpawnUnits event")
		    self.tactics_engine:spawn_all(
		        script.players,
		        script.enemies,
		        script.neutral,
				script.animation
		    )
		end
	elseif script is battle_script.script.ModifyTerrain then
		effect = function()
			LOG.debug("Handling ModifyTerrain event")
			self.battle_map:update_terrain(
				script.tile_label,
				script.new_terrain
			)
		end
	else
		error()
	end

	self.event_listener:on(
		event,
		function(args: {string: any})
			if filter(args) then
				effect()
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
