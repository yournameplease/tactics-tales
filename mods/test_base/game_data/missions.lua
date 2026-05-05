local tile_labels = {
    ["player_spawn"] = { 0x01 },
    ["enemy_spawn"]  = { 0x02 },
}

---@type ModMissionsModule
local battles = {
    -- Rout victory with no enemies: 0 enemies always satisfies rout.
    -- VICTORY on the first finish_player_turn().
    rout_no_enemies = function(_campaign_config)
        return {
            map_id             = "test_arena",
            tile_labels        = tile_labels,
            victory_conditions = { { type = "rout" } },
            failure_conditions = {},
            units              = {},
            scripts            = {},
        }
    end,

    -- Rout victory with one player unit present.
    -- VICTORY on the first finish_player_turn().
    rout_with_player = function(_campaign_config)
        return {
            map_id             = "test_arena",
            tile_labels        = tile_labels,
            victory_conditions = { { type = "rout" } },
            failure_conditions = {},
            units              = {
                { side = "player", character_source = { type = "template", template = "test_fighter" }, tile = "player_spawn" },
            },
            scripts            = {},
        }
    end,

    -- Turn-limit defeat: turn_limit = 1, so turn 2 (reached after 2× finish_player_turn) triggers DEFEAT.
    -- First finish_player_turn ends turn 1 (1 > 1 = false). Second advances to turn 2 (2 > 1 = true → DEFEAT).
    turn_limit_defeat = function(_campaign_config)
        return {
            map_id             = "test_arena",
            tile_labels        = tile_labels,
            turn_limit         = 1,
            victory_conditions = {},
            failure_conditions = { { type = "turn_limit" } },
            units              = {
                { side = "player", character_source = { type = "template", template = "test_fighter" }, tile = "player_spawn" },
            },
            scripts            = {},
        }
    end,
    -- Close-combat: armed enemy adjacent to player, all_players_die failure condition.
    -- DEFEAT on first finish_player_turn() — enemy attacks and kills the player unit.
    -- Used by permadeath tests; battle_config.permadeath controls character persistence.
    close_combat = function(_campaign_config)
        return {
            map_id             = "test_close_arena",
            tile_labels        = tile_labels,
            victory_conditions = {},
            failure_conditions = { { type = "all_players_die" } },
            units              = {
                {
                    side = "player",
                    character_source = { type = "template", template = "test_fighter" },
                    tile = "player_spawn"
                },
                {
                    side = "enemy",
                    character_source = { type = "template", template = "test_armed_enemy" },
                    tile = "enemy_spawn",
                    ai = { move = "zero", target_sides = { "player" } }
                },
            },
            scripts            = {},
        }
    end,
}

return battles
