---@brief
--- Defines the core data structure for a persistent character.
--- This includes a character's stats, appearance, inventory,
--- and other permanent attributes.

require("src.tactics.character.items.object.weapon")
require("src.tactics.character.animation_data")
local animation = require("src.tactics.animation")
local ItemInventory = require("src.tactics.character.items.object.item_inventory")
local targeting = require("src.tactics.character.items.object.weapon").targeting
local Targeting = targeting.Targeting
local maps = require("src.tactics.util.maps")
local Point = require("src.tactics.util.point").Point

local enum Side
    "player"
    "enemy"
    "neutral"
end

local enum CharacterAppearanceKey
	"head"
	"hair"
	"skin"
	"hair_color"
	"body_class"
	"beard"
	"eyes"
	"eyewear"
	"headwear"
end

local record CharacterAppearance
    gender: string
	head: string
    hair: string
    skin: string
    hair_color: string
    body_class: string
    beard: string
    eyes: string
	eyewear: string
	headwear: string
end

local record CharacterStats
    hp_max: integer
    movement: integer
    def: integer
end

local record Character
    id: integer
    name: string
    appearance: CharacterAppearance
    stats: CharacterStats
	inventory: ItemInventory.ItemInventory
    tags: maps.Set<string>
	
	-- may be overridden by inventory
	get_appearance: function(self): CharacterAppearance
	
	get_weapon_targeting: function(self): Targeting
end

function Character:get_appearance(): CharacterAppearance
	local items = self.inventory:get_equipped_items()

	local overrides: {string: string}  = {}

	if items["BODY"] ~= nil and items["BODY"].appearance_overrides ~= nil then
		local item_overrides = items["BODY"].appearance_overrides as CharacterAppearance
		for k,v in pairs(item_overrides as {string: string}) do
			overrides[k] = v
		end
	end

	return setmetatable(overrides as CharacterAppearance, {
		__index = self.appearance
	})
end

function Character:get_weapon_targeting(): Targeting
	local weapons = self.inventory:get_equipped_weapons()

	if #weapons == 0 then
		return targeting.none
	end

	-- TODO: dual weilding
	return weapons[1].targeting 
end

local enum FacingVertical
	"up"
	"down"
end

local enum FacingHorizontal
	"left"
	"right"
end

local record Facing
	vertical: FacingVertical
	horizontal : FacingHorizontal
end

local facing = {}

function Facing:turn_to(direction: CardinalDirection)
	if direction == "up" then
		self.vertical = "up"
	elseif direction == "down" then
		self.vertical = "down"
	elseif direction == "left" then
		self.horizontal = "left"
	elseif direction == "right" then
		self.horizontal = "right"
	else
		unexpected(direction)
	end
end

---@param hard -- if false, keep looking up if moving horizontally
function Facing:face_point(p: Point, hard: boolean)
    local angle = pt.atan2(p.x, p.y)

    if pt.absf(angle) < 0.25 then
        self.horizontal = "right"
    elseif pt.absf(angle) > 0.25 then
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

function facing.of(direction: CardinalDirection): Facing
	local self: Facing = setmetatable({
		vertical = "down",
		horizontal = "right"
	}, { __index = Facing })
	self:turn_to(direction) 
	return self
end

local interface DrawableCharacterInstance
	side: Side
	facing: Facing
	has_acted: boolean -- used for outline color...

	animation_data: animation.AnimatedSpriteData
    -- prerendered sprites by animation frame name
    sprites: { AnimationFrameName: { FacingVertical: Userdata} }

	character: Character
end

local character = {
	facing = facing,
	Side = Side,
	Facing = Facing,
	CharacterAppearanceKey = CharacterAppearanceKey,
	CharacterAppearance = CharacterAppearance,
	CharacterStats = CharacterStats,
	Character = Character,
	DrawableCharacterInstance = DrawableCharacterInstance,
}

return character
