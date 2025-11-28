require("src/types")

local CONFIG = require("src/config")
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

-- normalize to offsets from first tile
-- multiply by tile scale
global function to_tile_path(path: { TilePoint }): { AnimationPoint }
    assert(#path > 0)
    --if #path == 0 then return path end

    local base_x = path[1].x
    local base_y = path[1].y
    return tmap(path, function(p: TilePoint): AnimationPoint
        return {
            x = (p.x - base_x) * CONFIG.TILE_WIDTH,
            y = (p.y - base_y) * CONFIG.TILE_HEIGHT
        }
    end)
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

-- 0-indexed
global record Array2D<V>
    w: integer
    h: integer
    data: {{ V }}
end

function Array2D.new<V>(w: integer, h: integer): Array2D<V>
    local out = {
        w = w,
        h = h,
        data = {}
    }
    for i=0, w-1 do
        out.data[i] = {}
    end
    setmetatable(out, { __index = Array2D })
    return out
end

function Array2D:get<V>(x: integer, y: integer): V
    assert(x >= 0 and y >= 0 and x < self.w and y < self.h)
    return self.data[x][y]
end

function Array2D:set<V>(x: integer, y: integer, v: V)
    assert(x >= 0 and y >= 0 and x < self.w and y < self.h)
    self.data[x][y] = v
end

function Array2D:foreach<V>(fn: function(x: integer, y: integer, v: V))
    for x, col in ipairs(self.data) do
        for y, v in ipairs(col) do
            fn(x, y, v)
        end
    end
end
