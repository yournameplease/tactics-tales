local unit_ai = require("src/tactics/battle/unit/unit_ai")
local battle_definition = require("src/tactics/battle/definition")
local battle_script = require("src/tactics/battle/scripts/battle_script")
local battle_definition_types = require("src/tactics/battle/definition/types")

local ai = {
    default = { move = "two", target = "player"},
    move_one = { move = "one", target = "player"},
    move_two = { move = "two", target = "player"},
    move_inf = { move = "infinity", target = "player"},
    stationary = { move = "zero", target = "player"},
}

local function spawn_players(
    players: { battle_definition_types.PlayerSpawnData },
    turn: integer,
    phase: battle_script.trigger.TurnTriggerPhase
): battle_script.BattleScript
    return battle_script.script.spawn_units(
        battle_script.trigger.turn(turn, nil, phase),
        players,
        {}
    )
end

local function spawn_enemies(
    enemies: { battle_definition_types.EnemySpawnData },
    turn: integer,
    repeating: integer, --nillable
    phase: battle_script.trigger.TurnTriggerPhase
): battle_script.BattleScript
    return battle_script.script.spawn_units(
        battle_script.trigger.turn(turn, repeating, phase),
        {},
        enemies
    )
end


global BATTLE_DATA: { string: battle_definition.BattleDefinition } = {
    ["bandit_village"] = {
        map_id = "bandit_village",
        tile_labels = {
            ["player_deployment"] = { 0x00 },
            ["bandit_boss"] = { 0x10 },
            ["bandit_goon"] = { 0x11 },
            ["bandit_guard"] = { 0x12 },
            ["bandit_reinforce_a"] = { 0x18 },
            ["bandit_reinforce_b"] = { 0x19 },
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
            { template = "bandit_boss", ai = ai.stationary, tile = "bandit_boss" },
            { template = "bandit_guard", ai = ai.stationary, tile = "bandit_guard" },
            { template = "bandit_goon", ai = ai.move_two, tile = "bandit_goon" },
        },
        players = {
            { tile = "player_deployment" },
        },
        scripts = {
            spawn_players({
                { template = "militia_spearman", tile = "player_spearman" },
                { template = "militia_archer", tile = "player_archer" },
                { template = "militia_armor", tile = "player_armor" },
            },
                2,
                "before_player"
            ),
            spawn_enemies({
                { template = "bandit_goon", ai = ai.move_inf, tile = "bandit_reinforce_b" },
            },
                3,
                3,
                "after_enemy"
            ),
            spawn_enemies({
                { template = "bandit_goon", ai = ai.move_inf, tile = "bandit_reinforce_a" },
            },
                6,
                3,
                "after_enemy"
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
            { template = "cultist_boss", ai = ai.stationary, tile = "cultist_boss" },
            { template = "cultist_guard", ai = ai.stationary, tile = "cultist_guard" },
            { template = "cultist_spear", ai = ai.stationary, tile = "cultist_guard" },
            { template = "cultist_goon", ai = ai.move_two, tile = "cultist_goon" },
        },
        neutral = {
            { template = "old_fart", ai = ai.stationary, tile = "jailed_priest" },
            { template = "village_hero", ai = ai.stationary, tile = "jailed_royal" },
            { template = "bandit_guard", ai = ai.move_inf, tile = "jailed_bandit" },
            { template = "bandit_berzerker", ai = ai.move_inf, tile = "jailed_bandit_bro" },
        },
        players = {
            { tile = "player_deployment" },
        },
        scripts = {
            spawn_enemies({
                { template = "cultist_goon", ai = ai.move_inf, tile = "cultist_reinforce_b" },
            },
                3,
                3,
                "after_enemy"
            ),
            spawn_enemies({
                { template = "cultist_goon", ai = ai.move_inf, tile = "cultist_reinforce_a" },
            },
                6,
                3,
                "after_enemy"
            ),
        }
    }
}

return BATTLE_DATA
