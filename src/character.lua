include "src/util.lua"
include "src/character/animation_data.lua"
include "src/character/weapons.lua"

local id_counter = IdCounter.new()
local characters = {}

local CharacterManager = {}



local COLOR_SKIN = 29
local COLOR_SKIN_SHADOW = 13
local COLOR_HAIR = 23
local COLOR_BEARD = 22
local COLOR_EYE = 21
local COLOR_EYE_WHITE = 7

local HAIR_COLORS = {
    4, 5, 6, 9, 10, 20, 21, 22, 24, 25, 31
}
local SKIN_COLORS = {
    {15, 31},
    {31, 4},
    {4, 20},
    {20, 21}
}

local BASE_UNIT_SPRITE = 256
local BASE_HEAD_SPRITE = 256 + 64
local BASE_M_HAIR_SPRITE = 256 + 72
local BASE_F_HAIR_SPRITE = 256 + 80
local BASE_BEARD_SPRITE = 256 + 88

Character = {}

function Character:start_animation(animation_id, direction)
    self.animation_data = ANIMATION_MANAGER.create_animation(animation_id, direction)
    self.animation_blocking = true
end

function Character:start_walk_animation(target_x, target_y)
    self.animation_data = ANIMATION_MANAGER.create_walk_animation(target_x, target_y)
    self.animation_blocking = true
end

function Character:end_animation()
    self.animation_data = ANIMATION_MANAGER.create_animation("IDLE", 0)
    self.animation_blocking = false
end

function Character:update_animation()
    if self.animation_data == nil then return end
    self.animation_data:update()
    self.animation_blocking = self.animation_data.id ~= "IDLE" and self.animation_data.playing
end

function get_anchor_offsets(base_x, base_y, anchor_x, anchor_y, limb_x, limb_y, flip_h, flip_v)
    local diff_x = anchor_x - limb_x
    local diff_y = anchor_y - limb_y
    if flip_h then diff_x = -diff_x end
    if flip_v then diff_y = -diff_y end

    return base_x + diff_x, base_y + diff_y
end

function Character:get_body_type()
    local base_body_type = self.weapon.body_type

    return "STANDARD_"..base_body_type
end

function Character:draw(x, y, side, set_pal)
    if self.animation_data == nil then
        -- this could go somewhere else...
        self.animation_data = ANIMATION_MANAGER.create_animation("IDLE", 0)
    end

    -- TODO: consider pre-rendering some of this
    local flip_h = side ~= 0
    local sex = self.appearance.sex

    local frame_data = self.animation_data:get_frame_data()
    local base_x = x + frame_data.x
    local base_y = y + frame_data.y
    --local body_sprite_data = ANIMATION_DATA["STANDARD_BACK_HAND"][frame_data.sprite_id]
    printh(self.weapon.body_type)
    local body_sprite_data = ANIMATION_DATA[self:get_body_type()][frame_data.sprite_id]

    local body_main_hand_x = body_sprite_data.anchors.main_hand.x
    local body_main_hand_y = body_sprite_data.anchors.main_hand.y
    local weapon_main_hand_x = self.weapon.hand_anchor.x
    local weapon_main_hand_y = self.weapon.hand_anchor.y

    local body_neck_x = body_sprite_data.anchors.neck.x
    local body_neck_y = body_sprite_data.anchors.neck.y
    local HEAD_NECK_X = 9
    local HEAD_NECK_Y = 7

    if set_pal then
        if side == 1 then
            pal(16, 8)
            pal(19, 24)
        end
        local skin = self.appearance.skin
        pal(COLOR_SKIN, SKIN_COLORS[skin][1])
        pal(COLOR_SKIN_SHADOW, SKIN_COLORS[skin][2])
        pal(COLOR_HAIR, self.appearance.hair_color)
        pal(COLOR_BEARD, self.appearance.beard_color)
    end

    spr(BASE_UNIT_SPRITE + body_sprite_data.sprite, base_x, base_y, flip_h)

    local head_x, head_y = get_anchor_offsets(base_x, base_y, body_neck_x, body_neck_y, HEAD_NECK_X, HEAD_NECK_Y, flip_h)
    spr(BASE_HEAD_SPRITE + 4 * sex, head_x, head_y, flip_h)
    if sex == 0 then
        spr(BASE_M_HAIR_SPRITE + self.appearance.hair, head_x, head_y, flip_h)
    else
        spr(BASE_F_HAIR_SPRITE + self.appearance.hair, head_x, head_y, flip_h)
    end
    if self.appearance.beard ~= nil then
        spr(BASE_BEARD_SPRITE + self.appearance.beard, head_x, head_y, flip_h)
    end

    local weapon_x, weapon_y = get_anchor_offsets(base_x, base_y, body_main_hand_x, body_main_hand_y, weapon_main_hand_x, weapon_main_hand_y, flip_h)
    spr(BASE_UNIT_SPRITE + self.weapon.sprite, weapon_x, weapon_y, flip_h)

    if set_pal then
        pal()
    end

end

function generate_appearance()
    local appearance = {}

    appearance.sex = rndi(2)
    appearance.hair = rndi(6)
    appearance.skin = rndi(#SKIN_COLORS)+1
    while appearance.hair_color == nil
            or appearance.hair_color == SKIN_COLORS[appearance.skin][1]
    do
        appearance.hair_color = choose_random_from_list(HAIR_COLORS)
    end

    if appearance.sex == 0 then -- male
        appearance.body = rndi(4)
        appearance.beard = rndi(7)
        if rnd(6) <= 1 then
            appearance.beard_color = choose_random_from_list(HAIR_COLORS)
        else
            appearance.beard_color = appearance.hair_color
        end
    else -- female
        appearance.body = rndi(4)
    end

    return appearance
end

function CharacterManager.generate_character()
    local character = {
        id = id_counter:get_id(),
        appearance = generate_appearance(),
        s = 264,
        stats = {
            hp_max = 5,
            damage = 5,
            min_range = 2,
            max_range = 3,
            movement = 6,
            def = 1
        },
        weapon = choose_random_from_table(WEAPON_DATA)
    }

    setmetatable(character, { __index = Character })

    characters[character.id] = character

    return character
end


return CharacterManager