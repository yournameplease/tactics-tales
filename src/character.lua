include "util.lua"
include "animation.lua"

local id_counter = IdCounter.new()
local characters = {}

local CharacterManager = {}



local COLOR_SKIN = 4
local COLOR_SKIN_SHADOW = 20
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

local BASE_HEAD_SPRITE = 256 + 64
local BASE_M_HAIR_SPRITE = 256 + 72
local BASE_F_HAIR_SPRITE = 256 + 80
local BASE_BEARD_SPRITE = 256 + 88
local BASE_BODY_SPRITE = 256 + 96
local BASE_WEAPON_SPRITE = 256 + 104

Character = {}

function Character:start_animation(animation_id, direction)
    self.animation_data = create_animation(animation_id, direction)
    self.animation_playing = true
end

function Character:start_walk_animation(target_x, target_y)
    self.animation_data = create_walk_animation(target_x, target_y)
    self.animation_playing = true
end

function Character:end_animation()
    self.animation_data = nil
    self.animation_playing = false
end

function Character:update_animation()
    if self.animation_data == nil then return end
    update_animation(self.animation_data)
    self.animation_playing = self.animation_data.playing
end

function Character:draw(x, y, side, set_pal)
    -- TODO: consider pre-rendering some of this
    local flip_h = side ~= 0
    local sex = self.appearance.sex

    local o_x, o_y = get_x_y_from_animation(self.animation_data)
    x = x + o_x
    y = y + o_y

    spr(BASE_WEAPON_SPRITE, x, y, flip_h)

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
    spr(BASE_BODY_SPRITE + 4 * sex + self.appearance.body, x, y, flip_h)
    spr(BASE_HEAD_SPRITE + 4 * sex, x, y, flip_h)
    if sex == 0 then
        spr(BASE_M_HAIR_SPRITE + self.appearance.hair, x, y, flip_h)
    else
        spr(BASE_F_HAIR_SPRITE + self.appearance.hair, x, y, flip_h)
    end
    if self.appearance.beard ~= nil then
        spr(BASE_BEARD_SPRITE + self.appearance.beard, x, y, flip_h)
    end
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
        appearance.body = flr(rnd(6)/5)
        appearance.beard = rndi(6)
        if rnd(6) <= 1 then
            appearance.beard_color = choose_random_from_list(HAIR_COLORS)
        else
            appearance.beard_color = appearance.hair_color
        end
    else -- female
        appearance.body = rndi(2)
    end

    return appearance
end

function CharacterManager.generate_character()
    local character = {
        id = id_counter:get_id(),
        appearance = generate_appearance(),
        s = 264,
        stats = {
            hp_max = 10,
            damage = 5,
            min_range = 2,
            max_range = 3,
            movement = 6,
            def = 1
        },
        weapon = {
            damage = 5,
            accuracy = 70
        }
    }

    setmetatable(character, { __index = Character })

    characters[character.id] = character

    return character
end


return CharacterManager