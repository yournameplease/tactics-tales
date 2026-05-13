local luassert       = require("luassert")

local battles_mod    = require("tt_procedural_campaign.game_data.missions")
local campaign_state = require("src.tactics.campaign.campaign_state")
local random         = require("src.tactics.util.random")

local function make_mem()
    return campaign_state.new({ get_character = function() return nil end })
end

local function make_sc(mem)
    return setmetatable({ memory = mem }, {})
end

local function make_rng_ctx(seed)
    return { battle_rng = random.new(seed or 1) }
end

local function skirmish(campaign_config, rng_ctx)
    return battles_mod["skirmish"](campaign_config, rng_ctx or make_rng_ctx())
end

local function find_unit(battle_def, tile)
    for _, u in ipairs(battle_def.units) do
        if u.tile == tile then return u end
    end
end

describe("tt_procedural_campaign.missions skirmish", function()
    it("declares recruit_slot tile label", function()
        local sc = make_sc(make_mem())
        local def = skirmish(sc)
        luassert.is_not_nil(def.tile_labels["recruit_slot"])
    end)

    it("spawns normal enemy at recruit_slot when no turncoat_enemy pending", function()
        local mem = make_mem()
        mem:set("pending_recruits", campaign_state.list({}))
        local def = skirmish(make_sc(mem))
        local unit = find_unit(def, "recruit_slot")
        luassert.is_not_nil(unit)
        luassert.are_equal("enemy", unit.side)
        luassert.is_nil(unit.tags or nil) -- no "turncoat" tag on normal enemy
    end)

    it("spawns turncoat unit at recruit_slot when turncoat_enemy is pending", function()
        local mem = make_mem()
        mem:set("pending_recruits", campaign_state.list({ "turncoat_enemy" }))
        local def = skirmish(make_sc(mem))
        local unit = find_unit(def, "recruit_slot")
        luassert.is_not_nil(unit)
        luassert.are_equal("enemy", unit.side)
        local has_tag = false
        for _, t in ipairs(unit.tags or {}) do
            if t == "turncoat" then has_tag = true end
        end
        luassert.is_true(has_tag)
    end)

    it("adds an interaction script when turncoat_enemy is pending", function()
        local mem = make_mem()
        mem:set("pending_recruits", campaign_state.list({ "turncoat_enemy" }))
        local def = skirmish(make_sc(mem))
        luassert.is_true(#def.scripts > 0)
    end)

    it("has no interaction scripts when no turncoat_enemy is pending", function()
        local mem = make_mem()
        mem:set("pending_recruits", campaign_state.list({}))
        local def = skirmish(make_sc(mem))
        luassert.are_equal(0, #def.scripts)
    end)

    it("works when memory is absent from campaign_config", function()
        local sc = {}
        luassert.has_no_error(function()
            skirmish(sc)
        end)
    end)

    it("turncoat script has on_talk trigger for 'turncoat' tag", function()
        local mem = make_mem()
        mem:set("pending_recruits", campaign_state.list({ "turncoat_enemy" }))
        local def = skirmish(make_sc(mem))
        local s = def.scripts[1]
        luassert.is_not_nil(s)
        luassert.are_equal("unit_interaction", s.trigger.type)
        local trigger = s.trigger --[[@as UnitInteraction]]
        local specifier = trigger.unit_specifier --[[@as TagLookupUnitSelector]]
        luassert.are_equal("turncoat", specifier.tag)
    end)

    it("turncoat script includes recruit_unit effect", function()
        local mem = make_mem()
        mem:set("pending_recruits", campaign_state.list({ "turncoat_enemy" }))
        local def = skirmish(make_sc(mem))
        local s = def.scripts[1]
        local has_recruit = false
        for _, e in ipairs(s.effects) do
            if e.type == "recruit_units" then has_recruit = true end
        end
        luassert.is_true(has_recruit)
    end)
end)
