require("src/util/random")
require("src/character/weapons")


global enum Sex
    "male"
    "female"
end 

global enum HeadwearId
	"glasses"
	"hood"
	"wizard_hat"
	"hooded_wizard_hat"
end

global enum BodyClass
	"CHILD"
	"DEFAULT"
	"SLEEVELESS"
	"SHIRTLESS" -- for female, this will convert to sleeveless
	"ROBED"
end

-- all fields are optional in the templates
global record CharacterTemplate
	movement: integer
	hp_max: integer
	weapon_options: Randomizer<string>
	headwear_options: Randomizer<HeadwearId>
	body_options: Randomizer<BodyClass>
	sex_options: Randomizer<Sex>
	hair_options_m: Randomizer<integer>
	hair_options_f: Randomizer<integer>
	beard_options: Randomizer<integer>
	eye_options: Randomizer<integer>
	-- ability_options

	parent_template: string
end

local BASE_UNIT: CharacterTemplate = {
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
	hair_options_m = RandomRange.of(6),
	hair_options_f = RandomRange.of(6),
	beard_options = RandomRange.of(7),
	eye_options = RandomRange.of(8),

	parent_template = nil
}

local UNIT_TEMPLATES: { string: CharacterTemplate } = {
    human_base = {
        movement = 5,
        hp_max = 5
    },
	bandit_base = {
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
        parent_template = "human_base",
        weapon_options = WeightedOptionSelector.of( "club", "axe" )
    },
    bandit_boss = {
        parent_template = "bandit_goon",
        hp_max = 8,
        weapon_options = WeightedOptionSelector.of( "poleaxe" )
    }
}


