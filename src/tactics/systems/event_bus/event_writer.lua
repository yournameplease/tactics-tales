---@brief
--- A write-only wrapper around the EventBus interface.

local event_bus = require("src.tactics.systems.event_bus")

---@class EventWriter
---@field bus EventBus Underlying bus; all emits are forwarded here.
local EventWriter = {}
EventWriter.__index = EventWriter

local event_writer = {}

--- Create a new EventWriter that forwards emits to `bus`.
---@param bus EventBus Bus to write events to.
---@return EventWriter
function event_writer.new(bus)
    ---@type EventWriter
    local self = setmetatable({}, EventWriter)
    self.bus = bus
    return self
end

--- Emit `event_name` with `args` on the underlying bus.
---@param event_name GameEvent Event to emit.
---@param args EventArgs|nil Arguments forwarded to each listener.
function EventWriter:emit(event_name, args)
    self.bus:emit(event_name, args)
end

return event_writer
