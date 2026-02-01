---@brief
--- A write-only wrapper around the EventBus interface.

local event_bus = require("src.tactics.systems.event_bus")


local interface EventWriter
	emit: function(self, event_name: event_bus.GameEvent, args: {string: any})
end

local event_writer = {
	EventWriter = EventWriter
}

local record EventWriterImpl
	is EventWriter

	bus: event_bus.EventBus
end

function event_writer.new(
	bus: event_bus.EventBus
): EventWriter
	local self: EventWriterImpl = setmetatable({}, {
		__index = EventWriterImpl
	})

	self.bus = bus

	return self
end

function EventWriterImpl:emit(
	event_name: event_bus.GameEvent,
	args: {string: any}
)
	self.bus:emit(event_name, args)
end

return event_writer
