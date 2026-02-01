---@brief
--- A simple utility for generating unique integer IDs.

local record IdGenerator
    id_count: integer
end

local id_generator = {
	IdGenerator = IdGenerator
}

function IdGenerator:get_id(): integer
    local id = self.id_count
    self.id_count = self.id_count + 1
    return id
end

function id_generator.new(): IdGenerator
    local counter = { id_count = 1 }
    setmetatable(counter, { __index = IdGenerator })
    return counter
end

return id_generator
