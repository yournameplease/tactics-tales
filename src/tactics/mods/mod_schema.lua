---@brief
--- Specification for game mods.
--- Note that reference fields may be provided by dependent mods as well.
--- Used for mod validation.
--- Certain segments of mod data, such as battles, primarily use factory functions
--- and are excluded from static schema checking

--- TODO: this was mostly AI generated, some cleanup is still needed

local s = require("src.tactics.validator.schema_definition")

local maps_spec = s.dictionary(
	s.string(),
	s.record({
		type = s.string(),
		file = s.optional(s.string()),
	})
)

-- Schemas for `items`
local item_spec_record = s.record({
	name = s.string(),
	type = s.string(),
	slots = s.integer(),
	equip_slot = s.string(),

	equipment_effects = s.optional(s.list(s.record({
		type = s.string(),
		amount = s.integer(),
		defense_type = s.optional(s.string()),
		avoid_type = s.optional(s.string()),
	}))),
	appearance_overrides = s.optional(s.dictionary(s.string(), s.string())),

	sprite_data = s.optional(s.record({
		sprite = s.integer(),
		anchor = s.record({ x = s.integer(), y = s.integer() }),
	})),

	weapon_definition = s.optional(s.record({
		name = s.string(),
		sprite = s.integer(),
		damage = s.integer(),
		accuracy = s.integer(),
		targeting = s.optional(s.record({
			get_selection_tiles = s.func(),
			get_targets_for_selection = s.func(),
			is_target_valid = s.func(),
			range_min = s.optional(s.integer()),
			range_max = s.optional(s.integer()),
		})),
		type = s.string(),
		body_type = s.string(),
		effects = s.optional(s.list(s.record({type = s.string()}))),
	})),
})
local items_spec = s.dictionary(s.string(), item_spec_record)

-- Schemas for `characters`
local randomizer_options_spec = s.record({
	type = s.string(),
	-- `options` is a table that can be a list of strings or a dictionary of string to number.
	-- We are validating it as a generic table, as the schema system does not support unions.
	options = s.record({})
})

local character_template_spec = s.record({
	parent_template = s.optional(s.reference("characters")),
	movement = s.optional(s.integer()),
	hp_max = s.optional(s.integer()),
	item_loadout = s.optional(s.list(s.reference("items"))),
	head_options_m = s.optional(randomizer_options_spec),
	head_options_f = s.optional(randomizer_options_spec),
	headwear_options = s.optional(randomizer_options_spec),
	eyewear_options = s.optional(randomizer_options_spec),
	body_options = s.optional(randomizer_options_spec),
	gender_options = s.optional(randomizer_options_spec),
	skin_color_options = s.optional(randomizer_options_spec),
	hair_color_options = s.optional(randomizer_options_spec),
	beard_options = s.optional(randomizer_options_spec),
	eye_options = s.optional(randomizer_options_spec),
	hair_options_m = s.optional(randomizer_options_spec),
	hair_options_f = s.optional(randomizer_options_spec),
})
local characters_spec = s.dictionary(s.string(), character_template_spec)

local battles_spec = s.dictionary(s.string(), s.factory())

-- Campaign nodes can contain factory functions (CampaignNodeFactory), so deep
-- validation is not possible here. Accept any table, like battles_spec.
local campaigns_data_spec = s.dictionary(s.string(), s.record({}))

local campaigns_spec = s.record({
    data = campaigns_data_spec,
    default_campaign = s.reference("campaigns.data"),
    campaign_select = s.list(s.reference("campaigns.data")),
})

local game_data_schema = s.record({
	loaded_mods = s.dictionary(
		s.string(),
		s.boolean()
	),
	maps = maps_spec,
	battles = battles_spec,
	campaigns = campaigns_spec,
	characters = characters_spec,
	items = items_spec,
})

return {
	maps = maps_spec,
	battles = battles_spec,
	campaigns = campaigns_spec,
	characters = characters_spec,
	items = items_spec,
	final_schema = game_data_schema,
}
