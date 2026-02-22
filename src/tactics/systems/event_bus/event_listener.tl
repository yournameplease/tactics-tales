---@brief
--- A helper class to manage event subscriptions for a service,
--- simplifying the teardown of listeners.
 
local event_bus = require("src.tactics.systems.event_bus")


local interface EventListener
	on: function(self, event_name: event_bus.GameEvent, callback: function(args: { string: any })): integer
	remove: function(self, integer)
	teardown: function(self)
end

local event_listener = {
	EventListener = EventListener
}

local record EventListenerImpl
	is EventListener

    listener_ids: {integer}
	bus: event_bus.EventBus
end

function event_listener.new(
	bus: event_bus.EventBus
): EventListener
	local self: EventListenerImpl = setmetatable({}, {
		__index = EventListenerImpl
	})

	self.bus = bus
	self.listener_ids = {}

	return self
end

function EventListenerImpl:on(event_name: event_bus.GameEvent, callback: function(args: { string: any })): integer
	local id = self.bus:on(event_name, callback)
	pt.add(self.listener_ids, id)
	return id
end

function EventListenerImpl:remove(id: integer)
	self.bus:remove(id)
end

function EventListenerImpl:teardown()
	self.bus:remove_all(self.listener_ids)
end

return event_listener
