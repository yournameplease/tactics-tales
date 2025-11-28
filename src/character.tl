require("src/util")
local ANIMATION_DATA = require("src/character/animation_data")
local WEAPON_DATA = require("src/character/weapons")

local id_counter = IdCounter.new()
local characters = {}

local CharacterManager = {}

global enum Sex
    "male"
    "female"
end 

global record CharacterAppearance
    sex: Sex
    hair: integer
    skin: integer
    hair_color: Color
    body: integer
    beard: integer
    beard_color: Color
end

global record CharacterStats
    hp_max: integer
    movement: integer
    def: integer
end

global record Character
    id: integer
    name: string
    appearance: CharacterAppearance
    stats: CharacterStats
    weapon: Weapon
end

local COLOR_SKIN = 29
local COLOR_SKIN_SHADOW = 13
local COLOR_HAIR = 23
local COLOR_BEARD = 22
local COLOR_EYE = 21
local COLOR_EYE_WHITE = 7

local HAIR_COLORS: { Color } = {
    4, 5, 6, 9, 10, 20, 21, 22, 24, 25, 31
}
local SKIN_COLORS: { { Color, Color } } = {
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


function Character:start_animation(animation_id: integer, direction: Angle)
    self.animation_data = ANIMATION_MANAGER.create_animation(animation_id, direction)
    self.animation_blocking = true
end

function Character:start_walk_animation(path)
    self.animation_data = ANIMATION_MANAGER.create_walk_animation(to_tile_path(path))
    self.animation_blocking = true
end

function Character:end_animation()
    self.animation_data = ANIMATION_MANAGER.create_global_animation("IDLE")
    self.animation_blocking = false
end

function Character:update_animation()
    if self.animation_data == nil then return end
    self.animation_data:update()
    if not self.animation_data.playing then
        self:end_animation()
    end
    self.animation_blocking = self.animation_data.id ~= "IDLE" and self.animation_data.playing
end

local function get_anchor_offsets(base: DrawPoint, anchor: AnimationAnchorPoint, child: AnimationAnchorPoint, flip_h: boolean, flip_v: boolean): AnimationOffset
    local diff_x = anchor.x - child.x
    local diff_y = anchor.y - child.y
    if flip_h then diff_x = -diff_x end
    if flip_v then diff_y = -diff_y end

    return { x = base.x + diff_x, y = base.y + diff_y }
end

function Character:get_body_type()
    local base_body_type = self.weapon.body_type

    return "STANDARD_"..base_body_type
end

-- @return the position of the "feet_center" anchor
function Character:get_animation_offset(): AnimationOffset
    if self.animation_data == nil then
        -- this could go somewhere else...
        self.animation_data = ANIMATION_MANAGER.create_global_animation("IDLE")
    end

    local frame_data = self.animation_data:get_frame_data()

    local body_sprite_data = ANIMATION_DATA[self:get_body_type()][frame_data.sprite_id]

    return frame_data.x + body_sprite_data.anchors.feet_center.x,
            frame_data.y + body_sprite_data.anchors.feet_center.y
end

function Character:set_pal(side: Side)
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

function Character:draw_head(point: DrawPoint, side: Side, set_pal: boolean)
    local flip_h = side ~= 0
    local sex = self.appearance.sex

    if set_pal then
        self:set_pal(side)
    end

    spr(BASE_HEAD_SPRITE + 4 * sex, x, y, flip_h)
    if sex == 0 then
        spr(BASE_M_HAIR_SPRITE + self.appearance.hair, x, y, flip_h)
    else
        spr(BASE_F_HAIR_SPRITE + self.appearance.hair, x, y, flip_h)
    end
    if self.appearance.beard ~= nil then
        spr(BASE_BEARD_SPRITE + self.appearance.beard, x, y, flip_h)
    end

end

function Character:draw(point: DrawPoint, side: Side, set_pal: boolean, apply_animation: boolean)
    set_pal = set_pal ~= false
    apply_animation = apply_animation ~= false

    if self.animation_data == nil then
        -- this could go somewhere else...
        self.animation_data = ANIMATION_MANAGER.create_global_animation("IDLE")
    end

    -- TODO: consider pre-rendering some of this
    local flip_h = side ~= 0
    local sex = self.appearance.sex

    local frame_data = self.animation_data:get_frame_data()
    local offset_x, offset_y = frame_data.x, frame_data.y
    if not apply_animation then
        offset_x, offset_y = 0, 0
    end

    local base_x = x + offset_x
    local base_y = y + offset_y
    --local body_sprite_data = ANIMATION_DATA["STANDARD_BACK_HAND"][frame_data.sprite_id]
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
        self:set_pal(side)
    end

    spr(BASE_UNIT_SPRITE + body_sprite_data.sprite, base_x, base_y, flip_h)

    local head_anchor = get_anchor_offsets(base_x, base_y, body_neck_x, body_neck_y, HEAD_NECK_X, HEAD_NECK_Y, flip_h, false)
    self:draw_head(head_anchor, side, set_pal)

    local weapon_anchor = get_anchor_offsets(base_x, base_y, body_main_hand_x, body_main_hand_y, weapon_main_hand_x, weapon_main_hand_y, flip_h, false)
    spr(BASE_UNIT_SPRITE + self.weapon.sprite, weapon_anchor, flip_h)

    if set_pal then
        pal()
    end

end

local function generate_appearance(): CharacterAppearance
    local appearance: CharacterAppearance = {}

    appearance.sex = choose_random_from_list({"male", "female"})
    appearance.hair = rndi(6)
    appearance.skin = rndi(#SKIN_COLORS)+1
    while appearance.hair_color == nil
            or appearance.hair_color == SKIN_COLORS[appearance.skin][1]
    do
        appearance.hair_color = choose_random_from_list(HAIR_COLORS)
    end

    if appearance.sex == "male" then 
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

function CharacterManager.generate_character(): Character
    local character: Character = {
        id = id_counter:get_id(),
        appearance = generate_appearance(),
        stats = {
            hp_max = 5,
            movement = 5,
            def = 0
        },
        weapon = choose_random_from_table(WEAPON_DATA)
    }
    character.name = character.appearance.sex == "male" and "Bob" or "Alice",

    setmetatable(character, { __index = Character })

    characters[character.id] = character

    return character
end


return CharacterManager
