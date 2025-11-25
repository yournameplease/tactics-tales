
local listeners = {}
local event_bus = {}

local MAX_EVENT_HISTORY = 99
local event_history = {}

function event_bus.on(event_name, callback)
    if not listeners[event_name] then
        listeners[event_name] = {}
    end
    add(listeners[event_name], callback)
end

function event_bus.emit(event_name, args)
    if #event_history > MAX_EVENT_HISTORY then
        deli(event_history, 1)
    end
    add(event_history, event_name)

    local slots = listeners[event_name]
    if slots then
        for callback in all(slots) do
            callback(args)
        end
    end
end

function event_bus.get_event_history()
    return event_history
end

return event_bus