---@type table<string, SkillDefinition>
return {
    heal = {
        name            = "Heal",
        effect_type     = "heal",
        heal_amount     = 5,
        hp_cost         = 1,
        cooldown        = nil,
        uses_per_battle = nil,
        targeting = {
            get_selection_tiles = function(origin, map)
                local out = {}
                for dx = -2, 2 do
                    for dy = -2, 2 do
                        local p = origin + lib.point.of(dx, dy)
                        local distance = lib.point.taxicab_distance(origin, p)
                        if distance >= 1 and distance <= 2 and map:tile_is_in_map(p) then
                            local unit = map:get_at_tile(p)
                            if unit and unit.side == "player"
                                and unit.hp_current < unit.character.stats.hp_max
                            then
                                add(out, p)
                            end
                        end
                    end
                end
                return out
            end,
            get_targets_for_selection = function(_origin, selection, map)
                local unit = map:get_at_tile(selection)
                if unit then return { unit } end
                return {}
            end,
            is_target_valid = function(origin, selection, map)
                local distance = lib.point.taxicab_distance(origin, selection)
                if distance < 1 or distance > 2 then return false end
                local unit = map:get_at_tile(selection)
                return unit ~= nil
                    and unit.side == "player"
                    and unit.hp_current < unit.character.stats.hp_max
            end,
        },
    },

    missile = {
        name            = "Missile",
        effect_type     = "damage",
        damage          = 3,
        accuracy        = 100,
        hp_cost         = nil,
        cooldown        = nil,
        uses_per_battle = 1,
        targeting = {
            get_selection_tiles = function(origin, map)
                local out = {}
                for dx = -2, 2 do
                    for dy = -2, 2 do
                        local p = origin + lib.point.of(dx, dy)
                        local distance = lib.point.taxicab_distance(origin, p)
                        if distance >= 1 and distance <= 2 and map:tile_is_in_map(p) then
                            local unit = map:get_at_tile(p)
                            if unit and unit.side == "enemy" then
                                add(out, p)
                            end
                        end
                    end
                end
                return out
            end,
            get_targets_for_selection = function(_origin, selection, map)
                local unit = map:get_at_tile(selection)
                if unit then return { unit } end
                return {}
            end,
            is_target_valid = function(origin, selection, map)
                local distance = lib.point.taxicab_distance(origin, selection)
                if distance < 1 or distance > 2 then return false end
                local unit = map:get_at_tile(selection)
                return unit ~= nil and unit.side == "enemy"
            end,
        },
    },
}
