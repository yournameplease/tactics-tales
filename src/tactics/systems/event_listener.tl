---@brief
--- manages ids of event bus `on` events
--- to allow easy teardown 
require("src/tactics/systems/event_bus")


local interface EventListener
	on: function(self, event_name: GameEvent, callback: function(args: { string: any })): integer
	teardown: function(self)
end

local event_listener = {
	EventListener = EventListener
}

local record EventListenerImpl
	is EventListener

    listener_ids: {integer}
	bus: EventBus
end

function event_listener.new(
	bus: EventBus
): EventListener
	local self: EventListenerImpl = setmetatable({}, {
		__index = EventListenerImpl
	})

	self.bus = bus
	self.listener_ids = {}

	return self
end

function EventListenerImpl:on(event_name: GameEvent, callback: function(args: { string: any })): integer
	pt.add(self.listener_ids, self.bus:on(event_name, callback))
end

function EventListenerImpl:teardown()

end

