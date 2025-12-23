---@brief service to listen for script triggers
--- and apply the battle events

local event_bus = require("src/tactics/systems/event_bus")
local battle_script = require("src/tactics/battle/scripts/battle_script")
local battle_map = require("src/tactics/battle/battle_map")
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
	event_bus: EventBus
	event_listener_ids: {integer}
end

function ScriptManagerImpl:register_script(
	script: battle_script.BattleScript
)

	local event: GameEvent
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
		    self.tactics_engine:spawn_all(
		        script.players,
		        script.enemies,
		        script.neutral
		    )
		end
	elseif script is battle_script.script.ModifyTerrain then
		effect = function()
			self.battle_map:
			error("unimplementned")

		end
	else
		error()
	end

	pt.add(self.event_listener_ids, self.event_bus:on(
		event,
		function(args: {string: any})
			if filter(args) then
				effect()
			end
		end
	))
end

function script_manager.new(
	scripts: { battle_script.BattleScript },
	event_bus: EventBus,
	battle_map: BattleMap,
	tactics_engine: tactics_engine.TacticsEngine
): ScriptManager
	scripts = scripts or {}

	local self: ScriptManagerImpl = setmetatable({},{
		__index = ScriptManagerImpl	
	})

	self.event_bus = event_bus
	self.event_listener_ids = {}
	self.tactics_engine = tactics_engine
	self.battle_map = battle_map

	for _,script in ipairs(scripts) do
		self:register_script(script)
	end

	return self as ScriptManager
end

function ScriptManagerImpl:teardown()
    self.event_bus:remove_all(self.event_listener_ids)
end

return script_manager
