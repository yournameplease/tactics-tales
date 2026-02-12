---@brief
--- A collection of functional-style utility functions for map/table manipulation.

local type Set<Value> = {Value: boolean}

local maps = {
    Set = Set
}

function maps.set<Value>(values: {Value}): Set<Value>
    local out: Set<Value> = {}
    for _,v in ipairs(values) do
        out[v] = true
    end
    return out
end

function maps.do_map<Key, From, To>(m: {Key: From}, fn: function(Key, From): To): { Key: To }
    local out = {}
    for k,v in pairs(m) do
        out[k] = fn(k, v)
    end
    return out
end

function maps.map<Key, From, To>(fn: function(Key, From): To): function(m: {Key: From}) : { Key: To }
    return function(m: {Key: From}): { Key: To }
        return maps.do_map(m, fn)
    end
end

local function full_map<KeyFrom, KeyTo, From, To>(
    m: {KeyFrom: From},
    key_fn: function(KeyFrom, From): KeyTo,
    val_fn: function(KeyFrom, From): To
): { KeyTo: To }
    local out = {}
    for k,v in pairs(m) do
        out[key_fn(k, v)] = val_fn(k, v)
    end
    return out
end

function maps.full_map<KeyFrom, KeyTo, From, To>(
    key_fn: function(KeyFrom, From): KeyTo,
    val_fn: function(KeyFrom, From): To
) : function({KeyFrom: From}): { KeyTo: To }
    return function(m: {KeyFrom: From}): { KeyTo: To }
        return full_map(m, key_fn, val_fn)
    end
end

function maps.do_get_at<K,V>(m: {K: V}, k: K): V 
    return m[k]
end

function maps.get_at<K,V>(m: {K: V}): function(k: K): V
    return function(k: K): V
        return maps.do_get_at(m,k)
    end
end

function maps.size<Key, Value>(m: {Key: Value}): integer
    local count = 0
    for _,v in pairs(m) do
        count = count + 1
    end
    return count
end

function maps.to_list<Key, Value>(m: {Key: Value}): {Value}
    --todo: add a sort function
    local out: {Value} = {}
    for _,v in pairs(m) do
        pt.add(out, v)
    end
    return out
end

function maps.collect<Key,Value,ListValue>(
    list: {ListValue},
    key_fn: function(ListValue): Key,
    value_fn: function(ListValue): Value
): {Key: Value}
    local out = {}
    for _,elem in ipairs(list) do
        out[key_fn(elem)] = value_fn(elem)
    end
    return out
end

function maps.add_all<Key, Value>(m1: {Key: Value}, m2: {Key: Value}) 
    for k,v in pairs(m2) do
        if m1[k] == nil then
            m1[k] = v
        end
    end
end

function maps.merge<Key, Value>(...: {Key: Value}): {Key: Value}
    local ms = {...}
    local out: {Key: Value} = {}
    for _,m in ipairs(ms) do
        maps.add_all(out, m)
    end
    return out
end

function maps.deep_merge(m1: {string: any}, m2: {string: any}): {string: any}
    local out: {string: any} = {}
    for k,v in pairs(m1) do
        if pt.type(v) == "table" then
            out[k] = maps.deep_merge({}, v as {string: any})
        else
            out[k] = v
        end
    end
    for k,v in pairs(m2) do
        if pt.type(v) == "table" then
            local cur = out[k]
            if cur == nil then
                out[k] = maps.deep_merge({}, v as {string: any})
            elseif pt.type(cur) == "table" then
                out[k] = maps.deep_merge(out[k] as {string: any}, v as {string: any})
            else
                log.warn("Overwriting a value with a table")
                out[k] = maps.deep_merge({}, v as {string: any})
            end
        else
            out[k] = v
        end
    end
    return out
end

return maps
