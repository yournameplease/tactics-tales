local ai <const> = {
    default = { move = "two", target = "player"},
    move_one = { move = "one", target = "player"},
    move_two = { move = "two", target = "player"},
    move_inf = { move = "infinity", target = "player"},
    stationary = { move = "zero", target = "player"},
    stationary_allied = { move = "zero", target = "enemy"},
    stationary_neutral = { move = "zero", target = nil }
}

local character_source = {}

function character_source.template(template)
	local self = {
		type = "template",
		template = template,
	}
	return self
end

function character_source.player_roster()
	local self = {
		type = "player_roster",
	}
	return self
end

local objectives = {}

function objectives.rout()
    local self = {
        type = "rout",
        text = "Defeat all enemies"
    }
    return self
end

function objectives.defeat_tagged(tag, text)
    local self = {
        type = "defeat_tagged",
        text = text,
        tag = tag,
    }
    return self
end

function objectives.survive()
    local self = {
        type = "survive",
        text = "Survive"
    }
    return self
end

function objectives.escape()
    local self = {
        type = "escape",
        text = "Escape",
    }
    return self
end


function objectives.all_players_die()
    local self = {
        type = "all_players_die",
    }
    return self
end

function objectives.tagged_unit_dies(tag)
    local self = {
        type = "tagged_unit_dies",
        tag = tag,
    }
    return self
end

function objectives.turn_limit()
    local self = {
        type = "turn_limit",
    }
    return self
end

local scripts = {
    trigger = {},
    effect = {},
}

function scripts.trigger.turn(
	turn,
	repeating,
	phase
)
	return {
		type = "turn",
		turn = turn,
		repeating = repeating,
		phase = phase,
	}
end

function scripts.trigger.unit_death(
	unit_label
)
	return {
		type = "unit_death",
		unit_label = unit_label,
	}
end

function scripts.effect.spawn_units(
	players,
	enemies,
	animation
)
	return {
		type = "spawn_units",
		players = players,
		enemies = enemies,
		animation = animation,
	}
end

function scripts.effect.despawn(
	units
)
	return {
		type = "despawn_units",
		units = units
	}
end

function scripts.effect.dialogue(
	unit,
	text
)
	return {
		type = "dialogue",
		unit = unit,
		text = text
	}
end

function scripts.effect.modify_units(
	unit_tag,
	new_ai,
	new_side
)
	return {
		type = "modify_units",
		unit_selector = {
		    type = "tag_lookup",
		    tag = unit_tag,
		},
		new_ai = new_ai,
		new_side = new_side,
	}
end

function scripts.effect.change_side(
    unit_tag,
    new_side
)
    return scripts.effect.modify_units(unit_tag, nil, new_side)
end

function scripts.effect.change_ai(
    unit_tag,
    new_ai
)
    return scripts.effect.modify_units(unit_tag, new_ai, nil)
end

function scripts.effect.modify_terrain(
	tile_label,
	new_terrain
)
	return {
		type = "modify_terrain",
		tile_label = tile_label,
		new_terrain = new_terrain
	}
end

local function spawn_players(
    players,
    turn,
    phase,
    animation
)
    return {
        trigger = scripts.trigger.turn(turn, nil, phase),
        effects = {
            scripts.effect.spawn_units(players, {}, animation),
        },
    }
end

local function free_players(
    players,
    unit_label,
    animation
)
    return {
        trigger = scripts.trigger.unit_death(unit_label),
        effects = {
            scripts.effect.spawn_units(players, {}, animation),
        },
    }
end

local function spawn_enemies(
    enemies,
    turn,
    repeating, --nillable
    phase,
    animation
)
    return {
        trigger = scripts.trigger.turn(turn, repeating, phase),
        effects = {
            scripts.effect.spawn_units({}, enemies, animation),
        },
    }
end

local function modify_units(
    turn,
    phase,
    unit_tag,
    new_ai,
    new_side
)
    return {
        trigger = scripts.trigger.turn(turn, nil, phase),
        effects = {
            scripts.effect.modify_units(unit_tag, new_ai, new_side),
        },
    }
end

local function open_door_front(
    enemy_label,
    tile_label
)
    return {
        trigger = scripts.trigger.unit_death(enemy_label),
        effects = {
            scripts.effect.modify_terrain(
                tile_label,
                {
                    ["front_wall"] = 0
                }
            ),
        },
    }
end

local function open_door_mid(
    enemy_label,
    tile_label
)
    return {
        trigger = scripts.trigger.unit_death(enemy_label),
        effects = {
            scripts.effect.modify_terrain(
                tile_label,
                {
                    ["mid_wall"] = 0
                }
            ),
        },
    }
end

function escape(tile_tag)
    return {
        trigger = {
            type = "tile_interaction",
            tile_specifier = {
                type = "tag_lookup",
                tag = tile_tag,
            },
            interaction_text = "Escape",
            interaction_distance = "on",
        },
        effects = {
            scripts.effect.dialogue(
                {
            		    type = "trigger_source"
                },
                {
                    "I'm retreating!",
                }
            ),
            scripts.effect.despawn({
        		    type = "trigger_source"
        		}),
            scripts.effect.dialogue(
                {
            		    type = "trigger_source"
                },
                {
                    "Bye Bye!",
                }
            ),
        },
    }
end


local BATTLE_DATA = {
    ["bandit_village"] = {
        map_id = "bandit_village",
        tile_labels = {
            ["player_deployment"] = { 0x00 },
            ["bandit_boss"] = { 0x1E },
            ["bandit_goon"] = { 0x11 },
            ["bandit_reinforce_l"] = { 0x18 },
            ["bandit_reinforce_r"] = { 0x19 },
            ["bandit_miniboss_gate"] = { 0x1A },
            ["bandit_miniboss_l"] = { 0x1B },
            ["bandit_miniboss_r"] = { 0x1C },
            ["player_captain"] = { 0x0B },
            ["player_spearman"] = { 0x08 },
            ["player_archer"] = { 0x09 },
            ["player_armor"] = { 0x0A },
        },
        turn_limit = 10,
        victory_conditions = {
            objectives.defeat_tagged("boss", "Defeat bandit leader")
        },
        failure_conditions = {
            objectives.turn_limit(),
            objectives.tagged_unit_dies("hero")
        },
        enemies = {
            { character_source = character_source.template("bandit_boss"), ai = ai.stationary, tile = "bandit_boss", tags = { "boss" } },
            { character_source = character_source.template("bandit_goon"), ai = ai.move_two, tile = "bandit_goon" },
            { character_source = character_source.template("bandit_guard"), ai = ai.stationary, tile = "bandit_miniboss_gate" },
            { character_source = character_source.template("bandit_goon"), ai = ai.stationary, tile = "bandit_miniboss_l", tags = { "spawn_child_bow" } },
            { character_source = character_source.template("bandit_goon"), ai = ai.stationary, tile = "bandit_miniboss_r", tags = { "spawn_child_axe" } },
        },
        players = {
            { character_source = character_source.player_roster(), tile = "player_deployment" },
        },
        scripts = {
            spawn_players({
                { character_source = character_source.template("militia_spear_captain"), tile = "player_captain" },
                { character_source = character_source.template("militia_spearman"), tile = "player_spearman" },
                { character_source = character_source.template("militia_archer"), tile = "player_archer" },
                { character_source = character_source.template("militia_armor"), tile = "player_armor" },
            },
                2,
                "before_player",
                "from_east"
            ),
            spawn_enemies({
                { character_source = character_source.template("bandit_goon"), ai = ai.move_inf, tile = "bandit_reinforce_l" },
            },
                3,
                3,
                "after_enemy",
                "from_west"
            ),
            spawn_enemies({
                { character_source = character_source.template("bandit_goon"), ai = ai.move_inf, tile = "bandit_reinforce_r" },
            },
                6,
                3,
                "after_enemy",
                "from_east"
            ),
            open_door_mid("bandit_miniboss_gate","bandit_miniboss_gate"),
            free_players(
                {{ character_source = character_source.template("child_bow"), tile = "bandit_miniboss_l" }},
                "spawn_child_bow",
                nil
            ),
            free_players(
                {{ character_source = character_source.template("child_axe"), tile = "bandit_miniboss_r" }},
                "spawn_child_axe",
                nil
            ),

        }
    },
    ["cultist_cave"] = {
        map_id = "cultist_cave",
        tile_labels = {
            ["player_deployment"] = { 0x00 },
            ["cultist_boss"] = { 0x10 },
            ["cultist_goon"] = { 0x12 },
            ["cultist_guard"] = { 0x11 },
            ["cultist_door_guard_b"] = { 0x13 },
            ["cultist_door_guard_c"] = { 0x14 },
            ["cultist_door_guard_d"] = { 0x15 },
            ["cultist_door_guard_e"] = { 0x16 },
            ["door_b"] = { 0x33 },
            ["door_c"] = { 0x34 },
            ["door_d"] = { 0x35 },
            ["door_e"] = { 0x36 },
            ["escape_point"] = { 0x38 },
            ["cultist_reinforce_a"] = { 0x18 },
            ["cultist_reinforce_b"] = { 0x19 },
            ["jailed_royal"] = { 0x20 },
            ["jailed_priest"] = { 0x21 },
            ["jailed_bandit"] = { 0x28 },
            ["jailed_bandit_bro"] = { 0x29 },
        },
        turn_limit = 10,
        victory_conditions = {
            objectives.escape(),
            objectives.defeat_tagged("boss", "Defeat cultist leader"),
        },
        failure_conditions = {
            objectives.turn_limit(),
            objectives.tagged_unit_dies("hero")
        },
        enemies = {
            { character_source = character_source.template("cultist_boss"), ai = ai.stationary, tile = "cultist_boss", tags = {"boss"} },
            { character_source = character_source.template("cultist_goon"), ai = ai.stationary, tile = "cultist_goon" },
            { character_source = character_source.template("cultist_guard"), ai = ai.stationary, tile = "cultist_guard" },
            { character_source = character_source.template("cultist_spearman"), ai = ai.stationary, tile = "cultist_door_guard_b" },
            { character_source = character_source.template("cultist_spearman"), ai = ai.stationary, tile = "cultist_door_guard_e" },
            { character_source = character_source.template("cultist_spearman"), ai = ai.stationary, tile = "cultist_door_guard_d" },
            { character_source = character_source.template("cultist_guard"), ai = ai.stationary, tile = "cultist_door_guard_c" },
        },
        neutral = {
            { character_source = character_source.template("old_fart"), ai = ai.stationary, tile = "jailed_priest" },
            { character_source = character_source.template("village_hero"), ai = ai.stationary, tile = "jailed_royal" },
            { character_source = character_source.template("bandit_guard"), ai = ai.move_inf, tile = "jailed_bandit" },
            { character_source = character_source.template("bandit_berzerker"), ai = ai.move_inf, tile = "jailed_bandit_bro" },
        },
        players = {
            { character_source = character_source.player_roster(), tile = "player_deployment" },
        },
        scripts = {
            spawn_enemies({
                { character_source = character_source.template("cultist_goon"), ai = ai.move_inf, tile = "cultist_reinforce_b" },
            },
                3,
                3,
                "after_enemy",
                "from_south"
            ),
            spawn_enemies({
                { character_source = character_source.template("cultist_spearman"), ai = ai.move_inf, tile = "cultist_reinforce_a" },
            },
                6,
                3,
                "after_enemy",
                "from_south"
            ),
            open_door_front("cultist_door_guard_b","door_b"),
            open_door_front("cultist_door_guard_c","door_c"),
            open_door_front("cultist_door_guard_d","door_d"),
            open_door_front("cultist_door_guard_e","door_e"),
            escape("escape_point"),
        }
    },
    ["fortress_town"] = {
        map_id = "fortress_town",
        tile_labels = {
            ["player_deployment"] = { 0x00, 0x01 },
            ["bandit_goon"] = { 0x10 },
            ["bandit_axe"] = { 0x11, 0x13 },
            ["bandit_boss"] = { 0x18 },
            ["bandit_reinforce_w"] = { 0x11 },
            ["bandit_reinforce_sw"] = { 0x01 },
            ["civilian_sword"] = { 0x20 },
            ["civilian_axe"] = { 0x21 },
            ["civilian_noncombatant"] = { 0x22 },
            ["barricade"] = { 0x30 },
            ["militia_armor"] = { 0x2A },
            ["militia_bow"] = { 0x2B },
            ["militia_sword"] = { 0x2C },
            ["militia_boss"] = { 0x2D },
            ["monarch"] = { 0x29 },
            ["counselor"] = { 0x29 }
        },
        turn_limit = 10,
        victory_conditions = {
            objectives.defeat_tagged("boss", "Defeat bandit and militia leaders"),
        },
        failure_conditions = {
            objectives.turn_limit(),
            objectives.tagged_unit_dies("hero")
        },
        deployment = {
            deployment_tiles_tag = "player_deployment",
        },
        enemies = {
            { character_source = character_source.template("bandit_berzerker"), ai = ai.stationary, tile = "bandit_boss", tags = {"boss"} },
            { character_source = character_source.template("bandit_goon"), ai = ai.move_two, tile = "bandit_goon" },
            { character_source = character_source.template("bandit_axe"), ai = ai.move_one, tile = "bandit_axe" }
        },
        neutral = {
            -- civilians
            { character_source = character_source.template("civilian"), ai = ai.stationary, tile = "civilian_noncombatant", tags = {"civilian"} },
            { character_source = character_source.template("child_greatsword"), ai = ai.stationary, tile = "civilian_sword", tags = {"civilian"} },
            { character_source = character_source.template("village_axe"), ai = ai.stationary, tile = "civilian_axe", tags = {"civilian"} },
            -- militia who turn enemy
            { character_source = character_source.template("militia_armor"), ai = ai.stationary_neutral, tile = "militia_armor", tags = {"enemy_militia_stationairy"}},
            { character_source = character_source.template("militia_archer"), ai = ai.stationary_neutral, tile = "militia_bow", tags = {"enemy_militia_moblie"}},
            { character_source = character_source.template("militia_sword"), ai = ai.stationary_neutral, tile = "militia_sword", tags = {"enemy_militia_moblie"}},
            { character_source = character_source.template("militia_sword_captain"), ai = ai.stationary_neutral, tile = "militia_boss", tags = {"enemy_militia_stationairy", "boss"}}
            -- story units
            -- { character_source = character_source.template("monarch"), ai = ai.stationary_neutral, tile = "monarch" }
            -- { character_source = character_source.template("counselor"), ai = ai.stationary_neutral, tile = "counselor" }
        },
        players = {},
        scripts = {
            spawn_enemies({
                { character_source = character_source.template("bandit_axe"), ai = ai.move_inf, tile = "cultist_reinforce_w" },
            },
                6,
                3,
                "after_enemy",
                "from_west"
            ),
            spawn_enemies({
                { character_source = character_source.template("bandit_axe"), ai = ai.move_inf, tile = "bandit_reinforce_sw" },
            },
                3,
                3,
                "after_enemy",
                "from_west"
            ),
            modify_units(
                4,
                "after_enemy",
                "enemy_militia_stationary",
                ai.move_zero,
                "enemy"
            ),
            modify_units(
                4,
                "after_enemy",
                "enemy_militia_mobile",
                ai.move_inf,
                "enemy"
            ),
        }
    },
    ["cliff_crossing"] = {
        map_id = "cliff_crossing",
        tile_labels = {
            ["player_deployment"] = { 0x00, 0x01, 0x02 },
            ["bandit_boulder"] = { 0x17 },
            ["bandit_goon"] = { 0x10 },
            ["cultist_goon"] = { 0x11 },
            ["bandit_guard"] = { 0x12 },
            ["cultist_guard"] = { 0x13 },
            ["enemy_reinforce_e"] = { 0x18 },
            ["enemy_reinforce_se"] = { 0x19 },
            ["enemy_reinforce_sw_goon"] = { 0x01 },
            ["enemy_reinforce_sw_boss"] = { 0x02 },
            ["escape_point"] = { 0x38 },
        },
        turn_limit = 10,
        victory_conditions = {
            objectives.escape()
        },
        failure_conditions = {
            objectives.turn_limit(),
            objectives.tagged_unit_dies("hero")
        },
        enemies = {
            { character_source = character_source.template("bandit_boulder"), ai = ai.move_inf, tile = "bandit_boulder", tags = { "boss" } },
            { character_source = character_source.template("bandit_axe"), ai = ai.move_two, tile = "bandit_goon" },
            { character_source = character_source.template("cultist_spearman"), ai = ai.move_two, tile = "cultist_goon" },
            { character_source = character_source.template("bandit_guard"), ai = ai.stationary, tile = "bandit_guard" },
            { character_source = character_source.template("cultist_guard"), ai = ai.stationary, tile = "cultist_guard" },
        },
        players = {
            { character_source = character_source.player_roster(), tile = "player_deployment" },
        },
        scripts = {
            spawn_enemies({
                { character_source = character_source.template("bandit_axe"), ai = ai.move_inf, tile = "enemy_reinforce_se" },
            },
                2,
                2,
                "after_enemy",
                "from_east"
            ),
            spawn_enemies({
                { character_source = character_source.template("cultist_spearman"), ai = ai.move_inf, tile = "enemy_reinforce_se" },
            },
                3,
                2,
                "after_enemy",
                "from_east"
            ),
            spawn_enemies({
                { character_source = character_source.template("bandit_axe"), ai = ai.move_inf, tile = "enemy_reinforce_e" },
            },
                5,
                2,
                "after_enemy",
                "from_east"
            ),
            spawn_enemies({
                { character_source = character_source.template("cultist_spearman"), ai = ai.move_inf, tile = "enemy_reinforce_e" },
            },
                6,
                2,
                "after_enemy",
                "from_east"
            ),
            spawn_enemies({
                { character_source = character_source.template("bandit_axe"), ai = ai.move_inf, tile = "enemy_reinforce_sw_goon" },
            },
                6,
                nil,
                "after_enemy",
                "from_west"
            ),
            spawn_enemies({
                { character_source = character_source.template("bandit_berzerker"), ai = ai.move_inf, tile = "enemy_reinforce_sw_boss" },
            },
                6,
                nil,
                "after_enemy",
                "from_west"
            ),
            escape("escape_point"),
        }
    }
}

return BATTLE_DATA
