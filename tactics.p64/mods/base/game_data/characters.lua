
local options = {}

function options.list(opts)
	return {
		type = "list",
		options = opts
	}
end

function options.weighted(opts)
	return {
		type = "weighted",
		options = opts
	}
end

local NATURAL_HAIR_COLORS = options.list{
	"brown",
	"dark_grey",
	"light_grey",
	"orange",
	"yellow",
	"dark_brown",
	"darker_grey",
	"dark_red",
	"dark_orange",
	"medium_grey",
	"peach",
}

local YOUNG_HAIR_COLORS = options.list{
	"brown",
	"orange",
	"yellow",
	"dark_brown",
	"darker_grey",
	"dark_red",
	"dark_orange",
	"peach",
}

local OLD_HAIR_COLORS = options.list{
	"dark_grey",
	"light_grey",
	"darker_grey",
	"medium_grey",
	"white",
}

local BASE_UNIT = {
	movement = 5,
	hp_max = 4,
	item_loadout = {
		"dagger",
		"shield"
	},

	headwear_options = options.weighted{
		["none"] = 8,
		["wizard_hat"] = 1,	
		["hood"] = 1,
		["bandana"] = 1
	},
	eyewear_options = options.weighted{
		["none"] = 90,
		["glasses_a"] = 2,
		["glasses_b"] = 2,
		["glasses_c"] = 2,
		["eyepatch_l"] = 1,
		["eyepatch_r"] = 1
	},
	body_options = options.weighted{
		["default"] = 8,
		["sleeveless"] = 1,
		["robed"] = 1
	},
	gender_options = options.list{"male", "female"},
	skin_color_options = options.list{
		"a", "b", "c", "d"
	},
    hair_color_options = NATURAL_HAIR_COLORS,
	beard_options = options.weighted{
		["none"] = 8,
		["beard"] = 1,
		["handlebar"] = 1,
		["walrus"] = 1,
		["sideburns"] = 1,
		["chin_beard"] = 1,
		["goatee"] = 1,
		["bushy_beard"] = 1,
		["long_beard"] = 1
	},
	eye_options = options.weighted{
		["a"] = 14,
		["b"] = 1,
		["c"] = 1,
		["d"] = 1,
		["e"] = 1,
		["f"] = 1,
		["g"] = 1,
		["h"] = 1
	},
	hair_options_m = options.list{
		"bald",
		"pompadour",
		"short",
		"wavy",
		"afro_a",
		"buzz_a",
		"emo",
		"balding",
		"flat_top"
	},
	hair_options_f = options.list{
		"bald",
		"bob_bangs",
		"bob_a",
		"bob_b",
		"bob_c",
		"afro_b",
		"pigtails",
		"bun",
		"buzz_b"
	},

	parent_template = nil
}

local UNIT_TEMPLATES = {
	default = BASE_UNIT,
    human_base = {
        movement = 5,
        hp_max = 4
    },
    child_base = {
        movement = 5,
        hp_max = 3,
				body_options = options.list{ "child" },
				beard_options = options.list{"none"}
    },
	child_axe = {
        parent_template = "child_base",
        item_loadout = {
			 "axe" 
		}
	},
	child_bow = {
        parent_template = "child_base",
        item_loadout = {
			 "bow" 
		}
	},
	child_greatsword = {
		parent_template = "child_base",
		item_loadout = {
			"greatsword"
		}
	},
	village_axe = {
		parent_template = "human_base",
		item_loadout = {
			"axe"
		}
	},
	bandit_base = {
		parent_template = "human_base",
		gender_options = options.weighted{
			["male"] = 5,
			["female"] = 1
		},
		body_options = options.weighted{
			["sleeveless"] = 1,
			["shirtless"] = 4
		},
		eyewear_options = options.weighted{
			["none"] = 9,
			["eyepatch_l"] = 1,
			["eyepatch_r"] = 1
		},
		headwear_options = options.weighted{
			["none"] = 9,
			["bandana"] = 1
		}
	},
    bandit_weakling = {
        parent_template = "bandit_base",
		hp_max = 3,
        item_loadout = {
			 "club" 
		}
    },
    bandit_goon = {
        parent_template = "bandit_base",
		hp_max = 4,
        item_loadout = {
			 "club" 
		}
    },
    bandit_axe = {
        parent_template = "bandit_base",
			hp_max = 4,
        item_loadout = {
			 "axe" ,
			"shield"
		}
    },
    bandit_guard = {
        parent_template = "bandit_base",
			hp_max = 4,
        item_loadout = {
			 "axe" ,
			"shield"
		}
    },
    bandit_berzerker = {
        parent_template = "bandit_base",
        hp_max = 5,
        item_loadout = {
			"axe",
			"axe"
		}
    },
    bandit_boss = {
        parent_template = "bandit_base",
        hp_max = 5,
        item_loadout = {
			 "poleaxe" 
		}
    },
	militia_base = {
		parent_template = "human_base",
		body_options = options.weighted{
			["default"] = 1,
			["sleeveless"] = 1
		},
		headwear_options = options.weighted{
			["none"] = 3,
			["hood"] = 1
		}
	},
	militia_spear_captain = {
		parent_template = "militia_base",
        hp_max = 5,
        item_loadout = {
			"spear" ,
			"shield" 
		}
	}, 
	militia_sword_captain = {
		parent_template = "militia_base",
        hp_max = 5,
        item_loadout = {
			"spear" ,
			"shield" 
		}
	}, 
	militia_spearman = {
		parent_template = "militia_base",
        item_loadout = {
			 "spear" 
		}
	}, 
	militia_sword = {
		parent_template = "militia_base",
    item_loadout = {
			 "sword" 
		}
	}, 
	militia_armor = {
		parent_template = "militia_base",
        hp_max = 5,
        item_loadout = {
			 "mace" ,
			"shield" ,
			"armor" 
		}
	}, 
	militia_archer = {
		parent_template = "militia_base",
        item_loadout = {
			 "bow" 
		}
	}, 
	cultist_base = {
		parent_template = "human_base",
        hp_max = 3,
		body_options = options.list{"robed"},
		headwear_options = options.list{"cultist_hood"}
	},
	cultist_goon = {
		parent_template = "cultist_base",
		headwear_options = options.list{"cultist_hood"},
        item_loadout = {
			 "dagger" 
		},
	},
	cultist_spearman = {
		parent_template = "cultist_base",
		headwear_options = options.list{"cultist_hood"},
        item_loadout = {
			 "spear" 
		},
	},
	cultist_guard = {
		parent_template = "cultist_base",
		headwear_options = options.list{"hooded_wizard_hat"},
        item_loadout = {
			 "spear" ,
			 "shield" 
		},
	},
	cultist_boss = {
		parent_template = "cultist_base",
        hp_max = 5,
		headwear_options = options.list{"hooded_wizard_hat"},
        item_loadout = {},
	},
	village_hero = {
		parent_template = "human_base",
        item_loadout = {
			"sword"
		}
	},
	old_fart = {
		parent_template = "human_base",
        hp_max = 2,
        item_loadout = {
		},
	},
	civilian = {
		parent_template = "human_base",
        hp_max = 3,
        body_options = options.list{
        	"default",
        	"robed",
        	"child"
        },
        item_loadout = {},
	},
}

return UNIT_TEMPLATES
