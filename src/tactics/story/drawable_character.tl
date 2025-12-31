require("src/tactics/character/object/character")

local record DrawableCharacter
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


