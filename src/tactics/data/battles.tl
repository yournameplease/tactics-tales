local battle_definition <const> = require("src/tactics/battle/definition")
local battle_script <const> = require("src/tactics/battle/scripts/battle_script")
local unit_spawn_data <const> = require("src/tactics/battle/unit/spawn_data")

local character_template <const> = unit_spawn_data.character_source.template
local player_roster <const> = unit_spawn_data.character_source.player_roster

local ai = {
    default = { move = "two", target = "player"},
    move_one = { move = "one", target = "player"},
    move_two = { move = "two", target = "player"},
    move_inf = { move = "infinity", target = "player"},
    stationary = { move = "zero", target = "player"},
}

local function spawn_players(
    players: { unit_spawn_data.UnitSpawnData },
    turn: integer,
    phase: battle_script.trigger.TurnTriggerPhase,
	animation: unit_spawn_data.UnitSpawnAnimation
): battle_script.BattleScript
    return battle_script.script.spawn_units(
        battle_script.trigger.turn(turn, nil, phase),
        players,
        {},
        animation
    )
end

local function free_players(
    players: { unit_spawn_data.UnitSpawnData },
    unit_label: string,
	animation: unit_spawn_data.UnitSpawnAnimation
): battle_script.BattleScript
    return battle_script.script.spawn_units(
        battle_script.trigger.unit_death(unit_label),
        players,
        {},
        animation
    )
end

local function spawn_enemies(
    enemies: { unit_spawn_data.UnitSpawnData },
    turn: integer,
    repeating: integer, --nillable
    phase: battle_script.trigger.TurnTriggerPhase,
	animation: unit_spawn_data.UnitSpawnAnimation
): battle_script.BattleScript
    return battle_script.script.spawn_units(
        battle_script.trigger.turn(turn, repeating, phase),
        {},
        enemies,
        animation
    )
end

local function open_door_front(
    enemy_label: string,
    tile_label: string
): battle_script.BattleScript
    return battle_script.script.modify_terrain(
        battle_script.trigger.unit_death(enemy_label),
        tile_label,
        {
            ["front_wall"] = 0
        }
    )
end

local function open_door_mid(
    enemy_label: string,
    tile_label: string
): battle_script.BattleScript
    return battle_script.script.modify_terrain(
        battle_script.trigger.unit_death(enemy_label),
        tile_label,
        {
            ["mid_wall"] = 0
        }
    )
end


global BATTLE_DATA: { string: battle_definition.BattleDefinition } = {
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
        victory_conditions = { {
            type = "ROUT"
        } },
        failure_conditions = { {
            type = "TURN_LIMIT"
        } },
        enemies = {
            { character_source = character_template("bandit_boss"), ai = ai.stationary, tile = "bandit_boss", tags = { "boss" } },
            { character_source = character_template("bandit_guard"), ai = ai.stationary, tile = "bandit_miniboss_gate" },
            { character_source = character_template("bandit_guard"), ai = ai.stationary, tile = "bandit_miniboss_l" },
            { character_source = character_template("bandit_guard"), ai = ai.stationary, tile = "bandit_miniboss_r" },
            { character_source = character_template("bandit_goon"), ai = ai.move_two, tile = "bandit_goon" },
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
                "from_west"
            ),
            spawn_enemies({
                { character_source = character_template("bandit_goon"), ai = ai.move_inf, tile = "bandit_reinforce_l" },
            },
                3,
                3,
                "after_enemy",
                "from_east"
            ),
            spawn_enemies({
                { character_source = character_template("bandit_goon"), ai = ai.move_inf, tile = "bandit_reinforce_r" },
            },
                6,
                3,
                "after_enemy",
                "from_west"
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
            ["cultist_guard"] = { 0x11 },
            ["cultist_door_guard_a"] = { 0x12 },
            ["cultist_door_guard_b"] = { 0x13 },
            ["cultist_door_guard_c"] = { 0x14 },
            ["cultist_door_guard_d"] = { 0x15 },
            ["cultist_door_guard_e"] = { 0x16 },
            ["door_a"] = { 0x32 },
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
        victory_conditions = { {
            type = "ROUT"
        } },
        failure_conditions = { {
            type = "TURN_LIMIT"
        } },
        enemies = {
            { character_source = character_template("cultist_boss"), ai = ai.stationary, tile = "cultist_boss" },
            { character_source = character_template("cultist_guard"), ai = ai.stationary, tile = "cultist_guard" },
            { character_source = character_template("cultist_spearman"), ai = ai.stationary, tile = "cultist_door_guard_a" },
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
            open_door_front("cultist_door_guard_a","door_a"),
            open_door_front("cultist_door_guard_b","door_b"),
            open_door_front("cultist_door_guard_c","door_c"),
            open_door_front("cultist_door_guard_d","door_d"),
            open_door_front("cultist_door_guard_e","door_e"),
        }
    }
}

return BATTLE_DATA
