
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
    metamethod __eq: function<A is Point, B is Point>(A|any, B|any): boolean
    metamethod __add: function<A is Point, B is Point>(A|any, B|any): A--|B
    metamethod __sub: function<A is Point, B is Point>(A|any, B|any): A--|B
    metamethod __mul: function<A is Point, B is Point>(A|number|any, B|number|any): A--|B -- gets rounded!
    metamethod __unm: function<A is Point>(A): A
    metamethod __tostring: function<A is Point>(A): string
end

local record BasePoint
    is Point
end

local base_point_mt = {
    __eq = function(a: Point, b: Point): boolean
        return a.x == b.x and a.y == b.y
    end,
    __add = function(a: Point, b: Point): Point
        return BasePoint.of(a.x + b.x, a.y + b.y)
    end,
    __sub = function(a: Point, b: Point): Point
        return BasePoint.of(a.x - b.x, a.y - b.y)
    end,
    __mul = function(a: Point|number, b: Point|number): Point
        if a is number then
            assert(b is Point)
            return BasePoint.of(flr(a * b.x), flr(a * b.y))
        end
        if b is number then
            assert(a is Point)
            return BasePoint.of(flr(a.x * b), flr(a.y * b))
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
