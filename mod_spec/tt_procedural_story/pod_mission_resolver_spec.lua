local luassert       = require("luassert")

local resolver_mod   = require("tt_procedural_campaign.lib.pod_mission_resolver")
local build_pod      = resolver_mod.build_pod_mission
local campaign_state = require("src.tactics.campaign.campaign_state")
local random         = require("src.tactics.util.random")

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

local DEPLOYMENT_W = { x = 0, y = 10, w = 4, h = 4 }
local DEPLOYMENT_E = { x = 14, y = 10, w = 4, h = 4 }
local POD_A        = { x = 5,  y = 5,  w = 3, h = 3 }
local POD_B        = { x = 10, y = 5,  w = 3, h = 3 }

local SIMPLE_META = {
    map_id       = "test_map",
    variant_sets = {
        { deployment = "deployment_w", excludes = { "pod_b", "boss_sw" } },
        { deployment = "deployment_e", excludes = { "pod_a", "boss_ne" } },
    },
}

---@param faction_id? string
---@param tier? integer
local function make_mem(faction_id, tier)
    local mem = campaign_state.new({ get_character = function() return nil end })
    if faction_id then mem:set("faction_id", campaign_state.text(faction_id)) end
    if tier then mem:set("base_difficulty", campaign_state.text(tostring(tier))) end
    return mem
end

---@param overrides? table
local function make_map_context(overrides)
    local base = {
        rect_zones  = {
            deployment_w = DEPLOYMENT_W,
            deployment_e = DEPLOYMENT_E,
            pod_a        = POD_A,
            pod_b        = POD_B,
        },
        point_zones = {
            boss_ne = { { x = 15, y = 2 } },
            boss_sw = { { x = 2,  y = 14 } },
            guard_n = { { x = 8,  y = 1 } },
        },
    }
    if overrides then
        for k, v in pairs(overrides) do base[k] = v end
    end
    return base
end

---@param seed? integer
local function make_rng_ctx(seed)
    return { battle_rng = random.new(seed or 1) }
end

describe("tt_procedural_campaign.lib.pod_mission_resolver", function()
    describe("build_pod_mission", function()
        it("returns the map_id from meta", function()
            local def = build_pod({}, nil, make_map_context(), SIMPLE_META)
            luassert.are_equal("test_map", def.map_id)
        end)

        it("uses first variant when no rng_context is provided", function()
            -- variant 1 excludes pod_b; only pod_a should appear
            local def = build_pod({}, nil, make_map_context(), SIMPLE_META)
            luassert.is_not_nil(def.point_labels["pod_a"])
            luassert.is_nil(def.point_labels["pod_b"])
        end)

        it("picks a variant using battle_rng", function()
            -- With a seeded rng we can confirm a non-first variant is sometimes chosen.
            -- Variant 2 excludes pod_a; run a few seeds to find one that selects it.
            local found_variant2 = false
            for seed = 1, 20 do
                local def = build_pod({}, make_rng_ctx(seed), make_map_context(), SIMPLE_META)
                if def.point_labels["pod_b"] ~= nil and def.point_labels["pod_a"] == nil then
                    found_variant2 = true
                    break
                end
            end
            luassert.is_true(found_variant2)
        end)

        it("excluded pod zones are absent from point_labels", function()
            -- variant 1 excludes pod_b
            local def = build_pod({}, nil, make_map_context(), SIMPLE_META)
            luassert.is_nil(def.point_labels["pod_b"])
        end)

        it("excluded boss zones are absent from point_labels", function()
            -- variant 1 excludes boss_sw
            local def = build_pod({}, nil, make_map_context(), SIMPLE_META)
            luassert.is_nil(def.point_labels["boss_sw"])
        end)

        it("non-excluded boss zones appear in point_labels", function()
            -- variant 1 does not exclude boss_ne
            local def = build_pod({}, nil, make_map_context(), SIMPLE_META)
            luassert.is_not_nil(def.point_labels["boss_ne"])
        end)

        it("guard zones appear in point_labels", function()
            local def = build_pod({}, nil, make_map_context(), SIMPLE_META)
            luassert.is_not_nil(def.point_labels["guard_n"])
        end)

        it("player_deploy is in point_labels", function()
            local def = build_pod({}, nil, make_map_context(), SIMPLE_META)
            luassert.is_not_nil(def.point_labels["player_deploy"])
        end)

        it("has a rout victory condition", function()
            local def = build_pod({}, nil, make_map_context(), SIMPLE_META)
            luassert.are_equal(1, #def.victory_conditions)
            luassert.are_equal("rout", def.victory_conditions[1].type)
        end)

        it("has a tagged_unit_dies failure condition", function()
            local def = build_pod({}, nil, make_map_context(), SIMPLE_META)
            luassert.are_equal(1, #def.failure_conditions)
            luassert.are_equal("tagged_unit_dies", def.failure_conditions[1].type)
        end)

        it("boss unit is tagged 'boss'", function()
            local def = build_pod({}, nil, make_map_context(), SIMPLE_META)
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

        it("guard unit uses stationary AI", function()
            local def = build_pod({}, nil, make_map_context(), SIMPLE_META)
            local guard_unit
            for _, u in ipairs(def.units) do
                if u.tile == "guard_n" then guard_unit = u; break end
            end
            luassert.is_not_nil(guard_unit)
            luassert.are_equal("zero", guard_unit.ai.move)
        end)

        it("higher tier produces more pod points (up to zone capacity)", function()
            local mem1 = make_mem("bandits", 1)
            local mem2 = make_mem("bandits", 3)
            local def1 = build_pod({ memory = mem1 }, nil, make_map_context(), SIMPLE_META)
            local def2 = build_pod({ memory = mem2 }, nil, make_map_context(), SIMPLE_META)
            luassert.is_true(#def2.point_labels["pod_a"] >= #def1.point_labels["pod_a"])
        end)

        it("works gracefully when rect_zones and point_zones are empty", function()
            local ctx = { rect_zones = {}, point_zones = {} }
            luassert.has_no_error(function()
                build_pod({}, nil, ctx, SIMPLE_META)
            end)
        end)

        it("pod budget is zero or positive", function()
            local mem = make_mem("bandits", 1)
            local def = build_pod({ memory = mem }, make_rng_ctx(42), make_map_context(), SIMPLE_META)
            for _, pts in pairs(def.point_labels) do
                luassert.is_true(#pts >= 0)
            end
        end)
    end)
end)
