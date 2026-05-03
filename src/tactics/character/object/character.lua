---@brief
--- Defines the core data structure for a persistent character.
--- This includes a character's stats, appearance, inventory,
--- and other permanent attributes.

local targeting = require("src.tactics.character.items.object.weapon").targeting
local lists = require("src.tactics.util.lists")

---@alias Side "player"|"enemy"|"neutral"
---@alias CharacterId integer Unique persistent ID of a Character instance.

---@alias CharacterAppearanceKey "head"|"hair"|"skin"|"hair_color"|"body_class"|"beard"|"eyes"|"eyewear"|"headwear"

--- All appearance attributes that define how a character looks.
---@class CharacterAppearance
---@field gender string
---@field head string
---@field hair string
---@field skin string
---@field hair_color string
---@field body_class string
---@field beard string
---@field eyes string
---@field eyewear string
---@field headwear string
local CharacterAppearance = {}

--- Combat and movement statistics for a character.
---@class CharacterStats
---@field hp_max integer Maximum hit points.
---@field movement integer Movement range in tiles per turn.
---@field def integer Defence value subtracted from incoming damage.

--- Serializable snapshot of a character, used for save/load.
---@class SerializedCharacter
---@field id CharacterId
---@field name string
---@field appearance CharacterAppearance
---@field stats CharacterStats
---@field inventory string[] Ordered list of item IDs in the inventory slots.
---@field tags table<string, boolean> Set of string tags (e.g. "player", "enemy").

--- A persistent game character with inventory and derived appearance.
---@class Character
---@field id CharacterId
---@field name string
---@field appearance CharacterAppearance Base appearance before equipment overrides.
---@field stats CharacterStats
---@field inventory ItemInventory
---@field tags table<string, boolean> Set of string tags.
---@field dead boolean? True when the character has been killed.
local Character = {}
Character.__index = Character

--- Return a serializable snapshot of this character.
---@return SerializedCharacter
function Character:serialize()
    return {
        id = self.id,
        name = self.name,
        appearance = self.appearance,
        stats = self.stats,
        inventory = lists.map(function(i) return i.id end)(self.inventory:get_items()),
        tags = self.tags,
    }
end

--- Return the effective appearance after applying any equipped item overrides.
---@return CharacterAppearance
function Character:get_appearance()
    local items = self.inventory:get_equipped_items()

    local overrides = {}

    if items["BODY"] ~= nil and items["BODY"].appearance_overrides ~= nil then
        local item_overrides = items["BODY"].appearance_overrides
        for k, v in pairs(item_overrides) do
            overrides[k] = v
        end
    end

    return setmetatable(overrides, {
        __index = self.appearance
    })
end

--- Return the Targeting of the first equipped weapon, or the bare-hands targeting.
---@return Targeting
function Character:get_weapon_targeting()
    local weapons = self.inventory:get_equipped_weapons()

    if #weapons == 0 then
        return targeting.none
    end

    -- TODO: dual weilding
    return weapons[1].targeting
end

---@alias FacingVertical "up"|"down"

---@alias FacingHorizontal "left"|"right"

--- The direction a character is currently facing, split into vertical and horizontal components.
---@class Facing
---@field vertical FacingVertical
---@field horizontal FacingHorizontal
local Facing = {}
Facing.__index = Facing

--- Update facing to match a cardinal direction.
---@param direction CardinalDirection
function Facing:turn_to(direction)
    if direction == "up" then
        self.vertical = "up"
    elseif direction == "down" then
        self.vertical = "down"
    elseif direction == "left" then
        self.horizontal = "left"
    elseif direction == "right" then
        self.horizontal = "right"
    else
        error("unexpected direction: " .. tostring(direction))
    end
end

--- Update facing to look toward a point relative to the origin.
---@param p Point Target point to face toward.
---@param hard boolean When false, keep current vertical facing when moving horizontally.
function Facing:face_point(p, hard)
    local angle = atan2(p.x, p.y)

    if math.abs(angle) < 0.25 then
        self.horizontal = "right"
    elseif math.abs(angle) > 0.25 then
        self.horizontal = "left"
    end

    if angle > 0 and angle < 0.5 then
        self.vertical = "up"
    elseif angle < 0 and angle > -0.5 then
        self.vertical = "down"
    else
        if hard then self.vertical = "down" end
    end
end

local facing = {}

--- Create a new Facing initialised to the given cardinal direction.
---@param direction CardinalDirection
---@return Facing
function facing.of(direction)
    ---@type Facing
    local self = setmetatable({
        vertical = "down",
        horizontal = "right"
    }, { __index = Facing })
    self:turn_to(direction)
    return self
end

--- Abstract interface for a character instance that can be drawn to the screen.
---@class DrawableCharacterInstance
---@field side Side Which team the character belongs to.
---@field facing Facing Current facing direction.
---@field has_acted boolean True when the character has already acted this turn; affects outline colour.
---@field animation_data AnimatedSpriteData Active animation state.
---@field sprites table<AnimationFrameName, table<FacingVertical, userdata>> Pre-rendered sprites keyed by frame and vertical facing.
---@field character Character The underlying persistent character.

---@class DrawableCharacter : DrawableCharacterInstance

---@param char Character
---@param side Side
---@param facing_dir Facing
---@return DrawableCharacter
local function create_drawable_unit(char, side, facing_dir)
    ---@diagnostic disable-next-line missing-fields
    return {
        character = char,
        side = side,
        facing = facing_dir,
        sprites = {},
    }
end

local character = {
    facing = facing,
    Facing = Facing,
    CharacterAppearance = CharacterAppearance,
    Character = Character,
    create_drawable_unit = create_drawable_unit,
}

return character
