local luassert = require("luassert")

local zones = require("base.lib.zones")

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

---@param seed integer
---@return RngInstance
local function make_rng(seed)
    local state = math.floor(seed) & 0xFFFFFFFF
    local RngInstance = {}
    RngInstance.__index = RngInstance
    local function advance(self)
        local x = self._state
        x = x ~ ((x << 13) & 0xFFFFFFFF)
        x = x ~ (x >> 17)
        x = x ~ ((x << 5) & 0xFFFFFFFF)
        self._state = x
        return x
    end
    function RngInstance:rndi(i)
        return advance(self) % i
    end
    return setmetatable({ _state = state == 0 and 1 or state }, RngInstance)
end

-- ---------------------------------------------------------------------------

describe("base.lib.zones", function()
    describe("unit_count", function()
        it("floors the division of budget by slot cost", function()
            luassert.are_equal(2, zones.unit_count(12, 5))
        end)

        it("returns zero when budget is less than slot cost", function()
            luassert.are_equal(0, zones.unit_count(3, 5))
        end)
    end)

    describe("expand with grid pattern", function()
        it("returns exactly count points in row-major order on a 3x2 rect", function()
            local rect = { x = 0, y = 0, w = 3, h = 2 }
            local result = zones.expand(rect, "grid", 4)
            luassert.are_equal(4, #result)
            luassert.are_same({ x = 0, y = 0 }, result[1])
            luassert.are_same({ x = 1, y = 0 }, result[2])
            luassert.are_same({ x = 2, y = 0 }, result[3])
            luassert.are_same({ x = 0, y = 1 }, result[4])
        end)

        it("respects rect offset", function()
            local rect = { x = 5, y = 3, w = 2, h = 2 }
            local result = zones.expand(rect, "grid", 1)
            luassert.are_same({ x = 5, y = 3 }, result[1])
        end)

        it("stops at total tile count when count exceeds rect size", function()
            local rect = { x = 0, y = 0, w = 2, h = 2 }
            local result = zones.expand(rect, "grid", 99)
            luassert.are_equal(4, #result)
        end)
    end)

    describe("expand with checkerboard pattern", function()
        it("returns only alternating tiles capped at count", function()
            local rect = { x = 0, y = 0, w = 3, h = 2 }
            local result = zones.expand(rect, "checkerboard", 3)
            luassert.are_equal(3, #result)
            for _, pt in ipairs(result) do
                luassert.are_equal(0, (pt.x + pt.y) % 2)
            end
        end)

        it("skips tiles where (x+y) % 2 != 0", function()
            local rect = { x = 0, y = 0, w = 2, h = 1 }
            local result = zones.expand(rect, "checkerboard", 99)
            luassert.are_equal(1, #result)
            luassert.are_same({ x = 0, y = 0 }, result[1])
        end)
    end)

    describe("expand with random pattern", function()
        it("is deterministic for the same seed", function()
            local rect = { x = 0, y = 0, w = 4, h = 4 }
            local r1 = zones.expand(rect, "random", 6, make_rng(42))
            local r2 = zones.expand(rect, "random", 6, make_rng(42))
            luassert.are_same(r1, r2)
        end)

        it("produces a different order for a different seed", function()
            local rect = { x = 0, y = 0, w = 4, h = 4 }
            local r1 = zones.expand(rect, "random", 8, make_rng(1))
            local r2 = zones.expand(rect, "random", 8, make_rng(9999))
            local same = true
            for i = 1, #r1 do
                if r1[i].x ~= r2[i].x or r1[i].y ~= r2[i].y then
                    same = false
                    break
                end
            end
            luassert.is_false(same)
        end)

        it("returns count points", function()
            local rect = { x = 0, y = 0, w = 4, h = 4 }
            local result = zones.expand(rect, "random", 5, make_rng(1))
            luassert.are_equal(5, #result)
        end)

        it("falls back to sequential order when rng is absent", function()
            local rect = { x = 0, y = 0, w = 3, h = 1 }
            local result = zones.expand(rect, "random", 3)
            luassert.are_same({ x = 0, y = 0 }, result[1])
            luassert.are_same({ x = 1, y = 0 }, result[2])
            luassert.are_same({ x = 2, y = 0 }, result[3])
        end)
    end)
end)
