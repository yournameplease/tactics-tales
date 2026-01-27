local id_generator = require("src/tactics/util/id_generator")
local GameData = require("src/tactics/game_data").GameData
local Character = require("src/tactics/character/object/character").Character
local character_generator = require("src/tactics/character/character_generator")
local lists = require("src/tactics/util/lists")
local maps = require("src/tactics/util/maps")

-- Eventually, may want to differentiate between persistent
-- and transient characters.  No real reason now though.
local interface CharacterManager
    get_character: function(self, id: integer): Character
    generate_character: function(self, template_id: string, tags: {string}): Character
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
    local character: Character = character_generator.generate_from_template(
        self.id_generator:get_id(),
        template_id,
        tags,
        self.game_data
    )

    return character
end

function CharacterManagerImpl:persist_player(character: Character)
    self.characters[character.id] = character
    pt.add(self.player_ids, character.id)
end

function CharacterManagerImpl:get_player_roster(): { Character }
    return lists.map(
        maps.get_at(self.characters)
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
