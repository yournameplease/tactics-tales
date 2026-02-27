local story_memory = require("src.tactics.story.story_memory")
local character = require("src.tactics.character.object.character")
local lists = require("src.tactics.util.lists")
local story_types = require("src.tactics.story.types")

local save_system = {}

local SAVE_PATH = "/appdata/tactics_tales/saves/"

local record GameSaveData
	story_id: story_types.StoryId
	story_node_id: string
	story_node_step: integer
	story_memory: story_memory.StoryMemory
	roster: {character.Character}
end

local record SerializedGameSaveData
	story_id: story_types.StoryId
	story_node_id: string
	story_node_step: integer
	story_memory: story_memory.SerializedStoryMemory
	roster: {character.SerializedCharacter}
end

-- todo: sanitize path
-- todo: check for existing files
function save_system.save(name: string, data: GameSaveData)
	local serialized_data = {
		story_id = data.story_id,
		story_node_id = data.story_node_id,
		story_node_step = data.story_node_step,
		story_memory = data.story_memory:serialize(),
		roster = lists.map(function(c: character.Character): character.SerializedCharacter
			return c:serialize()
		end)(data.roster)
	}

	local path = SAVE_PATH..name..".pod"
	log.debug("Saving data: ", name, path)
	pt.store(path, serialized_data, nil)
end

function save_system.list_saves(): {string}
	local paths = pt.ls(SAVE_PATH) or {}
	return lists.map(function(p: string): string
		return pt.split(p, '.')[1]
	end)(paths)
end

function save_system.load(name: string): SerializedGameSaveData
	local path = SAVE_PATH..name..".pod"
	log.debug("Loading data: ", name, path)
	local data: SerializedGameSaveData = pt.fetch(path) as SerializedGameSaveData

	return data
end

return save_system
