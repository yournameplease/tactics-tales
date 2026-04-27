---@brief Save and load game state to/from disk in .pod format.

local lists = require("src.tactics.util.lists")

---@class GameSaveData
---@field character_id_generator IdGenerator
---@field story_id string
---@field story_config table<string, string>
---@field story_node_id string
---@field story_node_step integer
---@field story_memory StoryMemory
---@field roster Character[]
---@field stats StoryResults
---@field story_seed integer
---@field story_rng_state integer

---@class SerializedGameSaveData
---@field character_id_count integer
---@field story_id StoryId
---@field story_config table<string, string>
---@field story_node_id string
---@field story_node_step integer
---@field story_memory SerializedStoryMemory
---@field roster SerializedCharacter[]
---@field stats StoryResults
---@field story_seed integer
---@field story_rng_state integer

local save_system = {}

local SAVE_PATH = "/appdata/tactics_tales/saves/"

-- todo: sanitize path
-- todo: check for existing files
--- Serialize and write a game save to disk.
---@param name string Save slot name (used as filename without extension).
---@param data GameSaveData
function save_system.save(name, data)
	---@type SerializedGameSaveData
	local serialized_data = {
		character_id_count = data.character_id_generator.id_count,
		story_id = data.story_id,
		story_node_id = data.story_node_id,
		story_config = data.story_config,
		story_node_step = data.story_node_step,
		story_memory = data.story_memory:serialize(),
		roster = lists.map(function(c)
			return c:serialize()
		end)(data.roster),
		stats = data.stats,
		story_seed = data.story_seed,
		story_rng_state = data.story_rng_state,
	}

	local path = SAVE_PATH .. name .. ".pod"
	log.debug("Saving data: ", name, path)
	store(path, serialized_data, nil)
end

--- Return a list of save slot names found on disk.
---@return string[]
function save_system.list_saves()
	local paths = ls(SAVE_PATH) or {}
	return lists.map(function(p)
		return split(p, '.')[1]
	end)(paths)
end

--- Load and return a serialized save by slot name, or nil if not found.
---@param name string Save slot name (used as filename without extension).
---@return SerializedGameSaveData?
function save_system.load(name)
	local path = SAVE_PATH .. name .. ".pod"
	log.debug("Loading data: ", name, path)
	return fetch(path)
end

--- Delete the save file for the given slot name.
---@param name string Save slot name.
function save_system.delete(name)
	local path = SAVE_PATH .. name .. ".pod"
	log.debug("Deleting save: ", name, path)
	rm(path)
end

return save_system
