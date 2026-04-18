---@brief
--- A key-value store for story variables, allowing data to be
--- persisted and used across different story nodes.

---@alias StoryMemoryEntryType "text"|"character"

---@alias StoryMemoryMap table<string, string>

---@class StoryMemoryEntry
---@field type StoryMemoryEntryType
---@field text string Human-readable representation of the entry.

---@class TextMemoryEntry : StoryMemoryEntry
---@field type "text"
---@field text string

---@class CharacterMemoryEntry : StoryMemoryEntry
---@field type "character"
---@field character_id CharacterId
---@field text string

---@alias SerializedStoryMemory table<string, StoryMemoryEntry>

---@class StoryMemory Abstract interface; use story_memory.new() to get an implementation.
---@field set fun(self: StoryMemory, key: string, entry: StoryMemoryEntry) Store an entry under the given key.
---@field get fun(self: StoryMemory, key: string): StoryMemoryEntry? Retrieve a stored entry by key.
---@field get_as_map fun(self: StoryMemory): StoryMemoryMap Flatten all entries into a string-to-string map for template substitution.
---@field serialize fun(self: StoryMemory): SerializedStoryMemory Serialize all entries to a plain table.
---@field deserialize fun(self: StoryMemory, data: SerializedStoryMemory) Load entries from a serialized table.
local StoryMemory = {}

---@class StoryMemoryImpl : StoryMemory
---@field global table<string, StoryMemoryEntry> Internal store of all memory entries.
---@field character_manager CharacterManager
local StoryMemoryImpl = {}
StoryMemoryImpl.__index = StoryMemoryImpl

--- Store an entry under the given key.
---@param key string
---@param entry StoryMemoryEntry
function StoryMemoryImpl:set(key, entry)
    self.global[key] = entry
end

--- Retrieve a stored entry by key.
---@param key string
---@return StoryMemoryEntry?
function StoryMemoryImpl:get(key)
    return self.global[key]
end

--- Flatten all entries into a string-to-string map for template substitution.
---@return StoryMemoryMap
function StoryMemoryImpl:get_as_map()
    ---@type StoryMemoryMap
    local out = {}
    for k, e in pairs(self.global) do
        if e.type == "text" then
            out[k] = e.text
        elseif e.type == "character" then
            ---@cast e CharacterMemoryEntry
            local character = self.character_manager:get_character(e.character_id)
            assert(character ~= nil)
            out[k .. ".name"] = character.name
        else
            error("unexpected entry type: " .. tostring(e.type))
        end
    end
    return out
end

--- Serialize all entries to a plain table.
---@return SerializedStoryMemory
function StoryMemoryImpl:serialize()
    ---@type SerializedStoryMemory
    local out = {}
    for k, e in pairs(self.global) do
        out[k] = e
    end
    return out
end

--- Load entries from a serialized table.
---@param data SerializedStoryMemory
function StoryMemoryImpl:deserialize(data)
    for k, e in pairs(data) do
        self.global[k] = e
    end
end

local story_memory = {
    StoryMemory = StoryMemory,
    SerializedStoryMemory = nil,
}

--- Create a text memory entry.
---@param text string
---@return StoryMemoryEntry
function story_memory.text(text)
    ---@type TextMemoryEntry
    local entry = {
        type = "text",
        text = text,
    }
    return entry
end

--- Create a character memory entry.
---@param character_id CharacterId
---@return StoryMemoryEntry
function story_memory.character(character_id)
    ---@type CharacterMemoryEntry
    local entry = {
        type = "character",
        character_id = character_id,
        text = "[Character " .. character_id .. "]",
    }
    return entry
end

--- Create a new StoryMemory backed by the given character manager.
---@param character_manager CharacterManager
---@return StoryMemory
function story_memory.new(character_manager)
    ---@type StoryMemoryImpl
    local self = setmetatable({
        global = {},
        character_manager = character_manager,
    }, StoryMemoryImpl)
    return self
end

return story_memory
