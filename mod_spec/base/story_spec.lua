local luassert = require("luassert")

local story = require("base.lib.story").story

describe("base.lib.story", function()
    describe("config_branch", function()
        it("returns a factory function", function()
            local factory = story.config_branch(function(_) return true end, { type = "advance" }, { type = "advance" })
            luassert.are_equal("function", type(factory))
        end)

        it("returns node_if_true when predicate is true", function()
            local node_true = { type = "text", text = "yes" }
            local node_false = { type = "text", text = "no" }
            local factory = story.config_branch(function(_) return true end, node_true, node_false)
            luassert.are_equal(node_true, factory({}))
        end)

        it("returns node_if_false when predicate is false", function()
            local node_true = { type = "text", text = "yes" }
            local node_false = { type = "text", text = "no" }
            local factory = story.config_branch(function(_) return false end, node_true, node_false)
            luassert.are_equal(node_false, factory({}))
        end)

        it("passes the full config table to the predicate", function()
            local received_config = nil
            local config = { difficulty = "hard" }
            local factory = story.config_branch(
                function(c) received_config = c; return true end,
                { type = "advance" },
                { type = "advance" }
            )
            factory(config)
            luassert.are_equal(config, received_config)
        end)
    end)
end)
