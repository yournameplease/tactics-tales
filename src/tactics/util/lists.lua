---@brief
--- A collection of functional-style utility functions for list manipulation.

---@alias MapEntry<K, V> [K, V]

local lists = {}

---@generic V
---@param list V[]
---@return integer
function lists.size(list)
    return #list
end

---@generic V
---@param list V[]
---@param elements V[]
function lists.add_all(list, elements)
    for _, elem in ipairs(elements) do
        table.insert(list, elem)
    end
end

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

---@generic A
---@param list A[]
---@param filter fun(elem: A): boolean
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

---@generic A
---@param filter fun(elem: A): boolean
---@return fun(list: A[]): A[]
function lists.filter(filter)
    return function(list)
        return lists.do_filter(list, filter)
    end
end

---@generic A, B
---@param list A[]
---@param fn fun(elem: A): B
---@return B[]
function lists.do_map(list, fn)
    local out = {}
    for k, v in ipairs(list) do
        out[k] = fn(v)
    end
    return out
end

---@generic A, B
---@param fn fun(elem: A): B
---@return fun(list: A[]): B[]
function lists.map(fn)
    return function(list)
        return lists.do_map(list, fn)
    end
end

---@generic A, B
---@param list A[]
---@param fn fun(elem: A): B[]
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

---@generic A, B
---@param fn fun(elem: A): B[]
---@return fun(list: A[]): B[]
function lists.flat_map(fn)
    return function(list)
        return lists.do_flat_map(list, fn)
    end
end

---@generic A, V
---@param list A[]
---@param initial V
---@param fn fun(acc: V, elem: A): V
---@return V
function lists.do_reduce(list, initial, fn)
    local val = initial
    for _, e in ipairs(list) do
        val = fn(val, e)
    end
    return val
end

---@generic A, V
---@param initial V
---@param fn fun(acc: V, elem: A): V
---@return fun(list: A[]): V
function lists.reduce(initial, fn)
    return function(list)
        return lists.do_reduce(list, initial, fn)
    end
end

---@generic A
---@param list A[]
---@param fn fun(elem: A): number
---@return number
function lists.do_sum(list, fn)
    return lists.do_reduce(list, 0, function(s, a) return s + fn(a) end)
end

---@generic A
---@param fn fun(elem: A): number
---@return fun(list: A[]): number
function lists.sum(fn)
    return function(list)
        return lists.do_sum(list, fn)
    end
end

---@generic A
---@param fn fun(elem: A): integer
---@return fun(list: A[]): integer
function lists.max(fn)
    return lists.reduce(0, function(s, a) return math.max(s, fn(a)) end)
end

---@generic K, V
---@param list MapEntry<K, V>[]
---@return table<K, V>
function lists.do_collect_map(list)
    return lists.do_reduce(list, {}, function(acc, entry)
        acc[entry[1]] = entry[2]
        return acc
    end)
end

---@generic K, V
---@return fun(list: MapEntry<K, V>[]): table<K, V>
function lists.collect_map()
    return function(list)
        return lists.do_collect_map(list)
    end
end

---@generic V
---@param tab V[]
---@param val V
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
