---@brief
--- A simple counted mutex backed by unique integer lock IDs.

local id_generator = require("src.tactics.util.id_generator")

---@class Mutex
---@field _locks table<integer, boolean>
---@field _ids IdGenerator
local Mutex = {}
Mutex.__index = Mutex

local mutex = {}

--- Acquire the mutex and return a unique lock ID.
---@return integer
function Mutex:acquire()
    local id = self._ids:get_id()
    self._locks[id] = true
    return id
end

--- Release the lock with the given ID. Unknown IDs are silently ignored.
---@param id integer
function Mutex:release(id)
    self._locks[id] = nil
end

--- Return true if any lock is currently held.
---@return boolean
function Mutex:is_locked()
    for _ in pairs(self._locks) do
        return true
    end
    return false
end

--- Create a new Mutex with no locks held.
---@return Mutex
function mutex.new()
    ---@type Mutex
    local self = setmetatable({}, Mutex)
    self._locks = {}
    self._ids = id_generator.new()
    return self
end

return mutex
