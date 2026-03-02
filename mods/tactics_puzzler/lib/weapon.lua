
local weapon = {
    effect = {},
    range = {},
}

function weapon.effect.long_reach()
    return {
        type = "long_reach"
    }
end

function weapon.effect.shieldsplitter()
    return {
        type = "shieldsplitter"
    }
end

function weapon.effect.armorkiller()
    return {
        type = "armorkiller"
    }
end

function weapon.effect.shieldkiller()
    return {
        type = "shieldkiller"
    }
end

function weapon.range.single_target(min_range, max_range)
    return {
        get_selection_tiles = function(origin, map)
            local out = {}
            for x=-max_range,max_range do
                for y=-max_range,max_range do
                    local p = origin + lib.point.of(x, y)
                    local distance = lib.point.taxicab_distance(origin, p) 
                    if min_range <= distance and distance <= max_range
                        and map:tile_is_in_map(p)
                    then
                        add(out, p)
                    end
                end 
            end
            
            return out
        end,
        get_targets_for_selection = function(origin, selection, map)
            return { map:get_at_tile(selection) }
        end,
        is_target_valid = function(origin, selection, map)
            local distance = lib.point.taxicab_distance(origin, selection) 
            return min_range <= distance and distance <= max_range
        end,
    }
end

local default_weapon = {
    name = "Default Weapon",
    sprite = 104,
    hand_anchor = lib.point.of(1,8), -- the top left position of the handle
    damage = 1,
    accuracy = 100,
    type = "MELEE",
    body_type = "BACK_HAND",
    targeting = weapon.range.single_target(1,1),
}

function weapon.of(
    name,
    slots,
    equip_slot,
    sprite_data,
    data
)
    setmetatable(data, { __index = default_weapon })
    return {
        name = name,
        type = "WEAPON",
        slots = slots,
        equip_slot = equip_slot,
        sprite_data = sprite_data,

        weapon_definition = data,
        equipment_effects = {}
    }
end

function weapon.melee(
    name,
    sprite,
    damage,
    accuracy,
    slots,
    effects
)
    return weapon.of(
        name,
        slots,
        "MAIN_HAND",
        {
            sprite = sprite,
            anchor = lib.point.of(1,8)
        },
        {
            name = name,
            damage = damage,
            accuracy = accuracy,
            effects = effects or {}
        }
    )
end

function weapon.two_handed(
    name,
    sprite,
    damage,
    accuracy,
    slots,
    effects
)
    return weapon.of(
        name,
        slots,
        "TWO_HANDS",
        {
            sprite = sprite,
            anchor = lib.point.of(3,12)
        },
        {
            name = name,
            sprite = sprite,
            damage = damage,
            accuracy = accuracy,
            body_type = "HORIZONTAL",
            effects = effects or {}
        }
    )
end

function weapon.ranged(
    name,
    sprite,
    damage,
    accuracy,
    min_range,
    max_range,
    slots,
    effects
)
    return weapon.of(
        name,
        slots,
        "TWO_HANDS",
        {
            sprite = sprite,
            anchor = lib.point.of(13,9) 
        },
        {
            name = name,
            sprite = sprite,
            damage = damage,
            accuracy = accuracy,
            targeting = weapon.range.single_target(min_range,max_range),
            type = "RANGED",
            body_type = "FRONT_HAND",
            effects = effects or {}
        }
    )
end

return {
    weapon = weapon
}
