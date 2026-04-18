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
---@class CharacterManager
---@field game_data table GameData used to generate characters.
---@field id_generator IdGenerator Generates unique character IDs.
---@field characters table<CharacterId, Character> All known characters keyed by ID.
---@field player_ids CharacterId[] Ordered list of IDs in the player roster.
local CharacterManager = {}
CharacterManager.__index = CharacterManager

--- Retrieve a character by its unique ID.
---@param id CharacterId
---@return Character?
function CharacterManager:get_character(id)
    return self.characters[id]
end

--- Generate a new character from a template and assign tags.
---@param template_id string? Template ID; nil uses the "default" template.
---@param tags string[] Tags to assign to the generated character.
---@return Character
function CharacterManager:generate_character(template_id, tags)
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
function CharacterManager:load_character(data)
    -- note: ids may collide if loaded after game is running
    local out = character_generator.deserialize(data, self.game_data)
    return out
end

--- Add a character to the persistent player roster.
---@param c Character
function CharacterManager:persist_player(c)
    self.characters[c.id] = c
    table.insert(self.player_ids, c.id)
end

--- Return all living characters in the player roster.
---@return Character[]
function CharacterManager:get_player_roster()
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
function CharacterManager:teardown()
end

local character_manager = {}

--- Create a new CharacterManager backed by the given game data.
---@param game_data table GameData containing character templates and item definitions.
---@return CharacterManager
function character_manager.new(game_data)
    ---@type CharacterManager
    local self = setmetatable({}, { __index = CharacterManager })

    self.id_generator = id_generator.new()
    self.game_data = game_data
    self.characters = {}
    self.player_ids = {}

    return self
end

return character_manager
