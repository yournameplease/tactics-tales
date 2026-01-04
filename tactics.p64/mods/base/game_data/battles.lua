local ai <const> = {
    default = { move = "two", target = "player"},
    move_one = { move = "one", target = "player"},
    move_two = { move = "two", target = "player"},
    move_inf = { move = "infinity", target = "player"},
    stationary = { move = "zero", target = "player"}
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
    }
    return self
end

function objectives.defeat_tagged(tag)
    local self = {
        type = "defeat_tagged",
        tag = tag,
    }
    return self
end

function objectives.survive(turn_limit)
    local self = {
        type = "survive",
		turn_limit = turn_limit
    }
    return self
end

function objectives.escape()
    local self = {
        type = "escape",
    }
    return self
end


function objectives.all_players_die()
    local self = {
        type = "all_players_die",
    }
    return self
end

function objectives.tagged_player_dies(tag)
    local self = {
        type = "tagged_player_dies",
        tag = tag,
    }
    return self
end

function objectives.turn_limit(turn_limit)
    local self = {
        type = "turn_limit",
		turn_limit = turn_limit
    }
    return self
end

local scripts = {
    trigger = {},
    script = {}
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

function scripts.script.spawn_units(
	trigger,
	players,
	enemies,
	animation
)
	return {
		type = "spawn_units",
		trigger = trigger,
		players = players,
		enemies = enemies,
		animation = animation,
	}
end

function scripts.script.modify_terrain(
	trigger,
	tile_label,
	new_terrain
)
	return {
		type = "modify_terrain",
		trigger = trigger,
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
    return scripts.script.spawn_units(
        scripts.trigger.turn(turn, nil, phase),
        players,
        {},
        animation
    )
end

local function free_players(
    players,
    unit_label,
    animation
)
    return scripts.script.spawn_units(
        scripts.trigger.unit_death(unit_label),
        players,
        {},
        animation
    )
end

local function spawn_enemies(
    enemies,
    turn,
    repeating, --nillable
    phase,
    animation
)
    return scripts.script.spawn_units(
        scripts.trigger.turn(turn, repeating, phase),
        {},
        enemies,
        animation
    )
end

local function open_door_front(
    enemy_label,
    tile_label
)
    return scripts.script.modify_terrain(
        scripts.trigger.unit_death(enemy_label),
        tile_label,
        {
            ["front_wall"] = 0
        }
    )
end

local function open_door_mid(
    enemy_label,
    tile_label
)
    return scripts.script.modify_terrain(
        scripts.trigger.unit_death(enemy_label),
        tile_label,
        {
            ["mid_wall"] = 0
        }
    )
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
        victory_conditions = {
            objectives.defeat_tagged("boss")
        },
        failure_conditions = {
            objectives.turn_limit(10)
        },
        enemies = {
            { character_source = character_template("bandit_boss"), ai = ai.stationary, tile = "bandit_boss", tags = { "boss" } },
            { character_source = character_template("bandit_goon"), ai = ai.move_two, tile = "bandit_goon" },
            { character_source = character_template("bandit_guard"), ai = ai.stationary, tile = "bandit_miniboss_gate" },
            { character_source = character_template("bandit_goon"), ai = ai.stationary, tile = "bandit_miniboss_l" },
            { character_source = character_template("bandit_goon"), ai = ai.stationary, tile = "bandit_miniboss_r" },
        },
        players = {
            { character_source = player_roster(), tile = "player_deployment" },
        },
        scripts = {
            spawn_players({
                { character_source = character_template("militia_captain"), tile = "player_captain" },
                { character_source = character_template("militia_spearman"), tile = "player_spearman" },
                { character_source = character_template("militia_archer"), tile = "player_archer" },
                { character_source = character_template("militia_armor"), tile = "player_armor" },
            },
                2,
                "before_player",
                "from_east"
            ),
            spawn_enemies({
                { character_source = character_template("bandit_goon"), ai = ai.move_inf, tile = "bandit_reinforce_l" },
            },
                3,
                3,
                "after_enemy",
                "from_west"
            ),
            spawn_enemies({
                { character_source = character_template("bandit_goon"), ai = ai.move_inf, tile = "bandit_reinforce_r" },
            },
                6,
                3,
                "after_enemy",
                "from_east"
            ),
            open_door_mid("bandit_miniboss_gate","bandit_miniboss_gate"),
            free_players(
                {{ character_source = character_template("child_bow"), tile = "bandit_miniboss_l" }},
                "bandit_miniboss_l",
                nil
            ),
            free_players(
                {{ character_source = character_template("child_axe"), tile = "bandit_miniboss_r" }},
                "bandit_miniboss_r",
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
            ["cultist_reinforce_a"] = { 0x18 },
            ["cultist_reinforce_b"] = { 0x19 },
            ["jailed_royal"] = { 0x20 },
            ["jailed_priest"] = { 0x21 },
            ["jailed_bandit"] = { 0x28 },
            ["jailed_bandit_bro"] = { 0x29 },
        },
        victory_conditions = {
            objectives.defeat_tagged("boss"),
            objectives.escape(),
        },
        failure_conditions = {
            objectives.turn_limit(10),
        },
        enemies = {
            { character_source = character_template("cultist_boss"), ai = ai.stationary, tile = "cultist_boss", tags = {"boss"} },
            { character_source = character_template("cultist_goon"), ai = ai.stationary, tile = "cultist_goon" },
            { character_source = character_template("cultist_guard"), ai = ai.stationary, tile = "cultist_guard" },
            { character_source = character_template("cultist_spearman"), ai = ai.stationary, tile = "cultist_door_guard_b" },
            { character_source = character_template("cultist_spearman"), ai = ai.stationary, tile = "cultist_door_guard_e" },
            { character_source = character_template("cultist_spearman"), ai = ai.stationary, tile = "cultist_door_guard_d" },
            { character_source = character_template("cultist_guard"), ai = ai.stationary, tile = "cultist_door_guard_c" },
        },
        neutral = {
            { character_source = character_template("old_fart"), ai = ai.stationary, tile = "jailed_priest" },
            { character_source = character_template("village_hero"), ai = ai.stationary, tile = "jailed_royal" },
            { character_source = character_template("bandit_guard"), ai = ai.move_inf, tile = "jailed_bandit" },
            { character_source = character_template("bandit_berzerker"), ai = ai.move_inf, tile = "jailed_bandit_bro" },
        },
        players = {
            { character_source = player_roster(), tile = "player_deployment" },
        },
        scripts = {
            spawn_enemies({
                { character_source = character_template("cultist_goon"), ai = ai.move_inf, tile = "cultist_reinforce_b" },
            },
                3,
                3,
                "after_enemy",
                "from_south"
            ),
            spawn_enemies({
                { character_source = character_template("cultist_spear"), ai = ai.move_inf, tile = "cultist_reinforce_a" },
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
        }
    }
}

return BATTLE_DATA
