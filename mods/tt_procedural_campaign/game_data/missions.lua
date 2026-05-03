local factions_mod = include("mods/tt_procedural_campaign/game_data/factions.lua")
local factions_data = factions_mod.factions
local resolve_slot  = factions_mod.resolve_slot
local script_lib    = include("mods/base/lib/script.lua")
local script        = script_lib.script
local battle_lib    = include("mods/base/lib/battle.lua")
local battle        = battle_lib.battle

local character_source = battle.character_source
local ai <const>       = battle.ai

local objectives = {
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
    ["skirmish"] = function(campaign_config, rng_context)
        local faction  = get_faction(campaign_config)
        local tier     = get_tier(campaign_config)
        local pending  = mem_list(campaign_config, "pending_recruits")

        local has_turncoat = false
        for _, v in ipairs(pending) do
            if v == "turncoat_enemy" then has_turncoat = true; break end
        end

        local recruit_unit_entry
        local recruit_scripts = {}
        if has_turncoat then
            local rng = rng_context and rng_context.battle_rng
            local slot = rng and rng:choose_random_from_list(faction.recruitable) or faction.recruitable[1]
            local template = resolve_slot(faction, tier, slot)
            recruit_unit_entry = { side = "enemy", character_source = character_source.template(template), ai = ai.stationary, tile = "recruit_slot", tags = { "turncoat" } }
            table.insert(recruit_scripts,
                script.on_talk("turncoat")
                    :then_dialogue(script.unit.target(), { "[turncoat] Turncoat joins the player." })
                    :then_recruit_unit(script.unit.target())
                    :as_one_shot()
            )
        else
            recruit_unit_entry = { side = "enemy", character_source = character_source.template(resolve_slot(faction, tier, "enemy_infantry")), ai = ai.move_two, tile = "recruit_slot" }
        end

        return {
            map_id = "playground",
            music  = 0,
            tile_labels = {
                ["player_deployment"] = { 0x00, 0x01, 0x02, 0x03 },
                ["enemy_inf_a"]       = { 0x10 },
                ["enemy_inf_b"]       = { 0x11 },
                ["enemy_tank_a"]      = { 0x12 },
                ["enemy_cmdr"]        = { 0x13 },
                ["recruit_slot"]      = { 0x20 },
            },
            victory_conditions = { objectives.rout() },
            failure_conditions = { objectives.tagged_unit_dies("hero") },
            units = {
                { side = "player", character_source = character_source.player_roster(), tile = "player_deployment" },
                { side = "enemy",  character_source = character_source.template(resolve_slot(faction, tier, "enemy_infantry")),  ai = ai.move_two,   tile = "enemy_inf_a" },
                { side = "enemy",  character_source = character_source.template(resolve_slot(faction, tier, "enemy_infantry")),  ai = ai.move_two,   tile = "enemy_inf_b" },
                { side = "enemy",  character_source = character_source.template(resolve_slot(faction, tier, "enemy_tank")),      ai = ai.move_one,   tile = "enemy_tank_a" },
                { side = "enemy",  character_source = character_source.template(resolve_slot(faction, tier, "enemy_commander")), ai = ai.stationary, tile = "enemy_cmdr", tags = { "boss" } },
                recruit_unit_entry,
            },
            scripts = recruit_scripts,
        }
    end,
}

return battles
