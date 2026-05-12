---@brief
--- Reusable targeting helpers and skill definition factories for mod skill files.

local point = require("src.tactics.util.point")

local M = {}

-- ---------------------------------------------------------------------------
-- Internal helpers
-- ---------------------------------------------------------------------------

---@param min_dist integer
---@param max_dist integer
---@param predicate fun(unit: BattleUnit, source_side: Side): boolean
---@return Targeting
local function unit_in_range(min_dist, max_dist, predicate)
    return {
        get_selection_tiles = function(origin, map, source_side)
            local out = {}
            for dx = -max_dist, max_dist do
                for dy = -max_dist, max_dist do
                    local p = origin + point.of(dx, dy)
                    local distance = point.taxicab_distance(origin, p)
                    if distance >= min_dist and distance <= max_dist and map:tile_is_in_map(p) then
                        local unit = map:get_at_tile(p)
                        if unit and predicate(unit, source_side) then
                            table.insert(out, p)
                        end
                    end
                end
            end
            return out
        end,
        get_targets_for_selection = function(_origin, selection, map, _source_side)
            local unit = map:get_at_tile(selection)
            if unit then return { unit } end
            return {}
        end,
        is_target_valid = function(origin, selection, map, source_side)
            local distance = point.taxicab_distance(origin, selection)
            if distance < min_dist or distance > max_dist then return false end
            local unit = map:get_at_tile(selection)
            return unit ~= nil and predicate(unit, source_side)
        end,
    }
end

local ADJACENT_DELTAS = {
    point.of(1, 0), point.of(-1, 0), point.of(0, 1), point.of(0, -1),
}

---@param predicate fun(unit: BattleUnit, source_side: Side): boolean
---@return Targeting
local function adjacent_units(predicate)
    return {
        get_selection_tiles = function(origin, _map, _source_side)
            return { origin }
        end,
        get_targets_for_selection = function(origin, _selection, map, source_side)
            local out = {}
            for _, delta in ipairs(ADJACENT_DELTAS) do
                local p = origin + delta
                if map:tile_is_in_map(p) then
                    local unit = map:get_at_tile(p)
                    if unit and predicate(unit, source_side) then
                        table.insert(out, unit)
                    end
                end
            end
            return out
        end,
        is_target_valid = function(origin, selection, map, source_side)
            if point.taxicab_distance(origin, selection) ~= 0 then return false end
            for _, delta in ipairs(ADJACENT_DELTAS) do
                local p = origin + delta
                if map:tile_is_in_map(p) then
                    local unit = map:get_at_tile(p)
                    if unit and predicate(unit, source_side) then return true end
                end
            end
            return false
        end,
    }
end

---@param min_dist integer
---@param max_dist integer
---@param predicate fun(unit: BattleUnit, source_side: Side): boolean
---@return Targeting
local function all_in_range(min_dist, max_dist, predicate)
    return {
        get_selection_tiles = function(origin, _map, _source_side)
            return { origin }
        end,
        get_targets_for_selection = function(origin, _selection, map, source_side)
            local out = {}
            for dx = -max_dist, max_dist do
                for dy = -max_dist, max_dist do
                    local p = origin + point.of(dx, dy)
                    local distance = point.taxicab_distance(origin, p)
                    if distance >= min_dist and distance <= max_dist and map:tile_is_in_map(p) then
                        local unit = map:get_at_tile(p)
                        if unit and predicate(unit, source_side) then
                            table.insert(out, unit)
                        end
                    end
                end
            end
            return out
        end,
        is_target_valid = function(origin, selection, _map, _source_side)
            return point.taxicab_distance(origin, selection) == 0
        end,
    }
end

-- ---------------------------------------------------------------------------
-- Targeting helpers
-- ---------------------------------------------------------------------------

--- Targets only the caster's own tile; no player selection.
---@return Targeting
function M.self_target()
    return {
        get_selection_tiles = function(origin, _map, _source_side)
            return { origin }
        end,
        get_targets_for_selection = function(_origin, selection, map, _source_side)
            local unit = map:get_at_tile(selection)
            if unit then return { unit } end
            return {}
        end,
        is_target_valid = function(origin, selection, _map, _source_side)
            return point.taxicab_distance(origin, selection) == 0
        end,
    }
end

--- Single ally target within taxicab range [min, max]. Optional filter predicate.
---@param min integer
---@param max integer
---@param filter? fun(unit: BattleUnit): boolean
---@return Targeting
function M.ally_in_range(min, max, filter)
    return unit_in_range(min, max, function(unit, source_side)
        return unit.side == source_side and (not filter or filter(unit))
    end)
end

--- Single enemy target within taxicab range [min, max].
---@param min integer
---@param max integer
---@return Targeting
function M.enemy_in_range(min, max)
    return unit_in_range(min, max, function(unit, source_side)
        return unit.side ~= source_side
    end)
end

--- All adjacent ally tiles (distance == 1). Useful for AoE heals and formation skills.
---@return Targeting
function M.adjacent_allies()
    return adjacent_units(function(unit, source_side)
        return unit.side == source_side
    end)
end

--- All adjacent enemy tiles (distance == 1). Useful for Rampage-style skills.
---@return Targeting
function M.adjacent_enemies()
    return adjacent_units(function(unit, source_side)
        return unit.side ~= source_side
    end)
end

--- All allies within taxicab range [min, max]. Useful for Mass Heal.
---@param min integer
---@param max integer
---@return Targeting
function M.allies_in_range(min, max)
    return all_in_range(min, max, function(unit, source_side)
        return unit.side == source_side
    end)
end

-- ---------------------------------------------------------------------------
-- Skill factories
-- ---------------------------------------------------------------------------

--- Build a heal SkillDefinition.
---@param name string
---@param amount integer HP restored.
---@param targeting Targeting
---@param opts? {cooldown?: integer, uses_per_battle?: integer, hp_cost?: integer}
---@return SkillDefinition
function M.make_heal(name, amount, targeting, opts)
    opts = opts or {}
    local effects = {}
    if opts.hp_cost then
        table.insert(effects, { type = "hp_cost", amount = opts.hp_cost })
    end
    table.insert(effects, { type = "heal", amount = amount })
    return {
        name = name,
        cooldown = opts.cooldown,
        uses_per_battle = opts.uses_per_battle,
        targeting = targeting,
        effects = effects,
    }
end

--- Build a damage SkillDefinition.
---@param name string
---@param damage integer Flat damage dealt.
---@param accuracy integer Hit chance 0–100.
---@param targeting Targeting
---@param opts? {cooldown?: integer, uses_per_battle?: integer, hp_cost?: integer}
---@return SkillDefinition
function M.make_damage(name, damage, accuracy, targeting, opts)
    opts = opts or {}
    local effects = {}
    if opts.hp_cost then
        table.insert(effects, { type = "hp_cost", amount = opts.hp_cost })
    end
    table.insert(effects, { type = "damage", damage = damage, accuracy = accuracy })
    return {
        name = name,
        cooldown = opts.cooldown,
        uses_per_battle = opts.uses_per_battle,
        targeting = targeting,
        effects = effects,
    }
end

--- Build a debuff SkillDefinition.
---@param name string
---@param kind string Debuff subtype identifier.
---@param duration integer Duration in turns.
---@param targeting Targeting
---@param opts? {cooldown?: integer, uses_per_battle?: integer, hp_cost?: integer}
---@return SkillDefinition
function M.make_debuff(name, kind, duration, targeting, opts)
    opts = opts or {}
    local effects = {}
    if opts.hp_cost then
        table.insert(effects, { type = "hp_cost", amount = opts.hp_cost })
    end
    table.insert(effects, { type = "debuff", kind = kind, duration = duration })
    return {
        name = name,
        cooldown = opts.cooldown,
        uses_per_battle = opts.uses_per_battle,
        targeting = targeting,
        effects = effects,
    }
end

--- Build a buff SkillDefinition.
---@param name string
---@param kind string Buff subtype identifier.
---@param duration integer Duration in turns.
---@param targeting Targeting
---@param opts? {cooldown?: integer, uses_per_battle?: integer, hp_cost?: integer}
---@return SkillDefinition
function M.make_buff(name, kind, duration, targeting, opts)
    opts = opts or {}
    local effects = {}
    if opts.hp_cost then
        table.insert(effects, { type = "hp_cost", amount = opts.hp_cost })
    end
    table.insert(effects, { type = "buff", kind = kind, duration = duration })
    return {
        name = name,
        cooldown = opts.cooldown,
        uses_per_battle = opts.uses_per_battle,
        targeting = targeting,
        effects = effects,
    }
end

return M
