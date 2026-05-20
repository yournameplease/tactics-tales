local factions_mod   = include("mods/tt_procedural_campaign/game_data/factions.lua")
local factions_data  = factions_mod.factions
local resolve_slot   = factions_mod.resolve_slot
local map_generator  = include("src/tactics/battle/map/map_generator.lua")
local battle_lib     = include("mods/base/lib/battle.lua")
local battle         = battle_lib.battle
local character_source = battle.character_source
local ai <const>     = battle.ai

local AI_MODE = {
    enemy_infantry  = ai.move_two,
    enemy_ranged    = ai.move_two,
    enemy_tank      = ai.move_two,
    enemy_commander = ai.stationary,
}

local function mem_text(campaign_config, key)
    local mem = campaign_config.memory
    if not mem then return nil end
    local entry = mem:get(key)
    return entry and entry.text
end

local function get_faction(campaign_config)
    local faction_id = mem_text(campaign_config, "faction_id")
    return factions_data[faction_id] or factions_data["bandits"]
end

local function get_tier(campaign_config)
    return tonumber(mem_text(campaign_config, "base_difficulty")) or 1
end

--- Roll a fresh map seed from the campaign's battle RNG.
---@param rng_context CampaignRngContext
---@return integer
local function compute_seed(rng_context)
    local rng = rng_context and rng_context.battle_rng
    return rng and rng:rndi(2147483647) or 0
end

--- Build the unit list from a BattleMap's spawn_label_meta and the active faction/tier.
--- One UnitSpawnData is emitted per label; spawn_units iterates the points itself.
---@param campaign_config CampaignConfig
---@param battle_map BattleMap
---@return UnitSpawnData[]
local function build_units(campaign_config, battle_map)
    local faction = get_faction(campaign_config)
    local tier    = get_tier(campaign_config)

    local units = {}

    units[#units + 1] = {
        side             = "player",
        character_source = character_source.player_roster(),
        tile             = "player_deployment",
    }

    for label in pairs(battle_map.tile_labels) do
        local meta = battle_map.spawn_label_meta[label]
        if not meta then
            log.debug("[procgen_mission] SKIP label=", label, " (no meta)")
        elseif meta.role == "player" then
            log.debug("[procgen_mission] SKIP label=", label, " (player role)")
        else
            local template = resolve_slot(faction, tier, meta.role)
            if template then
                log.debug("[procgen_mission] SPAWN label=", label, " role=", meta.role,
                    " template=", template, " tags=", meta.tags and table.concat(meta.tags, ",") or "none")
                local entry = {
                    side             = "enemy",
                    character_source = character_source.template(template),
                    ai               = AI_MODE[meta.role],
                    tile             = label,
                }
                if meta.tags then entry.tags = meta.tags end
                units[#units + 1] = entry
            else
                log.debug("[procgen_mission] NO TEMPLATE label=", label, " role=", meta.role,
                    " faction=", faction and faction.id or "?", " tier=", tier)
            end
        end
    end

    return units
end

---@param objective string
---@param battle_map BattleMap
---@return VictoryCondition[]
local function victory_conditions_for(objective, battle_map)
    if objective == "kill_boss" then
        return { battle.victory.defeat_tagged("boss", "Defeat the boss") }
    end
    return { battle.victory.rout() }
end

---@param objective string
---@return FailureCondition[]
local function failure_conditions_for(objective)
    return { battle.failure.tagged_unit_dies("hero") }
end

---@param campaign_config CampaignConfig
---@param rng_context CampaignRngContext
---@param map_id string
---@param chunks_path string Path to the .chunks file for the castle theme.
---@param objective string Default "rout". Pass "kill_boss" to require defeating the boss.
---@return MissionDefinition
local function build_procgen_mission(campaign_config, rng_context, map_id, chunks_path, objective)
    objective = objective or "rout"
    local seed       = compute_seed(rng_context)
    local definition = { type = "procgen", theme = "castle", chunks = chunks_path, tileset_name = "paper_tileset", objective = objective }
    local battle_map = map_generator.load_map(definition, {}, nil, seed)

    log.debug("[procgen_mission] map=", map_id, " faction=", mem_text(campaign_config, "faction_id") or "bandits",
        " tier=", get_tier(campaign_config), " seed=", seed, " objective=", objective)

    local units = build_units(campaign_config, battle_map)

    log.debug("[procgen_mission] total units=", #units)

    return {
        map_id             = map_id,
        music              = 0,
        tile_labels        = {},
        victory_conditions = victory_conditions_for(objective, battle_map),
        failure_conditions = failure_conditions_for(objective),
        units              = units,
        scripts            = {},
        seed               = seed,
    }
end

return {
    build_procgen_mission    = build_procgen_mission,
    _compute_seed            = compute_seed,
    _build_units             = build_units,
    _victory_conditions_for  = victory_conditions_for,
    _failure_conditions_for  = failure_conditions_for,
}
