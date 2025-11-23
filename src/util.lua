
-- http://lua-users.org/wiki/CopyTable
function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function rndi(i)
    return flr(rnd(i)//1)
end

function choose_random(...)
    local i = rndi(args.n)+1
    return args[i]
end

function choose_random_from_list(list)
    local i = rndi(#list)+1
    return list[i]
end

function choose_random_from_table(table)
    local size = 0
    for k, v in pairs(table) do
        size = size + 1
    end
    local i = rndi(size)
    for k, v in pairs(table) do
        if i == 0 then return v end
        i = i - 1
    end
    error("Table was empty! (Or I made a bug here...)")
end

function reverse_list(list)
    local out = {}
    for i = 1,#list do
        out[#list-i+1] = list[i]
    end
    return out
end

function fn_true()
    return true
end

function tmap(table, fn)
    printh("Mapping..." .. #table)
    local out = {}
    for k,v in pairs(table) do
        out[k] = fn(v)
    end
    return out
end

-- normalize to offsets from first tile
-- multiply by tile scale
function to_tile_path(path)
    if #path == 0 then return path end

    local base_x = path[1].x
    local base_y = path[1].y
    return tmap(path, function(p)
        return {
            x = (p.x - base_x) * CONFIG.TILE_WIDTH,
            y = (p.y - base_y) * CONFIG.TILE_HEIGHT
        }
    end)
end

IdCounter = {}

function IdCounter:get_id()
    local id = self.id_count
    self.id_count = self.id_count + 1
    return id
end

function IdCounter.new()
    local counter = { id_count = 1 }
    setmetatable(counter, { __index = IdCounter })
    return counter
end