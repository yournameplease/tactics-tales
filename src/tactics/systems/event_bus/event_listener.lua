---@brief
--- A helper class to manage event subscriptions for a service,
--- simplifying the teardown of listeners.

local event_bus = require("src.tactics.systems.event_bus")

---@class EventListener
---@field listener_ids table<integer, boolean> Set of active subscription IDs managed by this listener.
---@field bus EventBus Bus this listener is subscribed to.
local EventListener = {}
EventListener.__index = EventListener

local event_listener = {}

--- Create a new EventListener backed by `bus`.
---@param bus EventBus Bus to subscribe to.
---@return EventListener
function event_listener.new(bus)
    ---@type EventListener
    local self = setmetatable({}, EventListener)
    self.bus = bus
    self.listener_ids = {}
    return self
end

--- Subscribe `callback` to `event_name` and track the resulting ID.
---@param event_name GameEvent Event to subscribe to.
---@param callback fun(args: EventArgs) Function invoked when the event fires.
---@return integer Subscription ID; pass to `remove` to unsubscribe individually.
function EventListener:on(event_name, callback)
    local id = self.bus:on(event_name, callback)
    self.listener_ids[id] = true
    return id
end

--- Unsubscribe the listener with the given ID.
---@param id integer Subscription ID returned by `on`.
function EventListener:remove(id)
    self.listener_ids[id] = nil
    self.bus:remove(id)
end

--- Remove all subscriptions managed by this listener.
function EventListener:teardown()
    self.bus:remove_all(self.listener_ids)
end

return event_listener
