
local enum ScriptTriggerType
	"turn"
	"unit_death"
end

local interface ScriptTrigger
	type: ScriptTriggerType
end

local enum TurnTriggerPhase
	"before_player"
	"after_player"
	"before_enemy"
	"after_enemy"
end

local record Turn
	is ScriptTrigger
	where self.type == "unit_death"
	turn: integer
	repeating: integer
	phase: TurnTriggerPhase
end

local record UnitDeath
	is ScriptTrigger
	where self.type == "unit_death"
	unit_label: string 
end

local enum ScriptType
	"spawn_units"
	"modify_terrain"
end

local interface BattleScript
	type: ScriptType
	trigger: ScriptTrigger
end

local record SpawnUnits
	is BattleScript
	where self.type == "spawn_units"
end

local record ModifyTerrain
	is BattleScript
	where self.type == "modify_terrain"
end

local battle_script = {
	BattleScript = BattleScript,
	trigger = {
		Turn = Turn,
		UnitDeath = UnitDeath
	},
	script = {
		SpawnUnits = SpawnUnits,
		ModifyTerrain = ModifyTerrain
	}
}

return battle_script
