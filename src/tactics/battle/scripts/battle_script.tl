local battle_definition_types = require("src/tactics/battle/definition/types")

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
	where self.type == "turn"
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
	players: { battle_definition_types.PlayerSpawnData }
	enemies: { battle_definition_types.EnemySpawnData }
	neutral: { battle_definition_types.NeutralSpawnData }
end

local enum TerrainLocation
	"floor"
	"back"
	"mid"
	"front"
end

local record ModifyTerrain
	is BattleScript
	where self.type == "modify_terrain"
	new_terrain: { TerrainLocation: integer }
end

local battle_script = {
	BattleScript = BattleScript,
	trigger = {
		Turn = Turn,
		TurnTriggerPhase = TurnTriggerPhase,
		UnitDeath = UnitDeath
	},
	script = {
		SpawnUnits = SpawnUnits,
		TerrainLocation = TerrainLocation,
		ModifyTerrain = ModifyTerrain
	}
}

function battle_script.trigger.turn(
	turn: integer,
	repeating: integer,
	phase: TurnTriggerPhase
): Turn
	return {
		type = "turn",
		turn = turn,
		repeating = repeating,
		phase = phase,
	}
end

function battle_script.trigger.unit_death(
	unit_label: string
): UnitDeath
	return {
		type = "unit_death",
		unit_label = unit_label,
	}
end

function battle_script.script.spawn_units(
	trigger: ScriptTrigger,
	players: { battle_definition_types.PlayerSpawnData },
	enemies: { battle_definition_types.EnemySpawnData }
): SpawnUnits
	return {
		type = "spawn_units",
		trigger = trigger,
		players = players,
		enemies = enemies,
	}
end

function battle_script.script.modify_terrain(
	trigger: ScriptTrigger,
	new_terrain: { TerrainLocation: integer }
): ModifyTerrain
	return {
		type = "modify_terrain",
		trigger = trigger,
		new_terrain = new_terrain
	}
end


return battle_script
