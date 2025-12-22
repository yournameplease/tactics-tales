---@brief service to listen for script triggers
--- and apply the battle events

local event_bus = require("src/tactics/systems/event_bus")
local battle_script = require("src/tactics/battle/scripts/battle_script")

local interface ScriptManager
	

	teardown: function(self)
end

local script_manager = {
	ScriptManager = ScriptManager
}

local record ScriptManagerImpl
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
		elseif trigger.phase == "before_enemy" then
			event = "TACTICS_END_ENEMY_TURN"
		else
			error()	
		end

		if trigger.repeating ~= nil then
			filter = function(ctx: {string: any}): boolean
				return ctx.turn_number == trigger.turn
			end
		else
			filter = function(ctx: {string: any}): boolean
				local turn = ctx.turn_number as integer
				return turn >= trigger.turn
					and (turn - trigger.turn) % trigger.repeating == 0 
			end
		end
	elseif trigger is battle_script.trigger.UnitDeath then
		
	else
		error()
	end
	
	local effect: function

	if script is battle_script.script.SpawnUnits then
		
	elseif script is battle_script.script.ModifyTerrain then

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
	event_bus: EventBus
)

end

function ScriptManagerImpl:teardown()
    self.event_bus:remove_all(self.event_listener_ids)
end
