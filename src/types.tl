
-- Utility types for the migration Lua -> Teal
-- TODO: these should eventually move into relevant files

global interface Point
    x: number
    y: number
end

global record TilePoint
    is Point
    x: integer
    y: integer
end

global record ScreenPoint
    is Point
    x: integer
    y: integer
end

global record AnimationPoint
    is Point
    x: number
    y: number
end

global type Side = integer