require("src/character")


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

local function get_body_type()
    -- local base_body_type = self.weapon.body_type

    -- return "STANDARD_"..base_body_type
end

-- @return the position of the "feet_center" anchor
function CharacterRenderer.get_animation_offset(character: Character): AnimationOffset
    return { x = 0, y = 0}
    -- local frame_data = self.animation_data:get_frame_data()

    -- local body_sprite_data = ANIMATION_DATA[self:get_body_type()][frame_data.sprite_id]

    -- return frame_data.x + body_sprite_data.anchors.feet_center.x,
    --         frame_data.y + body_sprite_data.anchors.feet_center.y
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

    local frame_data: AnimationFrameData = {
        frame = {
            sprite_offset = 160,
            anchors = {
                neck = { x = 9, y = 7 },
                main_hand = { x = 1, y = 8 },
                off_hand = { x = 14, y = 12 },
                feet_center = { x = 7, y = 15 }
            }
        },
        offset = {x = 0, y = 0}
    } -- TODO: have this updated in the background by animation_manager
    local offset_x, offset_y = frame_data.offset.x, frame_data.offset.y
    if not apply_animation then
        offset_x, offset_y = 0, 0
    end

    local base_point = { x = point.x + offset_x, y = point.y + offset_y }
    
    local HEAD_NECK_X = 9
    local HEAD_NECK_Y = 7

    if set_pal then
        set_palette(character, side)
    end

    spr(BASE_UNIT_SPRITE + frame_data.frame.sprite_offset, base_point.x, base_point.y, flip_h)

    local head_anchor = get_anchor_offsets(base_point, frame_data.frame.anchors.neck, { x = HEAD_NECK_X, y = HEAD_NECK_Y }, flip_h, false)
    CharacterRenderer.draw_head(character, head_anchor, side, set_pal)

    local weapon_anchor = get_anchor_offsets(base_point, frame_data.frame.anchors.main_hand, character.weapon.hand_anchor, flip_h, false)
    spr(BASE_UNIT_SPRITE + character.weapon.sprite, weapon_anchor.x, weapon_anchor.y, flip_h)

    if set_pal then
        pal()
    end

end

return CharacterRenderer
