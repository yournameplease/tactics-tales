---@brief
--- A key-value store for story variables, allowing data to be
--- persisted and used across different story nodes.

---@alias CampaignStateEntryType "text"|"character"|"map"|"list"

---@alias CampaignStateMap table<string, string>

---@class CampaignStateEntry
---@field type CampaignStateEntryType
---@field text? string Human-readable representation of the entry.

---@class TextMemoryEntry : CampaignStateEntry
---@field type "text"
---@field text string

---@class CharacterMemoryEntry : CampaignStateEntry
---@field type "character"
---@field character_id CharacterId
---@field text string

---@class MapMemoryEntry : CampaignStateEntry
---@field type "map"
---@field entries table<string, string>

---@class ListMemoryEntry : CampaignStateEntry
---@field type "list"
---@field values string[]

---@alias SerializedCampaignState table<string, CampaignStateEntry>

---@class CampaignState Abstract interface; use campaign_state.new() to get an implementation.
---@field set fun(self: CampaignState, key: string, entry: CampaignStateEntry) Store an entry under the given key.
---@field get fun(self: CampaignState, key: string): CampaignStateEntry? Retrieve a stored entry by key.
---@field get_as_map fun(self: CampaignState): CampaignStateMap Flatten all entries into a string-to-string map for template substitution.
---@field serialize fun(self: CampaignState): SerializedCampaignState Serialize all entries to a plain table.
---@field deserialize fun(self: CampaignState, data: SerializedCampaignState) Load entries from a serialized table.

---@class CampaignStateImpl : CampaignState
---@field global table<string, CampaignStateEntry> Internal store of all memory entries.
---@field character_manager CharacterManager
local CampaignStateImpl = {}
CampaignStateImpl.__index = CampaignStateImpl

--- Store an entry under the given key.
---@param key string
---@param entry CampaignStateEntry
function CampaignStateImpl:set(key, entry)
    self.global[key] = entry
end

--- Retrieve a stored entry by key.
---@param key string
---@return CampaignStateEntry?
function CampaignStateImpl:get(key)
    return self.global[key]
end

--- Flatten all entries into a string-to-string map for template substitution.
---@return CampaignStateMap
function CampaignStateImpl:get_as_map()
    ---@type CampaignStateMap
    local out = {}
    for k, e in pairs(self.global) do
        if e.type == "text" then
            ---@cast e TextMemoryEntry
            out[k] = e.text
        elseif e.type == "character" then
            ---@cast e CharacterMemoryEntry
            local character = self.character_manager:get_character(e.character_id)
            assert(character ~= nil)
            out[k .. ".name"] = character.name
        elseif e.type == "map" then
            -- Map entries are programmatic data; intentionally excluded from template substitution.
        elseif e.type == "list" then
            -- List entries are programmatic data; intentionally excluded from template substitution.
        else
            error("unexpected entry type: " .. tostring(e.type))
        end
    end
    return out
end

--- Serialize all entries to a plain table.
---@return SerializedCampaignState
function CampaignStateImpl:serialize()
    ---@type SerializedCampaignState
    local out = {}
    for k, e in pairs(self.global) do
        out[k] = e
    end
    return out
end

--- Load entries from a serialized table.
---@param data SerializedCampaignState
function CampaignStateImpl:deserialize(data)
    for k, e in pairs(data) do
        self.global[k] = e
    end
end

local campaign_state = {
    SerializedCampaignState = nil,
}

--- Create a text memory entry.
---@param text string
---@return TextMemoryEntry
function campaign_state.text(text)
    ---@type TextMemoryEntry
    local entry = {
        type = "text",
        text = text,
    }
    return entry
end

--- Create a character memory entry.
---@param character_id CharacterId
---@return CharacterMemoryEntry
function campaign_state.character(character_id)
    ---@type CharacterMemoryEntry
    local entry = {
        type = "character",
        character_id = character_id,
        text = "[Character " .. character_id .. "]",
    }
    return entry
end

--- Create a map memory entry (string-to-string table, for structured run state).
---@param entries table<string, string>
---@return MapMemoryEntry
function campaign_state.map(entries)
    ---@type MapMemoryEntry
    local entry = {
        type = "map",
        entries = entries,
    }
    return entry
end

--- Create a list memory entry (ordered string array, for structured run state).
---@param values string[]
---@return ListMemoryEntry
function campaign_state.list(values)
    ---@type ListMemoryEntry
    local entry = {
        type = "list",
        values = values,
    }
    return entry
end

--- Create a new CampaignState backed by the given character manager.
---@param character_manager CharacterManager
---@return CampaignState
function campaign_state.new(character_manager)
    ---@type CampaignStateImpl
    local self = setmetatable({
        global = {},
        character_manager = character_manager,
    }, CampaignStateImpl)
    return self
end

return campaign_state
