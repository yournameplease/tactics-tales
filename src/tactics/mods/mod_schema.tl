---@brief Specification for game mods.
--- Note that reference fields may be provided by dependent mods as well
--- Used for mod validation
local s = require("src.tactics.validator.schema_definition")

local base_spec = s.record({
	id = s.string(),
	name = s.optional(s.string()),
	version = s.optional(s.string()),

	dependendcies = s.list(
		s.reference("loaded_mods")
	),
	content = s.list(
		s.string()
	),
})

local maps_spec = s.dictionary(
	s.string(),
	s.record({
		type = s.string(),
		file = s.string(),
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

	attacks = s.optional(s.list(s.record({
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
	}))),
	weapon_effects = s.optional(s.list(s.record({type = s.string()}))),
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

-- Schemas for `battles`
local objective_spec = s.record({
    type = s.string(),
    text = s.optional(s.string()),
    tag = s.optional(s.string()),
})

local character_source_spec = s.record({
    type = s.string(),
    template = s.optional(s.reference("characters")),
})

local ai_spec = s.record({
    move = s.string(),
    target_sides = s.list(s.string()),
    exclude_tags = s.optional(s.list(s.string())),
})

local battle_spawn_spec = s.record({
    character_source = character_source_spec,
    tile = s.string(), -- Should be a reference to a tile_label key
    ai = s.optional(ai_spec),
    tags = s.optional(s.list(s.string())),
})

local battle_deployment_spec = s.record({
    deployment_tiles_tag = s.string(), -- Should be a reference to a tile_label key
})

local battle_spec = s.record({
    map_id = s.reference("maps"),
    tile_labels = s.dictionary(s.string(), s.list(s.integer())),
    turn_limit = s.optional(s.integer()),
    victory_conditions = s.list(objective_spec),
    failure_conditions = s.list(objective_spec),
    enemies = s.list(battle_spawn_spec),
    players = s.list(battle_spawn_spec),
    neutral = s.optional(s.list(battle_spawn_spec)),
    deployment = s.optional(battle_deployment_spec),
    scripts = s.list(s.record({})), -- Scripts are too complex to define statically
})

local battles_spec = s.dictionary(s.string(), battle_spec)

-- Schemas for `stories`
local story_node_spec = s.record({
    type = s.string(),
    text = s.optional(s.string()),
    chapter_number = s.optional(s.integer()),
    template = s.optional(s.reference("characters")),
    tags = s.optional(s.list(s.string())),
    battle_id = s.optional(s.reference("battles")),
    next_node_victory = s.optional(s.string()), -- ref to node
    next_node_failure = s.optional(s.string()), -- ref to node
    key = s.optional(s.string()),
    name_key = s.optional(s.string()), -- ref to memory
    -- `value` field for set_memory is not validated as it can be any type.
    next_node = s.optional(s.string()), -- ref to node
})

local story_definition_spec = s.record({
    starting_node = s.string(), -- ref to node key
    nodes = s.dictionary(s.string(), s.list(story_node_spec)),
})

local stories_data_spec = s.dictionary(s.string(), story_definition_spec)

local stories_spec = s.record({
    data = stories_data_spec,
    default_story = s.reference("stories.data"),
    story_select = s.list(s.reference("stories.data")),
})

local game_data_schema = s.record({
	loaded_mods = s.dictionary(
		s.string(),
		s.boolean()
	),
	maps = maps_spec,
	battles = battles_spec,
	stories = stories_spec,
	characters = characters_spec,
	items = items_spec,
})

return {
	maps = maps_spec,
	battles = battles_spec,
	stories = stories_spec,
	characters = characters_spec,
	items = items_spec,
	final_schema = game_data_schema,
}
