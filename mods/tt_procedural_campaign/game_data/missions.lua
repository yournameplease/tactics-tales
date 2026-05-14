local resolver_mod        = include("mods/tt_procedural_campaign/lib/pod_mission_resolver.lua")
local build_pod_mission   = resolver_mod.build_pod_mission
local factions_mod        = include("mods/tt_procedural_campaign/game_data/factions.lua")
local factions_data       = factions_mod.factions
local resolve_slot        = factions_mod.resolve_slot

local script_lib          = include("mods/base/lib/script.lua")
local script           = script_lib.script
local battle_lib       = include("mods/base/lib/battle.lua")
local battle           = battle_lib.battle

local character_source = battle.character_source
local ai <const>       = battle.ai

local objectives       = {
    rout             = battle.victory.rout,
    tagged_unit_dies = battle.failure.tagged_unit_dies,
}

local function mem_text(campaign_config, key)
    local mem = campaign_config.memory
    if not mem then return nil end
    local entry = mem:get(key)
    return entry and entry.text
end

local function mem_list(campaign_config, key)
    local mem = campaign_config.memory
    if not mem then return {} end
    local entry = mem:get(key)
    if not entry then return {} end
    ---@cast entry ListMemoryEntry
    return entry.values
end

local function get_faction(campaign_config)
    local faction_id = mem_text(campaign_config, "faction_id")
    return factions_data[faction_id] or factions_data["bandits"]
end

local function get_tier(campaign_config)
    return tonumber(mem_text(campaign_config, "base_difficulty")) or 1
end

---@type ModMissionsModule
local battles = {
    ["village_overrun"] = function(campaign_config, rng_context, map_context)
        local meta = include("mods/tt_procedural_campaign/game_data/maps/village_overrun_meta.lua")
        return build_pod_mission(campaign_config, rng_context, map_context, meta)
    end,
    ["cavern_fortress"] = function(campaign_config, rng_context, map_context)
        local meta = include("mods/tt_procedural_campaign/game_data/maps/cavern_fortress_meta.lua")
        return build_pod_mission(campaign_config, rng_context, map_context, meta)
    end,
    ["castle_escape"] = function(campaign_config, rng_context, map_context)
        local meta = include("mods/tt_procedural_campaign/game_data/maps/castle_escape_meta.lua")
        return build_pod_mission(campaign_config, rng_context, map_context, meta)
    end,
}

return battles
