---@brief
--- Manages the lifecycle and storage of all character instances.
--- It holds the player roster and is responsible for generating new
--- characters for battles.

local id_generator = require("src.tactics.util.id_generator")
local GameData = require("src.tactics.game_data").GameData
local character = require("src.tactics.character.object.character")
local Character = character.Character
local character_generator = require("src.tactics.character.character_generator")
local fp = require("src.tactics.util.fp")
local lists = require("src.tactics.util.lists")
local maps = require("src.tactics.util.maps")

-- Eventually, may want to differentiate between persistent
-- and transient characters.  No real reason now though.
local interface CharacterManager
    id_generator: id_generator.IdGenerator

    get_character: function(self, id: integer): Character
    generate_character: function(self, template_id: string, tags: {string}): Character
    load_character: function(self, data: character.SerializedCharacter): Character
    persist_player: function(self, character: Character)
    get_player_roster: function(self): { Character }
    teardown: function(self) 
end

local character_manager = {
    CharacterManager = CharacterManager
}

local record CharacterManagerImpl
    is CharacterManager

    game_data: GameData
    
    id_generator: id_generator.IdGenerator
    characters: { integer: Character }

    player_ids: { integer }
end
    
function CharacterManagerImpl:get_character(id: integer): Character
    return self.characters[id]
end

function CharacterManagerImpl:generate_character(
    template_id: string,
    tags: {string}
): Character
    local out: Character = character_generator.generate_from_template(
        self.id_generator:get_id(),
        template_id,
        tags,
        self.game_data
    )

    return out
end

function CharacterManagerImpl:load_character(
    data: character.SerializedCharacter
): Character
    -- note: ids may collide if loaded after game is running
    local out: Character = character_generator.deserialize(data, self.game_data)

    return out
end

function CharacterManagerImpl:persist_player(c: Character)
    self.characters[c.id] = c
    pt.add(self.player_ids, c.id)
end

function CharacterManagerImpl:get_player_roster(): { Character }
    return fp.pipeline_2(
        lists.map(
            maps.get_at(self.characters)
        ),
        lists.filter(function(c: Character): boolean
            return not c.dead
        end)
    )(self.player_ids)
end

-- event handlers

function character_manager.new(
    game_data: GameData
): CharacterManager
    local self: CharacterManagerImpl = setmetatable({
    }, { __index = CharacterManagerImpl})

    self.id_generator = id_generator.new()
    self.game_data = game_data
    self.characters = {}
    self.player_ids = {}

    return self
end

function CharacterManagerImpl:teardown()
end

return character_manager
