

require("src/tactics/debug")
require("src/tactics/character/animation_data")
require("src/tactics/animation")
require("src/tactics/types")
require("src/tactics/character/object/character")
require("src/tactics/character/items/object/weapon")
local unit_ai = require("src/tactics/battle/unit/unit_ai")
local maps = require("src/tactics/util/maps")

global record DrawableCharacter
    is DrawableCharacterInstance

    side: Side
    
    character: Character
end

local drawable_character = {
    DrawableCharacter = DrawableCharacter
}

function drawable_character.create_drawable_unit(character: Character, side: Side): DrawableCharacter
    local instance: DrawableCharacter = {
        character = character,
        side = side,
        sprites = {},
    }

    setmetatable(instance, { __index = DrawableCharacter })

    return instance
end

return drawable_character


