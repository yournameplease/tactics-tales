---@brief
--- Defines the data structures for character templates.
--- Specifies how character attributes and their randomization
--- options are structured.

local enum AttributeDefinitionType
	"list"
	"weighted"
	"static"
end

local interface AttributeOptions
	type: AttributeDefinitionType
end

local record ListOptions
	is AttributeOptions
	where self.type == "list"
	options: {string}
end

local record WeightedOptions
	is AttributeOptions
	where self.type == "weighted"
	options: {string: integer}
end

local record StaticOption
	is AttributeOptions
	where self.type == "static"
	option: string
end

local record CharacterTemplate
	movement: integer
	hp_max: integer
	item_loadout: {string}
	head_options_m: AttributeOptions
	head_options_f: AttributeOptions
	eyewear_options: AttributeOptions
	headwear_options: AttributeOptions
	body_options: AttributeOptions
	gender_options: AttributeOptions
	skin_color_options: AttributeOptions
	hair_color_options: AttributeOptions
	hair_options_m: AttributeOptions
	hair_options_f: AttributeOptions
	beard_options: AttributeOptions
	eye_options: AttributeOptions
	-- ability_options

	parent_template: string
end

local character_definition = {
	AttributeOptions = AttributeOptions,
	ListOptions = ListOptions,
	WeightedOptions = WeightedOptions,
	StaticOption = StaticOption,

	CharacterTemplate = CharacterTemplate,
}

return character_definition
