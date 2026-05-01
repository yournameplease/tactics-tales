---@brief
--- A simple event bus for decoupled communication between systems.
--- Allows services to subscribe to and emit global game events.

local id_generator = require("src.tactics.util.id_generator")

---@alias EventArgs table<string, any>
---@alias ListenerId integer Unique subscription ID returned by EventBus:on.

---@alias GameEvent
---| "TACTICS_BEGIN_TURN"
---| "TACTICS_END_TURN"
---| "TACTICS_BEGIN_PHASE"
---| "TACTICS_END_PHASE"
---| "TACTICS_FINISH_SIDE_ACTIONS"
---| "TACTICS_BEGIN_BATTLE"
---| "TACTICS_UNIT_END_ACTION"
---| "TACTICS_UNIT_DEATH"
---| "TACTICS_INTERACTION"
---| "UNIT_COMBAT"
---| "BEFORE_COMBAT"
---| "BEFORE_COUNTERATTACK"
---| "BATTLE_END"
---| "GAME_EXIT_CAMPAIGN"

---@class EventCallback
---@field id ListenerId Unique subscription ID used to remove this callback.
---@field callback fun(args: EventArgs) Function invoked when the event fires.

---@class EventBus
---@field id_generator IdGenerator Source of unique subscription IDs.
---@field event_history GameEvent[] Ring buffer of recently emitted events.
---@field listeners table<GameEvent, EventCallback[]> Callbacks keyed by event name.
local EventBus = {}
EventBus.__index = EventBus

local event_bus = {}

local MAX_EVENT_HISTORY = 20

--- Create a new, empty EventBus.
---@return EventBus
function event_bus.new()
    local self = setmetatable({}, EventBus)
    self.id_generator = id_generator.new()
    self.event_history = {}
    self.listeners = {}
    return self
end

--- Register `callback` to be called whenever `event_name` is emitted.
---@param event_name GameEvent Event to subscribe to.
---@param callback fun(args: EventArgs) Function invoked with the event's arguments.
---@return ListenerId Subscription ID; pass to `remove` to unsubscribe.
function EventBus:on(event_name, callback)
    if not self.listeners[event_name] then
        self.listeners[event_name] = {}
    end
    local id = self.id_generator:get_id()
    table.insert(self.listeners[event_name], {
        id = id,
        callback = callback,
    })
    return id
end

--- Remove the subscription with the given ID.
---@param id ListenerId Subscription ID returned by `on`.
function EventBus:remove(id)
    -- lazy: scan all event slots
    for _, slots in pairs(self.listeners) do
        for i, listener in ipairs(slots) do
            if listener.id == id then
                table.remove(slots, i)
                return
            end
        end
    end
    error("failed to remove listener")
end

--- Remove all subscriptions whose IDs are keys in `ids`.
---@param ids table<ListenerId, boolean> Set of subscription IDs to remove.
function EventBus:remove_all(ids)
    for id, _ in pairs(ids) do
        self:remove(id)
    end
end

--- Emit `event_name`, invoking all registered callbacks with `args`.
---@param event_name GameEvent Event to emit.
---@param args EventArgs? Arguments forwarded to each callback.
function EventBus:emit(event_name, args)
    log.debug("Received event", event_name)
    if args ~= nil then
        for k, v in pairs(args) do
            log.debug("arg: " .. k .. tostring(v))
        end
    end
    if #self.event_history > MAX_EVENT_HISTORY then
        table.remove(self.event_history, 1)
    end
    table.insert(self.event_history, event_name)

    local slots = self.listeners[event_name]
    if slots then
        for _, listener in ipairs(slots) do
            listener.callback(args or {})
        end
    end
end

--- Return up to `row_limit` events from the history, oldest first.
---@param row_limit integer Maximum number of history entries to return.
---@return GameEvent[]
function EventBus:get_event_history(row_limit)
    local out = {}
    for i = 1, row_limit do
        table.insert(out, self.event_history[i])
    end
    return out
end

return event_bus
