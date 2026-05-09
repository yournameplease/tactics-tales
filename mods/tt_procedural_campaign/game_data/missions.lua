local factions_mod        = include("mods/tt_procedural_campaign/game_data/factions.lua")
local factions_data       = factions_mod.factions
local resolve_slot        = factions_mod.resolve_slot
local resolve_slot_cost   = factions_mod.resolve_slot_cost
local zones               = include("mods/base/lib/zones.lua")
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
    ["abandoned_fortress_seize"] = function(campaign_config, _rng_context)
        local faction = get_faction(campaign_config)
        local tier    = get_tier(campaign_config)

        return {
            map_id             = "abandoned_fortress",
            music              = 0,
            victory_conditions = { objectives.rout() },
            failure_conditions = { objectives.tagged_unit_dies("hero") },
            units              = {
                {
                    side = "player",
                    layer = "deployment_seize",
                    slots = {
                        default = { character_source = character_source.player_roster() },
                    }
                },
                {
                    side = "enemy",
                    layer = "boss_seize",
                    tags = { "boss" },
                    slots = {
                        enemy_commander = { character_source = character_source.template(resolve_slot(faction, tier, "enemy_commander")), ai = ai.stationary },
                    }
                },
                {
                    side = "enemy",
                    layer = "guard_west",
                    tags = {},
                    slots = {
                        default = { character_source = character_source.template(resolve_slot(faction, tier, "enemy_tank")), ai = ai.stationary },
                    }
                },
                {
                    side = "enemy",
                    layer = "guard_east",
                    tags = {},
                    slots = {
                        default = { character_source = character_source.template(resolve_slot(faction, tier, "enemy_tank")), ai = ai.stationary },
                    }
                },
                {
                    side = "enemy",
                    layer = "squad_center",
                    tags = {},
                    slots = {
                        default = { character_source = character_source.template(resolve_slot(faction, tier, "enemy_infantry")), ai = ai.move_two },
                    }
                },
                {
                    side = "enemy",
                    layer = "squad_north",
                    tags = {},
                    slots = {
                        default = { character_source = character_source.template(resolve_slot(faction, tier, "enemy_infantry")), ai = ai.move_two },
                    }
                },
                {
                    side = "enemy",
                    layer = "squad_center_south",
                    tags = {},
                    slots = {
                        default = { character_source = character_source.template(resolve_slot(faction, tier, "enemy_infantry")), ai = ai.move_two },
                    }
                },
                {
                    side = "enemy",
                    layer = "squad_west",
                    tags = {},
                    slots = {
                        default = { character_source = character_source.template(resolve_slot(faction, tier, "enemy_infantry")), ai = ai.move_two },
                    }
                },
                {
                    side = "enemy",
                    layer = "squad_east",
                    tags = {},
                    slots = {
                        default = { character_source = character_source.template(resolve_slot(faction, tier, "enemy_infantry")), ai = ai.move_two },
                    }
                },
            },
            scripts            = {},
        }
    end,
    ["village_overrun"] = function(campaign_config, _rng_context, map_context)
        local faction    = get_faction(campaign_config)
        local tier       = get_tier(campaign_config)
        local base_budget = 4
        local scale       = 2
        local budget      = base_budget + tier * scale

        local inf_zone   = map_context.rect_zones["pod_sw"]
        local inf_count  = zones.unit_count(budget, resolve_slot_cost(faction, "enemy_infantry"))
        local inf_points = inf_zone and zones.expand(inf_zone, "grid", inf_count) or {}

        local tank_zone   = map_context.rect_zones["pod_w"]
        local tank_count  = zones.unit_count(budget, resolve_slot_cost(faction, "enemy_tank"))
        local tank_points = tank_zone and zones.expand(tank_zone, "grid", tank_count) or {}

        local deploy_zone   = map_context.rect_zones["deployment_w"]
        local deploy_points = deploy_zone and zones.expand(deploy_zone, "grid", 16) or {}

        return {
            map_id             = "village_overrun",
            music              = 0,
            tile_labels        = {},
            point_labels       = {
                player_deploy     = deploy_points,
                enemy_infantry_sw = inf_points,
                enemy_tank_w      = tank_points,
                boss_ne           = { { x = 15, y = 4 } },
            },
            victory_conditions = { objectives.rout() },
            failure_conditions = { objectives.tagged_unit_dies("hero") },
            units              = {
                {
                    side             = "player",
                    character_source = character_source.player_roster(),
                    tile             = "player_deploy",
                },
                {
                    side             = "enemy",
                    character_source = character_source.template(resolve_slot(faction, tier, "enemy_commander")),
                    ai               = ai.stationary,
                    tile             = "boss_ne",
                    tags             = { "boss" },
                },
                {
                    side             = "enemy",
                    character_source = character_source.template(resolve_slot(faction, tier, "enemy_infantry")),
                    ai               = ai.move_two,
                    tile             = "enemy_infantry_sw",
                },
                {
                    side             = "enemy",
                    character_source = character_source.template(resolve_slot(faction, tier, "enemy_tank")),
                    ai               = ai.stationary,
                    tile             = "enemy_tank_w",
                },
            },
            scripts            = {},
        }
    end,
    ["skirmish"] = function(campaign_config, rng_context)
        local faction      = get_faction(campaign_config)
        local tier         = get_tier(campaign_config)
        local pending      = mem_list(campaign_config, "pending_recruits")

        local has_turncoat = false
        for _, v in ipairs(pending) do
            if v == "turncoat_enemy" then
                has_turncoat = true; break
            end
        end

        local recruit_unit_entry
        local recruit_scripts = {}
        if has_turncoat then
            local rng = rng_context and rng_context.battle_rng
            local slot = rng and rng:choose_random_from_list(faction.recruitable) or faction.recruitable[1]
            local template = resolve_slot(faction, tier, slot)
            recruit_unit_entry = {
                side = "enemy",
                character_source = character_source.template(template),
                ai = ai
                    .stationary,
                tile = "recruit_slot",
                tags = { "turncoat" }
            }
            table.insert(recruit_scripts,
                script.on_talk("turncoat")
                :then_dialogue(script.unit.target(), { "[turncoat] Turncoat joins the player." })
                :then_recruit_unit(script.unit.target())
                :as_one_shot()
            )
        else
            recruit_unit_entry = {
                side = "enemy",
                character_source = character_source.template(resolve_slot(faction,
                    tier, "enemy_infantry")),
                ai = ai.move_two,
                tile = "recruit_slot"
            }
        end

        return {
            map_id             = "abandoned_fortress",
            music              = 0,
            tile_labels        = {
                ["player_deployment"] = { 0x00, 0x01, 0x02, 0x03 },
                ["enemy_inf_a"]       = { 0x10 },
                ["enemy_inf_b"]       = { 0x11 },
                ["enemy_tank_a"]      = { 0x12 },
                ["enemy_cmdr"]        = { 0x13 },
                ["recruit_slot"]      = { 0x20 },
            },
            victory_conditions = { objectives.rout() },
            failure_conditions = { objectives.tagged_unit_dies("hero") },
            units              = {
                { side = "player", character_source = character_source.player_roster(),                                          tile = "player_deployment" },
                { side = "enemy",  character_source = character_source.template(resolve_slot(faction, tier, "enemy_infantry")),  ai = ai.move_two,          tile = "enemy_inf_a" },
                { side = "enemy",  character_source = character_source.template(resolve_slot(faction, tier, "enemy_infantry")),  ai = ai.move_two,          tile = "enemy_inf_b" },
                { side = "enemy",  character_source = character_source.template(resolve_slot(faction, tier, "enemy_tank")),      ai = ai.move_one,          tile = "enemy_tank_a" },
                { side = "enemy",  character_source = character_source.template(resolve_slot(faction, tier, "enemy_commander")), ai = ai.stationary,        tile = "enemy_cmdr",  tags = { "boss" } },
                recruit_unit_entry,
            },
            scripts            = recruit_scripts,
        }
    end,
}

return battles
