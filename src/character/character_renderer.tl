require("src/debug")

require("src/character")
local ANIMATION_DATA = require("src/character/animation_data")

local BASE_UNIT_SPRITE = 256
local BASE_HEAD_SPRITE = 256 + 64
local BASE_M_HAIR_SPRITE = 256 + 72
local BASE_F_HAIR_SPRITE = 256 + 80
local BASE_BEARD_SPRITE = 256 + 88

local SKIN_COLORS: { { Color, Color } } = {
    {15, 31},
    {31, 4},
    {4, 20},
    {20, 21}
}

local COLOR_SKIN = 29
local COLOR_SKIN_SHADOW = 13
local COLOR_HAIR = 23
local COLOR_BEARD = 22
local COLOR_EYE = 21
local COLOR_EYE_WHITE = 7

local record CharacterRenderer

end

local function get_anchor_offsets(base: DrawPoint, anchor: AnimationAnchorPoint, child: AnimationAnchorPoint, flip_h: boolean, flip_v: boolean): DrawPoint
    local diff_x = anchor.x - child.x
    local diff_y = anchor.y - child.y
    if flip_h then diff_x = -diff_x end
    if flip_v then diff_y = -diff_y end

    return { x = base.x + diff_x, y = base.y + diff_y }
end

local function get_body_type(character: Character): AnimationName
    local base_body_type = character.weapon.body_type

    return ("STANDARD_"..base_body_type) as AnimationName
end

local record RenderedAnimationFrame
	offset: AnimationOffset
	sprite: integer
	anchors: { AnchorPointName: AnimationAnchorPoint }
end

local function get_animation_frame(character: Character): RenderedAnimationFrame
	local frame_name: AnimationFrameName 
	local offset: AnimationOffset
	if character.animation_data ~= nil and character.animation_data.current_frame ~= nil then
		frame_name = character.animation_data.current_frame.frame
		offset = character.animation_data.current_frame.offset
	else
		frame_name = "idle_1"
		offset = {x = 0, y = 0}
	end

    local animation_frame = ANIMATION_DATA[get_body_type(character)][frame_name]

	return {
		offset = offset,
		sprite = BASE_UNIT_SPRITE + animation_frame.sprite,
		anchors = animation_frame.anchors
	}
end

-- @return the position of the "feet_center" anchor
function CharacterRenderer.get_animation_offset(character: Character): AnimationOffset
    local frame_data = get_animation_frame(character)

    return { x = frame_data.offset.x + frame_data.anchors.feet_center.x,
             y = frame_data.offset.y + frame_data.anchors.feet_center.y}
end

local function set_palette(character: Character, side: Side)
    if side == 1 then
        pal(16, 8)
        pal(19, 24)
    end
    local skin = character.appearance.skin
    pal(COLOR_SKIN, SKIN_COLORS[skin][1])
    pal(COLOR_SKIN_SHADOW, SKIN_COLORS[skin][2])
    pal(COLOR_HAIR, character.appearance.hair_color)
    pal(COLOR_BEARD, character.appearance.beard_color)
end

function CharacterRenderer.draw_head(character: Character, point: DrawPoint, side: Side, set_pal: boolean)
    local flip_h = side ~= 0
    local sex_offset = character.appearance.sex == "male" and 0 or 1

    if set_pal then
        set_palette(character, side)
    end

    spr(BASE_HEAD_SPRITE + 4 * sex_offset, point.x, point.y, flip_h)
    if character.appearance.sex == "male" then
        spr(BASE_M_HAIR_SPRITE + character.appearance.hair, point.x, point.y, flip_h)
    else
        spr(BASE_F_HAIR_SPRITE + character.appearance.hair, point.x, point.y, flip_h)
    end
    if character.appearance.beard ~= nil then
        spr(BASE_BEARD_SPRITE + character.appearance.beard, point.x, point.y, flip_h)
    end

end

function CharacterRenderer.draw(character: Character, point: DrawPoint, side: Side, set_pal: boolean, apply_animation: boolean)
    set_pal = set_pal ~= false
    apply_animation = apply_animation ~= false

    -- TODO: consider pre-rendering some of this
    local flip_h = side ~= 0

	local animation_frame = get_animation_frame(character)
    local offset_x, offset_y = animation_frame.offset.x, animation_frame.offset.y
    if not apply_animation then
        offset_x, offset_y = 0, 0
    end

    local base_point = { x = point.x + offset_x, y = point.y + offset_y }
    
    local HEAD_NECK_X = 9
    local HEAD_NECK_Y = 7

    if set_pal then
        set_palette(character, side)
    end
LOG.debug("Drawing", animation_frame.sprite, base_point.x, base_point.y)
    spr(animation_frame.sprite, base_point.x, base_point.y, flip_h)

    local head_anchor = get_anchor_offsets(base_point, animation_frame.anchors.neck, { x = HEAD_NECK_X, y = HEAD_NECK_Y }, flip_h, false)
    CharacterRenderer.draw_head(character, head_anchor, side, set_pal)

    local weapon_anchor = get_anchor_offsets(base_point, animation_frame.anchors.main_hand, character.weapon.hand_anchor, flip_h, false)
    spr(BASE_UNIT_SPRITE + character.weapon.sprite, weapon_anchor.x, weapon_anchor.y, flip_h)

    if set_pal then
        pal()
    end

end

return CharacterRenderer
