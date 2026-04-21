---@type ModMapsModule
local maps = {
    -- 16×16 open arena used by battle integration tests.
    -- player_spawn: metatile 0x01 at (2, 7)
    -- enemy_spawn:  metatile 0x02 at (13, 7)
    test_arena = { type = "static", file = "map/test_arena.map" },
    -- 16×16 open arena with adjacent spawns for close-combat tests.
    -- player_spawn: metatile 0x01 at (7, 15)
    -- enemy_spawn:  metatile 0x02 at (8, 15)
    test_close_arena = { type = "static", file = "map/test_close_arena.map" },
}

return maps
