require("src/debug")
require("src/types")

require("src/battle/tactics/battle_unit")
require("src/character/character_manager")
require("src/character/object/character")
require("src/character/sprite_data")

local ANIMATION_DATA = require("src/character/animation_data")

local BASE_UNIT_SPRITE = 256

local COLOR_SKIN = 29
local COLOR_SKIN_SHADOW = 13
local COLOR_HAIR = 23
local COLOR_BEARD = 22
local _COLOR_EYE = 21
local _COLOR_EYE_WHITE = 7

local record CharacterRenderer

end

local function get_anchor_offsets(base: DrawPoint, anchor: AnimationAnchorPoint, child: AnimationAnchorPoint, flip_h: boolean, flip_v: boolean): DrawPoint
    local diff_x = anchor.x - child.x
    local diff_y = anchor.y - child.y
    if flip_h then diff_x = -diff_x end
    if flip_v then diff_y = -diff_y end

    return { x = base.x + diff_x, y = base.y + diff_y }
end

local function get_body_type(battle_unit: BattleUnit): AnimationName
    -- local base_body_type = battle_unit.character.weapon.body_type
    local base_body_type = "BACK_HAND"
	local body_class = battle_unit.character.appearance.body_class
	if battle_unit.character.appearance.sex == "female" and body_class == "SHIRTLESS" then
		body_class = "SLEEVELESS"
	end

	-- TODO: type safety
    return (body_class.."_"..base_body_type) as AnimationName
end

local record RenderedAnimationFrame
	offset: AnimationOffset
	sprite: integer
	anchors: { AnchorPointName: AnimationAnchorPoint }
end

local function get_animation_frame(battle_unit: BattleUnit): RenderedAnimationFrame
	local frame_name: AnimationFrameName 
	local offset: AnimationOffset
	if battle_unit.animation_data ~= nil and battle_unit.animation_data.current_frame ~= nil then
		frame_name = battle_unit.animation_data.current_frame.frame
		offset = battle_unit.animation_data.current_frame.offset
	else
		LOG.debug("Unrecognized animation frame.")
		frame_name = "idle_1"
		offset = {x = 0, y = 0}
	end

    local animation_frame = ANIMATION_DATA[get_body_type(battle_unit)][frame_name]

	return {
		offset = offset,
		sprite = BASE_UNIT_SPRITE + animation_frame.sprite,
		anchors = animation_frame.anchors
	}
end

-- @return the position of the "feet_center" anchor
function CharacterRenderer.get_animation_offset(battle_unit: BattleUnit): AnimationOffset
    local frame_data = get_animation_frame(battle_unit)

    return { x = frame_data.offset.x + frame_data.anchors.feet_center.x,
             y = frame_data.offset.y + frame_data.anchors.feet_center.y}
end

local function set_palette(battle_unit: BattleUnit, side: Side)
    if side == 1 then
        pt.set_pal(16, 8)
        pt.set_pal(19, 24)
    end
    local skin = battle_unit.character.appearance.skin
    pt.set_pal(COLOR_SKIN, SKIN_COLORS[skin][1])
    pt.set_pal(COLOR_SKIN_SHADOW, SKIN_COLORS[skin][2])
    pt.set_pal(COLOR_HAIR, battle_unit.character.appearance.hair_color)
    pt.set_pal(COLOR_BEARD, battle_unit.character.appearance.hair_color)
end

function CharacterRenderer.draw_head(battle_unit: BattleUnit, point: DrawPoint, side: Side, set_pal: boolean)
    local flip_h = side ~= 0

    if set_pal then
        set_palette(battle_unit, side)
    end

	local headwear: HeadwearSpriteData = nil
	if battle_unit.character.appearance.headwear then
		headwear = HEADWEAR_SPRITE_DATA[battle_unit.character.appearance.headwear]	
	end

    pt.spr(BASE_UNIT_SPRITE + battle_unit.character.appearance.head, point.x, point.y, flip_h)
	-- Eye sprite currently is just the default.
	if headwear == nil or headwear.draw_beard then
	    if battle_unit.character.appearance.beard ~= nil then
	        pt.spr(BASE_UNIT_SPRITE + battle_unit.character.appearance.beard, point.x, point.y, flip_h)
	    end
	end
	if headwear == nil or headwear.draw_eyewear then
	    pt.spr(BASE_UNIT_SPRITE + battle_unit.character.appearance.eyes, point.x, point.y, flip_h)
		if battle_unit.character.appearance.eyewear ~= nil then
	        pt.spr(BASE_UNIT_SPRITE + battle_unit.character.appearance.eyewear, point.x, point.y, flip_h)
		end
	end
	if headwear == nil or headwear.draw_hair then
        pt.spr(BASE_UNIT_SPRITE + battle_unit.character.appearance.hair, point.x, point.y, flip_h)
	end
	if headwear ~= nil then
        pt.spr(BASE_UNIT_SPRITE + headwear.sprite, point.x, point.y, flip_h)
	end

end

function CharacterRenderer.draw(battle_unit: BattleUnit, point: DrawPoint, side: Side, set_pal: boolean, apply_animation: boolean)
    -- TODO: consider pre-rendering some of this
    local flip_h = side ~= 0

	local animation_frame = get_animation_frame(battle_unit)

	local offset = animation_frame.offset
	if not apply_animation then
		offset = AnimationOffset.of(0,0)
	end
	
    local base_point = get_anchor_offsets(
		point + offset,
		AnimationAnchorPoint.of(0, 0),
		animation_frame.anchors.feet_center,
		-- flip_h,
		false,
		false
	)
    
    local HEAD_NECK_X = 9
    local HEAD_NECK_Y = 7

    if set_pal then
        set_palette(battle_unit, side)
    end

    pt.spr(animation_frame.sprite, base_point.x, base_point.y, flip_h)

    local head_anchor = get_anchor_offsets(base_point, animation_frame.anchors.neck, { x = HEAD_NECK_X, y = HEAD_NECK_Y }, flip_h, false)
    CharacterRenderer.draw_head(battle_unit, head_anchor, side, set_pal)

	local equipment = battle_unit.character.inventory:get_equipped_items()
	for slot,equip in pairs(equipment) do
		if slot == "BODY" then

		else
			if equip:get_sprite_data() ~= nil then
				local anchor: AnchorPointName = slot == "OFF_HAND" and "off_hand" or "main_hand"
			    local equip_anchor = get_anchor_offsets(base_point, animation_frame.anchors[anchor], equip:get_sprite_data().anchor, flip_h, false)
			    pt.spr(BASE_UNIT_SPRITE + equip:get_sprite_data().sprite, equip_anchor.x, equip_anchor.y, flip_h)
			end
		end
	end

    if set_pal then
        pt.reset_pal()
    end

end

return CharacterRenderer
