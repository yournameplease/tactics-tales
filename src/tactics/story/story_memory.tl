
local enum StoryMemoryEntryType
	"text"
	"character"
end

local interface StoryMemoryEntry
	type: StoryMemoryEntryType
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
end

local story_memory = {
	StoryMemory = StoryMemory
}

local record StoryMemoryImpl
	is StoryMemory
	global: {string: StoryMemoryEntry}
end

function StoryMemoryImpl:set(key: string, entry: StoryMemoryEntry)
	self.global[key] = entry
end

function StoryMemoryImpl:get(key: string): StoryMemoryEntry
	return self.global[key]
end

function story_memory.story_memory(): StoryMemory
	local self: StoryMemoryImpl = setmetatable({
		global = {}
	}, {
		__index = StoryMemoryImpl
	})
	return self
end

return story_memory
