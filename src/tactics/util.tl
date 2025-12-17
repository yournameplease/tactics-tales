require("src/types")
require("src/config")
local maps = require("src/util/maps")

global function fn_true(): boolean
    return true
end

-- normalize to offsets from first tile
-- multiply by tile scale
global function to_tile_path(path: { TilePoint }): { AnimationOffset }
    assert(#path > 0)
    --if #path == 0 then return path end

    local base_point = path[1]
    return maps.map(path, function(p: TilePoint): AnimationOffset
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

