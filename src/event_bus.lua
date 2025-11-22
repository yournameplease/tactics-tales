
local listeners = {}
local event_bus = {}

function event_bus.on(event_name, callback)
    if not listeners[event_name] then
        listeners[event_name] = {}
    end
    add(listeners[event_name], callback)
end

function event_bus.emit(event_name, args)
    local slots = listeners[event_name]
    if slots then
        for callback in all(slots) do
            callback(args)
        end
    end
end

return event_bus