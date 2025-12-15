-- Utility functions for functional programming on lists

local record List
	record MapEntry<K,V>
		key: K
		value: V
	end
end

function List.MapEntry.of<K,V>(k: K, v: V): List.MapEntry<K,V>
	return {
		key = k,
		value = v
	}
end

function List.do_pipeline<A,B>(list: {A}, ...: function(any): any): B
	local fns = {...}
	local result: any = list 
	for _,fn in ipairs(fns) do
		result = fn(result)
	end
	return result as B
end

-- This doesn't seem to work with typing rules
-- function List.pipeline<A,B>(...: function(any): any): function({A}): B
-- 	local args = {...}
-- 	return function(list: {A}): B
-- 		return List.do_pipeline(list, table.unpack(args))
-- 	end
-- end

function List.do_reverse<A>(list: {A}): {A} 
    local out = {}
    for i = 1,#list do
        out[#list-i+1] = list[i]
    end
    return out
end

function List.reverse<A>(): function({A}): {A}
	return function(list: {A}): {A} 
		return List.do_reverse(list) 
	end
end

function List.do_filter<A>(list: {A}, filter: function(A): boolean): { A }
    local out: {A} = {}
    for _,v in ipairs(list) do
		if filter(v) then
	        pt.add(out, v)
		end
    end
    return out
end

function List.filter<A>(filter: function(A): boolean): function({A}): {A}
	return function(list: {A}): {A}
		return List.do_filter(list, filter)
	end
end

function List.do_map<A, B>(list: {A}, fn: function(A): B): { B }
    local out: {B} = {}
    for k,v in ipairs(list) do
        out[k] = fn(v)
    end
    return out
end

function List.map<A, B>(fn: function(A): B): function({A}): {B}
	return function(list: {A}): {B}
		return List.do_map(list, fn)
	end
end

function List.do_reduce<A, V>(list: {A}, initial: V, fn: function(acc: V, elem: A): V): V
    local val = initial
    for _,e in ipairs(list) do
        val = fn(val, e)
    end
    return val
end

function List.reduce<A, V>(initial: V, fn: function(acc: V, elem: A): V): function({A}): V
	return function(list: {A}): V 
		return List.do_reduce(list, initial, fn)
	end
end

function List.do_sum<A>(list: {A}, fn: function(A): number): number
    return List.do_reduce(list, 0, function(s: number, a: A): number return s + fn(a) end)
end

function List.sum<A>(fn: function(A): number): function({A}): number
	return function(list: {A}): number 
		return List.do_sum(list, fn)
	end
end

function List.do_collect_map<K,V>(list: {List.MapEntry<K,V>}): { K: V }
	return List.do_reduce(list, {}, function(acc: { K: V}, entry: List.MapEntry<K, V>): { K: V }
		acc[entry.key] = entry.value
		return acc
	end)
end

function List.collect_map<K,V>(): function({List.MapEntry<K,V>}): { K: V }
	return function(list: {List.MapEntry<K,V>}): {K: V}
		return List.do_collect_map(list)
	end
end

return List
