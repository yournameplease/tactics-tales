
-- Utility types for the migration Lua -> Teal
-- TODO: these should eventually move into relevant files

-- global type numerical = number | integer

global type Angle = number

global type Color = integer

global interface Point<D>
    x: D
    y: D
    metamethod __add: function(Point, Point): Point
end

global record TilePoint
    is Point<integer>
    x: integer
    y: integer
end

global record WorldPoint
    is Point<integer>
    x: integer
    y: integer
end

global record AnimationOffset
    is Point<number>
    x: number
    y: number
end

global record AnimationAnchorPoint
    is Point<number>
    x: number
    y: number
end

global record DrawPoint
    is Point<number>
    x: number
    y: number
end

global function taxicab_distance(p1: Point<integer>, p2: Point<integer>): integer
    return abs(p1.x-p2.x)+abs(p1.y-p2.y)
end

global type Side = integer