require("src/util/random")
require("src/character/object/character")
require("src/character/items/object/weapon")
require("src/animation")

-- all fields are optional in the templates
global record CharacterTemplate
	movement: integer
	hp_max: integer
	item_loadout_options: Randomizer<{string}>
	eyewear_options: Randomizer<integer>
	headwear_options: Randomizer<HeadwearId>
	body_options: Randomizer<BodyClass>
	sex_options: Randomizer<Sex>
	skin_color_options: Randomizer<integer>
	hair_color_options: Randomizer<integer>
	hair_options_m: Randomizer<integer>
	hair_options_f: Randomizer<integer>
	beard_options: Randomizer<integer>
	eye_options: Randomizer<integer>
	-- ability_options

	parent_template: string
end

global BASE_UNIT: CharacterTemplate = {
	movement = 5,
	hp_max = 5,
	item_loadout_options = ListSelector.of_randomizers(
		WeightedOptionSelector.of("dagger"),
		WeightedOptionSelector.of("shield", "sword")
	),

	headwear_options = WeightedOptionSelector.of_weighted(
		WeightedOption.of(nil, 8),
		WeightedOption.of("wizard_hat", 1),	
		WeightedOption.of("hood", 1)
	),
	eyewear_options = WeightedOptionSelector.of_weighted(
		WeightedOption.of(nil, 9),
		WeightedOption.of(96, 1)	
	),
	body_options = WeightedOptionSelector.of_weighted(
		WeightedOption.of("DEFAULT", 8),
		WeightedOption.of("SLEEVELESS", 1),
		WeightedOption.of("ROBED", 1)
	),
	sex_options = WeightedOptionSelector.of("male", "female"),
	skin_color_options = RandomRange.between(1,4),
    hair_color_options = WeightedOptionSelector.of(4, 5, 6, 9, 10, 20, 21, 22, 24, 25, 31),
	beard_options = RandomRange.between(88, 94),
	eye_options = RandomRange.between(120, 120),
	hair_options_m = RandomRange.between(72, 77),
	hair_options_f = RandomRange.between(80, 85),

	parent_template = nil
}

global UNIT_TEMPLATES: { string: CharacterTemplate } = {
	default = BASE_UNIT,
    human_base = {
        movement = 5,
        hp_max = 5
    },
	bandit_base = {
		parent_template = "human_base",
		sex_options = WeightedOptionSelector.of_weighted(
			WeightedOption.of("male", 5),
			WeightedOption.of("female", 1)
		),
		body_options = WeightedOptionSelector.of_weighted(
			WeightedOption.of("SLEEVELESS", 1),
			WeightedOption.of("SHIRTLESS", 5)
		),
		headwear_options = WeightedOptionSelector.of_weighted(
			WeightedOption.of(nil, 1)
		)
	},
    bandit_goon = {
        parent_template = "bandit_base",
        item_loadout_options = ListSelector.of_randomizers(
			WeightedOptionSelector.of( "club", "axe" ),
			WeightedOptionSelector.of("shield", "axe")
		)
    },
    bandit_boss = {
        parent_template = "bandit_base",
        hp_max = 8,
        item_loadout_options = ListSelector.of_randomizers(
			WeightedOptionSelector.of( "poleaxe" )
		)
    },
	militia_base = {
		parent_template = "human_base",
		body_options = WeightedOptionSelector.of_weighted(
			WeightedOption.of("DEFAULT", 1),
			WeightedOption.of("SLEEVELESS", 1)
		),
		headwear_options = WeightedOptionSelector.of_weighted(
			WeightedOption.of(nil, 3),
			WeightedOption.of("hood", 1)
		)
	},
	militia_spearman = {
		parent_template = "militia_base",
        item_loadout_options = ListSelector.of_randomizers(
			WeightedOptionSelector.of( "spear" ),
			WeightedOptionSelector.of("shield" )
		)
	}, 
	militia_armor = {
		parent_template = "militia_base",
        item_loadout_options = ListSelector.of_randomizers(
			WeightedOptionSelector.of( "mace" ),
			WeightedOptionSelector.of("shield" ),
			WeightedOptionSelector.of("armor" )
		)
	}, 
	militia_archer = {
		parent_template = "militia_base",
        item_loadout_options = ListSelector.of_randomizers(
			WeightedOptionSelector.of( "bow" )
		)
	}, 
	cultist_base = {
		parent_template = "human_base",
		body_options = WeightedOptionSelector.of("ROBED"),
		headwear_options = WeightedOptionSelector.of("cultist_hood")
	},
}

return UNIT_TEMPLATES
