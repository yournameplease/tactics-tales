require("src/data/character_templates")
require("src/data/weapons")
local Item = require("src/character/items/object/item")
local ItemInventory  = require("src/character/items/object/item_inventory")

-- todo: deduplicate this from renderer
local SKIN_COLORS: { { Color, Color } } = {
    {15, 31},
    {31, 4},
    {4, 20},
    {20, 21}
}


local record CharacterGenerator
end

local function apply_template_to_parent(parent: CharacterTemplate, child: CharacterTemplate): CharacterTemplate
	return {
		movement = child.movement or parent.movement, 
		hp_max = child.hp_max or parent.hp_max, 
		weapon_options = child.weapon_options or parent.weapon_options, 
		headwear_options = child.headwear_options or parent.headwear_options, 
		body_options = child.body_options or parent.body_options, 
		sex_options = child.sex_options or parent.sex_options, 
		skin_color_options = child.skin_color_options or parent.skin_color_options, 
		hair_color_options = child.hair_color_options or parent.hair_color_options, 
		hair_options_m = child.hair_options_m or parent.hair_options_m, 
		hair_options_f = child.hair_options_f or parent.hair_options_f, 
		beard_options = child.beard_options or parent.beard_options, 
		eye_options = child.eye_options or parent.eye_options 
	} as CharacterTemplate
end

local function build_template(template_id: string): CharacterTemplate
	if template_id == nil then
		return apply_template_to_parent({}, UNIT_TEMPLATES["default"])
	end

	local template_definition = UNIT_TEMPLATES[template_id]
	local template_parent = build_template(template_definition.parent_template)
	return apply_template_to_parent(template_parent, template_definition)
end

function CharacterGenerator.generate_from_template(id: integer, template_id: string): Character
	LOG.debug("Generating from template ", template_id)
	local template = build_template(template_id)
	local character: Character = {
		id = id,
		appearance = {},
		stats = {}
	}
	
	character.stats.movement = template.movement
	character.stats.hp_max = template.hp_max
	character.stats.def = 0
	character.weapon = WEAPON_DATA[template.weapon_options:pick_random()]
	-- character..headwear_options = template.headwear_options
	character.appearance.body_class = template.body_options:pick_random()
	character.appearance.sex = template.sex_options:pick_random()
	character.appearance.skin = template.skin_color_options:pick_random()
    repeat
        character.appearance.hair_color = template.hair_color_options:pick_random()
    until character.appearance.hair_color ~= SKIN_COLORS[character.appearance.skin][1]
	if character.appearance.sex == "male" then
		character.appearance.hair = template.hair_options_m:pick_random()
		character.appearance.beard = template.beard_options:pick_random()
	else
		character.appearance.hair = template.hair_options_f:pick_random()
	end
	character.appearance.eyes = template.eye_options:pick_random()

    character.name = character.appearance.sex == "male" and "Bob" or "Alice"

	character.inventory = ItemInventory.new(4)
	local item1 = Item.new(
		"weapon_sword",
		"sword",
		"WEAPON",
		1,
		"MAIN_HAND"
	)
	local item2 = Item.new(
		"weapon_greatsword",
		"greatsword",
		"WEAPON",
		2,
		"TWO_HANDS"
	)
	character.inventory:add_item(item1)
	character.inventory:add_item(item2)
	
	return setmetatable(character, { __index = Character })
end

return CharacterGenerator
