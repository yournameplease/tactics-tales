---@brief
--- Data structure with a 0-indexed 2d array
--- with utilities for point access

require("src/tactics/types")

local interface Array2D<V>
    w: integer
    h: integer
    
    get: function(self, x: integer, y: integer): V
    get_point: function(self, p: Point): V
    set: function(self, x: integer, y: integer, v: V)
    set_point: function(self, p: Point, v: V)
    foreach: function(self, fn: function(x: integer, y: integer, v: V))
    foreachpoint: function(self, fn: function(point: Point, v: V))
end

local array_2d = {
    Array2D = Array2D
}

local record Array2DImpl<V>
    is Array2D<V>
    data: {integer: { integer: V }}
end

function array_2d.new<V>(w: integer, h: integer, initial?: V): Array2D<V>
    local out: Array2DImpl<V> = {
        w = w,
        h = h,
        data = {}
    }
    for x=1, w do
        out.data[x] = {}
        if initial ~= nil then
            for y=1,h do
                out.data[x][y] = initial
            end 
        end
    end
    setmetatable(out, { __index = Array2DImpl })
    return out
end

function Array2DImpl:get(x: integer, y: integer): V
    assert(x >= 0 and y >= 0 and x < self.w and y < self.h)
    return self.data[x+1][y+1]
end

function Array2DImpl:get_point(p: Point): V
    return self:get(p.x, p.y)
end

function Array2DImpl:set(x: integer, y: integer, v: V)
    assert(x >= 0 and y >= 0 and x < self.w and y < self.h)
    self.data[x+1][y+1] = v
end

function Array2DImpl:set_point(p: Point, v: V)
    self:set(p.x, p.y, v)
end

function Array2DImpl:foreach(fn: function(x: integer, y: integer, v: V))
    for x, col in pairs(self.data) do
        for y, v in pairs(col) do
            fn(x-1, y-1, v)
        end
    end
end

function Array2DImpl:foreachpoint(fn: function(point: Point, v: V))
    for x, col in pairs(self.data) do
        for y, v in pairs(col) do
            fn(TilePoint.of(x-1, y-1), v)
        end
    end
end

return array_2d
