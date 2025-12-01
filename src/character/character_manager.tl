require("src/debug")
require("src/util")
require("src/character/animation_data")
require("src/character/weapons")
require("src/animation")
require("src/character/object/character")
local CharacterGenerator = require("src/character/character_generator")

-- Eventually, may want to differentiate between persistent
-- and transient characters.  No real reason now though.
global record CharacterManager
    id_counter: IdCounter
    characters: { Character }
end

function CharacterManager.new(): CharacterManager
    local self: CharacterManager = setmetatable({}, { __index = CharacterManager})
    self.id_counter = IdCounter.new()
    self.characters = {}
    return self
end

function CharacterManager:generate_character(template_id: string): Character
    local character: Character = CharacterGenerator.generate_from_template(
        self.id_counter:get_id(),
        template_id
    )

    self.characters[character.id] = character

    return character
end


return CharacterManager
