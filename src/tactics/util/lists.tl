---@brief
--- A collection of functional-style utility functions for list manipulation.

-- Utility functions for functional programming on lists

local type MapEntry<Key,Value> = { Key, Value }

local lists = {
	MapEntry = MapEntry
}

function lists.size<Value>(list: {Value}): integer
	return #list
end

function lists.add_all<Value>(list: {Value}, elements: {Value})
	for _,elem in ipairs(elements) do
		pt.add(list, elem)
	end
end

function lists.merge<Value>(...: {Value}): {Value}
	local out = {}
	for _,l in ipairs({...}) do
		for _,elem in ipairs(l) do
			pt.add(out, elem)
		end
	end
	return out
end

function lists.do_reverse<A>(list: {A}): {A} 
    local out = {}
    for i = 1,#list do
        out[#list-i+1] = list[i]
    end
    return out
end

function lists.reverse<A>(list: {A}): {A}
    local out = {}
    for i = 1,#list do
        out[#list-i+1] = list[i]
    end
    return out
end

function lists.do_filter<A>(list: {A}, filter: function(A): boolean): { A }
    local out: {A} = {}
    for _,v in ipairs(list) do
		if filter(v) then
	        pt.add(out, v)
		end
    end
    return out
end

function lists.filter<A>(filter: function(A): boolean): function({A}): {A}
	return function(list: {A}): {A}
		return lists.do_filter(list, filter)
	end
end

function lists.do_map<A, B>(list: {A}, fn: function(A): B): { B }
    local out: {B} = {}
    for k,v in ipairs(list) do
        out[k] = fn(v)
    end
    return out
end

function lists.map<A, B>(fn: function(A): B): function({A}): {B}
	return function(list: {A}): {B}
		return lists.do_map(list, fn)
	end
end

function lists.do_flat_map<A, B>(list: {A}, fn: function(A): {B}): { B }
    local out: {B} = {}
    for _,v in ipairs(list) do
		local bs = fn(v)
		for _,b in ipairs(bs) do
	        pt.add(out, b)
		end
    end
    return out
end

function lists.flat_map<A, B>(fn: function(A): {B}): function({A}): {B}
	return function(list: {A}): {B}
		return lists.do_flat_map(list, fn)
	end
end

function lists.do_reduce<A, V>(list: {A}, initial: V, fn: function(acc: V, elem: A): V): V
    local val = initial
    for _,e in ipairs(list) do
        val = fn(val, e)
    end
    return val
end

function lists.reduce<A, V>(initial: V, fn: function(acc: V, elem: A): V): function({A}): V
	return function(list: {A}): V 
		return lists.do_reduce(list, initial, fn)
	end
end

function lists.do_sum<A>(list: {A}, fn: function(A): number): number
    return lists.do_reduce(list, 0, function(s: number, a: A): number return s + fn(a) end)
end

function lists.sum<A>(fn: function(A): number): function({A}): number
	return function(list: {A}): number 
		return lists.do_sum(list, fn)
	end
end

function lists.max<A>(fn: function(A): integer): function({A}): integer
	return lists.reduce(0, function(s: integer, a: A): integer
		return pt.max(s, fn(a))
	end)
end

function lists.do_collect_map<K,V>(list: {lists.MapEntry<K,V>}): { K: V }
	return lists.do_reduce(list, {}, function(acc: { K: V}, entry: lists.MapEntry<K, V>): { K: V }
		acc[entry[1]] = entry[2]
		return acc
	end)
end

function lists.collect_map<K,V>(): function({lists.MapEntry<K,V>}): { K: V }
	return function(list: {lists.MapEntry<K,V>}): {K: V}
		return lists.do_collect_map(list)
	end
end

function lists.contains<V>(tab: {V}, val: V): boolean
    for _,v in ipairs(tab) do
        if v == val then
            return true
        end
    end
    return false
end

return lists
