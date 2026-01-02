require("profiler")
require("src/tactics/debug")
local point = require("src/tactics/util/point")
local Point = point.Point

local draw = require("src/tactics/draw")
local colors = require("src/tactics/colors")
local DrawTargetManager = require("src/tactics/draw/draw_target_manager").DrawTargetManager
local battle_unit = require("src/tactics/battle/tactics/battle_unit")
local BattleUnit = battle_unit.BattleUnit
local character = require("src/tactics/character/object/character")
local Side = character.Side
local DrawableCharacterInstance = character.DrawableCharacterInstance
local sprite_data = require("src/tactics/character/sprite_data")
local wpn = require("src/tactics/character/items/object/weapon")

local ANIMATION_DATA = require("src/tactics/character/animation_data")

local BASE_UNIT_SPRITE = 6 * 256

local COLOR_SIDE_1 = 16
local COLOR_SIDE_2 = 19
local COLOR_SIDE_3 = 1

local COLOR_SKIN = 29
local COLOR_SKIN_SHADOW = 13
local COLOR_HAIR = 23
local COLOR_BEARD = 22
local _COLOR_EYE = 21
local _COLOR_EYE_WHITE = 7

local COLOR_OUTLINE = 33

local PALETTE_BY_SIDE <total>: {Side: {Color, Color, Color}} = {
	player = {16, 19, 1},
	enemy = {8, 24, 2},
	neutral = {27, 3, 19},
}

local MAX_HEALTH_BAR_WIDTH = 18

local character_renderer = {}

local function get_anchor_offsets(
	base: Point,
	anchor: Point,
	child: Point,
	flip_h: boolean,
	flip_v: boolean
): Point
    local diff_x = anchor.x - child.x
    local diff_y = anchor.y - child.y
    if flip_h then diff_x = -diff_x end
    if flip_v then diff_y = -diff_y end

    return { x = base.x + diff_x, y = base.y + diff_y }
end

local function get_body_type(
	drawable_unit: DrawableCharacterInstance
): AnimationName
    local weapons = drawable_unit.character.inventory:get_equipped_weapons()
	
    local base_body_type: wpn.WeaponBodyType = "BACK_HAND"
	if #weapons > 0 then
		base_body_type = weapons[1].body_type
	end


	local body_class_id = drawable_unit.character.appearance.body_class
	local body_class_prefix = sprite_data.BODY_CLASS[body_class_id].id_prefix
	-- if drawable_unit.character.appearance.sex == "female" and body_class == "SHIRTLESS" then
	-- 	body_class = "SLEEVELESS"
	-- end

	-- TODO: type safety
    return (body_class_prefix.."_"..base_body_type) as AnimationName
end

local record RenderedAnimationFrame
	offset: Point
	sprite: integer
	anchors: { AnchorPointName: Point }
end

local function get_animation_frame(
	drawable_unit: DrawableCharacterInstance
): RenderedAnimationFrame
	local frame_name: AnimationFrameName 
	local offset: Point
	if drawable_unit.animation_data ~= nil and drawable_unit.animation_data.current_frame ~= nil then
		frame_name = drawable_unit.animation_data.current_frame.frame
		offset = drawable_unit.animation_data.current_frame.offset
	else
		LOG.debug("Unrecognized animation frame.")
		frame_name = "idle_1"
		offset = {x = 0, y = 0}
	end

    local animation_frame = ANIMATION_DATA[get_body_type(drawable_unit)][frame_name]

	return {
		offset = offset,
		sprite = BASE_UNIT_SPRITE + animation_frame.sprite,
		anchors = animation_frame.anchors
	}
end

-- @return the position of the "feet_center" anchor
function character_renderer.get_animation_offset(
	drawable_unit: DrawableCharacterInstance
): Point
    local frame_data = get_animation_frame(drawable_unit)

    return { x = frame_data.offset.x + frame_data.anchors.feet_center.x,
             y = frame_data.offset.y + frame_data.anchors.feet_center.y}
end

local function set_palette(
	drawable_unit: DrawableCharacterInstance,
	draw_outline: boolean
)
	local side_palette = PALETTE_BY_SIDE[drawable_unit.side]
    pt.set_pal(COLOR_SIDE_1, side_palette[1])
    pt.set_pal(COLOR_SIDE_2, side_palette[2])
    pt.set_pal(COLOR_SIDE_3, side_palette[3])
    local skin = drawable_unit.character.appearance.skin
    pt.set_pal(COLOR_SKIN, sprite_data.SKIN_COLOR[skin].colors[1])
    pt.set_pal(COLOR_SKIN_SHADOW, sprite_data.SKIN_COLOR[skin].colors[2])
    pt.set_pal(COLOR_HAIR, sprite_data.COLOR_NAMES[drawable_unit.character.appearance.hair_color].color)
    pt.set_pal(COLOR_BEARD, sprite_data.COLOR_NAMES[drawable_unit.character.appearance.hair_color].color)

	if draw_outline then
		local outline_color = drawable_unit.has_acted and 21 or side_palette[3]
		pt.set_pal(COLOR_OUTLINE, outline_color)
	else
		pt.set_palt(COLOR_OUTLINE, true)
	end
end

local function draw_head(
	drawable_unit: DrawableCharacterInstance,
	draw_point: Point
)
    local flip_h = drawable_unit.side == "enemy"

	local head: sprite_data.SpriteData =
		sprite_data.HEAD[drawable_unit.character.appearance.head]	
	local headwear: sprite_data.HeadwearSpriteData =
		sprite_data.HEADWEAR[drawable_unit.character.appearance.headwear]	
	local eyes: sprite_data.SpriteData =
		sprite_data.EYES[drawable_unit.character.appearance.eyes]	
	local eyewear: sprite_data.SpriteData =
		sprite_data.EYEWEAR[drawable_unit.character.appearance.eyewear]	
	local hair: sprite_data.SpriteData =
		sprite_data.HAIR[drawable_unit.character.appearance.hair]	
	local beard: sprite_data.SpriteData =
		sprite_data.FACIAL_HAIR[drawable_unit.character.appearance.beard]	

    pt.spr(BASE_UNIT_SPRITE + head.sprite, draw_point.x, draw_point.y, flip_h)
	if eyes.sprite ~= nil then
        pt.spr(BASE_UNIT_SPRITE + eyes.sprite, draw_point.x, draw_point.y, flip_h)
	end
	if beard.sprite ~= nil and headwear.draw_beard then
        pt.spr(BASE_UNIT_SPRITE + beard.sprite, draw_point.x, draw_point.y, flip_h)
	end
	if eyewear.sprite ~= nil and headwear.draw_eyewear then
        pt.spr(BASE_UNIT_SPRITE + eyewear.sprite, draw_point.x, draw_point.y, flip_h)
	end
	if hair.sprite ~= nil and headwear.draw_hair then
        pt.spr(BASE_UNIT_SPRITE + hair.sprite, draw_point.x, draw_point.y, flip_h)
	end
	if headwear.sprite ~= nil then
        pt.spr(BASE_UNIT_SPRITE + headwear.sprite, draw_point.x, draw_point.y, flip_h)
	end

end

local function draw_character(
	drawable_unit: DrawableCharacterInstance,
	draw_point: Point
)
    local flip_h = drawable_unit.side == "enemy"

	local animation_frame = get_animation_frame(drawable_unit)

	local offset = point.of(0,0)

    local base_point = get_anchor_offsets(
		draw_point + offset,
		point.of(0, 0),
		animation_frame.anchors.feet_center,
		-- flip_h,
		false,
		false
	)

    local HEAD_NECK_X = 9
    local HEAD_NECK_Y = 7

    pt.spr(animation_frame.sprite, base_point.x, base_point.y, flip_h)

    local head_anchor = get_anchor_offsets(base_point, animation_frame.anchors.neck, { x = HEAD_NECK_X, y = HEAD_NECK_Y }, flip_h, false)
    draw_head(drawable_unit, head_anchor)

	local equipment = drawable_unit.character.inventory:get_equipped_items()
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
end

function character_renderer.draw(
	drawable_unit: DrawableCharacterInstance,
	draw_point: Point,
	draw_target_manager: DrawTargetManager,
	set_pal: boolean | colors.PaletteId,
	apply_animation: boolean,
	draw_outline: boolean
)
	profile("draw_character")
	local DRAW_TARGET_W = 32
	local DRAW_TARGET_H = 32
	local DRAW_TARGET_D = point.of(15, 31)

	local current_frame = drawable_unit.animation_data.current_frame.frame
	if drawable_unit.sprites[current_frame] == nil then
		draw_target_manager:push_target(DRAW_TARGET_W, DRAW_TARGET_H, DRAW_TARGET_D.x, DRAW_TARGET_D.y)

		-- bake sprite
		draw_target_manager:duplicate_target()

		draw_character(drawable_unit, point.of(0,0))

		local unit_sprite = draw_target_manager:pop_sprite()
        draw.draw_shadow(COLOR_OUTLINE,
            function(draw_x: integer,draw_y: integer)
				local outline_draw_point = point.of(draw_x, draw_y) - DRAW_TARGET_D
				pt.spr(unit_sprite, outline_draw_point.x, outline_draw_point.y)
            end,
            0, 0)
		pt.spr(unit_sprite, -DRAW_TARGET_D.x, -DRAW_TARGET_D.y)

		drawable_unit.sprites[drawable_unit.animation_data.current_frame.frame] = draw_target_manager:pop_sprite()
	end

	local sprite = drawable_unit.sprites[drawable_unit.animation_data.current_frame.frame]

	local animation_frame = get_animation_frame(drawable_unit)
	local offset = animation_frame.offset
	if not apply_animation then
		offset = point.of(0,0)
	end

	local sprite_draw_point = draw_point + offset - DRAW_TARGET_D

    if set_pal is boolean then
		if set_pal then
        	set_palette(drawable_unit, draw_outline)
		end
    elseif set_pal is colors.PaletteId then
		colors.apply_palette(set_pal)
	end
	
	pt.spr(sprite,sprite_draw_point.x,sprite_draw_point.y)

    if set_pal then
        pt.reset_pal()
    end
	profile("draw_character")
end

local function draw_health_bar(
	unit: BattleUnit,
	draw_point: Point
)
	local flip_h = unit.side == "enemy"

	local hp_current = unit.hp_current
	local hp_max = unit.character.stats.hp_max
	local cell_width = pt.flr((MAX_HEALTH_BAR_WIDTH-1) / hp_max)
	--TODO: switch to continuous renderer if cell_width < 1
	cell_width = pt.max(cell_width, 1)
	local width = cell_width * hp_max + 1
	local current_width = cell_width * hp_current + 1
	local height = 4

	local x: integer
	if flip_h then
		x = draw_point.x + (width>>1)
	else
		x = draw_point.x - (width>>1)
	end
	local y = draw_point.y - 2
	local COLOR_SIDE = 16
	-- TODO: get this from UI theme
	local COLOR_BORDER = 21
	local COLOR_SPENT = 15
    pt.rrectfill(x, y, width, height, 1, COLOR_BORDER)
    pt.rrectfill(x+1, y+1, width-2, height-2, 0, COLOR_SPENT)
    pt.rrectfill(x+1, y+1, current_width-2, height-2, 0, COLOR_SIDE)
	if cell_width > 1 then
		for i = 1,hp_max-1 do
			local x_bar = x+i*cell_width
			pt.line(x_bar,y,x_bar,y+height-1,COLOR_BORDER)
		end
	end
end


function character_renderer.draw_health_bar(
	unit: BattleUnit,
	draw_point: Point,
	set_pal: boolean,
	apply_animation: boolean
)
    -- TODO: consider pre-rendering some of this
    local flip_h = unit.side == "enemy"

	local animation_frame = get_animation_frame(unit)

	local offset = animation_frame.offset
	if not apply_animation then
		offset = point.of(0,0)
	end
	
    local base_point = get_anchor_offsets(
		draw_point + offset,
		point.of(0, 0),
		animation_frame.anchors.feet_center,
		-- flip_h,
		false,
		false
	)
    
    if set_pal then
        set_palette(unit, true)
    end

    local head_anchor = get_anchor_offsets(base_point, animation_frame.anchors.neck, point.of(0,0), flip_h, false)
	local health_bar_anchor = head_anchor - point.of(0,9)
    draw_health_bar(unit, health_bar_anchor)

    if set_pal then
        pt.reset_pal()
    end
end

return character_renderer
