local luassert = require("luassert")
local battle_harness = require("src.integration.helpers.battle_harness")

---@class BattleConfigInput
---@field permadeath? boolean

---@param params BattleConfigInput
---@return BattleConfig
local function battle_config(params)
    return {
        permadeath = params.permadeath or true
    }
end

describe("battle flow #it", function()
    local h

    after_each(function()
        if h then h:teardown() end
    end)

    describe("events", function()
        it("emits TACTICS_BEGIN_BATTLE on start", function()
            h = battle_harness.new()
            h:start_battle("rout_no_enemies", battle_config {})
            luassert.are_equal(1, #h:emitted("TACTICS_BEGIN_BATTLE"))
        end)

        it("emits TACTICS_BEGIN_TURN with turn=1 on start", function()
            h = battle_harness.new()
            h:start_battle("rout_no_enemies", battle_config {})
            local turns = h:emitted("TACTICS_BEGIN_TURN")
            luassert.are_equal(1, #turns)
            luassert.are_equal(1, turns[1].turn)
        end)
    end)

    describe("rout_no_enemies", function()
        it("battle_result is VICTORY after finish_player_turn", function()
            h = battle_harness.new()
            h:start_battle("rout_no_enemies", battle_config {})
            h:finish_player_turn()
            luassert.are_equal("VICTORY", h:battle_result())
        end)

        it("emits BATTLE_END once", function()
            h = battle_harness.new()
            h:start_battle("rout_no_enemies", battle_config {})
            h:finish_player_turn()
            luassert.are_equal(1, #h:emitted("BATTLE_END"))
        end)

        it("BATTLE_END payload has result='VICTORY'", function()
            h = battle_harness.new()
            h:start_battle("rout_no_enemies", battle_config {})
            h:finish_player_turn()
            luassert.are_equal("VICTORY", h:emitted("BATTLE_END")[1].result)
        end)
    end)

    describe("turn_limit_defeat", function()
        it("battle not over after one finish_player_turn", function()
            h = battle_harness.new()
            h:start_battle("turn_limit_defeat", battle_config {})
            h:finish_player_turn()
            luassert.is_nil(h:battle_result())
        end)

        it("battle_result is DEFEAT after two finish_player_turns", function()
            h = battle_harness.new()
            h:start_battle("turn_limit_defeat", battle_config {})
            h:finish_player_turn()
            h:finish_player_turn()
            luassert.are_equal("DEFEAT", h:battle_result())
        end)

        it("BATTLE_END payload has result='DEFEAT'", function()
            h = battle_harness.new()
            h:start_battle("turn_limit_defeat", battle_config {})
            h:finish_player_turn()
            h:finish_player_turn()
            luassert.are_equal("DEFEAT", h:emitted("BATTLE_END")[1].result)
        end)

        it("emits TACTICS_BEGIN_TURN twice (turns 1 and 2) before defeat", function()
            h = battle_harness.new()
            h:start_battle("turn_limit_defeat", battle_config {})
            h:finish_player_turn()
            h:finish_player_turn()
            local turns = h:emitted("TACTICS_BEGIN_TURN")
            luassert.are_equal(2, #turns)
            luassert.are_equal(1, turns[1].turn)
            luassert.are_equal(2, turns[2].turn)
        end)
    end)
end)
