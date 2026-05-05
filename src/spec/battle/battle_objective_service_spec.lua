---@brief
--- Tests for battle_objective_service: objective checking and text generation.

local luassert = require("luassert")
local battle_objective_service = require("src.tactics.battle.battle_objective_service")

-- Minimal battle map mock.  Accepts two lists of unit-like tables and
-- filters them by the predicate supplied to get_units / get_dead_units.
local function make_map(living_units, dead_units)
    living_units = living_units or {}
    dead_units = dead_units or {}
    return {
        get_units = function(_, predicate)
            local out = {}
            for _, u in ipairs(living_units) do
                if predicate(u) then table.insert(out, u) end
            end
            return out
        end,
        get_dead_units = function(_, predicate)
            local out = {}
            for _, u in ipairs(dead_units) do
                if predicate(u) then table.insert(out, u) end
            end
            return out
        end,
    }
end

-- Unit-like tables compatible with BattleUnit.is_enemy / is_player predicates
-- and with the inline lambdas in objective.lua that call unit:is_enemy() etc.
local function player(tags)
    local u = { side = "player", tags = tags or {} }
    function u:is_player() return self.side == "player" end

    function u:is_enemy() return self.side == "enemy" end

    return u
end

local function enemy(tags)
    local u = { side = "enemy", tags = tags or {} }
    function u:is_player() return self.side == "player" end

    function u:is_enemy() return self.side == "enemy" end

    return u
end

-- Convenience: build a service directly from definition-style tables.
local function make_service(map, turn_limit, victories, failures)
    return battle_objective_service.new(map, turn_limit, victories, failures)
end

describe("tactics.battle.battle_objective_service", function()
    describe("check_objectives", function()
        it("returns finished=false when nothing triggers", function()
            -- Both a living player and a living enemy: rout and all_players_die are both unsatisfied.
            local map = make_map({ player(), enemy() }, {})
            local svc = make_service(map, nil,
                { { type = "rout", text = "Rout" } },
                { { type = "all_players_die", text = "Survive" } }
            )
            local result = svc:check_objectives()
            luassert.is_false(result.finished)
            luassert.is_nil(result.result)
        end)

        it("returns VICTORY when the victory condition triggers", function()
            local map = make_map({}, {}) -- no living units → rout succeeds
            local svc = make_service(map, nil,
                { { type = "rout", text = "Rout" } },
                {}
            )
            local result = svc:check_objectives()
            luassert.is_true(result.finished)
            luassert.are_equal("VICTORY", result.result)
        end)

        it("returns DEFEAT when a failure condition triggers", function()
            local map = make_map({}, {}) -- no living players → all_players_die triggers
            local svc = make_service(map, nil,
                {},
                { { type = "all_players_die", text = "Survive" } }
            )
            local result = svc:check_objectives()
            luassert.is_true(result.finished)
            luassert.are_equal("DEFEAT", result.result)
        end)

        it("failure is checked before victory — defeat wins when both trigger", function()
            -- No living players (failure) AND no living enemies (victory) both trigger.
            local map = make_map({}, {})
            local svc = make_service(map, nil,
                { { type = "rout", text = "Rout" } },
                { { type = "all_players_die", text = "Survive" } }
            )
            local result = svc:check_objectives()
            luassert.is_true(result.finished)
            luassert.are_equal("DEFEAT", result.result)
        end)

        it("turn limit exceeded triggers TurnLimit failure condition", function()
            local map = make_map({ player() }, {})
            local svc = make_service(map, 5,
                {},
                { { type = "turn_limit", text = "Turn limit" } }
            )
            -- turn 5 is not exceeded (> 5 is false)
            svc:set_turn(5)
            luassert.is_false(svc:check_objectives().finished)
            -- turn 6 exceeds the limit
            svc:set_turn(6)
            local result = svc:check_objectives()
            luassert.is_true(result.finished)
            luassert.are_equal("DEFEAT", result.result)
        end)

        it("turn limit exceeded triggers Survive victory condition", function()
            local map = make_map({ player() }, {})
            local svc = make_service(map, 5,
                { { type = "survive", text = "Survive 5 turns" } },
                {}
            )
            svc:set_turn(5)
            luassert.is_false(svc:check_objectives().finished)
            svc:set_turn(6)
            local result = svc:check_objectives()
            luassert.is_true(result.finished)
            luassert.are_equal("VICTORY", result.result)
        end)

        it("defeat_tagged triggers when no tagged enemies remain", function()
            local map = make_map({ enemy({ boss = false }) }, {})
            local svc = make_service(map, nil,
                { { type = "defeat_tagged", text = "Defeat the boss", tag = "boss" } },
                {}
            )
            -- enemy without "boss" tag → tagged enemies = 0 → victory triggers
            local result = svc:check_objectives()
            luassert.is_true(result.finished)
            luassert.are_equal("VICTORY", result.result)
        end)

        it("defeat_tagged does not trigger while tagged enemies remain", function()
            local map = make_map({ enemy({ boss = true }) }, {})
            local svc = make_service(map, nil,
                { { type = "defeat_tagged", text = "Defeat the boss", tag = "boss" } },
                {}
            )
            luassert.is_false(svc:check_objectives().finished)
        end)

        it("tagged_player_dies triggers when a tagged player is in dead list", function()
            local map = make_map({ player() }, { player({ vip = true }) })
            local svc = make_service(map, nil,
                {},
                { { type = "tagged_unit_dies", text = "Protect the VIP", tag = "vip" } }
            )
            local result = svc:check_objectives()
            luassert.is_true(result.finished)
            luassert.are_equal("DEFEAT", result.result)
        end)

        it("escape triggers when no player units remain on the map", function()
            local map = make_map({}, {})
            local svc = make_service(map, nil,
                { { type = "escape", text = "Escape" } },
                {}
            )
            local result = svc:check_objectives()
            luassert.is_true(result.finished)
            luassert.are_equal("VICTORY", result.result)
        end)
    end)

    describe("objective_text", function()
        it("returns empty table when no conditions have text", function()
            local map = make_map({}, {})
            local svc = make_service(map, nil,
                { { type = "rout" } },
                {}
            )
            luassert.are_equal(0, #svc.objective_text)
        end)

        it("returns victory condition text", function()
            local map = make_map({}, {})
            local svc = make_service(map, nil,
                { { type = "rout", text = "Defeat all enemies" } },
                {}
            )
            luassert.are_equal(1, #svc.objective_text)
            luassert.are_equal("Defeat all enemies", svc.objective_text[1])
        end)

        it("prefixes entries after the first with 'or '", function()
            local map = make_map({}, {})
            local svc = make_service(map, nil,
                { { type = "rout", text = "Defeat all enemies" },
                    { type = "escape", text = "Escape" } },
                {}
            )
            luassert.are_equal(2, #svc.objective_text)
            luassert.are_equal("Defeat all enemies", svc.objective_text[1])
            luassert.are_equal("or Escape", svc.objective_text[2])
        end)

        it("inserts turn counter at position 1 when a turn limit is set", function()
            local map = make_map({}, {})
            local svc = make_service(map, 10,
                { { type = "rout", text = "Defeat all enemies" } },
                {}
            )
            svc:set_turn(3)
            -- "or" prefix is applied before the turn counter is inserted, so the
            -- single condition text keeps no prefix and the counter is index 1.
            luassert.are_equal(2, #svc.objective_text)
            luassert.are_equal("Turn 3/10", svc.objective_text[1])
            luassert.are_equal("Defeat all enemies", svc.objective_text[2])
        end)

        it("prefixes condition texts after the first with 'or ' when turn limit present", function()
            local map = make_map({}, {})
            local svc = make_service(map, 10,
                { { type = "rout", text = "Defeat all enemies" },
                    { type = "escape", text = "Escape" } },
                {}
            )
            svc:set_turn(3)
            luassert.are_equal(3, #svc.objective_text)
            luassert.are_equal("Turn 3/10", svc.objective_text[1])
            luassert.are_equal("Defeat all enemies", svc.objective_text[2])
            luassert.are_equal("or Escape", svc.objective_text[3])
        end)

        it("omits turn counter when no turn limit is set", function()
            local map = make_map({}, {})
            local svc = make_service(map, nil,
                { { type = "rout", text = "Defeat all enemies" } },
                {}
            )
            svc:set_turn(3)
            luassert.are_equal(1, #svc.objective_text)
            luassert.are_equal("Defeat all enemies", svc.objective_text[1])
        end)
    end)
end)
