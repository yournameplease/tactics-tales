
global enum GameEvent
    "TACTICS_BEGIN_PLAYER_TURN"
    "TACTICS_END_PLAYER_TURN"
    "TACTICS_BEGIN_ENEMY_TURN"
    "TACTICS_END_ENEMY_TURN"
    "TACTICS_UNIT_END_ACTION"
    "MOVE_AND_ATTACK"
    "MOVE_AND_WAIT"
end

global type EventListener = function(args: any)

global record EventBus
    event_history: { GameEvent }
    listeners: { GameEvent: {EventListener}}
end

local MAX_EVENT_HISTORY = 99

function EventBus.new(): EventBus
    local self = setmetatable({}, { __index = EventBus })
    return self
end

function EventBus:on(event_name: GameEvent, callback: function(args: any))
    if not self.listeners[event_name] then
        self.listeners[event_name] = {}
    end
    add(self.listeners[event_name], callback)
end

function EventBus:emit(event_name: GameEvent, args?: any)
    if #self.event_history > MAX_EVENT_HISTORY then
        deli(self.event_history, 1)
    end
    add(self.event_history, event_name)

    local slots = self.listeners[event_name]
    if slots then
        for _,callback in ipairs(slots) do
            callback(args)
        end
    end
end

function EventBus:get_event_history(): { GameEvent }
    return self.event_history
end

return EventBus
