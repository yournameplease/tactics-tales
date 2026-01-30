local script = lib.libs.script
local script_unit = script.unit

local ai <const> = {
    default = { move = "two", target_side = "player"},
    move_one = { move = "one", target_side = "player"},
    move_two = { move = "two", target_side = "player"},
    move_inf = { move = "infinity", target_side = "player"},
    stationary = { move = "zero", target_side = "player"},
    stationary_allied = { move = "zero", target_side = "enemy"},
    move_inf_allied = { move = "infinity", target_side = "enemy"},
    stationary_neutral = { move = "zero", target_side = nil }
}

local phase <const> = {
    before_player = { offset = "before", side = "player"},
    after_player = { offset = "after", side = "player"},
    before_enemy = { offset = "before", side = "enemy"},
    after_enemy = { offset = "after", side = "enemy"},
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


local function open_door_mid(
    enemy_label,
    tile_label
)
    return script.when_unit_dies(enemy_label)
        :then_modify_terrain(tile_label, {["mid_wall"] = 0})
end

function escape(tile_tag)
    return script.on_tile_interaction(tile_tag)
        :then_dialogue(script_unit.source(), "I'm retreating")
        :then_despawn_units(script_unit.source())
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
            script.on_turn(2, phase.before_player)
                :then_spawn_players({
                    { character_source = character_source.template("militia_spear_captain"), tile = "player_captain" },
                    { character_source = character_source.template("militia_spearman"), tile = "player_spearman" },
                    { character_source = character_source.template("militia_archer"), tile = "player_archer" },
                    { character_source = character_source.template("militia_armor"), tile = "player_armor" },
                },
                "from_east"
            ),
            script.on_turn(3, phase.after_enemy, 3)
                :then_spawn_enemies({
                    { character_source = character_source.template("bandit_goon"), ai = ai.move_inf, tile = "bandit_reinforce_l" },
                },
                "from_west"
            ),
            script.on_turn(6, phase.after_enemy, 3)
                :then_spawn_enemies({
                    { character_source = character_source.template("bandit_goon"), ai = ai.move_inf, tile = "bandit_reinforce_r" },
                },
                "from_east"
            ),
            script.when_unit_dies("bandit_miniboss_gate")
                :then_modify_terrain("bandit_miniboss_gate", {["mid_wall"] = 0}),
            script.when_unit_dies("spawn_child_bow")
                :then_spawn_players({{ character_source = character_source.template("child_bow"), tile = "bandit_miniboss_l" }}, nil),
            script.when_unit_dies("spawn_child_axe")
                :then_spawn_players({{ character_source = character_source.template("child_axe"), tile = "bandit_miniboss_r" }}, nil),
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
            ["room_b_ceiling"] = { 0x30, 0x11, 0x10 },
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
        deployment = {
            deployment_tiles_tag = "player_deployment",
        },
        enemies = {
            { character_source = character_source.template("cultist_boss"), ai = ai.stationary, tile = "cultist_boss", tags = {"boss"} },
            { character_source = character_source.template("cultist_goon"), ai = ai.move_two, tile = "cultist_goon" },
            { character_source = character_source.template("cultist_guard"), ai = ai.stationary, tile = "cultist_guard" },
            { character_source = character_source.template("cultist_guard"), ai = ai.stationary, tile = "cultist_door_guard_b" },
            { character_source = character_source.template("cultist_spearman"), ai = ai.stationary, tile = "cultist_door_guard_c" },
            { character_source = character_source.template("cultist_spearman"), ai = ai.stationary, tile = "cultist_door_guard_d" },
            { character_source = character_source.template("cultist_spearman"), ai = ai.stationary, tile = "cultist_door_guard_e" },
        },
        neutral = {
            { character_source = character_source.template("old_fart"), ai = ai.stationary, tile = "jailed_priest", tags = {"room_c"}  },
            { character_source = character_source.template("village_hero"), ai = ai.stationary, tile = "jailed_royal", tags = {"room_d"}  },
            { character_source = character_source.template("bandit_guard"), ai = ai.move_inf, tile = "jailed_bandit", tags = {"room_e", "bandit"}  },
            { character_source = character_source.template("bandit_berzerker"), ai = ai.move_inf, tile = "jailed_bandit_bro", tags = {"room_e", "bandit"} },
        },
        players = {
        },
        scripts = {
            script.on_turn(3, phase.after_enemy, 3)
                :then_spawn_enemies({
                    { character_source = character_source.template("cultist_goon"), ai = ai.move_inf, tile = "cultist_reinforce_b" },
                },
                "from_south"
            ),
            script.on_turn(6, phase.after_enemy, 3)
                :then_spawn_enemies({
                    { character_source = character_source.template("cultist_spearman"), ai = ai.move_inf, tile = "cultist_reinforce_a" },
                },
                "from_south"
            ),
            script.when_unit_dies("cultist_door_guard_b")
                :then_modify_terrain("door_b", {["front_wall"] = 0})
                :then_modify_terrain("door_b_ceiling", {["ceiling"] = 0})
                :then_dialogue(script_unit.tagged("cultist_boss"), {"Intruders?", "Attack!", "Don't let them escape!"}),
            script.when_unit_dies("cultist_door_guard_c")
                :then_modify_terrain("door_c", {["front_wall"] = 0})
                :then_dialogue(script_unit.tagged("jailed_priest"), {"Thank you for freeing me.", "Please, let me join and tend to your wounded."})
                :then_recruit_unit(script_unit.tagged("jailed_priest")),
            script.when_unit_dies("cultist_door_guard_d")
                :then_modify_terrain("door_d", {["front_wall"] = 0})
                :then_dialogue(script_unit.tagged("jailed_royal"), {"Those cultists worked with bandits to capture me.", "They should hate each other!", "Something dark is looming.",  "Allow me to travel with you to seek the truth."})
                :then_recruit_unit(script_unit.tagged("jailed_royal")),
            script.when_unit_dies("cultist_door_guard_e")
                :then_modify_terrain("door_e", {["front_wall"] = 0})
                :then_dialogue(script_unit.tagged("jailed_bandit_bro"), {"Aaaaaaargh, I'm gonna kill those cultists!"})
                :then_dialogue(script_unit.tagged("jailed_bandit"), {"Don't leave me behind, boss!"})
                :then_change_ai(script_unit.tagged("bandit"), ai.move_inf_allied),
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
            { character_source = character_source.template("child_greatsword"), ai = ai.move_inf_allied, tile = "civilian_sword", tags = {"civilian"} },
            { character_source = character_source.template("village_axe"), ai = ai.move_inf_allied, tile = "civilian_axe", tags = {"civilian"} },
            -- militia who turn enemy
            { character_source = character_source.template("militia_armor"), ai = ai.stationary_neutral, tile = "militia_armor", tags = {"enemy_militia_stationary"}},
            { character_source = character_source.template("militia_archer"), ai = ai.stationary_neutral, tile = "militia_bow", tags = {"enemy_militia_moblie"}},
            { character_source = character_source.template("militia_sword"), ai = ai.stationary_neutral, tile = "militia_sword", tags = {"enemy_militia_moblie"}},
            { character_source = character_source.template("militia_sword_captain"), ai = ai.stationary_neutral, tile = "militia_boss", tags = {"enemy_militia_stationary", "boss"}}
            -- story units
            -- { character_source = character_source.template("monarch"), ai = ai.stationary_neutral, tile = "monarch" }
            -- { character_source = character_source.template("counselor"), ai = ai.stationary_neutral, tile = "counselor" }
        },
        players = {},
        scripts = {
            script.on_turn(6, phase.after_enemy)
                :then_spawn_enemies({
                    { character_source = character_source.template("bandit_axe"), ai = ai.move_inf, tile = "cultist_reinforce_w" },
                },
                "from_west"
            ),
            script.on_turn(3, phase.after_enemy, 3)
                :then_spawn_enemies({
                    { character_source = character_source.template("bandit_axe"), ai = ai.move_inf, tile = "bandit_reinforce_sw" },
                },
                phase.after_enemy,
                "from_west"
            ),
            script.on_turn(3, phase.after_enemy)
                :then_dialogue(script_unit.tagged("militia_boss"),{"This is taking too long...", "Clear out these pests!"})
                :then_modify_units(
                    "enemy_militia_stationary",
                    ai.move_zero,
                    "enemy"
                )
                :then_modify_units(
                    "enemy_militia_mobile",
                    ai.move_inf,
                    "enemy"
            )
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
        deployment = {
            deployment_tiles_tag = "player_deployment",
        },
        enemies = {
            { character_source = character_source.template("bandit_boulder"), ai = ai.move_inf, tile = "bandit_boulder", tags = { "boss" } },
            { character_source = character_source.template("bandit_axe"), ai = ai.move_two, tile = "bandit_goon" },
            { character_source = character_source.template("cultist_spearman"), ai = ai.move_two, tile = "cultist_goon" },
            { character_source = character_source.template("bandit_guard"), ai = ai.stationary, tile = "bandit_guard" },
            { character_source = character_source.template("cultist_guard"), ai = ai.stationary, tile = "cultist_guard" },
        },
        players = {
        },
        scripts = {
            script.on_turn(2, phase.after_enemy, 2)
                :then_spawn_enemies({
                    { character_source = character_source.template("bandit_axe"), ai = ai.move_inf, tile = "enemy_reinforce_se" },
                },
                "from_east"
            ),
            script.on_turn(3, phase.after_enemy, 2)
                :then_spawn_enemies({
                    { character_source = character_source.template("cultist_spearman"), ai = ai.move_inf, tile = "enemy_reinforce_se" },
                },
                "from_east"
            ),
            script.on_turn(5, phase.after_enemy, 2)
                :then_spawn_enemies({
                    { character_source = character_source.template("bandit_axe"), ai = ai.move_inf, tile = "enemy_reinforce_e" },
                },
                "from_east"
            ),
            script.on_turn(6, phase.after_enemy, 2)
                :then_spawn_enemies({
                    { character_source = character_source.template("cultist_spearman"), ai = ai.move_inf, tile = "enemy_reinforce_e" },
                },
                "from_east"
            ),
            script.on_turn(6, phase.after_enemy)
                :then_spawn_enemies({
                    { character_source = character_source.template("bandit_berzerker"), ai = ai.move_inf, tile = "enemy_reinforce_sw_boss" },
                },
                "from_west"
                )
                :then_spawn_enemies({
                    { character_source = character_source.template("bandit_axe"), ai = ai.move_inf, tile = "enemy_reinforce_sw_goon" },
                },
                "from_west"
            ),
            escape("escape_point"),
        }
    }
}

return BATTLE_DATA
