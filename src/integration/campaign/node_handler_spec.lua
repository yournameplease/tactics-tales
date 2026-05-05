-- src/integration/campaign/node_handler_spec.lua
local luassert = require("luassert")
local campaign_harness = require("src.integration.helpers.campaign_harness")

describe("node handlers #it", function()
    -- Helper: inline campaign ending with exit_campaign after the given nodes
    local function single_node_campaign(node)
        return {
            campaigns = {
                test = {
                    starting_node = "start",
                    nodes = {
                        start = {
                            node,
                            { type = "exit_campaign" },
                        },
                    },
                },
            },
        }
    end

    describe("game_results", function()
        it("does not advance without confirm", function()
            local h = campaign_harness.new(single_node_campaign({ type = "game_results" }))
            h:start_campaign("test")
            luassert.is_false(h:is_complete())
        end)

        it("advances after one confirm when no chapters and no roster", function()
            local h = campaign_harness.new(single_node_campaign({ type = "game_results" }))
            h:start_campaign("test")
            h:confirm()
            luassert.is_true(h:is_complete())
        end)

        it("pre-builds unit_pages for roster units including dead", function()
            local campaign_def = {
                starting_node = "start",
                nodes = {
                    start = {
                        { type = "chapter_header", text = "Ch 1",            chapter_number = 1 },
                        { type = "roster_add",     template = "test_fighter" },
                        { type = "roster_add",     template = "test_fighter" },
                        { type = "game_results" },
                        { type = "exit_campaign" },
                    },
                },
            }
            local h = campaign_harness.new({ campaigns = { test = campaign_def } })
            h:start_campaign("test")
            h:confirm() -- advance past chapter_header
            -- Now on game_results node: 0 chapter pages, 2 unit pages
            local node = h:game_results_node()
            luassert.is_not_nil(node)
            ---@cast node RenderedGameResults
            luassert.are_equal(2, #node.unit_pages)
            luassert.are_equal("chapters", node.section)
            luassert.are_equal(1, node.page)
        end)

        it("transitions from chapters to units section on confirm", function()
            local campaign_def = {
                starting_node = "start",
                nodes = {
                    start = {
                        { type = "roster_add",   template = "test_fighter" },
                        { type = "game_results" },
                        { type = "exit_campaign" },
                    },
                },
            }
            local h = campaign_harness.new({ campaigns = { test = campaign_def } })
            h:start_campaign("test")
            -- 0 chapter pages, 1 unit page: first confirm → units section
            h:confirm()
            local node = h:game_results_node()
            luassert.is_not_nil(node)
            ---@cast node RenderedGameResults
            luassert.are_equal("units", node.section)
            luassert.are_equal(1, node.page)
        end)

        it("advances on confirm from last unit page", function()
            local campaign_def = {
                starting_node = "start",
                nodes = {
                    start = {
                        { type = "roster_add",   template = "test_fighter" },
                        { type = "game_results" },
                        { type = "exit_campaign" },
                    },
                },
            }
            local h = campaign_harness.new({ campaigns = { test = campaign_def } })
            h:start_campaign("test")
            h:confirm() -- chapters → units
            h:confirm() -- last unit page → advance
            luassert.is_true(h:is_complete())
        end)

        it("unit_pages include chapter_recruited from chapter_header", function()
            local campaign_def = {
                starting_node = "start",
                nodes = {
                    start = {
                        { type = "chapter_header", text = "Ch 3",            chapter_number = 3 },
                        { type = "roster_add",     template = "test_fighter" },
                        { type = "game_results" },
                        { type = "exit_campaign" },
                    },
                },
            }
            local h = campaign_harness.new({ campaigns = { test = campaign_def } })
            h:start_campaign("test")
            h:confirm() -- advance past chapter_header
            local node = h:game_results_node()
            luassert.is_not_nil(node)
            ---@cast node RenderedGameResults
            luassert.are_equal(1, #node.unit_pages)
            luassert.are_equal(3, node.unit_pages[1].chapter_recruited)
        end)
    end)

    describe("chapter_header", function()
        it("does not advance without confirm", function()
            local h = campaign_harness.new(single_node_campaign({
                type = "chapter_header", text = "Chapter 1", chapter_number = 1,
            }))
            h:start_campaign("test")
            luassert.is_false(h:is_complete())
        end)

        it("advances after one confirm", function()
            local h = campaign_harness.new(single_node_campaign({
                type = "chapter_header", text = "Chapter 1", chapter_number = 1,
            }))
            h:start_campaign("test")
            h:confirm()
            luassert.is_true(h:is_complete())
        end)
    end)

    describe("save_game", function()
        -- TODO: CampaignHarness:start_campaign does not accept a save_name parameter.
        -- Add harness support and a "does not auto-advance when save_name is configured" test.
        it("auto-advances when no save_name is configured", function()
            -- campaign_harness does not configure a save_name by default
            local h = campaign_harness.new(single_node_campaign({ type = "save_game" }))
            h:start_campaign("test")
            luassert.is_true(h:is_complete())
        end)
    end)

    describe("set_memory", function()
        it("auto-advances and writes value to memory", function()
            local h = campaign_harness.new(single_node_campaign(
                { type = "set_memory", key = "greeting", value = "hello" }
            ))
            h:start_campaign("test")
            luassert.is_true(h:is_complete())
            luassert.are_equal("hello", h:memory("greeting").text)
        end)
    end)

    describe("roster_add", function()
        it("records the current chapter number for the recruited unit", function()
            local campaign_def = {
                starting_node = "start",
                nodes = {
                    start = {
                        { type = "chapter_header", text = "Chapter 2",       chapter_number = 2 },
                        { type = "roster_add",     template = "test_fighter" },
                        { type = "exit_campaign" },
                    },
                },
            }
            local h = campaign_harness.new({ campaigns = { test = campaign_def } })
            h:start_campaign("test")
            h:confirm() -- advance past chapter_header
            local results = h:campaign_results()
            local recruited = results.chapter_recruited
            local unit_id = next(recruited)
            luassert.is_not_nil(unit_id)
            luassert.are_equal(2, recruited[unit_id])
        end)
    end)
end)
