-- src/integration/story/node_handler_spec.lua
local luassert = require("luassert")
local story_harness = require("src.integration.helpers.story_harness")

describe("node handlers #it", function()
    -- Helper: inline story ending with exit_story after the given nodes
    local function single_node_story(node)
        return {
            stories = {
                test = {
                    starting_node = "start",
                    nodes = {
                        start = {
                            node,
                            { type = "exit_story" },
                        },
                    },
                },
            },
        }
    end

    describe("game_results", function()
        it("does not advance without confirm", function()
            local h = story_harness.new(single_node_story({ type = "game_results" }))
            h:start_story("test")
            luassert.is_false(h:is_complete())
        end)

        it("advances after one confirm", function()
            local h = story_harness.new(single_node_story({ type = "game_results" }))
            h:start_story("test")
            h:confirm()
            luassert.is_true(h:is_complete())
        end)
    end)

    describe("chapter_header", function()
        it("does not advance without confirm", function()
            local h = story_harness.new(single_node_story({
                type = "chapter_header", text = "Chapter 1", chapter_number = 1,
            }))
            h:start_story("test")
            luassert.is_false(h:is_complete())
        end)

        it("advances after one confirm", function()
            local h = story_harness.new(single_node_story({
                type = "chapter_header", text = "Chapter 1", chapter_number = 1,
            }))
            h:start_story("test")
            h:confirm()
            luassert.is_true(h:is_complete())
        end)
    end)

    describe("save_game", function()
        -- TODO: StoryHarness:start_story does not accept a save_name parameter.
        -- Add harness support and a "does not auto-advance when save_name is configured" test.
        it("auto-advances when no save_name is configured", function()
            -- story_harness does not configure a save_name by default
            local h = story_harness.new(single_node_story({ type = "save_game" }))
            h:start_story("test")
            luassert.is_true(h:is_complete())
        end)
    end)

    describe("set_memory", function()
        it("auto-advances and writes value to memory", function()
            local h = story_harness.new(single_node_story(
                { type = "set_memory", key = "greeting", value = "hello" }
            ))
            h:start_story("test")
            luassert.is_true(h:is_complete())
            luassert.are_equal("hello", h:memory("greeting").text)
        end)
    end)
end)
