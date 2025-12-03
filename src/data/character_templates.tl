require("src/util/random")
require("src/character/object/character")
require("src/character/items/object/weapon")
require("src/animation")

-- all fields are optional in the templates
global record CharacterTemplate
	movement: integer
	hp_max: integer
	weapon_options: Randomizer<string>
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
	weapon_options = WeightedOptionSelector.of("dagger"),
	headwear_options = WeightedOptionSelector.of_weighted(
		WeightedOption.of(nil, 9),
		WeightedOption.of("glasses", 1)	
	),
	body_options = WeightedOptionSelector.of_weighted(
		WeightedOption.of("DEFAULT", 8),
		WeightedOption.of("SLEEVELESS", 1),
		WeightedOption.of("ROBED", 1)
	),
	sex_options = WeightedOptionSelector.of("male", "female"),
	skin_color_options = RandomRange.between(1,4),
    hair_color_options = WeightedOptionSelector.of(4, 5, 6, 9, 10, 20, 21, 22, 24, 25, 31),
	beard_options = RandomRange.of(7),
	eye_options = RandomRange.of(8),
	hair_options_m = RandomRange.of(6),
	hair_options_f = RandomRange.of(6),

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
		)
	},
    bandit_goon = {
        parent_template = "bandit_base",
        weapon_options = WeightedOptionSelector.of( "club", "axe" )
    },
    bandit_boss = {
        parent_template = "bandit_base",
        hp_max = 8,
        weapon_options = WeightedOptionSelector.of( "poleaxe" )
    }
}

return UNIT_TEMPLATES
