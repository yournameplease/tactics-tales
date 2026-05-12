local function unit_in_range(min_dist, max_dist, predicate)
    return {
        get_selection_tiles = function(origin, map)
            local out = {}
            for dx = -max_dist, max_dist do
                for dy = -max_dist, max_dist do
                    local p = origin + lib.point.of(dx, dy)
                    local distance = lib.point.taxicab_distance(origin, p)
                    if distance >= min_dist and distance <= max_dist and map:tile_is_in_map(p) then
                        local unit = map:get_at_tile(p)
                        if unit and predicate(unit) then add(out, p) end
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
            if distance < min_dist or distance > max_dist then return false end
            local unit = map:get_at_tile(selection)
            return unit ~= nil and predicate(unit)
        end,
    }
end

local function ally_in_range(min_dist, max_dist, filter)
    return unit_in_range(min_dist, max_dist, function(unit)
        return unit.side == "player" and (not filter or filter(unit))
    end)
end

local function enemy_in_range(min_dist, max_dist)
    return unit_in_range(min_dist, max_dist, function(unit)
        return unit.side == "enemy"
    end)
end

---@type table<string, SkillDefinition>
return {
    heal = {
        name            = "Heal",
        effect_type     = "heal",
        heal_amount     = 5,
        hp_cost         = 1,
        cooldown        = nil,
        uses_per_battle = nil,
        targeting       = ally_in_range(1, 2, function(u)
            return u.hp_current < u.character.stats.hp_max
        end),
    },

    missile = {
        name            = "Missile",
        effect_type     = "damage",
        damage          = 3,
        accuracy        = 100,
        hp_cost         = nil,
        cooldown        = nil,
        uses_per_battle = 1,
        targeting       = enemy_in_range(1, 2),
    },
}
