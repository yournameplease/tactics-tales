
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

function maps.map<Key, From, To>(m: {Key: From}, fn: function(From): To): { Key: To }
    local out = {}
    for k,v in pairs(m) do
        out[k] = fn(v)
    end
    return out
end

function maps.do_get_at<K,V>(m: {K: V}, k: K): V 
    return m[k]
end

function maps.get_at<K,V>(m: {K: V}): function(k: K): V
    return function(k: K): V
        return maps.do_get_at(m,k)
    end
end

return maps
