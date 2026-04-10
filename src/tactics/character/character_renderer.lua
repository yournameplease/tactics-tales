---@brief
--- Handles the rendering of character sprites to the screen.
--- Manages palette swaps, skeletal animation, and composing different
--- character parts and equipment into a final sprite.

require("profiler")
local point = require("src.tactics.util.point")
local Point = point.Point

local draw = require("src.tactics.draw")
local colors = require("src.tactics.colors")
local DrawTargetManager = require("src.tactics.draw.draw_target_manager").DrawTargetManager
local battle_unit = require("src.tactics.battle.tactics.battle_unit")
local BattleUnit = battle_unit.BattleUnit
local character = require("src.tactics.character.object.character")
local DrawableCharacterInstance = character.DrawableCharacterInstance
local sprite_data = require("src.tactics.character.sprite_data")
local wpn = require("src.tactics.character.items.object.weapon")

local animated_skeleton = require("src.tactics.animation.animated_skeleton")

local ANIMATION_DATA = require("src.tactics.character.animation_data")

local COLOR_SIDE_1 = 16
local COLOR_SIDE_2 = 19
local COLOR_SIDE_3 = 1

local COLOR_SKIN = 29
local COLOR_SKIN_SHADOW = 13
local COLOR_HAIR = 23
local COLOR_BEARD = 30

local COLOR_EYE = 21
local COLOR_EYE_WHITE = 7
local COLOR_EYE_L_INNER = 27
local COLOR_EYE_L_OUTER = 3
local COLOR_EYE_R_INNER = 11
local COLOR_EYE_R_OUTER = 26

local COLOR_OUTLINE = 33

local BASE_UNIT_SPRITE = 6 * 256

---@type table<Side, integer[]>
local PALETTE_BY_SIDE = {
    player = {16, 19, 1},
    enemy = {8, 24, 2},
    neutral = {27, 3, 19},
}

local MAX_HEALTH_BAR_WIDTH = 18

local NECK_ROOT = { x = 9, y = 8 }

--- A single rendered animation frame: an animation offset plus a skeleton node.
---@class AnimationFrame
---@field offset Point Pixel offset for this frame's animation position.
---@field node SkeletonNodeDefinition Skeleton node data for this frame.
local AnimationFrame = {}

---@alias LookDirection "left"|"right"

---@type string[]
local SPRITE_PART_ORDER = {
    "headwear_back",
    "hair_back",
    "eyewear_back",
    "body",
    "head",
    "eyes",
    "beard",
    "eyewear_front",
    "hair_front",
    "headwear_front",
    "off_hand",
    "main_hand",
}

---@class character_renderer
local character_renderer = {}

--- Compute the position of a child anchor relative to a parent anchor, with optional flip.
---@param base Point Current position of the parent node.
---@param anchor Point Attachment point on the parent where the child connects.
---@param child Point The child node's root anchor point.
---@param flip_h boolean Whether to mirror the horizontal offset.
---@param flip_v boolean Whether to mirror the vertical offset.
---@return Point
local function get_anchor_offsets(base, anchor, child, flip_h, flip_v)
    local diff_x = anchor.x - child.x
    local diff_y = anchor.y - child.y
    if flip_h then diff_x = -diff_x end
    if flip_v then diff_y = -diff_y end

    return { x = base.x + diff_x, y = base.y + diff_y }
end

--- Derive the AnimationName for the main stance of a drawable unit.
---@param drawable_unit DrawableCharacterInstance
---@return AnimationName
local function get_body_type(drawable_unit)
    local weapons = drawable_unit.character.inventory:get_equipped_weapons()

    local base_body_type = "BACK_HAND" ---@type string
    if #weapons > 0 then
        base_body_type = weapons[1].body_type
    end

    local body_class_id = drawable_unit.character:get_appearance().body_class
    local body_class_prefix = sprite_data.BODY_CLASS[body_class_id].id_prefix

    -- TODO: type safety
    return body_class_prefix .. "_" .. base_body_type
end

--- Derive the AnimationName for the COMMON (death/idle) stance of a drawable unit.
---@param drawable_unit DrawableCharacterInstance
---@return AnimationName
local function get_body_type_common(drawable_unit)
    local body_class_id = drawable_unit.character:get_appearance().body_class
    local body_class_prefix = sprite_data.BODY_CLASS[body_class_id].id_prefix

    -- TODO: type safety
    return body_class_prefix .. "_COMMON"
end

--- Resolve the current animation frame data for a drawable unit.
---@param drawable_unit DrawableCharacterInstance
---@return AnimationFrame
local function get_animation_frame(drawable_unit)
    local frame_name ---@type AnimationFrameName
    local offset ---@type Point
    if drawable_unit.animation_data ~= nil and drawable_unit.animation_data.current_frame ~= nil then
        frame_name = drawable_unit.animation_data.current_frame.frame
        offset = drawable_unit.animation_data.current_frame.offset
    else
        log.debug("Unrecognized animation frame.")
        frame_name = "idle_1"
        offset = {x = 0, y = 0}
    end

    local body_type = get_body_type(drawable_unit)
    local body_type_common = get_body_type_common(drawable_unit)

    local animation_frame ---@type SkeletonNodeDefinition
    if ANIMATION_DATA[body_type][frame_name] then
        animation_frame = ANIMATION_DATA[body_type][frame_name]
    elseif ANIMATION_DATA[body_type_common][frame_name] then
        animation_frame = ANIMATION_DATA[body_type_common][frame_name]
    else
        log.error("No frame data found!", drawable_unit)
    end

    return {
        offset = offset,
        node = animation_frame
    }
end

--- Return the pixel offset corresponding to the root anchor of the current animation frame.
---@param drawable_unit DrawableCharacterInstance
---@return Point
function character_renderer.get_animation_offset(drawable_unit)
    local frame_data = get_animation_frame(drawable_unit)

    return { x = frame_data.offset.x + frame_data.node.root.x,
             y = frame_data.offset.y + frame_data.node.root.y }
end

--- Apply palette swaps for a drawable unit's team colour, skin, hair, and eye direction.
---@param drawable_unit DrawableCharacterInstance
---@param draw_outline boolean Whether to draw an outline colour; when false, the outline colour is made transparent.
---@param look_direction LookDirection? Direction the eyes should face; nil uses the default forward gaze.
local function set_palette(drawable_unit, draw_outline, look_direction)
    profile("character_renderer_set_palette")

    local side_palette = PALETTE_BY_SIDE[drawable_unit.side]
    pt.set_pal(COLOR_SIDE_1, side_palette[1])
    pt.set_pal(COLOR_SIDE_2, side_palette[2])
    pt.set_pal(COLOR_SIDE_3, side_palette[3])
    local appearance = drawable_unit.character:get_appearance()
    local skin = appearance.skin
    pt.set_pal(COLOR_SKIN, sprite_data.SKIN_COLOR[skin].colors[1])
    pt.set_pal(COLOR_SKIN_SHADOW, sprite_data.SKIN_COLOR[skin].colors[2])
    pt.set_pal(COLOR_HAIR, sprite_data.COLOR_NAMES[appearance.hair_color].color)
    pt.set_pal(COLOR_BEARD, sprite_data.COLOR_NAMES[appearance.hair_color].color)

    if draw_outline then
        -- local outline_color = side_palette[1]
        local outline_color = 21
        if drawable_unit.side == "player" and not drawable_unit.has_acted then
            outline_color = 7
        end
        pt.set_pal(COLOR_OUTLINE, outline_color)
    else
        pt.set_palt(COLOR_OUTLINE, true)
    end

    --eyes
    -- todo: looking support
    -- NOTE: this will not work with prebaking the whole unit color palette.
    -- consider organizing colors into continuous segments?
    do
        if look_direction ~= nil then
            if look_direction == "left" and drawable_unit.facing.horizontal == "left"
                or look_direction == "right" and (drawable_unit.facing.horizontal == "right" or drawable_unit.facing.horizontal == nil)
            then
                pt.set_pal(COLOR_EYE_L_INNER, COLOR_EYE)
                pt.set_pal(COLOR_EYE_L_OUTER, COLOR_EYE_WHITE)
                pt.set_pal(COLOR_EYE_R_INNER, COLOR_EYE_WHITE)
                pt.set_pal(COLOR_EYE_R_OUTER, COLOR_EYE)
            else
                pt.set_pal(COLOR_EYE_L_INNER, COLOR_EYE_WHITE)
                pt.set_pal(COLOR_EYE_L_OUTER, COLOR_EYE)
                pt.set_pal(COLOR_EYE_R_INNER, COLOR_EYE)
                pt.set_pal(COLOR_EYE_R_OUTER, COLOR_EYE_WHITE)
            end
        else
            pt.set_pal(COLOR_EYE_L_INNER, COLOR_EYE)
            pt.set_pal(COLOR_EYE_L_OUTER, COLOR_EYE_WHITE)
            pt.set_pal(COLOR_EYE_R_INNER, COLOR_EYE)
            pt.set_pal(COLOR_EYE_R_OUTER, COLOR_EYE_WHITE)
        end
    end
    profile("character_renderer_set_palette")
end

--- Assemble and draw a multi-part character sprite using skeletal animation.
--- Gathers all sprite parts (body, head, hair, equipment), constructs a
--- skeleton to position them, and renders it to the screen.
---@param drawable_unit DrawableCharacterInstance
---@param draw_point Point Screen-space draw origin.
local function draw_character(drawable_unit, draw_point)
    local facing = drawable_unit.facing
    local animation_frame = get_animation_frame(drawable_unit)
    local body_node = animation_frame.node

    local equipment = drawable_unit.character.inventory:get_equipped_items()
    local equipment_nodes = {}
    for slot, equip in pairs(equipment) do
        if slot == "BODY" then
            -- this should modify the base frame?
        else
            if equip.sprite_data ~= nil then
                local anchor = slot == "OFF_HAND" and "off_hand" or "main_hand"
                local item_sprite_data = equip.sprite_data
                equipment_nodes[anchor] = {
                    sprite = item_sprite_data.sprite,
                    root = item_sprite_data.anchor,
                    parent = "body",
                }
            end
        end
    end

    local headwear = sprite_data.HEADWEAR[drawable_unit.character:get_appearance().headwear]
    local hair = headwear.draw_hair
        and sprite_data.HAIR[drawable_unit.character:get_appearance().hair]
        or nil
    local eyewear = headwear.draw_eyewear
        and sprite_data.EYEWEAR[drawable_unit.character:get_appearance().eyewear]
        or nil
    local beard = headwear.draw_beard
        and sprite_data.FACIAL_HAIR[drawable_unit.character:get_appearance().beard]
        or nil

    local skeleton_nodes = {
        head = {
            parent = "body",
            sprite = sprite_data.HEAD[drawable_unit.character:get_appearance().head].sprite,
            root = NECK_ROOT,
            scale_x = DYNAMIC_CONFIG.head_scale,
            scale_y = DYNAMIC_CONFIG.head_scale,
        },
        eyes = {
            parent = "head",
            sprite = sprite_data.EYES[drawable_unit.character:get_appearance().eyes].sprite,
        },
        beard = {
            parent = "head",
            sprite = beard and beard.sprite or nil,
        },
        eyewear_front = {
            parent = "head",
            sprite = eyewear and eyewear.sprite or nil,
        },
        eyewear_back = {
            parent = "head",
            sprite = eyewear and eyewear.back_sprite or nil,
        },
        hair_front = {
            parent = "head",
            sprite = hair and hair.sprite or nil,
        },
        hair_back = {
            parent = "head",
            sprite = hair and hair.back_sprite or nil,
        },
        headwear_front = {
            parent = "head",
            sprite = headwear.sprite,
        },
        headwear_back = {
            parent = "head",
            sprite = headwear.back_sprite,
        },
        off_hand = equipment_nodes["off_hand"],
        main_hand = equipment_nodes["main_hand"],
        body = body_node,
    }

    local offset = point.of(0, 0)

    local base_point = get_anchor_offsets(
        draw_point + offset,
        point.of(0, 0),
        point.of_record(body_node.root),
        -- flip_h,
        false,
        false
    )

    local skeleton = animated_skeleton.new(
        skeleton_nodes,
        SPRITE_PART_ORDER
    )

    local backwards = facing.vertical == "up"

    if backwards then
        skeleton:draw_backwards(BASE_UNIT_SPRITE, base_point.x, base_point.y)
    else
        skeleton:draw(BASE_UNIT_SPRITE, base_point.x, base_point.y)
    end
end

--- The main public rendering function for a character.
--- Manages a cache of pre-baked sprites per animation frame and facing direction.
--- If a valid sprite is not cached, renders via `draw_character` to a draw target
--- then stores it for future frames.
---@param drawable_unit DrawableCharacterInstance
---@param draw_point Point Screen-space draw origin.
---@param draw_target_manager DrawTargetManager
---@param set_pal boolean|integer True to apply palette swaps; false to skip; a PaletteId to apply a specific palette.
---@param apply_animation boolean Whether to apply the animation frame offset to the draw position.
---@param draw_outline boolean Whether to draw the character outline.
---@param look_direction LookDirection? Eye look direction; nil uses default forward gaze.
function character_renderer.draw(
    drawable_unit,
    draw_point,
    draw_target_manager,
    set_pal,
    apply_animation,
    draw_outline,
    look_direction
)
    -- profile("draw_character")
    local DRAW_TARGET_W = 32
    local DRAW_TARGET_H = 32
    local DRAW_TARGET_D = point.of(15, 31)

    local current_frame = drawable_unit.animation_data.current_frame

    -- update facing
    do
        if current_frame.facing ~= nil then
            drawable_unit.facing:turn_to(current_frame.facing)
        end
    end

    local facing_v = drawable_unit.facing.vertical
    local facing_h = drawable_unit.facing.horizontal

    local frame_name = current_frame.frame
    if drawable_unit.sprites[frame_name] == nil then
        drawable_unit.sprites[frame_name] = {}
    end
    if drawable_unit.sprites[frame_name][facing_v] == nil then
        draw_target_manager:push_target(DRAW_TARGET_W, DRAW_TARGET_H, DRAW_TARGET_D.x, DRAW_TARGET_D.y)

        -- bake sprite
        draw_target_manager:duplicate_target()

        draw_character(drawable_unit, point.of(0, 0))

        local unit_sprite = draw_target_manager:pop_sprite()
        draw.draw_shadow(COLOR_OUTLINE,
            function(draw_x, draw_y)
                local outline_draw_point = point.of(draw_x, draw_y) - DRAW_TARGET_D
                pt.spr(unit_sprite, outline_draw_point.x, outline_draw_point.y)
            end,
            0, 0)
        pt.spr(unit_sprite, -DRAW_TARGET_D.x, -DRAW_TARGET_D.y)

        drawable_unit.sprites[frame_name][facing_v] = draw_target_manager:pop_sprite()
    end
    local sprite = drawable_unit.sprites[frame_name][facing_v]

    local animation_frame = get_animation_frame(drawable_unit)
    local offset = animation_frame.offset
    if not apply_animation then
        offset = point.of(0, 0)
    end

    local sprite_draw_point = draw_point + offset - DRAW_TARGET_D
    if type(set_pal) == "boolean" then
        if set_pal then
            set_palette(drawable_unit, draw_outline, look_direction)
        end
    else
        colors.apply_palette(set_pal)
    end

    local flip_h = facing_h == "left"
    pt.spr(sprite, sprite_draw_point.x, sprite_draw_point.y, flip_h)

    if set_pal then
        pt.reset_pal()
    end
    -- profile("draw_character")
end

--- Internal: draw the health bar widget centred on `draw_point`.
---@param unit BattleUnit
---@param draw_point Point
local function draw_health_bar(unit, draw_point)
    local hp_current = unit.hp_current
    local hp_max = unit.character.stats.hp_max
    local cell_width = math.floor((MAX_HEALTH_BAR_WIDTH - 1) / hp_max)
    --TODO: switch to continuous renderer if cell_width < 1
    cell_width = math.max(cell_width, 1)
    local width = cell_width * hp_max + 1
    local current_width = cell_width * hp_current + 1
    local height = 4

    local x = draw_point.x - (width >> 1)
    local y = draw_point.y - 2
    local COLOR_SIDE = 16
    -- TODO: get this from UI theme
    local COLOR_BORDER = 21
    local COLOR_SPENT = 15
    pt.rrectfill(x, y, width, height, 1, COLOR_BORDER)
    pt.rrectfill(x + 1, y + 1, width - 2, height - 2, 0, COLOR_SPENT)
    pt.rrectfill(x + 1, y + 1, current_width - 2, height - 2, 0, COLOR_SIDE)
    if cell_width > 1 then
        for i = 1, hp_max - 1 do
            local x_bar = x + i * cell_width
            pt.line(x_bar, y, x_bar, y + height - 1, COLOR_BORDER)
        end
    end
end

--- Draw the health bar for a battle unit, optionally applying palette and animation offset.
---@param unit BattleUnit
---@param draw_point Point Screen-space draw origin.
---@param set_pal boolean Whether to apply palette swaps around the health bar draw.
---@param apply_animation boolean Whether to apply the animation frame offset.
function character_renderer.draw_health_bar(unit, draw_point, set_pal, apply_animation)
    local animation_frame = get_animation_frame(unit)
    local offset = animation_frame.offset
    if not apply_animation then
        offset = point.of(0, 0)
    end

    if set_pal then
        set_palette(unit, true, nil)
    end
    local health_bar_anchor = draw_point + offset + point.of(2, -16)
    draw_health_bar(unit, health_bar_anchor)

    if set_pal then
        pt.reset_pal()
    end
end

return character_renderer
