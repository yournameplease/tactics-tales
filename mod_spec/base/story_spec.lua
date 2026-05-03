local luassert = require("luassert")

local campaign = require("base.lib.campaign").campaign

describe("base.lib.campaign", function()
    describe("config_branch", function()
        it("returns a factory function", function()
            local factory = campaign.config_branch(function(_) return true end, { type = "advance" }, { type = "advance" })
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
                function(c) received_config = c; return true end,
                { type = "advance" },
                { type = "advance" }
            )
            factory(config)
            luassert.are_equal(config, received_config)
        end)
    end)

    describe("memory_branch", function()
        it("returns a factory function", function()
            local factory = campaign.memory_branch(function(_, _) return true end, { type = "advance" }, { type = "advance" })
            luassert.are_equal("function", type(factory))
        end)

        it("returns node_if_true when predicate is true", function()
            local node_true = { type = "text", text = "yes" }
            local node_false = { type = "text", text = "no" }
            local factory = campaign.memory_branch(function(_, _) return true end, node_true, node_false)
            luassert.are_equal(node_true, factory({}, {}, {}))
        end)

        it("returns node_if_false when predicate is false", function()
            local node_true = { type = "text", text = "yes" }
            local node_false = { type = "text", text = "no" }
            local factory = campaign.memory_branch(function(_, _) return false end, node_true, node_false)
            luassert.are_equal(node_false, factory({}, {}, {}))
        end)

        it("passes config and state_map to the predicate", function()
            local received_config, received_state = nil, nil
            local config = { difficulty = "hard" }
            local state = { hero_name = "Aeron" }
            local factory = campaign.memory_branch(
                function(c, s) received_config = c; received_state = s; return true end,
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
            local factory = campaign.memory_branch(
                function(_, s) return s["flag"] == "true" end,
                node_true,
                node_false
            )
            luassert.are_equal(node_true, factory({}, {}, { flag = "true" }))
            luassert.are_equal(node_false, factory({}, {}, { flag = "false" }))
        end)
    end)
end)
