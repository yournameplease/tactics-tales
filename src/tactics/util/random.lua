---@brief
--- A collection of utility functions for random number generation.

local random = {}

--- Return a random integer in [0, i-1].
---@param i number Upper bound (exclusive); the result is always less than i.
---@return integer
function random.rndi(i)
    return pt.flr(pt.rnd(i) // 1)
end

--- Return a random element from `list`.
---@generic A
---@param list A[] List to choose from; must be non-empty.
---@return A
function random.choose_random_from_list(list)
    local i = random.rndi(#list) + 1
    return list[i]
end

--- Return a random value from `tab`.
---@generic A
---@param tab table<string, A> Table to choose a random value from; must be non-empty.
---@return A
function random.choose_random_from_table(tab)
    local list = {}
    for _, v in pairs(tab) do
        table.insert(list, v)
    end
    return random.choose_random_from_list(list)
end

return random
