---@brief
--- Resolves CharacterSource entries to BattleUnits and handles spawn-point
--- selection, including blocked-tile policies.

local point = require("src.tactics.util.point")
local battle_unit = require("src.tactics.battle.tactics.battle_unit")
local character = require("src.tactics.character.object.character")

local unit_spawner = {}

--- Resolve a CharacterSource to a Character, advancing roster_count for
--- player_roster sources.
---@param char_man CharacterManager
---@param player_roster Character[]
---@param roster_count integer
---@param character_source CharacterSource
---@param side Side
---@return Character?, integer
function unit_spawner.resolve_character(char_man, player_roster, roster_count, character_source, side)
    if character_source.type == "template" then
        ---@cast character_source CharacterTemplateSource
        local unit_character = char_man:generate_character(character_source.template, {})
        if side == "player" then
            char_man:persist_player(unit_character)
        end
        return unit_character, roster_count
    elseif character_source.type == "player_roster" then
        ---@cast character_source PlayerRosterSource
        if player_roster[roster_count] ~= nil then
            return player_roster[roster_count], roster_count + 1
        end
        return nil, roster_count
    else
        unexpected(character_source.type)
        return nil, roster_count
    end
end

--- Attempt to spawn one unit at a single tile. Returns the spawned unit (or
--- nil) and the updated roster_count.
---@param engine TacticsEngine
---@param char_man CharacterManager
---@param player_roster Character[]
---@param roster_count integer
---@param spawn_point Point
---@param character_source CharacterSource
---@param side Side
---@param movement_side? string
---@param ai? UnitAI
---@param labels string[]
---@param blocked_behavior UnitSpawnBlockedBehavior
---@param facing? CardinalDirection Overrides position-derived default when present.
---@return BattleUnit?, integer
function unit_spawner.try_spawn_at(engine, char_man, player_roster, roster_count, spawn_point, character_source, side,
                                   movement_side, ai, labels, blocked_behavior, facing)
    local existing_unit = engine.battle_map:get_at_tile(spawn_point)
    if existing_unit ~= nil then
        if blocked_behavior == "prevent" then
            return nil, roster_count
        elseif blocked_behavior == "spawn_nearby" then
            -- todo
        else
            unexpected(blocked_behavior)
        end
    end

    local unit_character
    unit_character, roster_count = unit_spawner.resolve_character(
        char_man, player_roster, roster_count, character_source, side)
    if unit_character == nil then
        return nil, roster_count
    end

    local resolved_facing
    if facing then
        resolved_facing = character.facing.of(facing)
    else
        local facing_r = spawn_point.x <= (engine.battle_map.width >> 1) - 2
        resolved_facing = character.facing.of(facing_r and "right" or "left")
    end
    local unit = battle_unit.spawn_unit(
        unit_character,
        point.of_record(spawn_point),
        labels,
        side,
        movement_side,
        resolved_facing,
        ai,
        engine.skill_defs
    )
    engine:spawn_unit(unit, spawn_point)
    return unit, roster_count
end

return unit_spawner
