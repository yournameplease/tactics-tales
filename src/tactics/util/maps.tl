
local maps = {
	
}

function maps.map<K, A, B>(m: {K: A}, fn: function(A): B): { K: B }
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
