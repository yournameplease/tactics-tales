---@brief
--- Defines a 2D Point object and related vector math utilities.

---@class Point
---@field x integer
---@field y integer
---@field copy fun(self: Point): Point
---@operator add(Point): Point
---@operator sub(Point): Point
---@operator mul(Point|number): Point
---@operator unm: Point

---@class PointRecord
---@field x integer
---@field y integer

local point = {}

local point_of  -- forward declaration

local point_mt = {
    __eq = function(a, b)
        return a.x == b.x and a.y == b.y
    end,
    __lt = function(a, b)
        return a.y < b.y or (a.y == b.y and a.x < b.x)
    end,
    __le = function(a, b)
        return a.y < b.y or (a.y == b.y and a.x <= b.x)
    end,
    __add = function(a, b)
        return point_of(a.x + b.x, a.y + b.y)
    end,
    __sub = function(a, b)
        return point_of(a.x - b.x, a.y - b.y)
    end,
    __mul = function(a, b)
        if type(a) == "number" then
            return point_of(math.floor(a * b.x), math.floor(a * b.y))
        end
        if type(b) == "number" then
            return point_of(math.floor(a.x * b), math.floor(a.y * b))
        end
        return point_of(a.x * b.x, a.y * b.y)
    end,
    __unm = function(p)
        return point_of(-p.x, -p.y)
    end,
    __tostring = function(p)
        return "(" .. p.x .. "," .. p.y .. ")"
    end,
}
point_mt.__index = point_mt

---@param x integer
---@param y integer
---@return Point
function point.of(x, y)
    assert(x ~= nil)
    assert(y ~= nil)
    return setmetatable({ x = x, y = y }, point_mt)
end

point_of = point.of

---@param angle number
---@param scale number
---@return Point
function point.of_angle(angle, scale)
    local x = math.floor(scale * math.cos(angle) + 0.5)
    local y = math.floor(scale * math.sin(angle) + 0.5)
    return point.of(x, y)
end

---@param rec PointRecord
---@return Point
function point.of_record(rec)
    return point.of(rec.x, rec.y)
end

---@return Point
function point_mt:copy()
    return setmetatable({ x = self.x, y = self.y }, point_mt)
end

---@param p1 Point
---@param p2 Point
---@return integer
function point.taxicab_distance(p1, p2)
    return math.abs(p1.x - p2.x) + math.abs(p1.y - p2.y)
end

---@param p Point
---@return integer
function point.norm_squared(p)
    return p.x * p.x + p.y * p.y
end

return point
