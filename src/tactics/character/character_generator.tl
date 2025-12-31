require("src/tactics/data/character_templates")
require("src/tactics/character/object/character")
require("src/tactics/data/items")
require("src/tactics/character/items/object/weapon")
require("src/tactics/util")
local sprite_data = require("src/tactics/character/sprite_data")
local random = require("src/tactics/util/random")
require("src/tactics/util/randomizer")
local ItemInventory  = require("src/tactics/character/items/object/item_inventory")
local ItemGenerator = require("src/tactics/character/items/item_generator")
local NAMES = require("src/tactics/corpora/names")

local record CharacterGenerator
end

local function apply_template_to_parent(parent: CharacterTemplate, child: CharacterTemplate): CharacterTemplate
	return {
		movement = child.movement or parent.movement, 
		hp_max = child.hp_max or parent.hp_max, 
		item_loadout_options = child.item_loadout_options or parent.item_loadout_options, 
		eyewear_options = child.eyewear_options or parent.eyewear_options, 
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
	character.appearance.eyewear = template.eyewear_options:pick_random()
	character.appearance.headwear = template.headwear_options:pick_random()
	character.appearance.body_class = template.body_options:pick_random()
	character.appearance.sex = template.sex_options:pick_random()
	character.appearance.skin = template.skin_color_options:pick_random()
    repeat
        character.appearance.hair_color = template.hair_color_options:pick_random()
    until sprite_data.COLOR_NAMES[character.appearance.hair_color].color
		~= sprite_data.SKIN_COLOR[character.appearance.skin].colors[1]
	character.appearance.head = character.appearance.sex == "male" and "round" or "narrow_chin"
	if character.appearance.sex == "male" then
		character.appearance.hair = template.hair_options_m:pick_random()
		character.appearance.beard = template.beard_options:pick_random()
	else
		character.appearance.hair = template.hair_options_f:pick_random()
		character.appearance.beard = "none"
	end
	character.appearance.eyes = template.eye_options:pick_random()

	-- TODO: move these to a randomizer
    character.name = character.appearance.sex == "male"
		and random.choose_random_from_list(NAMES.MALE)
		or random.choose_random_from_list(NAMES.FEMALE)

	character.inventory = ItemInventory.new(4)
	local item_ids = template.item_loadout_options:pick_random()
	for i, item_id in ipairs(item_ids) do
		local item = ItemGenerator.generate(item_id)
		if character.inventory:can_add_item(item) then
			character.inventory:add_item(item)
			if character.inventory:can_equip(i) then
				character.inventory:equip_item(i)
			end
		end
	end

	if character.appearance.sex == "female" and character.appearance.body_class == "shirtless" then
		character.appearance.body_class = "sleeveless"
	end
	
	return setmetatable(character, { __index = Character })
end

return CharacterGenerator
