local luassert       = require("luassert")

local battles_mod    = require("tt_procedural_campaign.game_data.missions")
local campaign_state = require("src.tactics.campaign.campaign_state")

local DEPLOYMENT_W = { x = 0, y = 12, w = 4, h = 4 }
local POD_SW       = { x = 3, y = 12, w = 2, h = 4 }
local POD_W        = { x = 0, y = 8,  w = 2, h = 3 }
local BOSS_NE      = { x = 15, y = 4 }

local function make_map_context(overrides)
    local base = {
        rect_zones  = {
            deployment_w = DEPLOYMENT_W,
            pod_sw       = POD_SW,
            pod_w        = POD_W,
        },
        point_zones = {
            boss_ne = { BOSS_NE },
        },
    }
    if overrides then
        for k, v in pairs(overrides) do base[k] = v end
    end
    return base
end

local function make_mem(faction_id, tier)
    ---@diagnostic disable-next-line: missing-fields
    local mem = campaign_state.new({ get_character = function() return nil end })
    if faction_id then mem:set("faction_id", campaign_state.text(faction_id)) end
    if tier then mem:set("base_difficulty", campaign_state.text(tostring(tier))) end
    return mem
end

-- No rng → always picks variant_sets[1]: deployment_w, excludes pod_sw and boss_sw.
local function village_overrun(campaign_config, map_ctx)
    return battles_mod["village_overrun"](campaign_config, nil, map_ctx or make_map_context())
end

describe("tt_procedural_campaign.missions village_overrun", function()
    it("returns village_overrun as map_id", function()
        local def = village_overrun({})
        luassert.are_equal("village_overrun", def.map_id)
    end)

    it("has exactly one victory condition", function()
        local def = village_overrun({})
        luassert.are_equal(1, #def.victory_conditions)
    end)

    it("has exactly one failure condition", function()
        local def = village_overrun({})
        luassert.are_equal(1, #def.failure_conditions)
    end)

    it("point_labels contains pod_w entry (active pod in variant 1)", function()
        local def = village_overrun({})
        local pts = def.point_labels["pod_w"]
        luassert.is_not_nil(pts)
    end)

    it("boss_ne is in point_labels with exactly one point", function()
        local def = village_overrun({})
        local pts = def.point_labels["boss_ne"]
        luassert.is_not_nil(pts)
        luassert.are_equal(1, #pts)
        luassert.are_equal(15, pts[1].x)
        luassert.are_equal(4,  pts[1].y)
    end)

    it("higher tier produces more pod_w points (up to zone capacity)", function()
        local mem1 = make_mem("bandits", 1)
        local mem2 = make_mem("bandits", 3)
        local def1 = village_overrun({ memory = mem1 })
        local def2 = village_overrun({ memory = mem2 })
        local count1 = #def1.point_labels["pod_w"]
        local count2 = #def2.point_labels["pod_w"]
        luassert.is_true(count2 >= count1)
    end)

    it("boss unit is tagged 'boss'", function()
        local def = village_overrun({})
        local boss_unit
        for _, u in ipairs(def.units) do
            if u.tile == "boss_ne" then boss_unit = u; break end
        end
        luassert.is_not_nil(boss_unit)
        local has_boss = false
        for _, t in ipairs(boss_unit.tags or {}) do
            if t == "boss" then has_boss = true end
        end
        luassert.is_true(has_boss)
    end)

    it("works when map_context has no zones (graceful fallback)", function()
        local ctx = make_map_context({ rect_zones = {}, point_zones = {} })
        luassert.has_no_error(function()
            village_overrun({}, ctx)
        end)
    end)
end)
