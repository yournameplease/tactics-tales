
-- Utility types for the migration Lua -> Teal
-- TODO: these should eventually move into relevant files

global type Numerical = number | integer

global type Angle = number

global type Color = integer

local interface Point
    x: integer
    y: integer
    copy: function(self): self
    metamethod __eq: function<A is Point, B is Point>(A|any, B|any): boolean
    metamethod __add: function<A is Point, B is Point>(A|any, B|any): A--|B
    metamethod __sub: function<A is Point, B is Point>(A|any, B|any): A--|B
    metamethod __mul: function<A is Point, B is Point>(A|number|any, B|number|any): A--|B -- gets rounded!
    metamethod __unm: function<A is Point>(A): A
    metamethod __tostring: function<A is Point>(A): string
end

local point = {
    Point = Point,
}

local record PointImpl
    is Point
end

local base_point_mt: metatable<PointImpl>

function point.of(x: integer, y: integer): PointImpl
    return setmetatable({
        x = x,
        y = y
    }, base_point_mt)
end

function point.of_angle(angle: number, scale: number): PointImpl
    local x = pt.flr(scale * pt.cos(angle) + 0.5)
    local y = pt.flr(scale * pt.sin(angle) + 0.5)
    return point.of(x, y)
end

base_point_mt = {
    __eq = function(a: Point, b: Point): boolean
        return a.x == b.x and a.y == b.y
    end,
    __add = function(a: Point, b: Point): Point
        return point.of(a.x + b.x, a.y + b.y)
    end,
    __sub = function(a: Point, b: Point): Point
        return point.of(a.x - b.x, a.y - b.y)
    end,
    __mul = function(a: Point|number, b: Point|number): Point
        if a is number then
            assert(b is Point)
            return point.of(pt.flr(a * b.x), pt.flr(a * b.y))
        end
        if b is number then
            assert(a is Point)
            return point.of(pt.flr(a.x * b), pt.flr(a.y * b))
        end
        return point.of(a.x * b.x, a.y * b.y)
    end,
    __unm = function(p: Point): Point
        return point.of(- p.x, - p.y)
    end,
    __tostring = function(p: Point): string
        return "("..p.x..","..p.y..")"
    end,
    __index = PointImpl
}

function PointImpl:copy(): PointImpl
    return setmetatable({
        x = self.x,
        y = self.y
    }, base_point_mt as metatable<PointImpl>)
end

setmetatable(PointImpl, base_point_mt)


function point.taxicab_distance(p1: Point, p2: Point): integer
    return pt.abs(p1.x-p2.x)+pt.abs(p1.y-p2.y)
end

global type Side = integer

return point
