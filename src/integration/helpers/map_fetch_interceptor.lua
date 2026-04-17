---@brief
--- Intercepts _G.fetch to serve mock map data for integration tests.
--- Call new() to install the override, register() to add path→data entries,
--- and teardown() to restore the original fetch.

---@class MapFetchInterceptor
---@field _registry table<string, any>
---@field _original_fetch function
local MapFetchInterceptor = {}
MapFetchInterceptor.__index = MapFetchInterceptor

local map_fetch_interceptor = {}

--- Install the fetch override and return a new interceptor handle.
--- Only one interceptor should be active at a time; nesting is unsupported.
---@return MapFetchInterceptor
function map_fetch_interceptor.new()
    local self = setmetatable({}, MapFetchInterceptor)
    self._registry = {}
    self._original_fetch = _G.fetch

    _G.fetch = function(path)
        local data = self._registry[path]
        if data ~= nil then
            return data, nil
        end
        return self._original_fetch(path)
    end

    return self
end

--- Register a path with its mock fetch response data.
--- Passing nil as data is equivalent to not registering the path (falls through to real fetch).
---@param path string
---@param data any
function MapFetchInterceptor:register(path, data)
    self._registry[path] = data
end

--- Restore the original _G.fetch.
function MapFetchInterceptor:teardown()
    _G.fetch = self._original_fetch
end

return map_fetch_interceptor
