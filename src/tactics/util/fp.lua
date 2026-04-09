---@brief
--- A small collection of functional programming helper functions,
--- primarily for creating function pipelines.

local fp = {}

---@generic Arg
---@param ... fun(a: Arg): boolean
---@return fun(a: Arg): boolean
function fp.fn_and(...)
    local fns = {...}
    return function(a)
        for _, fn in ipairs(fns) do
            if not fn(a) then return false end
        end
        return true
    end
end

---@return boolean
function fp.fn_true()
    return true
end

---@generic T
---@param obj T
---@return boolean
function fp.not_nil(obj)
    return obj ~= nil
end

---@param str string
---@return boolean
function fp.not_empty(str)
    return #str > 0
end

-- this is kind of stupid...
-- but I think necessary due to no fn overloading with dif args

---@param val any
---@param ... fun(v: any): any
---@return any
local function do_pipeline(val, ...)
    local fns = {...}
    local result = val
    for _, fn in ipairs(fns) do
        result = fn(result)
    end
    return result
end

---@generic In, Out
---@param fn_1 fun(v: In): Out
---@return fun(v: In): Out
function fp.pipeline_1(fn_1)
    return function(val) return do_pipeline(val, fn_1) end
end

---@generic In, T1, Out
---@param fn_1 fun(v: In): T1
---@param fn_2 fun(v: T1): Out
---@return fun(v: In): Out
function fp.pipeline_2(fn_1, fn_2)
    return function(val) return do_pipeline(val, fn_1, fn_2) end
end

---@generic In, T1, T2, Out
---@param fn_1 fun(v: In): T1
---@param fn_2 fun(v: T1): T2
---@param fn_3 fun(v: T2): Out
---@return fun(v: In): Out
function fp.pipeline_3(fn_1, fn_2, fn_3)
    return function(val) return do_pipeline(val, fn_1, fn_2, fn_3) end
end

---@generic In, T1, T2, T3, Out
---@param fn_1 fun(v: In): T1
---@param fn_2 fun(v: T1): T2
---@param fn_3 fun(v: T2): T3
---@param fn_4 fun(v: T3): Out
---@return fun(v: In): Out
function fp.pipeline_4(fn_1, fn_2, fn_3, fn_4)
    return function(val) return do_pipeline(val, fn_1, fn_2, fn_3, fn_4) end
end

---@generic In, T1, T2, T3, T4, Out
---@param fn_1 fun(v: In): T1
---@param fn_2 fun(v: T1): T2
---@param fn_3 fun(v: T2): T3
---@param fn_4 fun(v: T3): T4
---@param fn_5 fun(v: T4): Out
---@return fun(v: In): Out
function fp.pipeline_5(fn_1, fn_2, fn_3, fn_4, fn_5)
    return function(val) return do_pipeline(val, fn_1, fn_2, fn_3, fn_4, fn_5) end
end

return fp
