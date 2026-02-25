local story_memory = require("src.tactics.story.story_memory")
local character = require("src.tactics.character.object.character")
local lists = require("src.tactics.util.lists")
local GameData = require("src.tactics.game_data").GameData
local character_generator = require("src.tactics.character.character_generator")

local save_system = {}

local record GameSaveData
	story_memory: story_memory.StoryMemory
	roster: {character.Character}
end

local record SerializedGameSaveData
	story_memory: story_memory.StoryMemory
	roster: {character.SerializedCharacter}
end

-- todo: sanitize path
-- todo: check for existing files
function save_system.save(name: string, data: GameSaveData)
	local serialized_data = {
		story_memory = data.story_memory,
		roster = lists.map(function(c: character.Character): character.SerializedCharacter
			return c:serialize()
		end)(data.roster)
	}
	
	pt.store("/appdata/tactics_tales/saves/"..name..".pod", serialized_data, nil)
end

function save_system.load(name: string, game_data: GameData): GameSaveData
	local data: SerializedGameSaveData = pt.fetch("/appdata/tactics_tales/saves/"..name..".pod") as SerializedGameSaveData

	return {
		story_memory = data.story_memory,
		roster = lists.map(function(c: character.SerializedCharacter): character.Character
			return character_generator.deserialize(c, game_data)
		end)(data.roster),
	}
end
