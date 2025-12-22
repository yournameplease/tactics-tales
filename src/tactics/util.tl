require("src/tactics/types")
local CONFIG = require("src/tactics/config")
local maps = require("src/tactics/util/maps")

global function fn_true(): boolean
    return true
end

-- normalize to offsets from first tile
-- multiply by tile scale
global function to_tile_path(path: { Point }): { Point }
    assert(#path > 0)
    --if #path == 0 then return path end

    --TODO:
    return {Point.of(0,0)}
    -- local base_point = path[1]
    -- return maps.map(path, function(p: Point): Point
    --     return (p - base_point) * CONFIG.TILE_SIZE
    -- end)
end

global function contains<V>(tab: {V}, val: V): boolean
    for _,v in ipairs(tab) do
        if v == val then
            return true
        end
    end
    return false
end

