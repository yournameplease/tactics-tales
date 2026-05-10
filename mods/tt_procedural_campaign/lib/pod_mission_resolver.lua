local factions_mod      = include("mods/tt_procedural_campaign/game_data/factions.lua")
local factions_data     = factions_mod.factions
local resolve_slot      = factions_mod.resolve_slot
local resolve_slot_cost = factions_mod.resolve_slot_cost
local zones             = include("mods/base/lib/zones.lua")
local battle_lib        = include("mods/base/lib/battle.lua")
local battle            = battle_lib.battle
local character_source  = battle.character_source
local ai <const>        = battle.ai

local BASE_BUDGET <const> = 4
local SCALE       <const> = 2
local VARIANCE    <const> = 1

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

---@param campaign_config table
---@param rng_context table?
---@param map_context MapContext
---@param meta table
---@return table
local function build_pod_mission(campaign_config, rng_context, map_context, meta)
    local faction = get_faction(campaign_config)
    local tier    = get_tier(campaign_config)
    local rng     = rng_context and rng_context.battle_rng

    local variant = rng and rng:choose_random_from_list(meta.variant_sets) or meta.variant_sets[1]

    local excluded = {}
    for _, name in ipairs(variant.excludes or {}) do
        excluded[name] = true
    end

    local budget = BASE_BUDGET + tier * SCALE

    local active_pods = {}
    for name in pairs(map_context.rect_zones or {}) do
        if name:sub(1, 4) == "pod_" and not excluded[name] then
            active_pods[#active_pods + 1] = name
        end
    end
    table.sort(active_pods)

    local eligible_slots = {}
    for slot in pairs(faction.costs) do
        if slot ~= "enemy_commander" then
            eligible_slots[#eligible_slots + 1] = slot
        end
    end
    table.sort(eligible_slots)

    local point_labels = {}
    local units        = {}

    local deploy_zone   = map_context.rect_zones and map_context.rect_zones[variant.deployment]
    local deploy_points = deploy_zone and zones.expand(deploy_zone, "grid", 16) or {}
    point_labels["player_deploy"] = deploy_points
    units[#units + 1] = {
        side             = "player",
        character_source = character_source.player_roster(),
        tile             = "player_deploy",
    }

    local base_share = #active_pods > 0 and math.floor(budget / #active_pods) or 0
    for _, pod_name in ipairs(active_pods) do
        local jitter     = rng and (rng:rndi(2 * VARIANCE + 1) - VARIANCE) or 0
        local pod_budget = math.max(0, base_share + jitter)
        local slot       = (rng and #eligible_slots > 0)
            and rng:choose_random_from_list(eligible_slots)
            or (eligible_slots[1] or "enemy_infantry")
        local unit_count = zones.unit_count(pod_budget, resolve_slot_cost(faction, slot))
        local pod_zone   = map_context.rect_zones[pod_name]
        local pod_points = pod_zone and zones.expand(pod_zone, "grid", unit_count) or {}
        point_labels[pod_name] = pod_points
        units[#units + 1] = {
            side             = "enemy",
            character_source = character_source.template(resolve_slot(faction, tier, slot)),
            ai               = ai.move_two,
            tile             = pod_name,
        }
    end

    local guard_names = {}
    for name in pairs(map_context.point_zones or {}) do
        if name:sub(1, 6) == "guard_" and not excluded[name] then
            guard_names[#guard_names + 1] = name
        end
    end
    table.sort(guard_names)
    for _, name in ipairs(guard_names) do
        point_labels[name] = map_context.point_zones[name]
        units[#units + 1] = {
            side             = "enemy",
            character_source = character_source.template(resolve_slot(faction, tier, "enemy_tank")),
            ai               = ai.stationary,
            tile             = name,
        }
    end

    local boss_names = {}
    for name in pairs(map_context.point_zones or {}) do
        if name:sub(1, 5) == "boss_" and not excluded[name] then
            boss_names[#boss_names + 1] = name
        end
    end
    table.sort(boss_names)
    for _, name in ipairs(boss_names) do
        point_labels[name] = map_context.point_zones[name]
        units[#units + 1] = {
            side             = "enemy",
            character_source = character_source.template(resolve_slot(faction, tier, "enemy_commander")),
            ai               = ai.stationary,
            tile             = name,
            tags             = { "boss" },
        }
    end

    return {
        map_id             = meta.map_id,
        music              = 0,
        tile_labels        = {},
        point_labels       = point_labels,
        victory_conditions = { battle.victory.rout() },
        failure_conditions = { battle.failure.tagged_unit_dies("hero") },
        units              = units,
        scripts            = {},
    }
end

return { build_pod_mission = build_pod_mission }
