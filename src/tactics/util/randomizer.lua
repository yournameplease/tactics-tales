---@brief
--- A utility for creating complex, weighted randomizers.

local random = require("src.tactics.util.random")
local lists = require("src.tactics.util.lists")

---@class Randomizer<V>
---@field pick_random fun(self: Randomizer<V>): V

---@alias WeightedOption<V> [V, integer]

---@class WeightedOptionSelector<V> : Randomizer<V>
---@field options WeightedOption<V>[] Ordered list of value-weight pairs.
---@field total_weight integer Sum of all option weights.

---@class ListSelector<V> : Randomizer<V[]>
---@field selectors Randomizer<V>[] Individual randomizers whose results are collected into a list.

---@class RandomRange : Randomizer<integer>
---@field min_value integer Inclusive lower bound.
---@field max_value integer Exclusive upper bound (stored as max+1 for the range calculation).

local WeightedOptionSelector = {}
local ListSelector = {}
local RandomRange = {}

local randomizer = {
    weighted_option_selector = {},
    list_selector = {},
    random_range = {},
}

-- Weighted Options

--- Create a selector that picks uniformly from the given values (each weight 1).
---@generic V
---@param ... V Values to choose from.
---@return WeightedOptionSelector<V>
function randomizer.weighted_option_selector.of(...)
    local array = {...}
    local options = lists.do_map(array, function(v) return { v, 1 } end)
    return setmetatable({
        options = options,
        total_weight = #array
    }, { __index = WeightedOptionSelector })
end

--- Create a selector from a map of values to weights.
---@generic V
---@param weights table<V, integer> Map of value → weight; higher weight means more likely to be picked.
---@return WeightedOptionSelector<V>
function randomizer.weighted_option_selector.of_weight_map(weights)
    local options = {}
    local total_weight = 0
    for v, w in pairs(weights) do
        table.insert(options, { v, w })
        total_weight = total_weight + w
    end
    return setmetatable({
        options = options,
        total_weight = total_weight
    }, { __index = WeightedOptionSelector })
end

--- Create a selector from explicit `{value, weight}` pairs.
---@generic V
---@param ... WeightedOption<V> Value-weight pairs in pick order.
---@return WeightedOptionSelector<V>
function randomizer.weighted_option_selector.of_weighted(...)
    local array = {...}
    return setmetatable({
        options = array,
        total_weight = lists.do_sum(array, function(o) return o[2] end)
    }, { __index = WeightedOptionSelector })
end

--- Create a selector by flattening weighted sub-selectors, scaling their inner weights by the outer weight.
---@generic V
---@param ... WeightedOption<WeightedOptionSelector<V>> Sub-selector weight pairs; inner option weights are scaled by the outer weight.
---@return WeightedOptionSelector<V>
function randomizer.weighted_option_selector.of_recursive(...)
    local array = {...}
    local options = lists.do_flat_map(array, function(o)
        local weight = o[2]
        return lists.do_map(o[1].options, function(n_o)
            return { n_o[1], n_o[2] * weight }
        end)
    end)
    return randomizer.weighted_option_selector.of_weighted(table.unpack(options))
end

--- Pick a random value, weighted by each option's weight.
---@generic V
---@return V
function WeightedOptionSelector:pick_random()
    local i = random.rndi(self.total_weight) + 1
    if #self.options == self.total_weight then
        return self.options[i][1]
    end
    local index = 0
    repeat
        index = index + 1
        i = i - self.options[index][2]
    until i <= 0
    return self.options[index][1]
end

-- List selectors

--- Create a selector that picks from each sub-randomizer and returns all results as a list.
---@generic V
---@param ... Randomizer<V> Sub-randomizers to invoke in order.
---@return ListSelector<V>
function randomizer.list_selector.of_randomizers(...)
    local selectors = {...}
    return setmetatable({
        selectors = selectors,
    }, { __index = ListSelector })
end

--- Pick a random value from each sub-randomizer and return them as a list.
---@generic V
---@return V[]
function ListSelector:pick_random()
    return lists.do_map(self.selectors, function(r) return r:pick_random() end)
end

-- Int range

--- Create a randomizer that picks a uniform integer in [min_value, max_value].
---@param min_value integer Inclusive lower bound.
---@param max_value integer Inclusive upper bound.
---@return RandomRange
function randomizer.random_range.between(min_value, max_value)
    return setmetatable({
        min_value = min_value,
        max_value = max_value + 1
    }, { __index = RandomRange })
end

--- Create a randomizer that picks a uniform integer in [0, n-1].
---@param n integer Number of distinct values (range size).
---@return RandomRange
function randomizer.random_range.of(n)
    return randomizer.random_range.between(0, n - 1)
end

--- Pick a random integer within this range.
---@return integer
function RandomRange:pick_random()
    return self.min_value + random.rndi(self.max_value - self.min_value)
end

return randomizer
