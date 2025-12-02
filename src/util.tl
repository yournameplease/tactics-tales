require("src/types")

require("src/config")
-- http://lua-users.org/wiki/CopyTable
-- global function deepcopy(orig)
--     local orig_type = type(orig)
--     local copy
--     if orig_type == 'table' then
--         copy = {}
--         for orig_key, orig_value in next, orig, nil do
--             copy[deepcopy(orig_key)] = deepcopy(orig_value)
--         end
--         setmetatable(copy, deepcopy(getmetatable(orig)))
--     else -- number, string, boolean, etc
--         copy = orig
--     end
--     return copy
-- end

global function rndi(i: number): integer
    return flr(rnd(i)//1)
end

-- global function choose_random(...)
--     local i = rndi(args.n)+1
--     return args[i]
-- end

global function choose_random_from_list<A>(list: {A}): A
    local i = rndi(#list)+1
    return list[i]
end

global function choose_random_from_table<A>(tab: {string: A}): A
    local list: {A} = {}
    for _, v in pairs(tab) do
        add(list, v)
    end
    return choose_random_from_list(list)
end

global function reverse_list<A>(list: {A}): {A} 
    local out = {}
    for i = 1,#list do
        out[#list-i+1] = list[i]
    end
    return out
end

global function fn_true(): boolean
    return true
end

global function tmap<K, A, B>(tab: {K: A}, fn: function(A): B): { K: B }
    local out = {}
    for k,v in pairs(tab) do
        out[k] = fn(v)
    end
    return out
end

global function reduce<A, V>(list: {A}, initial: V, fn: function(V, A): V): V
    local val = initial
    for _,e in ipairs(list) do
        val = fn(val, e)
    end
    return val
end

global function sum<A>(list: {A}, fn: function(A): number): number
    return reduce(list, 0, function(s: number, a: A): number return s + fn(a) end)
end

-- normalize to offsets from first tile
-- multiply by tile scale
global function to_tile_path(path: { TilePoint }): { AnimationOffset }
    assert(#path > 0)
    --if #path == 0 then return path end

    local base_point = path[1]
    return tmap(path, function(p: TilePoint): AnimationOffset
        return (p - base_point) * CONFIG.TILE_SIZE
    end)
end

global function contains<V>(tab: {V}, val: V): boolean
    for _,v in ipairs(tab) do
        if v == val then
            return true
        end
    end
    return false
end

global record IdCounter
    id_count: integer
end

function IdCounter:get_id(): integer
    local id = self.id_count
    self.id_count = self.id_count + 1
    return id
end

function IdCounter.new(): IdCounter
    local counter = { id_count = 1 }
    setmetatable(counter, { __index = IdCounter })
    return counter
end

-- 0-indexed methods,
-- but internal structure is 1-indexed
global record Array2D<V>
    w: integer
    h: integer
    _data: {integer: { integer: V }}
end

function Array2D.new<V>(w: integer, h: integer, initial?: V): Array2D<V>
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
    return self._data[x+1][y+1]
end

function Array2D:get_point<V>(p: Point): V
    return self:get(p.x, p.y)
end

function Array2D:set<V>(x: integer, y: integer, v: V)
    assert(x >= 0 and y >= 0 and x < self.w and y < self.h)
    self._data[x+1][y+1] = v
end

function Array2D:set_point<V>(p: Point, v: V)
    self:set(p.x, p.y, v)
end

function Array2D:foreach<V>(fn: function(x: integer, y: integer, v: V))
    for x, col in pairs(self._data) do
        for y, v in pairs(col) do
            fn(x-1, y-1, v)
        end
    end
end

function Array2D:foreachpoint<V>(fn: function(point: Point, v: V))
    for x, col in pairs(self._data) do
        for y, v in pairs(col) do
            fn(TilePoint.of(x-1, y-1), v)
        end
    end
end
