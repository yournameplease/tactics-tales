local unit_spawn_data = require("src/tactics/battle/unit/spawn_data")
local battle_map = require("src/tactics/battle/battle_map")
local unit_ai = require("src/tactics/battle/unit/unit_ai")
local character = require("src/tactics/character/object/character")
local point = require("src/tactics/util/point")
local PointRecord = point.PointRecord

local enum UnitSelectorMode
	"trigger_source"
	"trigger_target"
	"tag_lookup"	
end

local interface UnitSelector
	type: UnitSelectorMode
end

local record TriggerSourceUnitSelector
	is UnitSelector
	where self.type == "trigger_source"
end

local record TriggerTargetUnitSelector
	is UnitSelector
	where self.type == "trigger_target"
end

local record TagLookupUnitSelector
	is UnitSelector
	where self.type == "tag_lookup"
	tag: string
end

local enum TileSelectorMode
	"static_point"
	"tag_lookup"	
end

local interface TileSelector
	type: TileSelectorMode
end

local record StaticPointTileSelector
	is TileSelector
	where self.type == "static_point"
	point: PointRecord
end

local record TagLookupTileSelector
	is TileSelector
	where self.type == "tag_lookup"
	tag: string
end

local enum ScriptTriggerType
	"turn"
	"unit_death"
	"unit_interaction"
	"tile_interaction"
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

local enum InterractionDistance
	"on"
	"adjacent"
end

local record UnitInteraction
	is ScriptTrigger
	where self.type == "unit_interaction"
	unit_selector: UnitSelector
	interraction_text: string
end

local record TileInteraction
	is ScriptTrigger
	where self.type == "tile_interaction"
	tile_selector: TileSelector
	interraction_text: string
	interraction_distance: InterractionDistance
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
	selector = {
		UnitSelector = UnitSelector,
		TileSelector = TileSelector,

		TriggerSourceUnitSelector = TriggerSourceUnitSelector,
		TriggerTargetUnitSelector = TriggerTargetUnitSelector,
		TagLookupUnitSelector = TagLookupUnitSelector,
		StaticPointTileSelector = StaticPointTileSelector,
		TagLookupTileSelector = TagLookupTileSelector,
	},
	trigger = {
		ScriptTrigger = ScriptTrigger,

		Turn = Turn,
		TurnTriggerPhase = TurnTriggerPhase,
		UnitDeath = UnitDeath,
		UnitInteraction = UnitInteraction,
		TileInteraction = TileInteraction,
	},
	effect = {
		ScriptEffect = ScriptEffect,

		SpawnUnits = SpawnUnits,
		ModifyUnits = ModifyUnits,
		TerrainLocation = battle_map.TerrainLocation,
		ModifyTerrain = ModifyTerrain,
	}
}

return battle_script
