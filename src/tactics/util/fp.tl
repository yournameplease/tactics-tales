---@brief
--- A small collection of functional programming helper functions,
--- primarily for creating function pipelines.

local fp = {}

function fp.fn_and<Arg>(...: function(Arg): boolean): function(Arg): boolean
	local fns = {...}

	return function(a: Arg): boolean
		for _,fn in ipairs(fns) do
			if not fn(a) then
				return false
			end
		end
		return true
	end
end

function fp.fn_true(): boolean
    return true
end

function fp.not_nil<Type>(obj: Type): boolean
    return obj ~= nil
end

-- this is kind of stupid...
-- but I think necessary due to no fn overloading with dif args

local function do_pipeline<A,B>(val: A, ...: function(any): any): B
	local fns = {...}
	local result: any = val
	for _,fn in ipairs(fns) do
		result = fn(result)
	end
	return result as B
end

function fp.pipeline_1<In,Out>(
    fn_1: function(In): Out
): function(In): Out
	return function(val: In): Out
		return do_pipeline(val, fn_1)
	end
end

function fp.pipeline_2<In,T1,Out>(
    fn_1: function(In): T1,
    fn_2: function(T1): Out
): function(In): Out
	return function(val: In): Out
		return do_pipeline(val, fn_1, fn_2)
	end
end

function fp.pipeline_3<In,T1,T2,Out>(
    fn_1: function(In): T1,
    fn_2: function(T1): T2,
    fn_3: function(T2): Out
): function(In): Out
	return function(val: In): Out
		return do_pipeline(val, fn_1, fn_2, fn_3)
	end
end

function fp.pipeline_4<In,T1,T2,T3,Out>(
    fn_1: function(In): T1,
    fn_2: function(T1): T2,
    fn_3: function(T2): T3,
    fn_4: function(T3): Out
): function(In): Out
	return function(val: In): Out
		return do_pipeline(val, fn_1, fn_2, fn_3, fn_4)
	end
end

function fp.pipeline_5<In,T1,T2,T3,T4,Out>(
    fn_1: function(In): T1,
    fn_2: function(T1): T2,
    fn_3: function(T2): T3,
    fn_4: function(T3): T4,
    fn_5: function(T4): Out
): function(In): Out
	return function(val: In): Out
		return do_pipeline(val, fn_1, fn_2, fn_3, fn_4, fn_5)
	end
end

return fp
