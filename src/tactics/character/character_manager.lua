---@brief
--- Manages the lifecycle and storage of all character instances.
--- It holds the player roster and is responsible for generating new
--- characters for battles.

local id_generator = require("src.tactics.util.id_generator")
local character_generator = require("src.tactics.character.character_generator")
local fp = require("src.tactics.util.fp")
local lists = require("src.tactics.util.lists")
local maps = require("src.tactics.util.maps")

-- Eventually, may want to differentiate between persistent
-- and transient characters.  No real reason now though.

--- Public interface for the character manager.
---@class CharacterManager Abstract interface; use character_manager.new() to get an implementation.
---@field id_generator IdGenerator
---@field get_character fun(self: CharacterManager, id: integer): Character? Retrieve a character by its unique ID.
---@field generate_character fun(self: CharacterManager, template_id: string?, tags: string[]): Character Generate a new character from a template.
---@field load_character fun(self: CharacterManager, data: SerializedCharacter): Character Reconstruct a character from serialized data.
---@field persist_player fun(self: CharacterManager, char: Character) Add a character to the persistent player roster.
---@field get_player_roster fun(self: CharacterManager): Character[] Return all living characters in the player roster.
---@field teardown fun(self: CharacterManager) Release resources held by the manager.
local CharacterManager = {}

--- Internal implementation.
---@class CharacterManagerImpl : CharacterManager
---@field game_data table GameData used to generate characters.
---@field id_generator IdGenerator Generates unique character IDs.
---@field characters table<integer, Character> All known characters keyed by ID.
---@field player_ids integer[] Ordered list of IDs in the player roster.
local CharacterManagerImpl = {}
CharacterManagerImpl.__index = CharacterManagerImpl

--- Retrieve a character by its unique ID.
---@param id integer
---@return Character?
function CharacterManagerImpl:get_character(id)
    return self.characters[id]
end

--- Generate a new character from a template and assign tags.
---@param template_id string? Template ID; nil uses the "default" template.
---@param tags string[] Tags to assign to the generated character.
---@return Character
function CharacterManagerImpl:generate_character(template_id, tags)
    local out = character_generator.generate_from_template(
        self.id_generator:get_id(),
        template_id,
        tags,
        self.game_data
    )
    return out
end

--- Reconstruct a character from serialized data.
---@param data SerializedCharacter
---@return Character
function CharacterManagerImpl:load_character(data)
    -- note: ids may collide if loaded after game is running
    local out = character_generator.deserialize(data, self.game_data)
    return out
end

--- Add a character to the persistent player roster.
---@param c Character
function CharacterManagerImpl:persist_player(c)
    self.characters[c.id] = c
    table.insert(self.player_ids, c.id)
end

--- Return all living characters in the player roster.
---@return Character[]
function CharacterManagerImpl:get_player_roster()
    return fp.pipeline_2(
        lists.map(
            maps.get_at(self.characters)
        ),
        lists.filter(function(c)
            return not c.dead
        end)
    )(self.player_ids)
end

--- Release resources held by the manager.
function CharacterManagerImpl:teardown()
end

local character_manager = {
    CharacterManager = CharacterManager,
}

--- Create a new CharacterManager backed by the given game data.
---@param game_data table GameData containing character templates and item definitions.
---@return CharacterManager
function character_manager.new(game_data)
    ---@type CharacterManagerImpl
    local self = setmetatable({}, { __index = CharacterManagerImpl })

    self.id_generator = id_generator.new()
    self.game_data = game_data
    self.characters = {}
    self.player_ids = {}

    return self
end

return character_manager
