require("src/tactics/types")
local battle_definition_types = require("src/tactics/battle/definition/types")
local unit_ai = require("src/tactics/battle/unit/unit_ai")

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

function unit_spawn_data.character_source.template(template: string): CharacterSource
	local self: CharacterTemplateSource = {
		type = "template",
		template = template,
	}
	return self
end

function unit_spawn_data.character_source.player_roster(): CharacterSource
	local self: PlayerRosterSource = {
		type = "player_roster",
	}
	return self
end

return unit_spawn_data
