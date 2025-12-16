---@brief
--- Data structure with a 0-indexed 2d array
--- with utilities for point access

require("src/types")

local record Array2D<V>
    w: integer
    h: integer
    data: {integer: { integer: V }}
end

local array_2d = {
    Array2D = Array2D
}

function array_2d.new<V>(w: integer, h: integer, initial?: V): Array2D<V>
    local out = {
        w = w,
        h = h,
        _data = {}
    }
    for x=1, w do
        out._data[x] = {}
        if initial ~= nil then
            for y=1,h do
                out._data[x][y] = initial
            end 
        end
    end
    setmetatable(out, { __index = Array2D })
    return out
end

function Array2D:get<V>(x: integer, y: integer): V
    assert(x >= 0 and y >= 0 and x < self.w and y < self.h)
    return self.data[x+1][y+1]
end

function Array2D:get_point<V>(p: Point): V
    return self:get(p.x, p.y)
end

function Array2D:set<V>(x: integer, y: integer, v: V)
    assert(x >= 0 and y >= 0 and x < self.w and y < self.h)
    self.data[x+1][y+1] = v
end

function Array2D:set_point<V>(p: Point, v: V)
    self:set(p.x, p.y, v)
end

function Array2D:foreach<V>(fn: function(x: integer, y: integer, v: V))
    for x, col in pairs(self.data) do
        for y, v in pairs(col) do
            fn(x-1, y-1, v)
        end
    end
end

function Array2D:foreachpoint<V>(fn: function(point: Point, v: V))
    for x, col in pairs(self.data) do
        for y, v in pairs(col) do
            fn(TilePoint.of(x-1, y-1), v)
        end
    end
end

return array_2d
