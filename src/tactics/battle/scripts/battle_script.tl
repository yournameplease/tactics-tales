---@brief
--- Defines the data structures for the battle scripting system.
--- Specifies the shape of triggers and their corresponding effects,
--- forming the basis for event-driven scenarios in battles.

local unit_spawn_data = require("src.tactics.battle.unit.spawn_data")
local battle_map = require("src.tactics.battle.battle_map")
local TileDistance = require("src.tactics.battle.battle_map.types").TileDistance
local unit_ai = require("src.tactics.battle.unit.unit_ai")
local character = require("src.tactics.character.object.character")
local point = require("src.tactics.util.point")
local PointRecord = point.PointRecord

-- selector: may depend on script context.  for effects
-- specifier: no context.  for triggers

local enum UnitSelectorMode
	"trigger_source"
	"trigger_target"
	"tag_lookup"	
end

local interface UnitSelector
	type: UnitSelectorMode
end

local interface UnitSpecifier
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
	is UnitSelector, UnitSpecifier
	where self.type == "tag_lookup"
	tag: string
end

local enum TileSelectorMode
	"static_point"
	"tag_lookup"	
	"trigger_source"
	"trigger_target"
end

local interface TileSelector
	type: TileSelectorMode
end

local interface TileSpecifier
	type: TileSelectorMode
end

local record StaticPointTileSpecifier
	is TileSpecifier, TileSelector
	where self.type == "static_point"
	point: PointRecord
end

local record TagLookupTileSpecifier
	is TileSpecifier, TileSelector
	where self.type == "tag_lookup"
	tag: string
end

local record TriggerSourceTileSelector
	is TileSelector
	where self.type == "trigger_source"
end

local record TriggerTargetTileSelector
	is TileSelector
	where self.type == "trigger_target"
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

local enum TurnTriggerTimeOffset
	"before"
	"after"
end

local record TurnTriggerTime
	offset: TurnTriggerTimeOffset
	side: character.Side
end

local record Turn
	is ScriptTrigger
	where self.type == "turn"
	turn: integer
	repeating: integer
	phase: TurnTriggerTime
end

local record UnitDeath
	is ScriptTrigger
	where self.type == "unit_death"
	unit_label: string 
end

local record UnitInteraction
	is ScriptTrigger
	where self.type == "unit_interaction"
	unit_specifier: UnitSpecifier
	interaction_text: string
end

local record TileInteraction
	is ScriptTrigger
	where self.type == "tile_interaction"
	tile_specifier: TileSpecifier
	interaction_text: string
	interaction_distance: TileDistance
end

local enum ScriptEffectType
	"spawn_units"
	"modify_units"
	"modify_terrain"
	"dialogue"
	"despawn_units"
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
	unit: UnitSelector
	text: {string}
end

local record DespawnUnits
	is ScriptEffect
	where self.type == "despawn_units"
	units: UnitSelector
	-- todo: direction?
end

local record BattleScript
	id: integer
	trigger: ScriptTrigger
	effects: {ScriptEffect}
	one_shot: boolean -- should remove after firing
end

local battle_script = {
	BattleScript = BattleScript,
	selector = {
		UnitSelector = UnitSelector,
		TileSelector = TileSelector,
		UnitSpecifier = UnitSpecifier,
		TileSpecifier = TileSpecifier,

		TriggerSourceUnitSelector = TriggerSourceUnitSelector,
		TriggerTargetUnitSelector = TriggerTargetUnitSelector,
		TagLookupUnitSelector = TagLookupUnitSelector,
		StaticPointTileSpecifier = StaticPointTileSpecifier,
		TagLookupTileSpecifier = TagLookupTileSpecifier,
		TriggerSourceTileSelector = TriggerSourceTileSelector,
		TriggerTargetTileSelector = TriggerTargetTileSelector,
	},
	trigger = {
		ScriptTrigger = ScriptTrigger,

		Turn = Turn,
		TurnTriggerTimeOffset = TurnTriggerTimeOffset,
		TurnTriggerTime = TurnTriggerTime,
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
		Dialogue = Dialogue,
		DespawnUnits = DespawnUnits,
	}
}

return battle_script
