local unit_spawn_data = require("src/tactics/battle/unit/spawn_data")
local battle_map = require("src/tactics/battle/battle_map")
local unit_ai = require("src/tactics/battle/unit/unit_ai")
local character = require("src/tactics/character/object/character")

local enum UnitSelectorMode
	"trigger_source"
	"trigger_target"
	"tag_lookup"	
end

local interface UnitSelector
	type: UnitSelectorMode
end

local record TriggerSourceSelector
	is UnitSelector
	where self.type == "trigger_source"
end

local record TriggerTargetSelector
	is UnitSelector
	where self.type == "trigger_target"
end

local record TagLookupSelector
	is UnitSelector
	where self.type == "tag_lookup"
	tag: string
end

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

local enum ScriptEffectType
	"spawn_units"
	"modify_units"
	"modify_terrain"
	"dialogue"
	"exit_unit"
end

local interface ScriptEffect
	type: ScriptEffectType
end

local record SpawnUnits
	is ScriptEffect
	where self.type == "spawn_units"
	animation: unit_spawn_data.UnitSpawnAnimation
    enemies: { unit_spawn_data.UnitSpawnData}
    neutral: { unit_spawn_data.UnitSpawnData}
    players: { unit_spawn_data.UnitSpawnData}
end

local record ModifyUnits
	is ScriptEffect
	where self.type == "modify_units"
	unit_selector: UnitSelector
    new_side: character.Side
    new_ai: unit_ai.UnitAI
end

local record ModifyTerrain
	is ScriptEffect
	where self.type == "modify_terrain"
	tile_label: string
	new_terrain: battle_map.NewTilesMap
end

local record Dialogue
	is ScriptEffect
	where self.type == "dialogue"
	speaking_unit: UnitSelector
	text: {string}
end

local record BattleScript
	trigger: ScriptTrigger
	effects: {ScriptEffect}
end

local battle_script = {
	BattleScript = BattleScript,
	ScriptEffect = ScriptEffect,
	ScriptTrigger = ScriptTrigger,
	UnitSelector = UnitSelector,
	selector = {
		TriggerSourceSelector = TriggerSourceSelector,
		TriggerTargetSelector = TriggerTargetSelector,
		TagLookupSelector = TagLookupSelector,
	},
	trigger = {
		Turn = Turn,
		TurnTriggerPhase = TurnTriggerPhase,
		UnitDeath = UnitDeath
	},
	effect = {
		SpawnUnits = SpawnUnits,
		ModifyUnits = ModifyUnits,
		TerrainLocation = battle_map.TerrainLocation,
		ModifyTerrain = ModifyTerrain
	}
}

return battle_script
