local luassert        = require("luassert")

local factions_mod    = require("tt_procedural_campaign.game_data.factions")
local factions        = factions_mod.factions
local resolve_slot    = factions_mod.resolve_slot
local resolve_slot_cost = factions_mod.resolve_slot_cost

describe("tt_procedural_campaign.factions", function()
    describe("faction data", function()
        it("defines bandits, cultists, and militia", function()
            luassert.is_not_nil(factions.bandits)
            luassert.is_not_nil(factions.cultists)
            luassert.is_not_nil(factions.militia)
        end)

        it("each faction has exactly 2 tiers", function()
            for _, faction in pairs(factions) do
                luassert.are_equal(2, #faction.tiers)
            end
        end)

        it("bandits tier 1 has correct templates", function()
            local t = factions.bandits.tiers[1]
            luassert.are_equal("bandit_goon", t.enemy_infantry)
            luassert.are_equal("bandit_boss", t.enemy_commander)
            luassert.are_equal("bandit_guard", t.enemy_tank)
            luassert.is_nil(t.enemy_ranged)
        end)

        it("bandits tier 2 has correct templates", function()
            local t = factions.bandits.tiers[2]
            luassert.are_equal("bandit_axe", t.enemy_infantry)
            luassert.are_equal("bandit_berzerker", t.enemy_commander)
            luassert.are_equal("bandit_guard", t.enemy_tank)
            luassert.is_nil(t.enemy_ranged)
        end)

        it("cultists tier 1 has correct templates", function()
            local t = factions.cultists.tiers[1]
            luassert.are_equal("cultist_goon", t.enemy_infantry)
            luassert.are_equal("cultist_boss", t.enemy_commander)
            luassert.are_equal("cultist_guard", t.enemy_tank)
            luassert.is_nil(t.enemy_ranged)
        end)

        it("militia tier 1 has ranged", function()
            local t = factions.militia.tiers[1]
            luassert.are_equal("militia_archer", t.enemy_ranged)
        end)

        it("militia tier 2 has ranged", function()
            local t = factions.militia.tiers[2]
            luassert.are_equal("militia_archer", t.enemy_ranged)
        end)

        it("all factions declare enemy_ranged fallback to enemy_infantry", function()
            for name, faction in pairs(factions) do
                luassert.are_equal("enemy_infantry", faction.fallbacks.enemy_ranged,
                    name .. " missing fallback for enemy_ranged")
            end
        end)
    end)

    describe("resolve_slot", function()
        it("returns the template for a present slot", function()
            luassert.are_equal("bandit_goon", resolve_slot(factions.bandits, 1, "enemy_infantry"))
        end)

        it("returns tier 2 template when tier_index is 2", function()
            luassert.are_equal("bandit_axe", resolve_slot(factions.bandits, 2, "enemy_infantry"))
        end)

        it("clamps to last tier when tier_index exceeds tier count", function()
            luassert.are_equal("bandit_axe", resolve_slot(factions.bandits, 99, "enemy_infantry"))
        end)

        it("falls back via fallbacks when slot is absent", function()
            -- bandits have no enemy_ranged; fallback is enemy_infantry → tier 1 infantry
            luassert.are_equal("bandit_goon", resolve_slot(factions.bandits, 1, "enemy_ranged"))
        end)

        it("falls back to tier 2 infantry when requesting ranged at tier 2", function()
            luassert.are_equal("bandit_axe", resolve_slot(factions.bandits, 2, "enemy_ranged"))
        end)

        it("returns nil for a slot with no mapping and no fallback", function()
            local faction_no_fallback = {
                name = "test",
                tiers = { { enemy_infantry = "foo" } },
                fallbacks = {},
            }
            luassert.is_nil(resolve_slot(faction_no_fallback, 1, "enemy_ranged"))
        end)
    end)

    describe("resolve_slot_cost", function()
        it("returns the defined cost for enemy_infantry", function()
            luassert.are_equal(2, resolve_slot_cost(factions.bandits, "enemy_infantry"))
        end)

        it("returns the defined cost for enemy_tank", function()
            luassert.are_equal(5, resolve_slot_cost(factions.bandits, "enemy_tank"))
        end)

        it("returns the defined cost for enemy_commander", function()
            luassert.are_equal(8, resolve_slot_cost(factions.bandits, "enemy_commander"))
        end)

        it("returns 1 for an undefined slot tag", function()
            luassert.are_equal(1, resolve_slot_cost(factions.bandits, "enemy_ranged"))
        end)

        it("falls back to 1 when costs table is absent", function()
            local faction_no_costs = {
                name = "test",
                tiers = { { enemy_infantry = "foo" } },
                fallbacks = {},
            }
            luassert.are_equal(1, resolve_slot_cost(faction_no_costs, "enemy_infantry"))
        end)

        it("militia has a defined cost for enemy_ranged", function()
            luassert.are_equal(3, resolve_slot_cost(factions.militia, "enemy_ranged"))
        end)
    end)
end)
