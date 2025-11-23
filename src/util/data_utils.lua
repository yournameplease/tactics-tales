-- Helper function to lock a table's keys
function protect(tbl)
    return setmetatable(tbl, {
        -- Error if accessing a key that doesn't exist
        __index = function(t, k)
            error("CRITICAL: Attempted to access missing data key: '" .. tostring(k) .. "'", 2)
        end,

        -- Error if trying to write new data
        __newindex = function(t, k, v)
            error("CRITICAL: Attempted to modify static data key: '" .. tostring(k) .. "'", 2)
        end
    })
end

function enum(list)
    local e = {}
    for _, v in ipairs(list) do
        e[v] = v
    end
    return protect(e) -- Use the protect function from above!
end
