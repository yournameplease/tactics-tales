require("src/util")

global record RandomOption<V>
	value: V
	weight: integer
end

global record RandomSelection<V>
	options: {RandomOption<V>}
	total_weight: integer
end

function RandomSelection.of<V>(...: V): RandomSelection<V>
	local array = {...}
	local options: {RandomOption<V>} = tmap(array, function(v: V): RandomOption<V> return { value = v, weight = 1} end)
	return setmetatable({
		options = options,
		total_weight = #array
	}, { __index = RandomSelection })
end

function RandomSelection.of_weighted<V>(...: RandomOption<V>): RandomSelection<V>
	local array: {RandomOption<V>} = {...}
	return setmetatable({
		options = array,
		total_weight = sum(array, function(o: RandomOption<V>): number return o.weight end) as integer
	}, { __index = RandomSelection })
end

function RandomSelection:pick_random(): V
	local i = rndi(self.total_weight)
	if #self.options == self.total_weight then
		return self.options[i+1].value
	end
	local count = 0
	while i > 0 do
		i = i-self.options[count].weight
		count = count + 1
	end
	return self.options[count+1].value
end
