require("src/util")
require("src/character/animation_data")
require("src/character/weapons")
require("src/animation")

-- TODO: break "drawing" functionality into a CharacterRenderer

global record CharacterManager
    id_counter: IdCounter
    characters: { Character }
end

function CharacterManager.new(): CharacterManager
    local self: CharacterManager = setmetatable({}, { __index = CharacterManager})
    self.id_counter = IdCounter.new()
    self.characters = {}
    return self
end

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
    animation_data: AnimationInstance
    animation_blocking: boolean
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
    -- self.animation_data = animation_manager:create_animation(animation_id, direction)
    -- self.animation_blocking = true
end

function Character:start_walk_animation(path: { TilePoint })
    -- self.animation_data = animation_manager:create_walk_animation(to_tile_path(path))
    -- self.animation_blocking = true
end

function Character:end_animation()
    -- self.animation_data = animation_manager:create_idle_animation("IDLE")
    -- self.animation_blocking = false
end

function Character:update_animation()
    -- if self.animation_data == nil then return end
    -- self.animation_data:update()
    -- if not self.animation_data.playing then
    --     self:end_animation()
    -- end
    -- -- todo: this isn't ideal
    -- self.animation_blocking = not (self.animation_data is GlobalAnimationInstance)
end

local function get_anchor_offsets(base: DrawPoint, anchor: AnimationAnchorPoint, child: AnimationAnchorPoint, flip_h: boolean, flip_v: boolean): DrawPoint
    local diff_x = anchor.x - child.x
    local diff_y = anchor.y - child.y
    if flip_h then diff_x = -diff_x end
    if flip_v then diff_y = -diff_y end

    return { x = base.x + diff_x, y = base.y + diff_y }
end

function Character:get_body_type()
    -- local base_body_type = self.weapon.body_type

    -- return "STANDARD_"..base_body_type
end

-- @return the position of the "feet_center" anchor
function Character:get_animation_offset(): AnimationOffset
    return { x = 0, y = 0}
    -- local frame_data = self.animation_data:get_frame_data()

    -- local body_sprite_data = ANIMATION_DATA[self:get_body_type()][frame_data.sprite_id]

    -- return frame_data.x + body_sprite_data.anchors.feet_center.x,
    --         frame_data.y + body_sprite_data.anchors.feet_center.y
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
    local sex_offset = self.appearance.sex == "male" and 0 or 1

    if set_pal then
        self:set_pal(side)
    end

    spr(BASE_HEAD_SPRITE + 4 * sex_offset, point.x, point.y, flip_h)
    if self.appearance.sex == "male" then
        spr(BASE_M_HAIR_SPRITE + self.appearance.hair, point.x, point.y, flip_h)
    else
        spr(BASE_F_HAIR_SPRITE + self.appearance.hair, point.x, point.y, flip_h)
    end
    if self.appearance.beard ~= nil then
        spr(BASE_BEARD_SPRITE + self.appearance.beard, point.x, point.y, flip_h)
    end

end

function Character:draw(point: DrawPoint, side: Side, set_pal: boolean, apply_animation: boolean)
    set_pal = set_pal ~= false
    apply_animation = apply_animation ~= false

    -- TODO: consider pre-rendering some of this
    local flip_h = side ~= 0
    local sex = self.appearance.sex

    local frame_data: AnimationFrameData = {
        frame = {
            sprite_offset = 0,
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
        self:set_pal(side)
    end

    spr(BASE_UNIT_SPRITE + frame_data.frame.sprite_offset, base_point.x, base_point.y, flip_h)

    local head_anchor = get_anchor_offsets(base_point, frame_data.frame.anchors.neck, { x = HEAD_NECK_X, y = HEAD_NECK_Y }, flip_h, false)
    self:draw_head(head_anchor, side, set_pal)

    local weapon_anchor = get_anchor_offsets(base_point, frame_data.frame.anchors.main_hand, self.weapon.hand_anchor, flip_h, false)
    spr(BASE_UNIT_SPRITE + self.weapon.sprite, weapon_anchor.x, weapon_anchor.y, flip_h)

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

function CharacterManager:generate_character(): Character
    local character: Character = {
        id = self.id_counter:get_id(),
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

    self.characters[character.id] = character

    return character
end


return CharacterManager
