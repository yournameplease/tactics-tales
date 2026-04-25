local luassert = require("luassert")
local story_harness = require("src.integration.helpers.story_harness")

describe("story flow #it", function()
    describe("simple_exit", function()
        it("should complete immediately on start", function()
            local h = story_harness.new()
            h:start_story("simple_exit")
            luassert.is_true(h:is_complete())
        end)

        it("should emit GAME_EXIT_STORY", function()
            local h = story_harness.new()
            h:start_story("simple_exit")
            luassert.are_equal(1, #h:emitted("GAME_EXIT_STORY"))
        end)
    end)

    describe("linear_text", function()
        it("should not be complete before any confirm", function()
            local h = story_harness.new()
            h:start_story("linear_text")
            luassert.is_false(h:is_complete())
        end)

        it("should not be complete after one confirm", function()
            local h = story_harness.new()
            h:start_story("linear_text")
            h:confirm()
            luassert.is_false(h:is_complete())
        end)

        it("should complete after two confirms", function()
            local h = story_harness.new()
            h:start_story("linear_text")
            h:confirm()
            h:confirm()
            luassert.is_true(h:is_complete())
        end)
    end)

    describe("advance_and_exit", function()
        it("should complete immediately on start without any confirm", function()
            local h = story_harness.new()
            h:start_story("advance_and_exit")
            luassert.is_true(h:is_complete())
        end)
    end)

    describe("delete_file_and_exit", function()
        it("should complete immediately on start", function()
            local h = story_harness.new()
            h:start_story("delete_file_and_exit")
            luassert.is_true(h:is_complete())
        end)
    end)

    describe("jump_flow", function()
        it("should land on jump_target after starting", function()
            local h = story_harness.new()
            h:start_story("jump_flow")
            luassert.are_equal("jump_target", h:current_node_id())
        end)

        it("should not be complete before any confirm", function()
            local h = story_harness.new()
            h:start_story("jump_flow")
            luassert.is_false(h:is_complete())
        end)

        it("should complete after one confirm from jump_target", function()
            local h = story_harness.new()
            h:start_story("jump_flow")
            h:confirm()
            luassert.is_true(h:is_complete())
        end)
    end)

    describe("single_node_source", function()
        it("should complete when node entry is a bare StoryNode (not wrapped in array)", function()
            local h = story_harness.new({
                stories = {
                    single_node_source = {
                        starting_node = "start",
                        nodes = {
                            start = { type = "exit_story" },
                        },
                    },
                },
            })
            h:start_story("single_node_source")
            luassert.is_true(h:is_complete())
        end)

        it("should complete when node entry is a top-level factory function", function()
            local h = story_harness.new({
                stories = {
                    top_level_factory = {
                        starting_node = "start",
                        nodes = {
                            start = function(_) return { type = "exit_story" } end,
                        },
                    },
                },
            })
            h:start_story("top_level_factory")
            luassert.is_true(h:is_complete())
        end)
    end)

    describe("config_branch", function()
        it("should require a confirm when show_text is true", function()
            local h = story_harness.new()
            h:start_story("config_branch", { show_text = true })
            luassert.is_false(h:is_complete())
            h:confirm()
            luassert.is_true(h:is_complete())
        end)

        it("should complete immediately when show_text is false", function()
            local h = story_harness.new()
            h:start_story("config_branch", { show_text = false })
            luassert.is_true(h:is_complete())
        end)
    end)
end)
