---@brief
--- A simple utility for generating unique integer IDs.

---@class IdGenerator
---@field id_count integer Running counter; incremented on each call to get_id.

local IdGenerator = {}

local id_generator = {}

--- Return the next unique integer ID and advance the counter.
---@return integer
function IdGenerator:get_id()
    local id = self.id_count
    self.id_count = self.id_count + 1
    return id
end

--- Create a new IdGenerator whose sequence starts at 1.
---@return IdGenerator
function id_generator.new()
    local counter = { id_count = 1 }
    setmetatable(counter, { __index = IdGenerator })
    return counter
end

return id_generator
