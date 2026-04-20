local tile_labels = {
    ["player_spawn"] = { 0x01 },
    ["enemy_spawn"]  = { 0x02 },
}

---@type ModBattlesModule
local battles = {
    -- Rout victory with no enemies: 0 enemies always satisfies rout.
    -- VICTORY on the first finish_player_turn().
    rout_no_enemies = function(_story_config)
        return {
            map_id           = "test_arena",
            tile_labels      = tile_labels,
            victory_conditions = { { type = "rout" } },
            failure_conditions = {},
            units            = {},
            scripts          = {},
        }
    end,

    -- Rout victory with one player unit present.
    -- VICTORY on the first finish_player_turn().
    rout_with_player = function(_story_config)
        return {
            map_id           = "test_arena",
            tile_labels      = tile_labels,
            victory_conditions = { { type = "rout" } },
            failure_conditions = {},
            units = {
                { side = "player", character_source = { type = "template", template = "test_fighter" }, tile = "player_spawn" },
            },
            scripts = {},
        }
    end,

    -- Turn-limit defeat: turn_limit = 1, so turn 2 (reached after 2× finish_player_turn) triggers DEFEAT.
    -- First finish_player_turn ends turn 1 (1 > 1 = false). Second advances to turn 2 (2 > 1 = true → DEFEAT).
    turn_limit_defeat = function(_story_config)
        return {
            map_id           = "test_arena",
            tile_labels      = tile_labels,
            turn_limit       = 1,
            victory_conditions = {},
            failure_conditions = { { type = "turn_limit" } },
            units = {
                { side = "player", character_source = { type = "template", template = "test_fighter" }, tile = "player_spawn" },
            },
            scripts = {},
        }
    end,
}

return battles
