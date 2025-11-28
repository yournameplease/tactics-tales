
-- Utility types for the migration Lua -> Teal
-- TODO: these should eventually move into relevant files

global type Angle = number

global type Color = integer

global interface Point
    x: number
    y: number
    metamethod __add: function(Point, Point): Point
end

global record TilePoint
    is Point
    x: integer
    y: integer
end

global record WorldPoint
    is Point
    x: integer
    y: integer
end

global record AnimationOffset
    is Point
    x: number
    y: number
end

global record AnimationAnchorPoint
    is Point
    x: number
    y: number
end

global record DrawPoint
    is Point
    x: number
    y: number
end

global type Side = integer