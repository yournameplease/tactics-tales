---@brief
--- Game-wide constants.

---@class Highlight
---@field IS_REACHABLE integer Tile is within the active unit's movement range.
---@field IS_VALID integer Tile is a valid selection target.
---@field CAN_ATTACK integer Tile contains an attackable unit.
---@field IS_MARKED integer Tile has been explicitly marked.
---@field IS_INTERACTION integer Tile contains an interactable object.
---@field IS_INTERACTION_DESTINATION integer Tile is a reachable destination from which an attack or script interaction is available.

---@type Highlight
local HIGHLIGHT = {
    IS_REACHABLE               = 0x01,
    IS_VALID                   = 0x02,
    CAN_ATTACK                 = 0x04,
    IS_MARKED                  = 0x08,
    IS_INTERACTION             = 0x10,
    IS_INTERACTION_DESTINATION = 0x20,
}

---@class Constants
---@field HIGHLIGHT Highlight Bitmask constants used to tag tile highlights on the battle map.

---@type Constants
local CONSTANTS = {
    HIGHLIGHT = HIGHLIGHT,
}

return CONSTANTS
