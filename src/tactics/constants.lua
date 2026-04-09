---@brief
--- Game-wide constants.

---@class Highlight
---@field IS_REACHABLE integer Tile is within the active unit's movement range.
---@field IS_VALID integer Tile is a valid selection target.
---@field CAN_ATTACK integer Tile contains an attackable unit.
---@field IS_MARKED integer Tile has been explicitly marked.
---@field IS_INTERACTION integer Tile contains an interactable object.

---@type Highlight
local HIGHLIGHT = {
    IS_REACHABLE   = 0x1,
    IS_VALID       = 0x2,
    CAN_ATTACK     = 0x4,
    IS_MARKED      = 0x8,
    IS_INTERACTION = 0x10,
}

---@class Constants
---@field HIGHLIGHT Highlight Bitmask constants used to tag tile highlights on the battle map.

---@type Constants
local CONSTANTS = {
    HIGHLIGHT = HIGHLIGHT,
}

return CONSTANTS
