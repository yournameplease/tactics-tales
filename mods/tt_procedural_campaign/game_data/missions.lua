local resolver            = include("mods/tt_procedural_campaign/lib/pod_mission_resolver.lua")
local factions_mod        = include("mods/tt_procedural_campaign/game_data/factions.lua")
local factions_data       = factions_mod.factions
local resolve_slot        = factions_mod.resolve_slot

local script_lib          = include("mods/base/lib/script.lua")
local script           = script_lib.script
local script_unit      = script.unit
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
        return resolver.build_pod_mission(campaign_config, rng_context, map_context, meta)
    end,
    ["cavern_fortress"] = function(campaign_config, rng_context, map_context)
        local meta = include("mods/tt_procedural_campaign/game_data/maps/cavern_fortress_meta.lua")
        return resolver.build_pod_mission(campaign_config, rng_context, map_context, meta)
    end,
    ["castle_escape"] = function(campaign_config, rng_context, map_context)
        local meta = include("mods/tt_procedural_campaign/game_data/maps/castle_escape_meta.lua")
        local mission = resolver.build_pod_mission(campaign_config, rng_context, map_context, meta)

        table.insert(mission.units, {
            side             = "player",
            character_source = character_source.template("militia_spearman"),
            tile             = "deployment_1",
        })
        table.insert(mission.units, {
            side             = "player",
            character_source = character_source.template("militia_archer"),
            tile             = "deployment_2",
        })

        table.insert(mission.units, {
            side             = "neutral",
            movement_side    = "player",
            character_source = character_source.template("mage"),
            ai               = ai.stationary_allied,
            tile             = "ally_1",
            tags             = { "ally_mage" },
        })
        table.insert(mission.units, {
            side             = "neutral",
            movement_side    = "player",
            character_source = character_source.template("priest"),
            ai               = ai.stationary_allied,
            tile             = "ally_2",
            tags             = { "ally_priest" },
        })

        table.insert(mission.scripts,
            script.on_talk("ally_mage")
                :then_dialogue(script_unit.tagged("ally_mage"), { "[recruiting mage unit]" })
                :then_recruit_unit(script_unit.tagged("ally_mage"))
                :as_one_shot()
        )
        table.insert(mission.scripts,
            script.on_talk("ally_priest")
                :then_dialogue(script_unit.tagged("ally_priest"), { "[recruiting priest unit]" })
                :then_recruit_unit(script_unit.tagged("ally_priest"))
                :as_one_shot()
        )

        return mission
    end,
}

return battles
