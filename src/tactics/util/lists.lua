---@brief
--- A collection of functional-style utility functions for list manipulation.

---@alias MapEntry<K, V> [K, V]

local lists = {}

--- Return the number of elements in `list`.
---@generic V
---@param list V[]
---@return integer
function lists.size(list)
    return #list
end

--- Append all elements from `elements` onto `list` in order.
---@generic V
---@param list V[] Destination list; elements are appended in place.
---@param elements V[] Elements to append.
function lists.add_all(list, elements)
    for _, elem in ipairs(elements) do
        table.insert(list, elem)
    end
end

--- Return a new list containing all elements from the given lists, in order.
---@generic V
---@param ... V[]
---@return V[]
function lists.merge(...)
    local out = {}
    for _, l in ipairs({...}) do
        for _, elem in ipairs(l) do
            table.insert(out, elem)
        end
    end
    return out
end

--- Return a new list with elements in reverse order.
---@generic A
---@param list A[]
---@return A[]
function lists.do_reverse(list)
    local out = {}
    for i = 1, #list do
        out[#list - i + 1] = list[i]
    end
    return out
end

--- Return a new list with elements in reverse order.
---@generic A
---@param list A[]
---@return A[]
function lists.reverse(list)
    local out = {}
    for i = 1, #list do
        out[#list - i + 1] = list[i]
    end
    return out
end

--- Return a new list containing only the elements for which `filter` returns true.
---@generic A
---@param list A[]
---@param filter fun(elem: A): boolean Predicate; elements for which this returns true are kept.
---@return A[]
function lists.do_filter(list, filter)
    local out = {}
    for _, v in ipairs(list) do
        if filter(v) then
            table.insert(out, v)
        end
    end
    return out
end

--- Return a curried function that filters a list using `filter`.
---@generic A
---@param filter fun(elem: A): boolean Predicate; elements for which this returns true are kept.
---@return fun(list: A[]): A[]
function lists.filter(filter)
    return function(list)
        return lists.do_filter(list, filter)
    end
end

--- Return a new list with each element transformed by `fn`.
---@generic A, B
---@param list A[]
---@param fn fun(elem: A): B Transform applied to each element.
---@return B[]
function lists.do_map(list, fn)
    local out = {}
    for k, v in ipairs(list) do
        out[k] = fn(v)
    end
    return out
end

--- Return a curried function that maps a list using `fn`.
---@generic A, B
---@param fn fun(elem: A): B Transform applied to each element.
---@return fun(list: A[]): B[]
function lists.map(fn)
    return function(list)
        return lists.do_map(list, fn)
    end
end

--- Return a new list by mapping each element to a sub-list and concatenating the results.
---@generic A, B
---@param list A[]
---@param fn fun(elem: A): B[] Returns a sub-list for each element; sub-lists are concatenated.
---@return B[]
function lists.do_flat_map(list, fn)
    local out = {}
    for _, v in ipairs(list) do
        local bs = fn(v)
        for _, b in ipairs(bs) do
            table.insert(out, b)
        end
    end
    return out
end

--- Return a curried function that flat-maps a list using `fn`.
---@generic A, B
---@param fn fun(elem: A): B[] Returns a sub-list for each element; sub-lists are concatenated.
---@return fun(list: A[]): B[]
function lists.flat_map(fn)
    return function(list)
        return lists.do_flat_map(list, fn)
    end
end

--- Reduce `list` to a single value by accumulating with `fn`, starting from `initial`.
---@generic A, V
---@param list A[]
---@param initial V Accumulator starting value passed to the first `fn` call.
---@param fn fun(acc: V, elem: A): V Combines the running accumulator with the next element.
---@return V
function lists.do_reduce(list, initial, fn)
    local val = initial
    for _, e in ipairs(list) do
        val = fn(val, e)
    end
    return val
end

--- Return a curried function that reduces a list using `fn` starting from `initial`.
---@generic A, V
---@param initial V Accumulator starting value passed to the first `fn` call.
---@param fn fun(acc: V, elem: A): V Combines the running accumulator with the next element.
---@return fun(list: A[]): V
function lists.reduce(initial, fn)
    return function(list)
        return lists.do_reduce(list, initial, fn)
    end
end

--- Return the sum of `fn` applied to each element of `list`.
---@generic A
---@param list A[]
---@param fn fun(elem: A): number Extracts the numeric value to sum from each element.
---@return number
function lists.do_sum(list, fn)
    return lists.do_reduce(list, 0, function(s, a) return s + fn(a) end)
end

--- Return a curried function that sums a list by applying `fn` to each element.
---@generic A
---@param fn fun(elem: A): number Extracts the numeric value to sum from each element.
---@return fun(list: A[]): number
function lists.sum(fn)
    return function(list)
        return lists.do_sum(list, fn)
    end
end

--- Return a curried function that returns the maximum value of `fn` across a list.
---@generic A
---@param fn fun(elem: A): integer Extracts the integer value to maximise from each element.
---@return fun(list: A[]): integer
function lists.max(fn)
    return lists.reduce(0, function(s, a) return math.max(s, fn(a)) end)
end

--- Convert a list of key-value pairs into a table.
---@generic K, V
---@param list MapEntry<K, V>[]
---@return table<K, V>
function lists.do_collect_map(list)
    return lists.do_reduce(list, {}, function(acc, entry)
        acc[entry[1]] = entry[2]
        return acc
    end)
end

--- Return a curried function that converts a list of key-value pairs into a table.
---@generic K, V
---@return fun(list: MapEntry<K, V>[]): table<K, V>
function lists.collect_map()
    return function(list)
        return lists.do_collect_map(list)
    end
end

--- Return true if `val` is present in `tab`.
---@generic V
---@param tab V[] List to search.
---@param val V Value to look for.
---@return boolean
function lists.contains(tab, val)
    for _, v in ipairs(tab) do
        if v == val then
            return true
        end
    end
    return false
end

return lists
