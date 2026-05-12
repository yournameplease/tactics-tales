return {
    test_sword = {
        name              = "Test Sword",
        type              = "WEAPON",
        slots             = 1,
        equip_slot        = "MAIN_HAND",
        sprite_data       = { sprite = 104, anchor = lib.point.of(1, 8) },
        equipment_effects = {},
        weapon_definition = {
            name      = "Test Sword",
            sprite    = 104,
            damage    = 10,
            accuracy  = 100,
            type      = "MELEE",
            body_type = "BACK_HAND",
            effects   = {},
            targeting = {
                range_min = 1,
                range_max = 1,
                get_selection_tiles = function(origin, map, _source_side)
                    local out = {}
                    for dx = -1, 1 do
                        for dy = -1, 1 do
                            local p = origin + lib.point.of(dx, dy)
                            if lib.point.taxicab_distance(origin, p) == 1
                                and map:tile_is_in_map(p)
                            then
                                add(out, p)
                            end
                        end
                    end
                    return out
                end,
                get_targets_for_selection = function(_origin, selection, map, _source_side)
                    return { map:get_at_tile(selection) }
                end,
                is_target_valid = function(origin, selection, _map, _source_side)
                    return lib.point.taxicab_distance(origin, selection) == 1
                end,
            },
        },
    },
}
