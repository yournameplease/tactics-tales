local luassert = require("luassert")
local story_harness = require("src.integration.helpers.story_harness")

describe("story battle flow #it", function()
    local h

    after_each(function()
        if h then h:teardown() end
    end)

    describe("battle_and_exit story", function()
        it("story is not complete before finish_player_turn", function()
            h = story_harness.new()
            h:start_story("battle_and_exit")
            luassert.is_false(h:is_complete())
        end)

        it("story is complete after finish_player_turn (victory path)", function()
            h = story_harness.new()
            h:start_story("battle_and_exit")
            h:finish_player_turn()
            luassert.is_true(h:is_complete())
        end)

        it("emits GAME_EXIT_STORY after battle victory", function()
            h = story_harness.new()
            h:start_story("battle_and_exit")
            h:finish_player_turn()
            luassert.are_equal(1, #h:emitted("GAME_EXIT_STORY"))
        end)
    end)
end)
