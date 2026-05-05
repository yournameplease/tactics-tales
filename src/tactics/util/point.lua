---@brief
--- Defines a 2D Point object and related vector math utilities.

-- few stray typings:
---@alias Angle number
---@alias Path string
---@alias CardinalDirection "up"|"down"|"left"|"right"


---@class Point
---@field x integer
---@field y integer
---@operator add(Point): Point
---@operator sub(Point): Point
---@operator mul(Point|number): Point
---@operator unm: Point
local Point = {}
Point.__index = Point

---@class PointRecord
---@field x integer
---@field y integer

local point = {}

local point_of -- forward declaration

Point.__eq = function(a, b)
    return a.x == b.x and a.y == b.y
end
Point.__lt = function(a, b)
    return a.y < b.y or (a.y == b.y and a.x < b.x)
end
Point.__le = function(a, b)
    return a.y < b.y or (a.y == b.y and a.x <= b.x)
end
Point.__add = function(a, b)
    return point_of(a.x + b.x, a.y + b.y)
end
Point.__sub = function(a, b)
    return point_of(a.x - b.x, a.y - b.y)
end
Point.__mul = function(a, b)
    if type(a) == "number" then
        return point_of(math.floor(a * b.x), math.floor(a * b.y))
    end
    if type(b) == "number" then
        return point_of(math.floor(a.x * b), math.floor(a.y * b))
    end
    return point_of(a.x * b.x, a.y * b.y)
end
Point.__unm = function(p)
    return point_of(-p.x, -p.y)
end
Point.__tostring = function(p)
    return "(" .. p.x .. "," .. p.y .. ")"
end

--- Construct a Point from integer coordinates.
---@param x integer
---@param y integer
---@return Point
function point.of(x, y)
    assert(x ~= nil)
    assert(y ~= nil)
    return setmetatable({ x = x, y = y }, Point)
end

point_of = point.of

--- Construct a Point from polar coordinates, rounding to the nearest integer.
---@param angle number Angle in radians.
---@param scale number Radial distance (magnitude).
---@return Point
function point.of_angle(angle, scale)
    local x = math.floor(scale * cos(angle) + 0.5)
    local y = math.floor(scale * sin(angle) + 0.5)
    return point.of(x, y)
end

--- Construct a Point from a plain record with `x` and `y` fields.
---@param rec PointRecord Plain table with integer `x` and `y` fields.
---@return Point
function point.of_record(rec)
    return point.of(rec.x, rec.y)
end

--- Return a new Point with the same coordinates.
---@return Point
function Point:copy()
    return setmetatable({ x = self.x, y = self.y }, Point)
end

--- Return the Manhattan (L1) distance between two points.
---@param p1 Point
---@param p2 Point
---@return integer
function point.taxicab_distance(p1, p2)
    return math.abs(p1.x - p2.x) + math.abs(p1.y - p2.y)
end

--- Return the squared Euclidean norm (x²+y²) of the point.
---@param p Point
---@return integer squared Sum of squared coordinates.
function point.norm_squared(p)
    return p.x * p.x + p.y * p.y
end

return point
