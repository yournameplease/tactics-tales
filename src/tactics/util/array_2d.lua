---@brief
--- A generic 2D array data structure with utility methods.

local point = require("src.tactics.util.point")

---@class Array2D<V>
---@field w integer
---@field h integer
---@class Array2D<V> : Array2D<V>
---@field package data table<integer, table<integer, V>> 1-indexed column-major storage (col[x][y]).
local Array2D = {}

local array_2d = {}

--- Create a new Array2D of size `w`×`h`, optionally pre-filled with `initial`.
---@generic V
---@param w integer
---@param h integer
---@param initial? V Optional value to fill every cell; cells are nil when omitted.
---@return Array2D<V>
function array_2d.new(w, h, initial)
    local out = setmetatable({ w = w, h = h, data = {} }, { __index = Array2D })
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

--- Create a new Array2D populated by calling `initial` for each 0-indexed Point.
---@generic V
---@param w integer
---@param h integer
---@param initial fun(p: Point): V Called with each cell's 0-indexed Point to produce its initial value.
---@return Array2D<V>
function array_2d.new_from_function(w, h, initial)
    local out = setmetatable({ w = w, h = h, data = {} }, { __index = Array2D })
    for x = 1, w do
        out.data[x] = {}
        for y = 1, h do
            out.data[x][y] = initial(point.of(x - 1, y - 1))
        end
    end
    return out
end

--- Return true if (x, y) are valid 0-indexed coordinates within this array.
---@param x integer
---@param y integer
---@return boolean
function Array2D:is_in_range(x, y)
    return x >= 0 and y >= 0 and x < self.w and y < self.h
end

--- Return the value at 0-indexed (x, y), asserting the coordinates are in range.
---@generic V
---@param x integer
---@param y integer
---@return V?
function Array2D:get(x, y)
    assert(self:is_in_range(x, y))
    return self.data[x + 1][y + 1]
end

--- Return true if point `p` is within this array's bounds.
---@param p Point
---@return boolean
function Array2D:is_point_in_range(p)
    return self:is_in_range(p.x, p.y)
end

--- Return the value at point `p` (0-indexed).
---@generic V
---@param p Point
---@return V?
function Array2D:get_point(p)
    return self:get(p.x, p.y)
end

--- Set the value at 0-indexed (x, y), asserting the coordinates are in range.
---@generic V
---@param x integer
---@param y integer
---@param v V? Value to store at (x, y).
function Array2D:set(x, y, v)
    assert(x >= 0 and y >= 0 and x < self.w and y < self.h)
    self.data[x + 1][y + 1] = v
end

--- Set the value at point `p` (0-indexed).
---@generic V
---@param p Point
---@param v V? Value to store at `p`.
function Array2D:set_point(p, v)
    self:set(p.x, p.y, v)
end

--- Call `fn` for every cell in the array with its 0-indexed coordinates and value.
---@generic V
---@param fn fun(x: integer, y: integer, v: V) Callback invoked with 0-indexed x, y and the cell value.
function Array2D:foreach(fn)
    for x, col in pairs(self.data) do
        for y, v in pairs(col) do
            fn(x - 1, y - 1, v)
        end
    end
end

--- Call `fn` for every cell in the array with its 0-indexed Point and value.
---@generic V
---@param fn fun(p: Point, v: V) Callback invoked with the 0-indexed Point and cell value.
function Array2D:foreachpoint(fn)
    for x, col in pairs(self.data) do
        for y, v in pairs(col) do
            fn(point.of(x - 1, y - 1), v)
        end
    end
end

--- Return a new Array2D with each cell transformed by `fn`.
---@generic V, NewType
---@param fn fun(v: V): NewType Transform applied to each cell value.
---@return Array2D<NewType>
function Array2D:map(fn)
    local out = array_2d.new(self.w, self.h)
    self:foreachpoint(function(p, v)
        out:set_point(p, fn(v))
    end)
    return out
end

--- Return a new Array2D where each cell is produced by `fn` given its 0-indexed Point.
---@generic NewType
---@param fn fun(p: Point): NewType Produces the new cell value from the cell's 0-indexed Point.
---@return Array2D<NewType>
function Array2D:map_points(fn)
    local out = array_2d.new(self.w, self.h)
    self:foreachpoint(function(p, _)
        out:set_point(p, fn(p))
    end)
    return out
end

return array_2d
