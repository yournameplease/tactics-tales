local luassert = require("luassert")

local campaign = require("base.lib.campaign").campaign

describe("base.lib.campaign", function()
    describe("new_page", function()
        it("returns type new_page", function()
            luassert.are_equal("new_page", campaign.new_page().type)
        end)
    end)

    describe("chapter_header", function()
        it("returns type chapter_header", function()
            local node = campaign.chapter_header("Act I", 1)
            luassert.are_equal("chapter_header", node.type)
        end)

        it("stores text and chapter_number", function()
            local node = campaign.chapter_header("Act I", 2)
            luassert.are_equal("Act I", node.text)
            luassert.are_equal(2, node.chapter_number)
        end)
    end)

    describe("text", function()
        it("returns type text", function()
            local node = campaign.text("hello")
            luassert.are_equal("text", node.type)
        end)

        it("stores the text", function()
            local node = campaign.text("hello world")
            luassert.are_equal("hello world", node.text)
        end)
    end)

    describe("save_game", function()
        it("returns type save_game", function()
            luassert.are_equal("save_game", campaign.save_game().type)
        end)
    end)

    describe("delete_file", function()
        it("returns type delete_file", function()
            luassert.are_equal("delete_file", campaign.delete_file().type)
        end)
    end)

    describe("advance", function()
        it("returns type advance", function()
            luassert.are_equal("advance", campaign.advance().type)
        end)
    end)

    describe("exit_campaign", function()
        it("returns type exit_campaign", function()
            luassert.are_equal("exit_campaign", campaign.exit_campaign().type)
        end)
    end)

    describe("game_results", function()
        it("returns type game_results", function()
            luassert.are_equal("game_results", campaign.game_results().type)
        end)
    end)

    describe("recruit", function()
        it("returns type roster_add", function()
            local node = campaign.recruit("hero")
            luassert.are_equal("roster_add", node.type)
        end)

        it("stores template", function()
            local node = campaign.recruit("hero")
            luassert.are_equal("hero", node.template)
        end)

        it("stores tags when provided", function()
            local node = campaign.recruit("hero", { "player" })
            luassert.are_same({ "player" }, node.tags)
        end)
    end)

    describe("start_battle", function()
        it("returns type battle", function()
            local node = campaign.start_battle("b1", { victory = "v", failure = "f" })
            luassert.are_equal("battle", node.type)
        end)

        it("stores battle_id", function()
            local node = campaign.start_battle("bandit_village", { victory = "v", failure = "f" })
            luassert.are_equal("bandit_village", node.battle_id)
        end)

        it("maps victory branch to next_node_victory", function()
            local node = campaign.start_battle("b1", { victory = "win_node", failure = "lose_node" })
            luassert.are_equal("win_node", node.next_node_victory)
        end)

        it("maps failure branch to next_node_failure", function()
            local node = campaign.start_battle("b1", { victory = "win_node", failure = "lose_node" })
            luassert.are_equal("lose_node", node.next_node_failure)
        end)
    end)

    describe("character_customizer", function()
        it("returns type character_customizer", function()
            local node = campaign.character_customizer("hero", "hero_name")
            luassert.are_equal("character_customizer", node.type)
        end)

        it("stores key and name_key", function()
            local node = campaign.character_customizer("hero", "hero_name")
            luassert.are_equal("hero", node.key)
            luassert.are_equal("hero_name", node.name_key)
        end)
    end)

    describe("text_input", function()
        it("returns type text_input", function()
            local node = campaign.text_input("Enter name:", "hero_name")
            luassert.are_equal("text_input", node.type)
        end)

        it("stores text and key", function()
            local node = campaign.text_input("Enter name:", "hero_name")
            luassert.are_equal("Enter name:", node.text)
            luassert.are_equal("hero_name", node.key)
        end)
    end)

    describe("set_state", function()
        it("returns type set_memory", function()
            local node = campaign.set_state("flag", "true")
            luassert.are_equal("set_memory", node.type)
        end)

        it("stores key and value", function()
            local node = campaign.set_state("village", "Herotown")
            luassert.are_equal("village", node.key)
            luassert.are_equal("Herotown", node.value)
        end)
    end)

    describe("jump", function()
        it("returns type jump", function()
            local node = campaign.jump("intro")
            luassert.are_equal("jump", node.type)
        end)

        it("stores next_node", function()
            local node = campaign.jump("intro")
            luassert.are_equal("intro", node.next_node)
        end)
    end)

    describe("detour", function()
        it("returns type detour", function()
            local node = campaign.detour("sub")
            luassert.are_equal("detour", node.type)
        end)

        it("stores target", function()
            local node = campaign.detour("sub")
            luassert.are_equal("sub", node.target)
        end)
    end)

    describe("select_option", function()
        it("returns type select_option", function()
            local node = campaign.select_option({}, "choice")
            luassert.are_equal("select_option", node.type)
        end)

        it("stores options and memory_key", function()
            local opts = { { id = "a", name = "A" } }
            local node = campaign.select_option(opts, "my_choice")
            luassert.are_same(opts, node.options)
            luassert.are_equal("my_choice", node.memory_key)
        end)
    end)

    describe("config_branch", function()
        it("returns a factory function", function()
            local factory = campaign.config_branch(function(_) return true end, { type = "advance" },
                { type = "advance" })
            luassert.are_equal("function", type(factory))
        end)

        it("returns node_if_true when predicate is true", function()
            local node_true = { type = "text", text = "yes" }
            local node_false = { type = "text", text = "no" }
            local factory = campaign.config_branch(function(_) return true end, node_true, node_false)
            luassert.are_equal(node_true, factory({}))
        end)

        it("returns node_if_false when predicate is false", function()
            local node_true = { type = "text", text = "yes" }
            local node_false = { type = "text", text = "no" }
            local factory = campaign.config_branch(function(_) return false end, node_true, node_false)
            luassert.are_equal(node_false, factory({}))
        end)

        it("passes the full config table to the predicate", function()
            local received_config = nil
            local config = { difficulty = "hard" }
            local factory = campaign.config_branch(
                function(c)
                    received_config = c; return true
                end,
                { type = "advance" },
                { type = "advance" }
            )
            factory(config)
            luassert.are_equal(config, received_config)
        end)
    end)

    describe("state_branch", function()
        it("returns a factory function", function()
            local factory = campaign.state_branch(function(_, _) return true end, { type = "advance" },
                { type = "advance" })
            luassert.are_equal("function", type(factory))
        end)

        it("returns node_if_true when predicate is true", function()
            local node_true = { type = "text", text = "yes" }
            local node_false = { type = "text", text = "no" }
            local factory = campaign.state_branch(function(_, _) return true end, node_true, node_false)
            luassert.are_equal(node_true, factory({}, {}, {}))
        end)

        it("returns node_if_false when predicate is false", function()
            local node_true = { type = "text", text = "yes" }
            local node_false = { type = "text", text = "no" }
            local factory = campaign.state_branch(function(_, _) return false end, node_true, node_false)
            luassert.are_equal(node_false, factory({}, {}, {}))
        end)

        it("passes config and state_map to the predicate", function()
            local received_config, received_state = nil, nil
            local config = { difficulty = "hard" }
            local state = { hero_name = "Aeron" }
            local factory = campaign.state_branch(
                function(c, s)
                    received_config = c; received_state = s; return true
                end,
                { type = "advance" },
                { type = "advance" }
            )
            factory(config, {}, state)
            luassert.are_equal(config, received_config)
            luassert.are_equal(state, received_state)
        end)

        it("branches on a state value", function()
            local node_true = { type = "text", text = "met" }
            local node_false = { type = "text", text = "not met" }
            local factory = campaign.state_branch(
                function(_, s) return s["flag"] == "true" end,
                node_true,
                node_false
            )
            luassert.are_equal(node_true, factory({}, {}, { flag = "true" }))
            luassert.are_equal(node_false, factory({}, {}, { flag = "false" }))
        end)
    end)
end)
