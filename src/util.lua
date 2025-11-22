
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

function fn_true()
    return true
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