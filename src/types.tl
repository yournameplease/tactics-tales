
-- Utility types for the migration Lua -> Teal
-- TODO: these should eventually move into relevant files

global type Numerical = number | integer

global type Angle = number

global type Color = integer

global interface Point
    x: integer
    y: integer
    of: function(integer,integer): self
    of_angle: function(number,number): self-- gets rounded!
    copy: function(self): self
    metamethod __add: function(Point, Point): Point
    metamethod __sub: function(Point, Point): Point
    metamethod __mul: function(Point|integer, Point|integer): Point
    metamethod __unm: function(Point): Point
    metamethod __tostring: function(Point): string
end

local record BasePoint
    is Point
end

local base_point_mt = {
    __add = function(a: Point, b: Point): Point
        return BasePoint.of(a.x + b.x, a.y + b.y)
    end,
    __sub = function(a: Point, b: Point): Point
        return BasePoint.of(a.x - b.x, a.y - b.y)
    end,
    __mul = function(a: Point|integer, b: Point|integer): Point
        if a is integer then
            assert(b is Point)
            return BasePoint.of(a * b.x, a * b.y)
        end
        if b is integer then
            assert(a is Point)
            return BasePoint.of(a.x * b, a.y * b)
        end
        return BasePoint.of(a.x * b.x, a.y * b.y)
    end,
    __unm = function(p: Point): Point
        return BasePoint.of(- p.x, - p.y)
    end,
    __tostring = function(p: Point): string
        return "("..p.x..","..p.y..")"
    end,
    __index = BasePoint
}

function BasePoint.of(x: integer, y: integer): BasePoint
    return setmetatable({
        x = x,
        y = y
    }, base_point_mt as metatable<BasePoint>)
end

function BasePoint.of_angle(angle: number, scale: number): BasePoint
    local x = flr(scale * cos(angle) + 0.5) 
    local y = flr(scale * sin(angle) + 0.5) 
    return BasePoint.of(x, y)
end

function BasePoint:copy(): BasePoint
    return setmetatable({
        x = self.x,
        y = self.y
    }, base_point_mt as metatable<BasePoint>)
end

setmetatable(BasePoint, base_point_mt)

global record ScalePoint
    is Point
end
setmetatable(ScalePoint, { __index = BasePoint })

global record TilePoint
    is Point
end
setmetatable(TilePoint, { __index = BasePoint })

global record WorldPoint
    is Point
end
setmetatable(WorldPoint, { __index = BasePoint })

global record AnimationOffset
    is Point
end
setmetatable(AnimationOffset, { __index = BasePoint })

global record AnimationAnchorPoint
    is Point
end
setmetatable(AnimationAnchorPoint, { __index = BasePoint })

global record DrawPoint
    is Point
end
setmetatable(DrawPoint, { __index = BasePoint })

global function taxicab_distance(p1: Point, p2: Point): integer
    return abs(p1.x-p2.x)+abs(p1.y-p2.y)
end

global type Side = integer
