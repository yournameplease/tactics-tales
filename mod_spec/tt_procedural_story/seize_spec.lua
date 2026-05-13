local luassert       = require("luassert")

local battles_mod    = require("tt_procedural_campaign.game_data.missions")
local campaign_state = require("src.tactics.campaign.campaign_state")

local function make_mem()
    ---@diagnostic disable-next-line: missing-fields
    return campaign_state.new({ get_character = function() return nil end })
end

local function make_sc(mem)
    return { memory = mem }
end

local function seize(campaign_config)
    return battles_mod["abandoned_fortress_seize"](campaign_config)
end

local function find_unit(battle_def, side)
    for _, u in ipairs(battle_def.units) do
        if u.side == side then return u end
    end
end

describe("tt_procedural_campaign.missions abandoned_fortress_seize", function()
    it("returns the abandoned_fortress map", function()
        local def = seize({})
        luassert.are_equal("abandoned_fortress", def.map_id)
    end)

    it("has exactly one victory condition", function()
        local def = seize({})
        luassert.are_equal(1, #def.victory_conditions)
    end)

    it("has exactly one failure condition", function()
        local def = seize({})
        luassert.are_equal(1, #def.failure_conditions)
    end)

    it("deploys player to deployment_seize layer", function()
        local def = seize({})
        local u = find_unit(def, "player")
        luassert.is_not_nil(u)
        luassert.are_equal("deployment_seize", u.layer)
    end)

    it("spawns enemy at boss_seize layer", function()
        local def = seize({})
        local u = find_unit(def, "enemy")
        luassert.is_not_nil(u)
        luassert.are_equal("boss_seize", u.layer)
    end)

    it("tags enemy unit as 'boss'", function()
        local def = seize({})
        local u = find_unit(def, "enemy")
        luassert.is_not_nil(u.tags)
        local has_boss = false
        for _, t in ipairs(u.tags) do
            if t == "boss" then has_boss = true end
        end
        luassert.is_true(has_boss)
    end)

    it("works when memory is absent from campaign_config", function()
        luassert.has_no_error(function()
            seize({})
        end)
    end)

    it("resolves faction from memory when present", function()
        local mem = make_mem()
        mem:set("faction_id", campaign_state.text("bandits"))
        local def = seize(make_sc(mem))
        luassert.is_not_nil(def)
        luassert.are_equal("abandoned_fortress", def.map_id)
    end)
end)
