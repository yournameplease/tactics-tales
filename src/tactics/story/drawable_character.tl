local character = require("src/tactics/character/object/character")

local record DrawableCharacter
    is character.DrawableCharacterInstance

    side: character.Side
    
    character: character.Character
end

local drawable_character = {
    DrawableCharacter = DrawableCharacter
}

function drawable_character.create_drawable_unit(
    char: character.Character,
    side: character.Side,
    facing: character.Facing
): DrawableCharacter
    local instance: DrawableCharacter = {
        character = char,
        side = side,
        facing = facing,
        sprites = {},
    }

    setmetatable(instance, { __index = DrawableCharacter })

    return instance
end

return drawable_character


