local randomizer = require("src/tactics/util/randomizer")
local sprite_data = require("src/tactics/character/sprite_data")
require("src/tactics/character/object/character")
require("src/tactics/character/items/object/weapon")
require("src/tactics/animation")

-- all fields are optional in the templates
global record CharacterTemplate
	movement: integer
	hp_max: integer
	item_loadout_options: randomizer.Randomizer<{string}>
	eyewear_options: randomizer.Randomizer<string>
	headwear_options: randomizer.Randomizer<string>
	body_options: randomizer.Randomizer<string>
	sex_options: randomizer.Randomizer<Sex>
	skin_color_options: randomizer.Randomizer<string>
	hair_color_options: randomizer.Randomizer<string>
	hair_options_m: randomizer.Randomizer<string>
	hair_options_f: randomizer.Randomizer<string>
	beard_options: randomizer.Randomizer<string>
	eye_options: randomizer.Randomizer<string>
	-- ability_options

	parent_template: string
end

global BASE_UNIT: CharacterTemplate = {
	movement = 5,
	hp_max = 4,
	item_loadout_options = randomizer.list_selector.of_randomizers(
		randomizer.weighted_option_selector.of("dagger"),
		randomizer.weighted_option_selector.of("shield", "sword")
	),

	headwear_options = randomizer.weighted_option_selector.of_weighted(
		{"none", 8},
		{"wizard_hat", 1},	
		{"hood", 1},
		{"bandana", 1}
	),
	eyewear_options = randomizer.weighted_option_selector.of_weighted(
		{"none", 90},
		{"glasses_a", 2},
		{"glasses_b", 2},
		{"glasses_c", 2},
		{"eyepatch_l", 1},
		{"eyepatch_r", 1}
	),
	body_options = randomizer.weighted_option_selector.of_weighted(
		{"default", 8},
		{"sleeveless", 1},
		{"robed", 1}
	),
	sex_options = randomizer.weighted_option_selector.of("male", "female"),
	skin_color_options = randomizer.weighted_option_selector.of(
		"a", "b", "c", "d"
	),
    hair_color_options = randomizer.weighted_option_selector.of_recursive(
		{randomizer.weighted_option_selector.of(table.unpack(sprite_data.NATURAL_HAIR_COLORS)), 9},
		{randomizer.weighted_option_selector.of(table.unpack(sprite_data.UNNATURAL_HAIR_COLORS)), 1}
	),
	beard_options = randomizer.weighted_option_selector.of_weighted(
		{"none", 8},
		{"beard", 1},
		{"handlebar", 1},
		{"walrus", 1},
		{"sideburns", 1},
		{"chin_beard", 1},
		{"goatee", 1},
		{"bushy_beard", 1},
		{"long_beard", 1}
	),
	eye_options = randomizer.weighted_option_selector.of_weighted(
		{"a", 14},
		{"b", 1},
		{"c", 1},
		{"d", 1},
		{"e", 1},
		{"f", 1},
		{"g", 1},
		{"h", 1}
	),
	hair_options_m = randomizer.weighted_option_selector.of(
		"bald",
		"pompadour",
		"short",
		"wavy",
		"afro_a",
		"buzz_a",
		"emo",
		"balding",
		"flat_top"
	),
	hair_options_f = randomizer.weighted_option_selector.of(
		"bald",
		"bob_bangs",
		"bob_a",
		"bob_b",
		"bob_c",
		"afro_b",
		"pigtails",
		"bun",
		"buzz_b"
	),

	parent_template = nil
}

global UNIT_TEMPLATES: { string: CharacterTemplate } = {
	default = BASE_UNIT,
    human_base = {
        movement = 5,
        hp_max = 4
    },
	bandit_base = {
		parent_template = "human_base",
		sex_options = randomizer.weighted_option_selector.of_weighted(
			{"male", 5},
			{"female", 1}
		),
		body_options = randomizer.weighted_option_selector.of_weighted(
			{"sleeveless", 1},
			{"shirtless", 4}
		),
		eyewear_options = randomizer.weighted_option_selector.of_weighted(
			{"none", 9},
			{"eyepatch_l", 1},
			{"eyepatch_r", 1}
		),
		headwear_options = randomizer.weighted_option_selector.of_weighted(
			{"none", 9},
			{"bandana", 1}
		)
	},
    bandit_goon = {
        parent_template = "bandit_base",
        item_loadout_options = randomizer.list_selector.of_randomizers(
			randomizer.weighted_option_selector.of( "club" )
		)
    },
    bandit_guard = {
        parent_template = "bandit_base",
        item_loadout_options = randomizer.list_selector.of_randomizers(
			randomizer.weighted_option_selector.of( "axe" ),
			randomizer.weighted_option_selector.of("shield")
		)
    },
    bandit_berzerker = {
        parent_template = "bandit_base",
        hp_max = 5,
        item_loadout_options = randomizer.list_selector.of_randomizers(
			randomizer.weighted_option_selector.of("axe"),
			randomizer.weighted_option_selector.of("axe")
		)
    },
    bandit_boss = {
        parent_template = "bandit_base",
        hp_max = 5,
        item_loadout_options = randomizer.list_selector.of_randomizers(
			randomizer.weighted_option_selector.of( "poleaxe" )
		)
    },
	militia_base = {
		parent_template = "human_base",
		body_options = randomizer.weighted_option_selector.of_weighted(
			{"default", 1},
			{"sleeveless", 1}
		),
		headwear_options = randomizer.weighted_option_selector.of_weighted(
			{"none", 3},
			{"hood", 1}
		)
	},
	militia_leader = {
		parent_template = "militia_base",
        hp_max = 5,
        item_loadout_options = randomizer.list_selector.of_randomizers(
			randomizer.weighted_option_selector.of("spear" ),
			randomizer.weighted_option_selector.of("shield" )
		)
	}, 
	militia_spearman = {
		parent_template = "militia_base",
        item_loadout_options = randomizer.list_selector.of_randomizers(
			randomizer.weighted_option_selector.of( "spear" )
		)
	}, 
	militia_armor = {
		parent_template = "militia_base",
        hp_max = 5,
        item_loadout_options = randomizer.list_selector.of_randomizers(
			randomizer.weighted_option_selector.of( "mace" ),
			randomizer.weighted_option_selector.of("shield" ),
			randomizer.weighted_option_selector.of("armor" )
		)
	}, 
	militia_archer = {
		parent_template = "militia_base",
        item_loadout_options = randomizer.list_selector.of_randomizers(
			randomizer.weighted_option_selector.of( "bow" )
		)
	}, 
	cultist_base = {
		parent_template = "human_base",
        hp_max = 3,
		body_options = randomizer.weighted_option_selector.of("robed"),
		headwear_options = randomizer.weighted_option_selector.of("cultist_hood")
	},
	cultist_goon = {
		parent_template = "cultist_base",
		headwear_options = randomizer.weighted_option_selector.of("cultist_hood"),
        item_loadout_options = randomizer.list_selector.of_randomizers(
			randomizer.weighted_option_selector.of( "dagger" )
		),
	},
	cultist_spearman = {
		parent_template = "cultist_base",
		headwear_options = randomizer.weighted_option_selector.of("cultist_hood"),
        item_loadout_options = randomizer.list_selector.of_randomizers(
			randomizer.weighted_option_selector.of( "spear" )
		),
	},
	cultist_guard = {
		parent_template = "cultist_base",
		headwear_options = randomizer.weighted_option_selector.of("hooded_wizard_hat"),
        item_loadout_options = randomizer.list_selector.of_randomizers(
			randomizer.weighted_option_selector.of( "spear" ),
			randomizer.weighted_option_selector.of( "shield" )
		),
	},
	cultist_boss = {
		parent_template = "cultist_base",
        hp_max = 5,
		headwear_options = randomizer.weighted_option_selector.of("hooded_wizard_hat"),
        item_loadout_options = randomizer.list_selector.of_randomizers(),
	},
	village_hero = {
		parent_template = "human_base",
        item_loadout_options = randomizer.list_selector.of_randomizers(
			randomizer.weighted_option_selector.of("sword")
		)
	},
	old_fart = {
		parent_template = "human_base",
        hp_max = 2,
        item_loadout_options = randomizer.list_selector.of_randomizers(
		),
	},
}

return UNIT_TEMPLATES
