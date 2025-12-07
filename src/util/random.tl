require("src/util")
local List = require("src/util/list")

global interface Randomizer<V>
	pick_random: function(self): V
end

-- Weighted Options

global record WeightedOption<V>
	value: V
	weight: integer
end

function WeightedOption.of<V>(value: V, weight: integer): WeightedOption<V>
	return setmetatable({
		value = value,
		weight = weight
	}, { __index = WeightedOption })
end

global record WeightedOptionSelector<V>
	is Randomizer<V>
	options: {WeightedOption<V>}
	total_weight: integer
end

function WeightedOptionSelector.of<V>(...: V): WeightedOptionSelector<V>
	local array = {...}
	local options: {WeightedOption<V>} = tmap(array, function(v: V): WeightedOption<V> return { value = v, weight = 1} end)
	return setmetatable({
		options = options,
		total_weight = #array
	}, { __index = WeightedOptionSelector })
end

function WeightedOptionSelector.of_weighted<V>(...: WeightedOption<V>): WeightedOptionSelector<V>
	local array: {WeightedOption<V>} = {...}
	return setmetatable({
		options = array,
		total_weight = sum(array, function(o: WeightedOption<V>): number return o.weight end) as integer
	}, { __index = WeightedOptionSelector })
end

function WeightedOptionSelector:pick_random(): V
	local i = rndi(self.total_weight)+1
	if #self.options == self.total_weight then
		return self.options[i].value
	end
	local count = 0
	repeat
		count = count + 1
		i = i - self.options[count].weight
	until i <= 0
	return self.options[count].value
end

-- lists

global record ListSelector<V>
	is Randomizer<{V}>
	selectors: {Randomizer<V>}
end

function ListSelector.of_randomizers<V>(...: Randomizer<V>): ListSelector<V>
	local selectors = {...}
	return setmetatable({
		selectors = selectors,
	}, { __index = ListSelector })
end

function ListSelector:pick_random(): {V}
	return List.do_map(
		self.selectors,
		function (r: Randomizer<V>): V return r:pick_random() end
	)
end

-- Int range

global record RandomRange
	is Randomizer<integer>
	min_value: integer
	max_value: integer
end

function RandomRange.between(min_value: integer, max_value: integer): RandomRange
	return setmetatable({
		min_value = min_value,
		max_value = max_value
	}, { __index = RandomRange })
end

function RandomRange.of(count: integer): RandomRange
	return RandomRange.between(0, count - 1)
end

function RandomRange:pick_random(): integer
	return self.min_value + rndi(self.max_value - self.min_value)
end

