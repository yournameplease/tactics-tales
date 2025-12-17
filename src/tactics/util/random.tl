---@brief
--- Utility functions dealing with RNG

local random = {}

function random.rndi(i: number): integer
    return pt.flr(pt.rnd(i)//1)
end

function random.choose_random_from_list<A>(list: {A}): A
    local i = random.rndi(#list)+1
    return list[i]
end

function random.choose_random_from_table<A>(tab: {string: A}): A
    local list: {A} = {}
    for _, v in pairs(tab) do
        pt.add(list, v)
    end
    return random.choose_random_from_list(list)
end

return random
