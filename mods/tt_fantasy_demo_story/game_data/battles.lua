local script = lib.libs.script
local script_unit = script.unit

local ai <const> = {
    default = { move = "two", target_sides = {"player", "neutral"}, exclude_tags = {"neutral_enemy"}},
    move_one = { move = "one", target_sides = {"player", "neutral"}, exclude_tags = {"neutral_enemy"}},
    move_two = { move = "two", target_sides = {"player", "neutral"}, exclude_tags = {"neutral_enemy"}},
    move_inf = { move = "infinity", target_sides = {"player", "neutral"}, exclude_tags = {"neutral_enemy"}},
    stationary = { move = "zero", target_sides = {"player", "neutral"}, exclude_tags = {"neutral_enemy"}},
    stationary_allied = { move = "zero", target_sides = {"enemy"}},
    move_one_allied = { move = "one", target_sides = {"enemy"}},
    move_inf_allied = { move = "infinity", target_sides = {"enemy"}},
    stationary_neutral = { move = "zero", target_sides = {} }
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

local function escape(tile_tag)
    return script.on_tile_interaction(tile_tag, "Escape")
        :then_dialogue(script_unit.source(), {"I'm retreating"})
        :then_despawn_units(script_unit.source())
end


---@type ModBattlesModule
local BATTLE_DATA = {
    ["bandit_village"] = function(campaign_config)
        local turn_limits = {
            easy = nil,
            normal = 15,
            hard = 10,
        }
        local turn_limit = turn_limits[campaign_config.turn_difficulty or "normal"]

        local failure_conditions = {
            objectives.tagged_unit_dies("hero"),
        }
        if turn_limit then
            table.insert(failure_conditions, objectives.turn_limit())
        end
        
        return {
            map_id = "bandit_village",
            music = 0,
            tile_labels = {
                ["player_deployment"] = { 0x00 },
                ["bandit_boss"] = { 0x1E },
                ["bandit_goon"] = { 0x11 },
                ["bandit_first_goon"] = { 0x13 },
                ["bandit_reinforce_l"] = { 0x18 },
                ["bandit_reinforce_r"] = { 0x19 },
                ["bandit_miniboss_gate"] = { 0x1A },
                ["bandit_miniboss_l"] = { 0x1B },
                ["bandit_miniboss_r"] = { 0x1C },
                ["player_captain"] = { 0x20 },
                ["player_spearman"] = { 0x08 },
                ["player_archer"] = { 0x09 },
                ["player_armor"] = { 0x0A },
            },
            turn_limit = turn_limit,
            victory_conditions = {
                objectives.defeat_tagged("boss", "Defeat bandit leader")
            },
            failure_conditions = failure_conditions,
            units = {
                { side = "enemy", character_source = character_source.template("bandit_boss"), ai = ai.stationary, tile = "bandit_boss", tags = { "boss" } },
                { side = "enemy", character_source = character_source.template("bandit_goon"), ai = ai.move_two, tile = "bandit_goon" },
                { side = "enemy", character_source = character_source.template("bandit_goon"), ai = ai.move_two, tile = "bandit_first_goon" },
                { side = "enemy", character_source = character_source.template("bandit_guard"), ai = ai.stationary, tile = "bandit_miniboss_gate" },
                { side = "enemy", character_source = character_source.template("bandit_goon"), ai = ai.stationary, tile = "bandit_miniboss_l", tags = { "spawn_child_bow" } },
                { side = "enemy", character_source = character_source.template("bandit_goon"), ai = ai.stationary, tile = "bandit_miniboss_r", tags = { "spawn_child_axe" } },
                { side = "neutral", movement_side = "player", character_source = character_source.template("militia_spear_captain"), ai = ai.stationary, tile = "player_captain" },
            },
            scripts = {
                script.on_turn(1, phase.before_player)
                    :then_set_tutorial(true)
                    :then_spawn_units({
                        { side = "player", character_source = character_source.player_roster(), tile = "player_deployment" }
                    },
                    "from_west"
                )
                :then_dialogue(script_unit.tagged("player_captain"), {
                    "Help me save this village!",
                    "Come talk to me!",
                }),
                script.on_turn(1, phase.after_player)
                    :then_set_tutorial(false),
                script.on_talk("player_captain")
                    :then_play_music("recruit")
                    :then_dialogue(script_unit.tagged("player_captain"), {"I already called for reinforcements.", "Let me attack that bandit.", "My spear avoids counterattacks."})
                    :then_recruit_unit(script_unit.tagged("player_captain"))
                    :then_resume_music()
                    :as_one_shot(),
                script.on_turn(2, phase.before_player)
                    :then_spawn_units({
                        -- { side = "player", character_source = character_source.template("militia_spear_captain"), tile = "player_captain" },
                        { side = "player", character_source = character_source.template("militia_spearman"), tile = "player_spearman" },
                        { side = "player", character_source = character_source.template("militia_archer"), tile = "player_archer" },
                        { side = "player", character_source = character_source.template("militia_armor"), tile = "player_armor" },
                    },
                    "from_east"
                )
                :then_play_music("recruit")
                :then_dialogue(script_unit.tagged("player_captain"), {
                    "My reinforcements have arrived!",
                    "Defeat the leader to save this village!"
                })
                :then_resume_music(),
                script.on_turn(3, phase.after_enemy, 3)
                    :then_spawn_units({
                        { side = "enemy", character_source = character_source.template("bandit_goon"), ai = ai.move_inf, tile = "bandit_reinforce_l" },
                    },
                    "from_west"
                ),
                script.on_turn(6, phase.after_enemy, 3)
                    :then_spawn_units({
                        { side = "enemy", character_source = character_source.template("bandit_goon"), ai = ai.move_inf, tile = "bandit_reinforce_r" },
                    },
                    "from_east"
                ),
                script.before_combat("player_captain", "bandit_first_goon")
                    :then_dialogue(script_unit.source(), {"First, I attack with my spear."})
                    :as_one_shot(),
                script.before_counterattack("player_captain", "bandit_first_goon")
                    :then_dialogue(script_unit.source(), {"My long spear avoids counter- attacks!"})
                    :as_one_shot(),
                script.before_combat("bandit_first_goon", "player_captain")
                    :then_dialogue(script_unit.target(), {"They attack me now."})
                    :as_one_shot(),
                script.before_counterattack("bandit_first_goon", "player_captain")
                    :then_dialogue(script_unit.target(), {"I survived, so I can counterattack!"})
                    :as_one_shot(),
                script.when_unit_dies("bandit_miniboss_gate")
                    :then_modify_terrain("bandit_miniboss_gate", {["mid_wall"] = 0}),
                script.when_unit_dies("spawn_child_bow")
                    :then_play_music("recruit_short")
                    :then_spawn_units({
                        { side = "player", character_source = character_source.template("child_bow"), tile = "bandit_miniboss_l", tags = {"child_bow_player"} }
                    }, nil)
                    :then_dialogue(script_unit.tagged("child_bow_player"), {
                        "Thank you!",
                        "Let me fight, I'm good with a bow!",
                    })
                    :then_resume_music(),
                script.when_unit_dies("spawn_child_axe")
                    :then_play_music("recruit_short")
                    :then_spawn_units({
                        { side = "player", character_source = character_source.template("child_axe"), tile = "bandit_miniboss_r", tags = {"child_axe_player"} }
                    }, nil)
                    :then_dialogue(script_unit.tagged("child_axe_player"), {
                        "Gah, I'm free!",
                        "Those bandits will taste my axe!",
                    })
                    :then_resume_music(),
            }
        }
    end,
    ["cultist_cave"] = function(campaign_config)
        local turn_limits = {
            easy = nil,
            normal = 15,
            hard = 10,
        }
        local turn_limit = turn_limits[campaign_config.turn_difficulty or "normal"]

        local failure_conditions = {
            objectives.tagged_unit_dies("hero"),
        }
        if turn_limit then
            table.insert(failure_conditions, objectives.turn_limit())
        end
        
        return {
            map_id = "cultist_cave",
            music = 12,
            tile_labels = {
                ["player_deployment"] = { 0x00 },
                ["cultist_boss"] = { 0x10 },
                ["cultist_goon"] = { 0x12 },
                ["cultist_guard"] = { 0x11 },
                ["cultist_door_guard_b"] = { 0x13 },
                ["cultist_door_guard_c"] = { 0x14 },
                ["cultist_door_guard_d"] = { 0x15 },
                ["cultist_door_guard_e"] = { 0x16 },
                ["cultist_door_guard_f"] = { 0x17 },
                ["door_b"] = { 0x33 },
                ["room_b_ceiling"] = { 0x30, 0x12, 0x11, 0x10 },
                ["door_c"] = { 0x34 },
                ["door_d"] = { 0x35 },
                ["door_e"] = { 0x36 },
                ["door_f"] = { 0x37 },
                ["escape_point"] = { 0x38 },
                ["cultist_reinforce_w"] = { 0x18 },
                ["cultist_reinforce_e"] = { 0x19 },
                ["jailed_royal"] = { 0x20 },
                ["jailed_priest"] = { 0x21 },
                ["jailed_bandit_nerd"] = { 0x22 },
                ["jailed_bandit"] = { 0x28 },
                ["jailed_bandit_bro"] = { 0x29 },
            },
            turn_limit = turn_limit,
            victory_conditions = {
                objectives.escape(),
            },
            failure_conditions = failure_conditions,
            deployment = {
                deployment_tiles_tag = "player_deployment",
            },
            units = {
                { side = "enemy", character_source = character_source.template("cultist_boss"), ai = ai.stationary, tile = "cultist_boss", tags = {"wait_to_charge"} },
                { side = "enemy", character_source = character_source.template("cultist_goon"), ai = ai.move_two, tile = "cultist_goon" },
                { side = "enemy", character_source = character_source.template("cultist_guard"), ai = ai.move_one, tile = "cultist_guard", tags = {"wait_to_charge"} },
                { side = "enemy", character_source = character_source.template("cultist_guard"), ai = ai.stationary, tile = "cultist_door_guard_b" },
                { side = "enemy", character_source = character_source.template("cultist_spearman"), ai = ai.stationary, tile = "cultist_door_guard_c" },
                { side = "enemy", character_source = character_source.template("cultist_spearman"), ai = ai.stationary, tile = "cultist_door_guard_d" },
                { side = "enemy", character_source = character_source.template("cultist_spearman"), ai = ai.stationary, tile = "cultist_door_guard_e" },
                { side = "enemy", character_source = character_source.template("cultist_spearman"), ai = ai.stationary, tile = "cultist_door_guard_f" },
                { side = "neutral", movement_side = "player", character_source = character_source.template("militia_spearman"), ai = ai.stationary_neutral, tile = "jailed_priest", tags = {"room_c"}  },
                { side = "neutral", movement_side = "player", character_source = character_source.template("village_hero"), ai = ai.stationary_neutral, tile = "jailed_royal", tags = {"room_d"}  },
                { side = "neutral", movement_side = "player", character_source = character_source.template("bandit_nerd"), ai = ai.stationary_neutral, tile = "jailed_bandit_nerd", tags = {"room_f"}  },
                { side = "neutral", movement_side = "player", character_source = character_source.template("bandit_guard"), ai = ai.move_inf_allied, tile = "jailed_bandit", tags = {"room_e", "bandit"}  },
                { side = "neutral", movement_side = "player", character_source = character_source.template("bandit_berzerker"), ai = ai.move_inf_allied, tile = "jailed_bandit_bro", tags = {"room_e", "bandit"} },
            },
            scripts = {
                script.on_turn(2, phase.after_enemy, 3)
                    :then_spawn_units({
                        { side = "enemy", character_source = character_source.template("cultist_goon"), ai = ai.move_inf, tile = "cultist_reinforce_w" },
                    }, "from_west"
                    )
                    :then_spawn_units({
                        { side = "enemy", character_source = character_source.template("cultist_goon"), ai = ai.move_inf, tile = "cultist_reinforce_e" },
                    }, "from_east"),
                script.on_turn(5, phase.after_enemy, 3)
                    :then_spawn_units({
                        { side = "enemy", character_source = character_source.template("cultist_goon"), ai = ai.move_inf, tile = "cultist_reinforce_w" },
                    }, "from_west"
                    )
                    :then_spawn_units({
                        { side = "enemy", character_source = character_source.template("cultist_goon"), ai = ai.move_inf, tile = "cultist_reinforce_e" },
                    }, "from_east"),
                script.when_unit_dies("cultist_door_guard_c")
                    :then_play_music("recruit_short")
                    :then_modify_terrain("door_c", {["front_wall"] = 0})
                    :then_dialogue(script_unit.tagged("jailed_priest"), {
                        "Thank you for freeing me.",
                        "Please, let me join and fight with you."
                    })
                    :then_recruit_unit(script_unit.tagged("jailed_priest"))
                    :then_resume_music(),
                script.when_unit_dies("cultist_door_guard_f")
                    :then_play_music("recruit_short")
                    :then_modify_terrain("door_f", {["front_wall"] = 0})
                    :then_dialogue(script_unit.tagged("jailed_bandit_nerd"), {
                        "Those other bandits are too noisy for me.",
                        "Why don't I join you instead?"
                    })
                    :then_recruit_unit(script_unit.tagged("jailed_bandit_nerd"))
                    :then_resume_music(),
                script.when_unit_dies("cultist_door_guard_d")
                    :then_modify_terrain("door_d", {["front_wall"] = 0})
                    :then_play_music("recruit_short")
                    :then_dialogue(script_unit.tagged("jailed_royal"), {
                        "Those cultists worked with bandits.",
                        "They should hate each other!",
                        "Something dark is looming.",
                        "Allow me to travel with you."
                    })
                    :then_recruit_unit(script_unit.tagged("jailed_royal"))
                    :then_resume_music(),
                script.when_unit_dies("cultist_door_guard_e")
                    :then_modify_terrain("door_e", {["front_wall"] = 0})
                    :then_dialogue(script_unit.tagged("jailed_bandit_bro"), {"Aaaaaaargh, I'm gonna kill those cultists!"})
                    :then_dialogue(script_unit.tagged("jailed_bandit"), {"Don't leave me behind, boss!"}),
                script.on_turn(1, phase.before_enemy)
                    :then_dialogue(
                        script_unit.tagged("cultist_boss"),
                        {"Intruders?", "Get rid of them, my followers!"}),
                script.on_turn(8, phase.after_enemy)
                    :then_dialogue(
                        script_unit.tagged("cultist_boss"),
                        {"Why are the intruders still here?", "I guess we should get involved."})
                    :then_modify_units(
                        script_unit.tagged("wait_to_charge"),
                        ai.move_inf,
                        nil
                    ),
                escape("escape_point"),
            }
        }
    end,
    ["fortress_town"] = function(campaign_config)
        local turn_limits = {
            easy = nil,
            normal = 15,
            hard = 10,
        }
        local turn_limit = turn_limits[campaign_config.turn_difficulty or "normal"]

        local failure_conditions = {
            objectives.tagged_unit_dies("hero"),
        }
        if turn_limit then
            table.insert(failure_conditions, objectives.turn_limit())
        end
        
        return {
            map_id = "fortress_town",
            music = 0,
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
            turn_limit = turn_limit,
            victory_conditions = {
                objectives.defeat_tagged("boss", "Defeat bandit and militia leaders"),
            },
            failure_conditions = failure_conditions,
            deployment = {
                deployment_tiles_tag = "player_deployment",
            },
            units = {
                { side = "enemy", character_source = character_source.template("bandit_berzerker"), ai = ai.stationary, tile = "bandit_boss", tags = {"boss", "enemy_bandit_waiting"} },
                { side = "enemy", character_source = character_source.template("bandit_goon"), ai = ai.move_two, tile = "bandit_goon" },
                { side = "enemy", character_source = character_source.template("bandit_axe"), ai = ai.move_one, tile = "bandit_axe", tags = {"enemy_bandit_waiting"} },
                -- civilians
                { side = "neutral", movement_side = "player", character_source = character_source.template("civilian"), ai = ai.stationary, tile = "civilian_noncombatant", tags = {"civilian"} },
                { side = "neutral", movement_side = "player", character_source = character_source.template("child_greatsword"), ai = ai.stationary_allied, tile = "civilian_sword", tags = {"civilian"} },
                { side = "neutral", movement_side = "player", character_source = character_source.template("village_axe"), ai = ai.stationary_allied, tile = "civilian_axe", tags = {"civilian"} },
                -- militia who turn enemy
                { side = "enemy", movement_side = "enemy", character_source = character_source.template("militia_spear_captain"), ai = ai.stationary_neutral, tile = "militia_armor", tags = {"enemy_militia_stationary", "neutral_enemy"}},
                { side = "enemy", movement_side = "enemy", character_source = character_source.template("militia_archer"), ai = ai.stationary_neutral, tile = "militia_bow", tags = {"enemy_militia_mobile", "neutral_enemy"}},
                { side = "enemy", movement_side = "enemy", character_source = character_source.template("militia_spearman"), ai = ai.stationary_neutral, tile = "militia_sword", tags = {"enemy_militia_mobile", "neutral_enemy"}},
                { side = "enemy", movement_side = "enemy", character_source = character_source.template("militia_sword_captain"), ai = ai.stationary_neutral, tile = "militia_boss", tags = {"enemy_militia_stationary", "neutral_enemy", "boss"}},
            },
            scripts = {
                script.on_turn(1, phase.before_player)
                    :then_dialogue(
                        script_unit.tagged("militia_boss"),
                        {"We'll let the bandits soften them up.", "Move to attack on my command."}),
                script.on_turn(6, phase.after_enemy)
                    :then_spawn_units({
                        { side = "enemy", character_source = character_source.template("bandit_goon"), ai = ai.move_inf, tile = "cultist_reinforce_w" },
                    },
                    "from_west"
                ),
                script.on_turn(3, phase.after_enemy, 3)
                    :then_spawn_units({
                        { side = "enemy", character_source = character_source.template("bandit_goon"), ai = ai.move_inf, tile = "bandit_reinforce_sw" },
                    },
                    "from_west"
                ),
                script.on_turn(4, phase.after_enemy)
                    :then_dialogue(
                        script_unit.tagged("militia_boss"),
                        {"This is taking too long...", "Clear out these pests!"})
                    :then_modify_units(
                        script_unit.tagged("enemy_militia_stationary"),
                        ai.stationary,
                        nil
                    )
                    :then_modify_units(
                        script_unit.tagged("enemy_militia_mobile"),
                        ai.move_inf,
                        nil
                    )
                    :then_modify_units(
                        script_unit.tagged("enemy_bandit_waiting"),
                        ai.move_inf,
                        nil
                    ),
                script.on_talk("civilian_sword")
                    :with_tags{"recruit_civilians"}
                    :then_play_music("recruit")
                    :then_dialogue(script_unit.tagged("civilian_sword"), {"I've been training all my life", "to stand up to the crooked militia.", "Let us join you!"})
                    :then_recruit_unit(script_unit.tagged("civilian_sword"))
                    :then_recruit_unit(script_unit.tagged("civilian_axe"))
                    :then_remove_scripts("recruit_civilians")
                    :then_resume_music()
                    :as_one_shot(),
                script.on_talk("civilian_axe")
                    :with_tags{"recruit_civilians"}
                    :then_play_music("recruit")
                    :then_dialogue(script_unit.tagged("civilian_axe"), {"So there is still good in this world.", "I will join your cause.",  "I only ask, protect the civilians."})
                    :then_recruit_unit(script_unit.tagged("civilian_axe"))
                    :then_recruit_unit(script_unit.tagged("civilian_sword"))
                    :then_remove_scripts("recruit_civilians")
                    :then_resume_music()
                    :as_one_shot(),
            }
        }
    end,
    ["cliff_crossing"] = function(campaign_config)
        local turn_limits = {
            easy = nil,
            normal = 15,
            hard = 10,
        }
        local turn_limit = turn_limits[campaign_config.turn_difficulty or "normal"]

        local failure_conditions = {
            objectives.tagged_unit_dies("hero"),
        }
        if turn_limit then
            table.insert(failure_conditions, objectives.turn_limit())
        end
        
        return {
            map_id = "cliff_crossing",
            music = 12,
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
            turn_limit = turn_limit,
            victory_conditions = {
                objectives.escape()
            },
            failure_conditions = failure_conditions,
            deployment = {
                deployment_tiles_tag = "player_deployment",
            },
            units = {
                { side = "enemy", character_source = character_source.template("bandit_boulder"), ai = ai.move_inf, tile = "bandit_boulder", tags = { } },
                { side = "enemy", character_source = character_source.template("bandit_axe"), ai = ai.move_two, tile = "bandit_goon" },
                { side = "enemy", character_source = character_source.template("cultist_spearman"), ai = ai.move_two, tile = "cultist_goon" },
                { side = "enemy", character_source = character_source.template("bandit_guard"), ai = ai.stationary, tile = "bandit_guard" },
                { side = "enemy", character_source = character_source.template("cultist_guard"), ai = ai.stationary, tile = "cultist_guard" },
            },
            scripts = {
                script.on_turn(2, phase.after_enemy, 2)
                    :then_spawn_units({
                        { side = "enemy", character_source = character_source.template("bandit_axe"), ai = ai.move_inf, tile = "enemy_reinforce_se" },
                    },
                    "from_east"
                ),
                script.on_turn(3, phase.after_enemy, 2)
                    :then_spawn_units({
                        { side = "enemy", character_source = character_source.template("cultist_spearman"), ai = ai.move_inf, tile = "enemy_reinforce_se" },
                    },
                    "from_east"
                ),
                script.on_turn(5, phase.after_enemy, 2)
                    :then_spawn_units({
                        { side = "enemy", character_source = character_source.template("bandit_axe"), ai = ai.move_inf, tile = "enemy_reinforce_e" },
                    },
                    "from_east"
                ),
                script.on_turn(6, phase.after_enemy, 2)
                    :then_spawn_units({
                        { side = "enemy", character_source = character_source.template("cultist_spearman"), ai = ai.move_inf, tile = "enemy_reinforce_e" },
                    },
                    "from_east"
                ),
                script.on_turn(6, phase.after_enemy)
                    :then_spawn_units({
                        { side = "enemy", character_source = character_source.template("bandit_berzerker"), ai = ai.move_inf, tile = "enemy_reinforce_sw_boss" },
                    },
                    "from_west"
                    )
                    :then_spawn_units({
                        { side = "enemy", character_source = character_source.template("bandit_axe"), ai = ai.move_inf, tile = "enemy_reinforce_sw_goon" },
                    },
                    "from_west"
                ),
                escape("escape_point"),
            }
        }
    end,
    ["castle_defense"] = function(campaign_config)
        local turn_limits = {
            easy = 10,
            normal = 15,
            hard = 15,
        }
        local turn_difficulty = campaign_config.turn_difficulty or "normal"
        local turn_limit = turn_limits[turn_difficulty]

        local victory_conditions = {
            objectives.defeat_tagged("boss", "Defeat all enemy leaders"),
        }
        local failure_conditions = {
            objectives.tagged_unit_dies("hero"),
            objectives.tagged_unit_dies("monarch")
        }
        if turn_difficulty == "hard" then
            table.insert(failure_conditions, objectives.turn_limit())
        else
            table.insert(victory_conditions, objectives.survive())
        end
        
        return {
            map_id = "castle_defense",
            music = 0,
            tile_labels = {
                ["player_deployment"] = { 0x00 },
                ["militia_spearman"] = { 0x10 },
                ["militia_spear_captain"] = { 0x11 },
                ["militia_boss_w"] = { 0x12 },
                ["militia_boss_e"] = { 0x13 },
                ["cultist_boss"] = { 0x14 },
                ["cultist_guard"] = { 0x15 },
                ["cultist_spearman"] = { 0x16 },
                ["cultist_goon"] = { 0x17 },
                ["bandit_boss"] = { 0x18 },
                ["bandit_guard"] = { 0x19 },
                ["bandit_axe"] = { 0x1A },
                ["bandit_goon"] = { 0x1B },
                ["bandit_reinforce"] = { 0x1E },
                ["cultist_reinforce"] = { 0x1F },
                ["militia_reinforce_a"] = { 0x1C },
                ["militia_reinforce_b"] = { 0x1D },
                ["monarch"] = { 0x20 },
                ["counselor"] = { 0x21 },
                ["friendly_militia"] = { 0x22 },
            },
            turn_limit = turn_limit,
            victory_conditions = victory_conditions,
            failure_conditions = failure_conditions,
            deployment = {
                deployment_tiles_tag = "player_deployment",
            },
            units = {
                { side = "enemy", character_source = character_source.template("bandit_berzerker"), ai = ai.stationary, tile = "bandit_boss", tags = {"boss"} },
                { side = "enemy", character_source = character_source.template("bandit_goon"), ai = ai.move_two, tile = "bandit_goon" },
                { side = "enemy", character_source = character_source.template("bandit_axe"), ai = ai.move_two, tile = "bandit_axe" },
                { side = "enemy", character_source = character_source.template("bandit_guard"), ai = ai.move_one, tile = "bandit_guard" },
                { side = "enemy", character_source = character_source.template("cultist_boss"), ai = ai.stationary, tile = "cultist_boss", tags = {"boss"} },
                { side = "enemy", character_source = character_source.template("cultist_goon"), ai = ai.move_two, tile = "cultist_goon" },
                { side = "enemy", character_source = character_source.template("cultist_spearman"), ai = ai.move_two, tile = "cultist_spearman" },
                { side = "enemy", character_source = character_source.template("cultist_guard"), ai = ai.move_one, tile = "cultist_guard" },
                { side = "enemy", character_source = character_source.template("militia_sword_captain"), ai = ai.stationary, tile = "militia_boss_w", tags = {"boss"} },
                { side = "enemy", character_source = character_source.template("militia_spear_captain"), ai = ai.move_two, tile = "militia_spear_captain" },
                { side = "enemy", character_source = character_source.template("militia_spearman"), ai = ai.move_two, tile = "militia_spearman" },
                { side = "enemy", character_source = character_source.template("militia_armor"), ai = ai.move_one, tile = "militia_boss_e" },
                -- civilians
                { side = "neutral", movement_side = "player", character_source = character_source.template("monarch"), ai = ai.stationary, tile = "monarch", tags = {"civilian"} },
                { side = "neutral", movement_side = "player", character_source = character_source.template("militia_spear_captain"), ai = ai.move_one_allied, tile = "counselor", tags = {"civilian"} },
                { side = "neutral", movement_side = "player", character_source = character_source.template("militia_spearman"), ai = ai.stationary_allied, tile = "friendly_militia", tags = {"civilian"} },
            },
            scripts = {
                script.on_turn(1, phase.before_player)
                    :then_dialogue(
                        script_unit.tagged("counselor"),
                        {"Protect the monarch!", "Defeat enemy leaders to stop reinforcements."}),
                script.on_turn(4, phase.after_enemy, 4)
                    :with_tags{"bandit_reinforcements"}
                    :then_spawn_units({
                        { side = "enemy", character_source = character_source.template("bandit_axe"), ai = ai.move_inf, tile = "bandit_reinforce" },
                    },
                    "from_west"
                ),
                script.when_unit_dies("bandit_boss")
                    :then_remove_scripts("bandit_reinforcements")
                    :as_one_shot(),
                script.on_turn(6, phase.after_enemy, 4)
                    :with_tags{"cultist_reinforcements"}
                    :then_spawn_units({
                        { side = "enemy", character_source = character_source.template("cultist_guard"), ai = ai.move_inf, tile = "cultist_reinforce" },
                    },
                    "from_east"
                ),
                script.when_unit_dies("cultist_boss")
                    :then_remove_scripts("cultist_reinforcements")
                    :as_one_shot(),
                script.on_turn(6, phase.after_enemy, 4)
                    :with_tags{"militia_reinforcements"}
                    :then_spawn_units({
                        { side = "enemy", character_source = character_source.template("militia_archer"), ai = ai.move_inf, tile = "militia_reinforce_a" },
                        { side = "enemy", character_source = character_source.template("militia_spearman"), ai = ai.move_inf, tile = "militia_reinforce_b" },
                    },
                    "from_south"
                ),
                script.when_unit_dies("militia_boss")
                    :then_remove_scripts("militia_reinforcements")
                    :as_one_shot(),
            }
        }
    end,
    ["playground"] = function(campaign_config)
        return {
            map_id = "playground",
            tile_labels = {
                ["player_0"] = { 0x00 },
                ["player_1"] = { 0x01 },
                ["player_2"] = { 0x02 },
                ["player_3"] = { 0x03 },
                ["player_4"] = { 0x04 },
                ["player_5"] = { 0x05 },
                ["player_6"] = { 0x06 },
                ["player_7"] = { 0x07 },
                ["enemy_0"] = { 0x10 },
                ["enemy_1"] = { 0x11 },
                ["enemy_2"] = { 0x12 },
                ["enemy_3"] = { 0x13 },
                ["neutral_0"] = { 0x20 },
                ["escape_point"] = { 0x38 },
            },
            turn_limit = 1000,
            victory_conditions = {
                objectives.escape()
            },
            failure_conditions = {
            },
            units = {
                { side = "enemy", character_source = character_source.template("bandit_axe"), ai = ai.move_two, tile = "enemy_0" },
                { side = "enemy", character_source = character_source.template("cultist_spearman"), ai = ai.move_two, tile = "enemy_1" },
                { side = "enemy", character_source = character_source.template("bandit_guard"), ai = ai.stationary, tile = "enemy_2" },
                { side = "enemy", character_source = character_source.template("cultist_guard"), ai = ai.stationary, tile = "enemy_3" },
                { side = "player", character_source = character_source.template("militia_spear_captain"), tile = "player_0" },
                { side = "player", character_source = character_source.template("militia_archer"), tile = "player_1" },
                { side = "player", character_source = character_source.template("protagonist"), tile = "player_2" },
                { side = "player", character_source = character_source.template("child_greatsword"), tile = "player_3" },
                { side = "player", character_source = character_source.template("bandit_axe"), tile = "player_4" },
                { side = "player", character_source = character_source.template("bandit_guard"), tile = "player_5" },
                { side = "player", character_source = character_source.template("child_axe"), tile = "player_6" },
                { side = "player", character_source = character_source.template("bandit_axe"), tile = "player_7" },
                { side = "neutral", character_source = character_source.template("village_axe"), ai = ai.stationary_allied, tile = "neutral_0", tags = {"civilian"} },
            },
            scripts = {
                escape("escape_point"),
                script.on_talk("neutral_0")
                    :then_play_music("recruit_short")
                    :then_dialogue(script_unit.tagged("neutral_0"), {"Let me join you!"})
                    :then_recruit_unit(script_unit.tagged("neutral_0"))
                    :then_resume_music()
                    :as_one_shot(),
            }
        }
    end,
    ["model_room"] = function(campaign_config)
        return {
            map_id = "model_room",
            tile_labels = {
                ["player_0"] = { 0x00 },
                ["player_1"] = { 0x01 },
                ["player_2"] = { 0x02 },
                ["enemy_0"] = { 0x10 },
                ["enemy_1"] = { 0x11 },
                ["neutral_0"] = { 0x20 },
                ["neutral_1"] = { 0x21 },
            },
            turn_limit = 1000,
            victory_conditions = {
                objectives.escape()
            },
            failure_conditions = {
            },
            units = {
                { side = "enemy", character_source = character_source.template("bandit_axe"), ai = ai.move_two, tile = "enemy_0" },
                { side = "enemy", character_source = character_source.template("cultist_spearman"), ai = ai.move_two, tile = "enemy_1" },
                { side = "player", character_source = character_source.template("village_hero"), tile = "player_0" },
                { side = "player", character_source = character_source.template("militia_armor"), tile = "player_1" },
                { side = "player", character_source = character_source.template("militia_spear_captain"), tile = "player_2" },
                { side = "neutral", character_source = character_source.template("child_greatsword"), ai = ai.stationary_allied, tile = "neutral_0", tags = {"civilian"} },
                { side = "neutral", character_source = character_source.template("village_axe"), ai = ai.stationary_allied, tile = "neutral_1", tags = {"civilian"} },
            },
            scripts = {
            }
        }
    end
}

return BATTLE_DATA
