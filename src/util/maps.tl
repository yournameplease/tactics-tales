
local maps = {
	
}

function maps.map<K, A, B>(m: {K: A}, fn: function(A): B): { K: B }
    local out = {}
    for k,v in pairs(m) do
        out[k] = fn(v)
    end
    return out
end

return maps
