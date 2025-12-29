local randomizer = require("src/tactics/util/randomizer")
require("src/tactics/character/object/character")
require("src/tactics/character/items/object/weapon")
require("src/tactics/animation")

-- all fields are optional in the templates
global record CharacterTemplate
	movement: integer
	hp_max: integer
	item_loadout_options: randomizer.Randomizer<{string}>
	eyewear_options: randomizer.Randomizer<integer>
	headwear_options: randomizer.Randomizer<integer>
	body_options: randomizer.Randomizer<integer>
	sex_options: randomizer.Randomizer<Sex>
	skin_color_options: randomizer.Randomizer<integer>
	hair_color_options: randomizer.Randomizer<integer>
	hair_options_m: randomizer.Randomizer<integer>
	hair_options_f: randomizer.Randomizer<integer>
	beard_options: randomizer.Randomizer<integer>
	eye_options: randomizer.Randomizer<integer>
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
		{nil, 8},
		{1, 1},	
		{3, 1}
	),
	eyewear_options = randomizer.weighted_option_selector.of_weighted(
		{nil, 9},
		{96, 1}	
	),
	body_options = randomizer.weighted_option_selector.of_weighted(
		{1, 8},
		{2, 1},
		{4, 1}
	),
	sex_options = randomizer.weighted_option_selector.of("male", "female"),
	skin_color_options = randomizer.random_range.between(1,4),
    hair_color_options = randomizer.weighted_option_selector.of(4, 5, 6, 9, 10, 20, 21, 22, 24, 25, 31),
	beard_options = randomizer.random_range.between(88, 94),
	eye_options = randomizer.random_range.between(120, 120),
	hair_options_m = randomizer.random_range.between(72, 77),
	hair_options_f = randomizer.random_range.between(80, 85),

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
			{2, 1},
			{3, 5}
		),
		headwear_options = randomizer.weighted_option_selector.of_weighted(
			{nil, 1}
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
			{1, 1},
			{2, 1}
		),
		headwear_options = randomizer.weighted_option_selector.of_weighted(
			{nil, 3},
			{1, 1}
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
		body_options = randomizer.weighted_option_selector.of(4),
		headwear_options = randomizer.weighted_option_selector.of(2)
	},
	cultist_goon = {
		parent_template = "cultist_base",
		headwear_options = randomizer.weighted_option_selector.of(2),
        item_loadout_options = randomizer.list_selector.of_randomizers(
			randomizer.weighted_option_selector.of( "dagger" )
		),
	},
	cultist_spearman = {
		parent_template = "cultist_base",
		headwear_options = randomizer.weighted_option_selector.of(2),
        item_loadout_options = randomizer.list_selector.of_randomizers(
			randomizer.weighted_option_selector.of( "spear" )
		),
	},
	cultist_guard = {
		parent_template = "cultist_base",
		headwear_options = randomizer.weighted_option_selector.of(4),
        item_loadout_options = randomizer.list_selector.of_randomizers(
			randomizer.weighted_option_selector.of( "spear" ),
			randomizer.weighted_option_selector.of( "shield" )
		),
	},
	cultist_boss = {
		parent_template = "cultist_base",
        hp_max = 5,
		headwear_options = randomizer.weighted_option_selector.of(4),
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
