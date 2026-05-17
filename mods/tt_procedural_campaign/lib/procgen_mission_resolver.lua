local factions_mod   = include("mods/tt_procedural_campaign/game_data/factions.lua")
local factions_data  = factions_mod.factions
local resolve_slot   = factions_mod.resolve_slot
local map_generator  = include("src/tactics/battle/map/map_generator.lua")
local battle_lib     = include("mods/base/lib/battle.lua")
local battle         = battle_lib.battle
local character_source = battle.character_source
local ai <const>     = battle.ai

-- Roles for which enemy UnitSpawnData are created.
local ENEMY_ROLES = {
    { label = "enemy_infantry",  ai_mode = ai.move_two  },
    { label = "enemy_ranged",    ai_mode = ai.move_two  },
    { label = "enemy_tank",      ai_mode = ai.move_two  },
    { label = "enemy_commander", ai_mode = ai.stationary },
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

--- Derive a deterministic integer seed from campaign run seed and battle index.
local function compute_seed(campaign_config)
    local story_seed   = tonumber(mem_text(campaign_config, "story_seed")) or 0
    local battle_index = tonumber(mem_text(campaign_config, "battle_index")) or 1
    return story_seed * 1000 + battle_index
end

--- Build the unit list from a BattleMap's tile_labels and the active faction/tier.
--- One UnitSpawnData is emitted per point in each enemy spawn tile label.
---@param campaign_config CampaignConfig
---@param tile_labels table<string, any[]>
---@return UnitSpawnData[]
local function build_units(campaign_config, tile_labels)
    local faction = get_faction(campaign_config)
    local tier    = get_tier(campaign_config)

    local units = {}

    units[#units + 1] = {
        side             = "player",
        character_source = character_source.player_roster(),
        tile             = "player_deployment",
    }

    for _, role_def in ipairs(ENEMY_ROLES) do
        local label    = role_def.label
        local points   = tile_labels[label] or {}
        local template = resolve_slot(faction, tier, label)
        if template and #points > 0 then
            log.debug("[procgen_mission] role=", label, " template=", template, " count=", #points)
            for _ = 1, #points do
                units[#units + 1] = {
                    side             = "enemy",
                    character_source = character_source.template(template),
                    ai               = role_def.ai_mode,
                    tile             = label,
                }
            end
        end
    end

    return units
end

---@param campaign_config CampaignConfig
---@param map_id string
---@param chunks_path string Path to the .chunks file for the castle theme.
---@return MissionDefinition
local function build_procgen_mission(campaign_config, map_id, chunks_path)
    local seed       = compute_seed(campaign_config)
    local definition = { type = "procgen", theme = "castle", chunks = chunks_path, tileset_name = "paper_tileset" }
    local battle_map = map_generator.load_map(definition, {}, nil, seed)

    log.debug("[procgen_mission] map=", map_id, " faction=", mem_text(campaign_config, "faction_id") or "bandits",
        " tier=", get_tier(campaign_config), " seed=", seed)

    local units = build_units(campaign_config, battle_map.tile_labels)

    log.debug("[procgen_mission] total units=", #units)

    return {
        map_id             = map_id,
        music              = 0,
        tile_labels        = {},
        victory_conditions = { battle.victory.rout() },
        failure_conditions = { battle.failure.tagged_unit_dies("hero") },
        units              = units,
        scripts            = {},
        seed               = seed,
    }
end

return {
    build_procgen_mission = build_procgen_mission,
    _compute_seed         = compute_seed,
    _build_units          = build_units,
}
