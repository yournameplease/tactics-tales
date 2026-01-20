local character = require("src/tactics/character/object/character")
local character_definition = require("src/tactics/character/definition")
local CharacterTemplate = character_definition.CharacterTemplate
local GameData = require("src/tactics/game_data").GameData
require("src/tactics/character/items/object/weapon")
local sprite_data = require("src/tactics/character/sprite_data")
local random = require("src/tactics/util/random")
local randomizer = require("src/tactics/util/randomizer")
local ItemInventory  = require("src/tactics/character/items/object/item_inventory")
local ItemGenerator = require("src/tactics/character/items/item_generator")
local NAMES = require("src/tactics/corpora/names")
local maps = require("src/tactics/util/maps")

local character_generator = {}

local function to_randomizer(options: character_definition.AttributeOptions): randomizer.Randomizer<string>
	if options is character_definition.ListOptions then
		return randomizer.weighted_option_selector.of(table.unpack(options.options))
	elseif options is character_definition.WeightedOptions then
		return randomizer.weighted_option_selector.of_weight_map(options.options)
	elseif options is character_definition.StaticOption then
		return randomizer.weighted_option_selector.of(options.option)
	else
		unexpected(options.type)
	end
end

local function apply_template_to_parent(parent: CharacterTemplate, child: CharacterTemplate): CharacterTemplate
	local new_child: CharacterTemplate = {
		movement = child.movement or parent.movement, 
		hp_max = child.hp_max or parent.hp_max, 
		item_loadout = child.item_loadout or parent.item_loadout, 
		head_options_m = child.head_options_m or parent.head_options_m, 
		head_options_f = child.head_options_f or parent.head_options_f, 
		eyewear_options = child.eyewear_options or parent.eyewear_options, 
		headwear_options = child.headwear_options or parent.headwear_options, 
		body_options = child.body_options or parent.body_options, 
		gender_options = child.gender_options or parent.gender_options, 
		skin_color_options = child.skin_color_options or parent.skin_color_options, 
		hair_color_options = child.hair_color_options or parent.hair_color_options, 
		hair_options_m = child.hair_options_m or parent.hair_options_m, 
		hair_options_f = child.hair_options_f or parent.hair_options_f, 
		beard_options = child.beard_options or parent.beard_options, 
		eye_options = child.eye_options or parent.eye_options 
	}
	return new_child
end

local function build_template(template_id: string, game_data: GameData): CharacterTemplate
	if template_id == nil then
		return apply_template_to_parent({}, game_data.characters["default"])
	end

	local template_definition = game_data.characters[template_id]
	local template_parent = build_template(template_definition.parent_template, game_data)
	return apply_template_to_parent(template_parent, template_definition)
end

function character_generator.generate_from_template(
	id: integer,
	template_id: string,
	tags: {string},
	game_data: GameData
): character.Character
	log.debug("Generating from template ", template_id)
	local template = build_template(template_id, game_data)
	local char: character.Character = {
		id = id,
		appearance = {},
		stats = {}
	}
	
	char.stats.movement = template.movement
	char.stats.hp_max = template.hp_max
	char.stats.def = 0
	char.appearance.eyewear = to_randomizer(template.eyewear_options):pick_random()
	char.appearance.headwear = to_randomizer(template.headwear_options):pick_random()
	char.appearance.body_class = to_randomizer(template.body_options):pick_random()
	char.appearance.gender = to_randomizer(template.gender_options):pick_random()
	char.appearance.skin = to_randomizer(template.skin_color_options):pick_random()
    repeat
        char.appearance.hair_color = to_randomizer(template.hair_color_options):pick_random()
    until sprite_data.COLOR_NAMES[char.appearance.hair_color].color
		~= sprite_data.SKIN_COLOR[char.appearance.skin].colors[1]
	if char.appearance.gender == "male" then
		char.appearance.head = to_randomizer(template.head_options_m):pick_random()
		char.appearance.hair = to_randomizer(template.hair_options_m):pick_random()
		char.appearance.beard = to_randomizer(template.beard_options):pick_random()
	else
		char.appearance.head = to_randomizer(template.head_options_f):pick_random()
		char.appearance.hair = to_randomizer(template.hair_options_f):pick_random()
		char.appearance.beard = "none"
	end
	char.appearance.eyes = to_randomizer(template.eye_options):pick_random()

	-- TODO: move these to a randomizer
    char.name = char.appearance.gender == "male"
		and random.choose_random_from_list(NAMES.MALE)
		or random.choose_random_from_list(NAMES.FEMALE)

	char.inventory = ItemInventory.new(4)
	local item_ids = template.item_loadout
	for i, item_id in ipairs(item_ids) do
		local item = ItemGenerator.generate(item_id, game_data.items)
		if char.inventory:can_add_item(item) then
			char.inventory:add_item(item)
			if char.inventory:can_equip(i) then
				char.inventory:equip_item(i)
			end
		end
	end

	if char.appearance.gender == "female" and char.appearance.body_class == "shirtless" then
		char.appearance.body_class = "sleeveless"
	end

    char.tags = maps.set(tags)

	return setmetatable(char, { __index = character.Character })
end

return character_generator
