local battle_definition_types = require("src.tactics.battle.definition.types")
local unit_ai = require("src.tactics.battle.unit.unit_ai")

local enum UnitSpawnAnimation
    "from_north"
    "from_south"
    "from_east"
    "from_west"
end

local enum CharacterSourceType
    "template"
    "player_roster"
end

local interface CharacterSource
    type: CharacterSourceType
end

local record PlayerRosterSource
    is CharacterSource
    where self.type == "player_roster"
end

local record CharacterTemplateSource
    is CharacterSource
    where self.type == "template"
    template: string
end

local record UnitSpawnData
    character_source: CharacterSource
    -- optional for now, may want to make an interface
    ai: unit_ai.UnitAI
    tile: battle_definition_types.TileLabel
	tags: { string } -- spawn tile is added as a tag as well
end

local unit_spawn_data = {
	UnitSpawnAnimation = UnitSpawnAnimation,
	UnitSpawnData = UnitSpawnData,
	character_source = {
		CharacterSourceType = CharacterSourceType,
		CharacterSource = CharacterSource,
		PlayerRosterSource = PlayerRosterSource,
		CharacterTemplateSource = CharacterTemplateSource,
	}
}

return unit_spawn_data
