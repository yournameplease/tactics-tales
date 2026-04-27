---@brief
--- A collection of utility functions for random number generation.

local random = {}

--- Return a random integer in [0, i-1].
---@param i number Upper bound (exclusive); the result is always less than i.
---@return integer
function random.rndi(i)
    return flr(rnd(i))
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

---@class RngInstance Seedable xorshift32 RNG instance with independent state.
---@field package _state integer Internal xorshift32 state (always non-zero 32-bit).
local RngInstance = {}
RngInstance.__index = RngInstance

local function advance(instance)
    local x = instance._state
    x = x ~ ((x << 13) & 0xFFFFFFFF)
    x = x ~ (x >> 17)
    x = x ~ ((x << 5) & 0xFFFFFFFF)
    instance._state = x
    return x
end

--- Return the current internal state (use for save/load).
---@return integer
function RngInstance:get_state()
    return self._state
end

--- Restore the internal state (use for save/load).
---@param state integer Non-zero 32-bit integer.
function RngInstance:set_state(state)
    local s = math.floor(state) & 0xFFFFFFFF
    self._state = s == 0 and 1 or s
end

--- Return a random integer in [0, i-1].
---@param i integer Upper bound (exclusive).
---@return integer
function RngInstance:rndi(i)
    return advance(self) % i
end

--- Return a random element from `list`.
---@generic A
---@param list A[] List to choose from; must be non-empty.
---@return A
function RngInstance:choose_random_from_list(list)
    return list[self:rndi(#list) + 1]
end

--- Return a random value from `tab`.
---@generic A
---@param tab table<string, A> Table to choose a random value from; must be non-empty.
---@return A
function RngInstance:choose_random_from_table(tab)
    local list = {}
    for _, v in pairs(tab) do table.insert(list, v) end
    return self:choose_random_from_list(list)
end

--- Create a new independent RNG instance seeded with the given value.
--- Uses xorshift32; state 0 is replaced with 1.
---@param seed integer Initial seed (non-zero 32-bit integer preferred).
---@return RngInstance
function random.new(seed)
    local state = math.floor(seed) & 0xFFFFFFFF
    return setmetatable({ _state = state == 0 and 1 or state }, { __index = RngInstance })
end

return random
