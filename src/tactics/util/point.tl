local record Point
    x: integer
    y: integer
    copy: function(self): Point
    
    metamethod __eq: function(Point|any, Point|any): boolean
    metamethod __add: function(Point|any, Point|any): Point
    metamethod __sub: function(Point|any, Point|any): Point
    metamethod __mul: function(Point|number, Point|number): Point -- gets rounded!
    metamethod __unm: function(Point): Point
    metamethod __tostring: function(Point): string
end

local point = {
	Point = Point
}

local point_of: (function(integer, integer): Point)


local point_mt: metatable<Point> = {
    __eq = function(a: Point, b: Point): boolean
        return a.x == b.x and a.y == b.y
    end,
    __add = function(a: Point, b: Point): Point
        return point_of(a.x + b.x, a.y + b.y)
    end,
    __sub = function(a: Point, b: Point): Point
        return point_of(a.x - b.x, a.y - b.y)
    end,
    __mul = function(a: Point|number, b: Point|number): Point
        if a is number then
            assert(b is Point)
            return point_of(pt.flr(a * b.x), pt.flr(a * b.y))
        end
        if b is number then
            assert(a is Point)
            return point_of(pt.flr(a.x * b), pt.flr(a.y * b))
        end
        return point_of(a.x * b.x, a.y * b.y)
    end,
    __unm = function(p: Point): Point
        return point_of(- p.x, - p.y)
    end,
    __tostring = function(p: Point): string
        return "("..p.x..","..p.y..")"
    end,
    __index = Point
}

function point.of(x: integer, y: integer): Point
    assert(x ~= nil)
    assert(y ~= nil)
    return setmetatable({
        x = x,
        y = y
    }, point_mt)
end

point_of = point.of

function point.of_angle(angle: number, scale: number): Point
    local x = pt.flr(scale * pt.cos(angle) + 0.5)
    local y = pt.flr(scale * pt.sin(angle) + 0.5)
    return point.of(x, y)
end
function Point:copy(): Point
    return setmetatable({
        x = self.x,
        y = self.y
    }, point_mt as metatable<Point>)
end

function point.taxicab_distance(p1: Point, p2: Point): integer
    return pt.abs(p1.x-p2.x)+pt.abs(p1.y-p2.y)
end

return point
