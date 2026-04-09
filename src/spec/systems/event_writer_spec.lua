local luassert = require("luassert")

local event_bus    = require("src.tactics.systems.event_bus")
local event_writer = require("src.tactics.systems.event_bus.event_writer")

describe("tactics.systems.event_bus.event_writer", function()
    describe("emit", function()
        it("should forward emit calls to the underlying bus", function()
            local bus = event_bus.new()
            local writer = event_writer.new(bus)
            local called = false
            bus:on("BATTLE_END_VICTORY", function() called = true end)
            writer:emit("BATTLE_END_VICTORY", {})
            luassert.is_true(called)
        end)

        it("should pass args through to the bus callbacks", function()
            local bus = event_bus.new()
            local writer = event_writer.new(bus)
            local received = nil
            bus:on("GAME_EXIT_STORY", function(args) received = args end)
            writer:emit("GAME_EXIT_STORY", { reason = "done" })
            luassert.are_equal("done", received.reason)
        end)
    end)
end)
