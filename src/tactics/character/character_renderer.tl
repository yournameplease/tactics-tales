require("src/tactics/debug")
require("src/tactics/types")

require("src/tactics/battle/tactics/battle_unit")
require("src/tactics/character/object/character")
require("src/tactics/character/sprite_data")
local wpn = require("src/tactics/character/items/object/weapon")

local ANIMATION_DATA = require("src/tactics/character/animation_data")

local BASE_UNIT_SPRITE = 256

local COLOR_SKIN = 29
local COLOR_SKIN_SHADOW = 13
local COLOR_HAIR = 23
local COLOR_BEARD = 22
local _COLOR_EYE = 21
local _COLOR_EYE_WHITE = 7

local PALETTE_BY_SIDE <total>: {Side: {Color, Color}} = {
	player = {16, 19},
	enemy = {8, 24},
	neutral = {27, 3},
}

local MAX_HEALTH_BAR_WIDTH = 18

local character_renderer = {}

local function get_anchor_offsets(base: Point, anchor: Point, child: Point, flip_h: boolean, flip_v: boolean): Point
    local diff_x = anchor.x - child.x
    local diff_y = anchor.y - child.y
    if flip_h then diff_x = -diff_x end
    if flip_v then diff_y = -diff_y end

    return { x = base.x + diff_x, y = base.y + diff_y }
end

local function get_body_type(battle_unit: BattleUnit): AnimationName
    local weapons = battle_unit.character.inventory:get_equipped_weapons()
	
    local base_body_type: wpn.WeaponBodyType = "BACK_HAND"
	if #weapons > 0 then
		base_body_type = weapons[1].body_type
	end


	local body_class = battle_unit.character.appearance.body_class
	if battle_unit.character.appearance.sex == "female" and body_class == "SHIRTLESS" then
		body_class = "SLEEVELESS"
	end

	-- TODO: type safety
    return (body_class.."_"..base_body_type) as AnimationName
end

local record RenderedAnimationFrame
	offset: Point
	sprite: integer
	anchors: { AnchorPointName: Point }
end

local function get_animation_frame(battle_unit: BattleUnit): RenderedAnimationFrame
	local frame_name: AnimationFrameName 
	local offset: Point
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
function character_renderer.get_animation_offset(battle_unit: BattleUnit): Point
    local frame_data = get_animation_frame(battle_unit)

    return { x = frame_data.offset.x + frame_data.anchors.feet_center.x,
             y = frame_data.offset.y + frame_data.anchors.feet_center.y}
end

local function set_palette(battle_unit: BattleUnit)
	local side_palette = PALETTE_BY_SIDE[battle_unit.side]
    pt.set_pal(16, side_palette[1])
    pt.set_pal(19, side_palette[2])
    local skin = battle_unit.character.appearance.skin
    pt.set_pal(COLOR_SKIN, SKIN_COLORS[skin][1])
    pt.set_pal(COLOR_SKIN_SHADOW, SKIN_COLORS[skin][2])
    pt.set_pal(COLOR_HAIR, battle_unit.character.appearance.hair_color)
    pt.set_pal(COLOR_BEARD, battle_unit.character.appearance.hair_color)
end

function character_renderer.draw_head(battle_unit: BattleUnit, point: Point, set_pal: boolean)
    local flip_h = battle_unit.side == "enemy"

    if set_pal then
        set_palette(battle_unit)
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

function character_renderer.draw(battle_unit: BattleUnit, point: Point, set_pal: boolean, apply_animation: boolean)
    -- TODO: consider pre-rendering some of this
    local flip_h = battle_unit.side == "enemy"

	local animation_frame = get_animation_frame(battle_unit)

	local offset = animation_frame.offset
	if not apply_animation then
		offset = Point.of(0,0)
	end
	
    local base_point = get_anchor_offsets(
		point + offset,
		Point.of(0, 0),
		animation_frame.anchors.feet_center,
		-- flip_h,
		false,
		false
	)
    
    local HEAD_NECK_X = 9
    local HEAD_NECK_Y = 7

    if set_pal then
        set_palette(battle_unit)
    end

    pt.spr(animation_frame.sprite, base_point.x, base_point.y, flip_h)

    local head_anchor = get_anchor_offsets(base_point, animation_frame.anchors.neck, { x = HEAD_NECK_X, y = HEAD_NECK_Y }, flip_h, false)
    character_renderer.draw_head(battle_unit, head_anchor, set_pal)

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

local function draw_health_bar(battle_unit: BattleUnit, point: Point)
	local flip_h = battle_unit.side == "enemy"

	local hp_current = battle_unit.hp_current
	local hp_max = battle_unit.character.stats.hp_max
	local cell_width = pt.flr((MAX_HEALTH_BAR_WIDTH-1) / hp_max)
	--TODO: switch to continuous renderer if cell_width < 1
	cell_width = pt.max(cell_width, 1)
	local width = cell_width * hp_max + 1
	local current_width = cell_width * hp_current + 1
	local height = 4

	local x: integer
	if flip_h then
		x = point.x + (width>>1)
	else
		x = point.x - (width>>1)
	end
	local y = point.y - 2
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


function character_renderer.draw_health_bar(battle_unit: BattleUnit, point: Point, set_pal: boolean, apply_animation: boolean)
    -- TODO: consider pre-rendering some of this
    local flip_h = battle_unit.side == "enemy"

	local animation_frame = get_animation_frame(battle_unit)

	local offset = animation_frame.offset
	if not apply_animation then
		offset = Point.of(0,0)
	end
	
    local base_point = get_anchor_offsets(
		point + offset,
		Point.of(0, 0),
		animation_frame.anchors.feet_center,
		-- flip_h,
		false,
		false
	)
    
    local HEAD_NECK_X = 9
    local HEAD_NECK_Y = 7

    if set_pal then
        set_palette(battle_unit)
    end

    local head_anchor = get_anchor_offsets(base_point, animation_frame.anchors.neck, Point.of(0,0), flip_h, false)
	local health_bar_anchor = head_anchor - Point.of(0,8)
    draw_health_bar(battle_unit, health_bar_anchor)

    if set_pal then
        pt.reset_pal()
    end
end

return character_renderer
