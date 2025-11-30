
-- Utility types for the migration Lua -> Teal
-- TODO: these should eventually move into relevant files

global type Numerical = number | integer

global type Angle = number

global type Color = integer

global interface Point<D>
    x: D
    y: D
    of: function(D,D): Point<D>
    metamethod __add: function(Point<D>, Point<D>): Point<D>
    metamethod __sub: function(Point<D>, Point<D>): Point<D>
    metamethod __mul: function(Point<D>, Point<D>): Point<D>
    metamethod __unm: function(Point<D>): Point<D>
    metamethod __tostring: function(Point<D>): string
end

local record BasePoint<D>
    is Point<D>
end

local base_point_mt = {
    __add = function(a: Point<number>, b: Point<number>): Point<number>
        return BasePoint.of(a.x + b.x, a.y + b.y)
    end,
    __sub = function(a: Point<number>, b: Point<number>): Point<number>
        return BasePoint.of(a.x - b.x, a.y - b.y)
    end,
    __mul = function(a: Point<number>, b: Point<number>): Point<number>
        return BasePoint.of(a.x * b.x, a.y * b.y)
    end,
    __unm = function(p: Point<number>): Point<number>
        return BasePoint.of(- p.x, - p.y)
    end,
    __tostring = function(p: Point<number>): string
        return "("..p.x..","..p.y..")"
    end
}

function BasePoint.of(x: D, y: D): Point<D>
    return setmetatable({
        x = x,
        y = y
    }, base_point_mt as metatable<Point>)
end

setmetatable(BasePoint, base_point_mt)


global record TilePoint
    is Point<integer>
    x: integer
    y: integer
end
setmetatable(TilePoint, { __index = BasePoint })

global record WorldPoint
    is Point<integer>
    x: integer
    y: integer
end
setmetatable(WorldPoint, { __index = BasePoint })

global record AnimationOffset
    is Point<number>
    x: number
    y: number
end
setmetatable(AnimationOffset, { __index = BasePoint })

global record AnimationAnchorPoint
    is Point<number>
    x: number
    y: number
end
setmetatable(AnimationAnchorPoint, { __index = BasePoint })

global record DrawPoint
    is Point<number>
    x: number
    y: number
end
setmetatable(DrawPoint, { __index = BasePoint })

global function taxicab_distance(p1: Point<integer>, p2: Point<integer>): integer
    return abs(p1.x-p2.x)+abs(p1.y-p2.y)
end

global type Side = integer
