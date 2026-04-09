---@brief
--- A generic 2D array data structure with utility methods.

local point = require("src.tactics.util.point")

---@class Array2D<V>
---@field w integer
---@field h integer
---@field is_in_range fun(self: Array2D<V>, x: integer, y: integer): boolean
---@field get fun(self: Array2D<V>, x: integer, y: integer): V
---@field is_point_in_range fun(self: Array2D<V>, p: Point): boolean
---@field get_point fun(self: Array2D<V>, p: Point): V
---@field set fun(self: Array2D<V>, x: integer, y: integer, v: V)
---@field set_point fun(self: Array2D<V>, p: Point, v: V)
---@field foreach fun(self: Array2D<V>, fn: fun(x: integer, y: integer, v: V))
---@field foreachpoint fun(self: Array2D<V>, fn: fun(p: Point, v: V))
---@field map fun(self: Array2D<V>, fn: fun(v: V): any): Array2D<any>
---@field map_points fun(self: Array2D<V>, fn: fun(p: Point): any): Array2D<any>

---@class Array2DImpl<V> : Array2D<V>
---@field data table<integer, table<integer, V>>

local Array2DImpl = {}

local array_2d = {}

---@generic V
---@param w integer
---@param h integer
---@param initial? V
---@return Array2D<V>
function array_2d.new(w, h, initial)
    local out = setmetatable({ w = w, h = h, data = {} }, { __index = Array2DImpl })
    for x = 1, w do
        out.data[x] = {}
        if initial ~= nil then
            for y = 1, h do
                out.data[x][y] = initial
            end
        end
    end
    return out
end

---@generic V
---@param w integer
---@param h integer
---@param initial fun(p: Point): V
---@return Array2D<V>
function array_2d.new_from_function(w, h, initial)
    local out = setmetatable({ w = w, h = h, data = {} }, { __index = Array2DImpl })
    for x = 1, w do
        out.data[x] = {}
        for y = 1, h do
            out.data[x][y] = initial(point.of(x - 1, y - 1))
        end
    end
    return out
end

---@param x integer
---@param y integer
---@return boolean
function Array2DImpl:is_in_range(x, y)
    return x >= 0 and y >= 0 and x < self.w and y < self.h
end

---@generic V
---@param x integer
---@param y integer
---@return V
function Array2DImpl:get(x, y)
    assert(self:is_in_range(x, y))
    return self.data[x + 1][y + 1]
end

---@param p Point
---@return boolean
function Array2DImpl:is_point_in_range(p)
    return self:is_in_range(p.x, p.y)
end

---@generic V
---@param p Point
---@return V
function Array2DImpl:get_point(p)
    return self:get(p.x, p.y)
end

---@generic V
---@param x integer
---@param y integer
---@param v V
function Array2DImpl:set(x, y, v)
    assert(x >= 0 and y >= 0 and x < self.w and y < self.h)
    self.data[x + 1][y + 1] = v
end

---@generic V
---@param p Point
---@param v V
function Array2DImpl:set_point(p, v)
    self:set(p.x, p.y, v)
end

---@generic V
---@param fn fun(x: integer, y: integer, v: V)
function Array2DImpl:foreach(fn)
    for x, col in pairs(self.data) do
        for y, v in pairs(col) do
            fn(x - 1, y - 1, v)
        end
    end
end

---@generic V
---@param fn fun(p: Point, v: V)
function Array2DImpl:foreachpoint(fn)
    for x, col in pairs(self.data) do
        for y, v in pairs(col) do
            fn(point.of(x - 1, y - 1), v)
        end
    end
end

---@generic V, NewType
---@param fn fun(v: V): NewType
---@return Array2D<NewType>
function Array2DImpl:map(fn)
    local out = array_2d.new(self.w, self.h)
    self:foreachpoint(function(p, v)
        out:set_point(p, fn(v))
    end)
    return out
end

---@generic NewType
---@param fn fun(p: Point): NewType
---@return Array2D<NewType>
function Array2DImpl:map_points(fn)
    local out = array_2d.new(self.w, self.h)
    self:foreachpoint(function(p, _)
        out:set_point(p, fn(p))
    end)
    return out
end

return array_2d
