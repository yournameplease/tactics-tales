local luassert = require("luassert")

local forced_join_mod = require("tt_procedural_story.game_data.forced_join")
local forced_join_node = forced_join_mod.forced_join_node

describe("tt_procedural_story.forced_join", function()
    describe("forced_join_node", function()
        it("returns roster_add node when slot has forced_join", function()
            local slot = { type = "beat", beat_id = "opening_skirmish", forced_join = "bandit_goon" }
            local node = forced_join_node(slot)
            luassert.are_equal("roster_add", node.type)
        end)

        it("uses the slot's forced_join value as the template", function()
            local slot = { type = "beat", forced_join = "militia_spearman" }
            local node = forced_join_node(slot)
            luassert.are_equal("militia_spearman", node.template)
        end)

        it("passes an empty tags table", function()
            local slot = { type = "beat", forced_join = "bandit_goon" }
            local node = forced_join_node(slot)
            luassert.are_same({}, node.tags)
        end)

        it("returns advance node when slot has no forced_join", function()
            local slot = { type = "filler" }
            local node = forced_join_node(slot)
            luassert.are_equal("advance", node.type)
        end)

        it("returns advance node for beat slot without forced_join", function()
            local slot = { type = "beat", beat_id = "final_siege" }
            local node = forced_join_node(slot)
            luassert.are_equal("advance", node.type)
        end)

        it("works for filler slot with forced_join", function()
            local slot = { type = "filler", forced_join = "bandit_goon" }
            local node = forced_join_node(slot)
            luassert.are_equal("roster_add", node.type)
            luassert.are_equal("bandit_goon", node.template)
        end)

        it("returns advance node when slot is nil", function()
            local node = forced_join_node(nil)
            luassert.are_equal("advance", node.type)
        end)
    end)
end)
