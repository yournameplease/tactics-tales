require("src/util")
local random = require("src/util/random")
local lists = require("src/util/lists")
local maps = require("src/util/maps")


local interface Randomizer<V>
	pick_random: function(self): V
end

local type WeightedOption<V> = { V , integer }

local record WeightedOptionSelector<V>
	is Randomizer<V>
	options: {WeightedOption<V>}
	total_weight: integer
end

local record ListSelector<V>
	is Randomizer<{V}>
	selectors: {Randomizer<V>}
end

local record RandomRange
	is Randomizer<integer>
	min_value: integer
	max_value: integer
end

local randomizer = {
	Randomizer = Randomizer,
	WeightedOption = WeightedOption,
	weighted_option_selector = {},
	list_selector = {},
	random_range = {},
}

-- Weighted Options

function randomizer.weighted_option_selector.of<V>(...: V): WeightedOptionSelector<V>
	local array = {...}
	local options: {WeightedOption<V>} = maps.map(array, function(v: V): WeightedOption<V> return { v, 1 } end)
	return setmetatable({
		options = options,
		total_weight = #array
	}, { __index = WeightedOptionSelector })
end

function randomizer.weighted_option_selector.of_weighted<V>(...: WeightedOption<V>): WeightedOptionSelector<V>
	local array: {WeightedOption<V>} = {...}
	return setmetatable({
		options = array,
		total_weight = lists.do_sum(
			array,
			function(o: WeightedOption<V>): number return o[2] end
			) as integer
	}, { __index = WeightedOptionSelector })
end

function WeightedOptionSelector:pick_random(): V
	local i = random.rndi(self.total_weight)+1
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

-- lists

function randomizer.list_selector.of_randomizers<V>(...: Randomizer<V>): ListSelector<V>
	local selectors = {...}
	return setmetatable({
		selectors = selectors,
	}, { __index = ListSelector })
end

function ListSelector:pick_random(): {V}
	return lists.do_map(
		self.selectors,
		function (r: Randomizer<V>): V return r:pick_random() end
	)
end

-- Int range

function randomizer.random_range.between(min_value: integer, max_value: integer): RandomRange
	return setmetatable({
		min_value = min_value,
		max_value = max_value
	}, { __index = RandomRange })
end

function randomizer.random_range.of(n: integer): RandomRange
	return randomizer.random_range.between(0, n - 1)
end

function RandomRange:pick_random(): integer
	return self.min_value + random.rndi(self.max_value - self.min_value)
end

return randomizer
