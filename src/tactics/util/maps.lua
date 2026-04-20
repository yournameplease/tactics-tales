---@brief
--- A collection of functional-style utility functions for map/table manipulation.

---@alias Set<V> table<V, boolean>

local maps = {}

--- Convert a list of values into a set (table keyed by value, all mapped to true).
---@generic V
---@param values V[] Elements to include in the set.
---@return Set<V>
function maps.set(values)
    local out = {}
    for _, v in ipairs(values) do
        out[v] = true
    end
    return out
end

--- Returns true if any key in the map is present
---@generic K
---@generic V
---@param m table<K, V> Elements to include in the set.
---@return boolean
function maps.any_value(m)
    for _, _ in ipairs(m) do
        return true
    end
    return false
end

--- Return a new table with the same keys, each value transformed by `fn`.
---@generic K, From, To
---@param m table<K, From> Source table to transform.
---@param fn fun(k: K, v: From): To Transform applied to each key-value pair.
---@return table<K, To>
function maps.do_map(m, fn)
    local out = {}
    for k, v in pairs(m) do
        out[k] = fn(k, v)
    end
    return out
end

--- Return a curried function that maps a table's values using `fn`.
---@generic K, From, To
---@param fn fun(k: `K`, v: `From`): To Transform applied to each key-value pair.
---@return fun(m: table<K, From>): table<K, To>
function maps.map(fn)
    return function(m)
        return maps.do_map(m, fn)
    end
end

---@generic KFrom, KTo, From, To
---@param m table<KFrom, From>
---@param key_fn fun(k: KFrom, v: From): KTo
---@param val_fn fun(k: KFrom, v: From): To
---@return table<KTo, To>
local function full_map_impl(m, key_fn, val_fn)
    local out = {}
    for k, v in pairs(m) do
        out[key_fn(k, v)] = val_fn(k, v)
    end
    return out
end

--- Return a curried function that rebuilds a table with both keys and values transformed.
---@generic KFrom, KTo, From, To
---@param key_fn fun(k: KFrom, v: From): KTo Produces the new key from each entry.
---@param val_fn fun(k: KFrom, v: From): To Produces the new value from each entry.
---@return fun(m: table<KFrom, From>): table<KTo, To>
function maps.full_map(key_fn, val_fn)
    return function(m)
        return full_map_impl(m, key_fn, val_fn)
    end
end

--- Return the value stored at key `k` in table `m`.
---@generic K, V
---@param m table<K, V>
---@param k K
---@return V
function maps.do_get_at(m, k)
    return m[k]
end

--- Return a curried function that looks up keys in table `m`.
---@generic K, V
---@param m table<K, V> Table to look up values in.
---@return fun(k: K): V
function maps.get_at(m)
    return function(k)
        return maps.do_get_at(m, k)
    end
end

--- Return the number of entries in table `m`.
---@generic K, V
---@param m table<K, V>
---@return integer
function maps.size(m)
    local count = 0
    for _ in pairs(m) do
        count = count + 1
    end
    return count
end

--- Return all values of table `m` as an unordered list.
---@generic K, V
---@param m table<K, V>
---@return V[]
function maps.to_list(m)
    local out = {}
    for _, v in pairs(m) do
        table.insert(out, v)
    end
    return out
end

--- Build a table from a list by extracting each element's key and value.
---@generic K, V, L
---@param list L[]
---@param key_fn fun(elem: L): K Extracts the table key from each list element.
---@param value_fn fun(elem: L): V Extracts the table value from each list element.
---@return table<K, V>
function maps.collect(list, key_fn, value_fn)
    local out = {}
    for _, elem in ipairs(list) do
        out[key_fn(elem)] = value_fn(elem)
    end
    return out
end

--- Copy all entries from `m2` into `m1`, skipping keys that already exist in `m1`.
---@generic K, V
---@param m1 table<K, V> Destination table; existing keys are not overwritten.
---@param m2 table<K, V> Source table whose entries are merged in.
function maps.add_all(m1, m2)
    for k, v in pairs(m2) do
        if m1[k] == nil then
            m1[k] = v
        end
    end
end

--- Return a new table containing all entries from the given tables; earlier tables take priority.
---@generic K, V
---@param ... table<K, V>
---@return table<K, V>
function maps.merge(...)
    local out = {}
    for _, m in ipairs({...}) do
        maps.add_all(out, m)
    end
    return out
end

--- Return a new table that is a deep merge of `m1` and `m2`; `m1` values take priority.
---@param m1 table<string, any> Base table; its values take priority on key conflicts.
---@param m2 table<string, any> Override table; nested tables are merged recursively.
---@return table<string, any>
function maps.deep_merge(m1, m2)
    local out = {}
    for k, v in pairs(m1) do
        if type(v) == "table" then
            out[k] = maps.deep_merge({}, v)
        else
            out[k] = v
        end
    end
    for k, v in pairs(m2) do
        if type(v) == "table" then
            local cur = out[k]
            if cur == nil then
                out[k] = maps.deep_merge({}, v)
            elseif type(cur) == "table" then
                out[k] = maps.deep_merge(cur, v)
            else
                log.warn("Overwriting a value with a table")
                out[k] = maps.deep_merge({}, v)
            end
        else
            out[k] = v
        end
    end
    return out
end

return maps
