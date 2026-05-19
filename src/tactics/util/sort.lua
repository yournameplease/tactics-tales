local sort = {}

--- Sort `list` in-place using bubble sort.
--- `fn(a, b)` returns true if `a` should come before `b`; defaults to ascending `<`.
---@generic T
---@param list T[]
---@param fn? fun(a: T, b: T): boolean
function sort.by(list, fn)
    fn = fn or function(a, b) return a < b end
    local n = #list
    for i = 1, n - 1 do
        for j = i + 1, n do
            if fn(list[j], list[i]) then
                list[i], list[j] = list[j], list[i]
            end
        end
    end
end

return sort
