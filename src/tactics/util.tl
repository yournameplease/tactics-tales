require("src/tactics/types")
require("src/tactics/config")
local lists = require("src/tactics/util/lists")

global function fn_true(): boolean
    return true
end

-- normalize to offsets from first tile
-- multiply by tile scale
global function to_tile_path(path: { Point }): { Point }
    assert(#path > 0)
    --if #path == 0 then return path end

    local base_point = path[1]
    local normalize_point: function(Point): Point =
        function(p: Point): Point
            return (p - base_point) * CONFIG.TILE_SIZE
        end
    return lists.map(normalize_point)(path)
end

global function contains<V>(tab: {V}, val: V): boolean
    for _,v in ipairs(tab) do
        if v == val then
            return true
        end
    end
    return false
end

