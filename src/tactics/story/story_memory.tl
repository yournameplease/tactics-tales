local CharacterManager = require("src/tactics/character/character_manager").CharacterManager

local type StoryMemoryMap = { string: string
--| StoryMemoryMap
}

local enum StoryMemoryEntryType
	"text"
	"character"
end

local interface StoryMemoryEntry
	type: StoryMemoryEntryType
	text: string
end

local record TextMemoryEntry
	is StoryMemoryEntry where
	self.type == "text"
	text: string
end

local record CharacterMemoryEntry
	is StoryMemoryEntry where
	self.type == "character"
	character_id: integer
end

local interface StoryMemory
	set: function(self, key: string, entry: StoryMemoryEntry)
	get: function(self, key: string): StoryMemoryEntry
	get_as_map: function(self): StoryMemoryMap
end

local story_memory = {
	StoryMemory = StoryMemory
}

function story_memory.text(text: string): StoryMemoryEntry
	local entry: TextMemoryEntry = {
		type = 'text',
		text = text,
	}
	return entry
end

function story_memory.character(character_id: integer): StoryMemoryEntry
	local entry: CharacterMemoryEntry = {
		type = 'character',
		character_id = character_id,
		text = "[Character ".. character_id .. "]"
	}
	return entry
end

local record StoryMemoryImpl
	is StoryMemory

	global: {string: StoryMemoryEntry}

    character_manager: CharacterManager
end

function StoryMemoryImpl:set(key: string, entry: StoryMemoryEntry)
	self.global[key] = entry
end

function StoryMemoryImpl:get(key: string): StoryMemoryEntry
	return self.global[key]
end

function StoryMemoryImpl:get_as_map(): StoryMemoryMap
	local out: StoryMemoryMap = {}
	for k,e in pairs(self.global) do
		if e is TextMemoryEntry then
			out[k] = e.text
		elseif e is CharacterMemoryEntry then
			local character = self.character_manager:get_character(e.character_id)
			assert(character ~= nil)
			out[k .. ".name"] = character.name
		else
			unexpected(e.type)
		end
	end
	return out
end

function story_memory.new(
	character_manager: CharacterManager
): StoryMemory
	local self: StoryMemoryImpl = setmetatable({
		global = {},
		character_manager = character_manager,
	}, {
		__index = StoryMemoryImpl
	})
	return self
end

return story_memory
