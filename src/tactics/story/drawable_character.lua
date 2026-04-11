---@brief
--- Defines a drawable character instance for use in story scenes.

---@class DrawableCharacter : DrawableCharacterInstance
---@field side Side
---@field character Character
local DrawableCharacter = {}
DrawableCharacter.__index = DrawableCharacter

local drawable_character = {
    DrawableCharacter = DrawableCharacter,
}

--- Create a drawable character unit for use in a story scene.
---@param char Character
---@param side Side
---@param facing Facing
---@return DrawableCharacter
function drawable_character.create_drawable_unit(char, side, facing)
    ---@type DrawableCharacter
    local instance = setmetatable({
        character = char,
        side = side,
        facing = facing,
        sprites = {},
    }, DrawableCharacter)

    return instance
end

return drawable_character
