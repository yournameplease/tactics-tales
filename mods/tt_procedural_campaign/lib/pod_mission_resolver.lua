local factions_mod      = include("mods/tt_procedural_campaign/game_data/factions.lua")
local factions_data     = factions_mod.factions
local resolve_slot      = factions_mod.resolve_slot
local resolve_slot_cost = factions_mod.resolve_slot_cost
local zones             = include("mods/base/lib/zones.lua")
local battle_lib        = include("mods/base/lib/battle.lua")
local battle            = battle_lib.battle
local character_source  = battle.character_source
local ai <const>        = battle.ai

local BASE_BUDGET <const> = 3
local TIER_SCALE  <const> = 3
local JITTER      <const> = 1

local FACING_MAP <const> = {
    north = "up", south = "down", east = "right", west = "left",
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

    local base_budget = BASE_BUDGET + tier * TIER_SCALE

    log.debug("[pod_mission] map=", meta.map_id,
        " faction=", mem_text(campaign_config, "faction_id") or "bandits",
        " tier=", tier,
        " base_budget=", base_budget,
        " variant=", variant.deployment or "<none>")

    local point_labels = {}
    local units        = {}

    local deploy_zone   = map_context.rect_zones and map_context.rect_zones[variant.deployment]
    local deploy_points = deploy_zone and zones.expand(deploy_zone, "grid", 16) or {}
    point_labels["player_deploy"] = deploy_points
    log.debug("[pod_mission] player_deploy zone=", variant.deployment, " points=", #deploy_points)
    units[#units + 1] = {
        side             = "player",
        character_source = character_source.player_roster(),
        tile             = "player_deploy",
    }

    local spawn_zone_names = {}

    for _, group in ipairs(variant.spawn_groups or {}) do
        local role      = group.role
        local zone_name = group.zone
        local facing    = FACING_MAP[group.facing]

        spawn_zone_names[zone_name] = true

        local slot_tag     = (faction.role_map and faction.role_map[role]) or "enemy_infantry"
        local template     = resolve_slot(faction, tier, slot_tag)
        local group_budget = base_budget * (group.threat_mult or 1.0)
        if rng then group_budget = group_budget + rng:rndi(2*JITTER+1)-JITTER end

        if role == "guard" then
            local pts = map_context.point_zones and map_context.point_zones[zone_name]
            point_labels[zone_name] = pts or {}
            log.debug("[pod_mission] guard zone=", zone_name, " template=", template, " facing=", facing)
            units[#units + 1] = {
                side             = "enemy",
                character_source = character_source.template(template),
                ai               = ai.stationary,
                tile             = zone_name,
                facing           = facing,
            }
        elseif role == "boss" then
            local pts = map_context.point_zones and map_context.point_zones[zone_name]
            point_labels[zone_name] = pts or {}
            log.debug("[pod_mission] boss zone=", zone_name, " template=", template, " facing=", facing)
            units[#units + 1] = {
                side             = "enemy",
                character_source = character_source.template(template),
                ai               = ai.stationary,
                tile             = zone_name,
                tags             = { "boss" },
                facing           = facing,
            }
        else
            -- patrol or ambush: rect zone, budget-based multi-unit, move_two AI
            local rect       = map_context.rect_zones and map_context.rect_zones[zone_name]
            local slot_cost  = resolve_slot_cost(faction, slot_tag)
            local unit_count = zones.unit_count(group_budget, slot_cost)
            local pod_points = rect and zones.expand(rect, "grid", unit_count) or {}
            point_labels[zone_name] = pod_points
            log.debug("[pod_mission] ", role, " zone=", zone_name,
                " budget=", group_budget, " slot=", slot_tag, " slot_cost=", slot_cost,
                " unit_count=", unit_count, " template=", template, " facing=", facing)
            units[#units + 1] = {
                side             = "enemy",
                character_source = character_source.template(template),
                ai               = ai.move_two,
                tile             = zone_name,
                facing           = facing,
            }
        end
    end

    -- Explicitly include all non-excluded object layers not already registered as spawn zones.
    for name, pts in pairs(map_context.point_zones or {}) do
        if not excluded[name] and not spawn_zone_names[name] then
            point_labels[name] = pts
        end
    end
    for name, rect in pairs(map_context.rect_zones or {}) do
        if not excluded[name] and not spawn_zone_names[name] then
            point_labels[name] = zones.expand(rect, "grid", rect.w * rect.h)
        end
    end

    log.debug("[pod_mission] total units=", #units,
        " (", (function()
            local e = 0
            for _, u in ipairs(units) do if u.side == "enemy" then e = e + 1 end end
            return e
        end)(), " enemy + 1 player group)")

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
